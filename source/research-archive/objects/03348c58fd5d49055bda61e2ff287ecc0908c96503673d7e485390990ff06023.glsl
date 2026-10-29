// C32 body_1 unified INT8 tail: types, scale table, code points and the int8
// tile helpers for the expand, contract, QKV, QK, PV and output segments.
//
//   expand   E[f,t] = sum_c We[f,c] * X[c,t]    M=8  N=16 K=32
//   contract Y[o,t] = sum_e Wc[o,e] * E[e,t]    M=8  N=16 K=128 (4 x K32 steps)
//   QKV      Z[ch,t] = sum_c W?[ch,c] * Y[c,t]  M=8  N=16 K=32   (12 sites)
//   QK       S[key,q] = sum_d K[key,d] * Q[q,d] M=8  N=16 K=32   (8 sites)
//   PV       C[d,q]   = sum_k V[k,d] * P[q,k]   M=8  N=16 K=64 (2 x K32)
//   output   O[ch,q]  = sum_d WO[ch,d] * Ctx[d,q] M=8 N=16 K=32   (4 sites)
//
// Every one of those is one measured M8N16K32 signed-int8 -> int32 cooperative
// matrix: A = 8x32 int8 MatrixA, B = 32x16 int8 MatrixB, C = 8x16 int32
// Accumulator (candidates/dsh-int8-same-family-20261023/abi-probe/
// I8-ABI-MEASURED.json).  The parent's scalar FP16 chain (MpCubicSilu, per-token
// norm, score bias, swin exp, half denominator, reciprocal, residual seeds and
// every single narrow) is unchanged and is not a matrix multiply.
//
// SCALE CONVENTION.  Two kinds of scale exist and they are never mixed:
//   * static  : a per-output-channel weight scale sW[n] = amax_k|W[n,k]|/127,
//               computed offline by the checked-in generator and read from fsc.
//   * dynamic : an activation scale computed inside the kernel from the very
//               values that get quantised (per token for Y/K/Q/ctx, per query
//               for P, per dimension for V).  A dynamic scale is carried as
//               s = amax/127 (dequant) and inv = 127/amax (quantise), and it is
//               never folded into a static tap.
// The dequant of one output element is therefore always
//     real = int32acc * (static_row_tap * dynamic_column_scale)
// i.e. a rank-1 product, which is exact in f32 for every operand here.
#ifndef C32_I8_COMMON_GLSL
#define C32_I8_COMMON_GLSL
#define I8A coopmat<int8_t, gl_ScopeSubgroup, 8, 32, gl_MatrixUseA>
#define I8B coopmat<int8_t, gl_ScopeSubgroup, 32, 16, gl_MatrixUseB>
#define I8C coopmat<int, gl_ScopeSubgroup, 8, 16, gl_MatrixUseAccumulator>
#define I8F coopmat<float, gl_ScopeSubgroup, 8, 16, gl_MatrixUseAccumulator>
// fsc layout.
//   0=sX 1=invX 2=sE 3=invE, 4..131 = sX*sWe[128], 132..163 = sE*sWc[32]
//   -- the parent's 164 entries, copied verbatim by the pack generator, because
//      the expand and contract segments still run the parent's own dequant.
//   164..195 = sWq[32], 196..227 = sWk[32], 228..259 = sWv[32], 260..291 = sWo[32]
//   -- plain static per-output-channel weight scales of this card.  These are
//      NOT R02's table: R02 stored sY*sW? (a *folded* product with one block's
//      single-frame Y scale) at 164..259 plus invY at 260.  This card has no
//      static activation scale at all, so those entries are not reused.
#define C32_I8_MULT_E 4u
#define C32_I8_MULT_C 132u
#define C32_I8_DQ_Q 164u
#define C32_I8_DQ_K 196u
#define C32_I8_DQ_V 228u
#define C32_I8_DQ_O 260u
#define C32_I8_FSC_ENTRIES 292u
// w8 layout (bytes): the parent's expand 16 x 1024 and contract 16 x 1024 are
// untouched; this card appends the QKV and WO I8A K32 tiles.  Tile g holds the
// 8 output channels 8g..8g+7 of one plane; the code of (channel m, input k) sits
// at byte k*32 + m inside the 1024-byte tile, which is the stride-32 I8A K32
// addressing the kernel loads with coopMatLoad(..., 32u, LCOL).
#define C32_I8_QKV_W 32768u
#define C32_I8_WQ (C32_I8_QKV_W + 0u*4096u)
#define C32_I8_WK (C32_I8_QKV_W + 1u*4096u)
#define C32_I8_WV (C32_I8_QKV_W + 2u*4096u)
#define C32_I8_WO (C32_I8_QKV_W + 3u*4096u)
#define C32_I8_W8_BYTES 49152u

// One symmetric code point: real * inv, RNE, clamp to +-127.  (Parent function,
// byte-identical arithmetic; every quantiser in this kernel calls it.)
float nr_i8_code(float16_t v, float inv) {
    precise float c = float(v) * inv;
    return clamp(roundEven(c), -127.0, 127.0);
}
// Real value of one int32 accumulator fragment with the parent's static
// per-output-channel tap (contract / expand dequant).
NRH_C nr_i8_deq(I8C a, uint mbase, uint sbase) {
    I8F f = I8F(a);
    NRH_C o = NRH_C(0.0);
    for (int i = 0; i < 4; ++i) {
        uvec2 rc = nrh_coord_C(uint(i));
        o[i] = f[i] * fsc[sbase + mbase + rc.x];
    }
    return o;
}
// Contract epilogue: dequant plus the original FP32 seed, one narrow afterwards.
NRH_C nr_i8_deq_add(I8C a, uint mbase, uint sbase, NRH_C seed) {
    I8F f = I8F(a);
    NRH_C o = NRH_C(0.0);
    for (int i = 0; i < 4; ++i) {
        uvec2 rc = nrh_coord_C(uint(i));
        precise float p = f[i] * fsc[sbase + mbase + rc.x];
        precise float q = p + seed[i];
        o[i] = q;
    }
    return o;
}
// Rank-1 dequant: static per-output-channel tap (row) x dynamic activation scale
// of this lane's own column.  Used by QKV and by the output projection.
NRH_C nr_i8_deq_w(I8C a, uint mbase, uint sbase, float scol) {
    I8F f = I8F(a);
    NRH_C o = NRH_C(0.0);
    for (int i = 0; i < 4; ++i) {
        uvec2 rc = nrh_coord_C(uint(i));
        precise float tap = fsc[sbase + mbase + rc.x] * scol;
        o[i] = f[i] * tap;
    }
    return o;
}
// Output-projection epilogue: dequant + the parent's FP32 residual seed, then one
// narrow.  An int32 accumulator cannot inherit a float seed, so the seed enters
// here, exactly once, in the same `precise` two-step the parent's accumulate had.
NRH_C nr_i8_deq_add_w(I8C a, uint mbase, uint sbase, float scol, NRH_C seed) {
    I8F f = I8F(a);
    NRH_C o = NRH_C(0.0);
    for (int i = 0; i < 4; ++i) {
        uvec2 rc = nrh_coord_C(uint(i));
        precise float tap = fsc[sbase + mbase + rc.x] * scol;
        precise float p = f[i] * tap;
        precise float q = p + seed[i];
        o[i] = q;
    }
    return o;
}
// QK dequant: the A operand is K, whose static side is the *activation* itself,
// so its per-key scale lives in the workgroup tile sKsc (one float per key) and
// the B side (Q) is this lane's own column scale.
NRH_C nr_i8_deq_k(I8C a, uint rbase, float scol) {
    I8F f = I8F(a);
    NRH_C o = NRH_C(0.0);
    for (int i = 0; i < 4; ++i) {
        uvec2 rc = nrh_coord_C(uint(i));
        precise float tap = sKsc[rbase + rc.x] * scol;
        o[i] = f[i] * tap;
    }
    return o;
}
// PV dequant: per-dimension V scale for this lane's four rows (vec4 in component
// order) x this lane's own query scale.
NRH_C nr_i8_deq_v(I8C a, vec4 srow, float scol) {
    I8F f = I8F(a);
    NRH_C o = NRH_C(0.0);
    precise float t0 = srow.x * scol;
    precise float t1 = srow.y * scol;
    precise float t2 = srow.z * scol;
    precise float t3 = srow.w * scol;
    o[0] = f[0] * t0;
    o[1] = f[1] * t1;
    o[2] = f[2] * t2;
    o[3] = f[3] * t3;
    return o;
}
// ---- int8 tile writers ----------------------------------------------------
// All six tiles share the same per-fragment shape: component c of this lane is
// row 2c + (lane>=16) and column lane%16 of the 8x16 fragment, so one writer
// pattern serves every segment; only the destination array and the scale differ.
// X: 8 channels x 16 tokens, byte token*32 + channel (parent layout, unchanged).
void nr_i8_put_x(NRH_CH x, uint cbase, uint sgoff) {
    for (int i = 0; i < 4; ++i) {
        uvec2 rc = nrh_coord_CH(uint(i));
        sT8[sgoff + rc.y * 32u + cbase + rc.x] = int8_t(nr_i8_code(x[i], fsc[1]));
    }
}
// Y (QKV input) and Ctx (output-projection input) share the dead X storage; both
// are 8 channels x 16 tokens with the same byte token*32 + channel layout.
void nr_i8_put_y(NRH_CH y, uint cbase, uint sgoff, float inv) {
    for (int i = 0; i < 4; ++i) {
        uvec2 rc = nrh_coord_CH(uint(i));
        sT8[sgoff + rc.y * 32u + cbase + rc.x] = int8_t(nr_i8_code(y[i], inv));
    }
}
// Q and K tiles: 8 dims x 16 keys/tokens, byte token*32 + dim.
void nr_i8_put_q(NRH_CH q, uint cbase, uint sgoff, float inv) {
    for (int i = 0; i < 4; ++i) {
        uvec2 rc = nrh_coord_CH(uint(i));
        sQ8[sgoff + rc.y * 32u + cbase + rc.x] = int8_t(nr_i8_code(q[i], inv));
    }
}
void nr_i8_put_k(NRH_CH k, uint cbase, uint sgoff, float inv) {
    for (int i = 0; i < 4; ++i) {
        uvec2 rc = nrh_coord_CH(uint(i));
        sK8[sgoff + rc.y * 32u + cbase + rc.x] = int8_t(nr_i8_code(k[i], inv));
    }
}
// V tile: same byte layout, but the scale is per dimension, i.e. per component.
void nr_i8_put_v(NRH_CH v, uint cbase, uint sgoff, vec4 inv) {
    for (int i = 0; i < 4; ++i) {
        uvec2 rc = nrh_coord_CH(uint(i));
        sV8[sgoff + rc.y * 32u + cbase + rc.x] = int8_t(nr_i8_code(v[i], inv[i]));
    }
}
// P tile: 8 keys x 16 queries, byte query*64 + key (the B side of PV is P^T with
// a stride-64 column-major load, so the key is the inner index of a query row).
void nr_i8_put_p(NRH_CH p, uint kbase, uint sgoff, float inv) {
    for (int i = 0; i < 4; ++i) {
        uvec2 rc = nrh_coord_CH(uint(i));
        uint q = gl_SubgroupInvocationID & 15u;      // this lane owns one query
        sP8[sgoff + q * 64u + kbase + rc.x] = int8_t(nr_i8_code(p[i], inv));
    }
}
// ---- activation-scale reductions ------------------------------------------
// All four are cross-lane reductions over a *single* column of the fragment, and
// they are written as shuffles because the parent kernel deliberately has no
// subgroupAdd / subgroupMax (see the comment at nr_norm32_pair).
// A: one column's 32 rows live in this lane's 16 components (4 fragments x 4)
//    plus the parity partner's 16 -> one xor-16 shuffle.  Exact: max of halves.
float nr_col_max32(NRH_CH a, NRH_CH b, NRH_CH c, NRH_CH d) {
    float m = max(max(abs(float(a[0])), abs(float(a[1]))),
                  max(abs(float(a[2])), abs(float(a[3]))));
    m = max(m, max(max(abs(float(b[0])), abs(float(b[1]))),
                   max(abs(float(b[2])), abs(float(b[3])))));
    m = max(m, max(max(abs(float(c[0])), abs(float(c[1]))),
                   max(abs(float(c[2])), abs(float(c[3])))));
    m = max(m, max(max(abs(float(d[0])), abs(float(d[1]))),
                   max(abs(float(d[2])), abs(float(d[3])))));
    uint bits = packFloat2x16(f16vec2(float16_t(m), float16_t(m)));
    return max(m, float(unpackFloat2x16(subgroupShuffleXor(bits, 16u)).x));
}
// One fragment's own absolute maximum (no reduction); used to accumulate the
// per-token Q/K maximum across the four fragments.
float nr_abs4(NRH_CH x) {
    return max(max(abs(float(x[0])), abs(float(x[1]))),
               max(abs(float(x[2])), abs(float(x[3]))));
}
// The same reduction for eight fragments (the 64-key probability row): one local
// maximum over the lane's 32 values, then the same single xor-16 shuffle.
float nr_row_max64(NRH_CH a, NRH_CH b, NRH_CH c, NRH_CH d,
                   NRH_CH e, NRH_CH f, NRH_CH g, NRH_CH h) {
    float m = max(max(nr_abs4(a), nr_abs4(b)), max(nr_abs4(c), nr_abs4(d)));
    m = max(m, max(max(nr_abs4(e), nr_abs4(f)), max(nr_abs4(g), nr_abs4(h))));
    uint bits = packFloat2x16(f16vec2(float16_t(m), float16_t(m)));
    return max(m, float(unpackFloat2x16(subgroupShuffleXor(bits, 16u)).x));
}
// Per-dimension maximum of |V| over this subgroup's 16 keys.  Component c of
// fragment v owns dimension 2c + (lane>=16); the 16 keys of that dimension sit
// in the 16 lanes of the lane's own parity group, so a four-step xor tree over
// {1,2,4,8} combines them without leaving the subgroup.  (Dimensions are the
// output channels of the PV contraction, so this is a per-channel scale.)
vec4 nr_dim_max16(NRH_CH v) {
    vec4 m = vec4(abs(float(v[0])), abs(float(v[1])),
                  abs(float(v[2])), abs(float(v[3])));
    uint p01 = packFloat2x16(f16vec2(float16_t(m.x), float16_t(m.y)));
    uint p23 = packFloat2x16(f16vec2(float16_t(m.z), float16_t(m.w)));
    {
        f16vec2 a = unpackFloat2x16(subgroupShuffleXor(p01, 1u));
        f16vec2 b = unpackFloat2x16(subgroupShuffleXor(p23, 1u));
        m = max(m, vec4(float(a.x), float(a.y), float(b.x), float(b.y)));
        p01 = packFloat2x16(f16vec2(float16_t(m.x), float16_t(m.y)));
        p23 = packFloat2x16(f16vec2(float16_t(m.z), float16_t(m.w)));
    }
    {
        f16vec2 a = unpackFloat2x16(subgroupShuffleXor(p01, 2u));
        f16vec2 b = unpackFloat2x16(subgroupShuffleXor(p23, 2u));
        m = max(m, vec4(float(a.x), float(a.y), float(b.x), float(b.y)));
        p01 = packFloat2x16(f16vec2(float16_t(m.x), float16_t(m.y)));
        p23 = packFloat2x16(f16vec2(float16_t(m.z), float16_t(m.w)));
    }
    {
        f16vec2 a = unpackFloat2x16(subgroupShuffleXor(p01, 4u));
        f16vec2 b = unpackFloat2x16(subgroupShuffleXor(p23, 4u));
        m = max(m, vec4(float(a.x), float(a.y), float(b.x), float(b.y)));
        p01 = packFloat2x16(f16vec2(float16_t(m.x), float16_t(m.y)));
        p23 = packFloat2x16(f16vec2(float16_t(m.z), float16_t(m.w)));
    }
    {
        f16vec2 a = unpackFloat2x16(subgroupShuffleXor(p01, 8u));
        f16vec2 b = unpackFloat2x16(subgroupShuffleXor(p23, 8u));
        m = max(m, vec4(float(a.x), float(a.y), float(b.x), float(b.y)));
        p01 = packFloat2x16(f16vec2(float16_t(m.x), float16_t(m.y)));
        p23 = packFloat2x16(f16vec2(float16_t(m.z), float16_t(m.w)));
    }
    return m;
}
// Workgroup per-dimension |V| scale for fragment j: the four subgroups published
// their own 16-key maxima in sVpm before the cross-subgroup barrier, so the
// maximum of the four is the 64-key tile maximum.  s = amax/127 (dequant).
vec4 nr_v_scale(uint j) {
    vec4 s;
    for (int i = 0; i < 4; ++i) {
        uvec2 rc = nrh_coord_CH(uint(i));
        uint d = j * 8u + rc.x;
        float m = max(max(sVpm[d], sVpm[32u + d]),
                      max(sVpm[64u + d], sVpm[96u + d]));
        s[i] = (m > 0.0) ? (m * (1.0 / 127.0)) : 0.0;
    }
    return s;
}
// Component-wise 1/s with a zero scale mapped to a zero multiplier, so a
// degenerate (all-zero) tile codes to zero instead of a NaN.
vec4 nr_inv4(vec4 s) {
    return vec4((s.x > 0.0) ? (1.0 / s.x) : 0.0,
                (s.y > 0.0) ? (1.0 / s.y) : 0.0,
                (s.z > 0.0) ? (1.0 / s.z) : 0.0,
                (s.w > 0.0) ? (1.0 / s.w) : 0.0);
}
#endif
