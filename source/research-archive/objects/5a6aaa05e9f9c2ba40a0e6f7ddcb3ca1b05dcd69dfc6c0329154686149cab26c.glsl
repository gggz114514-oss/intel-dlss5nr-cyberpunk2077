// C32-I8 v1: static symmetric INT8 operands for the fused C32 FFN linear pair.
//   expand   E[f,t] = sum_c We[f,c] * X[c,t]   M=8(feature) N=16(token) K=32
//   contract Y[o,t] = sum_e Wc[o,e] * E[e,t]   M=8(output)  N=16(token) K=128 (4x32)
// The integer accumulator completes the whole K before one FP32 dequant multiply
// per output channel.  The original FP16 nonlinear (nr_act_h), the contract seed
// H(X*rs) and the single narrow after the accumulator are kept in original order.
// QKV, norm, score, exp, denominator, PV and the output projection stay FP16 and
// byte-identical to the parent kernel.
#ifndef C32_I8_COMMON_GLSL
#define C32_I8_COMMON_GLSL
#define I8A coopmat<int8_t, gl_ScopeSubgroup, 8, 32, gl_MatrixUseA>
#define I8B coopmat<int8_t, gl_ScopeSubgroup, 32, 16, gl_MatrixUseB>
#define I8C coopmat<int, gl_ScopeSubgroup, 8, 16, gl_MatrixUseAccumulator>
#define I8F coopmat<float, gl_ScopeSubgroup, 8, 16, gl_MatrixUseAccumulator>
// fsc layout: 0=sX 1=invX 2=sE 3=invE, 4..131 = sX*sWe[128], 132..163 = sE*sWc[32].
#define C32_I8_MULT_E 4u
#define C32_I8_MULT_C 132u
// ---- R02 QKV segment (added; the parent's 164 entries are unchanged) -------
// 164..195 = sY*sWq[32], 196..227 = sY*sWk[32], 228..259 = sY*sWv[32],
// 260 = invY.  sY*sW? is the folded per-output-channel dequant factor, exactly
// the convention C32_I8_MULT_E / C32_I8_MULT_C already use: the activation
// scale is static per tensor, so it is folded into the 96 channel factors at
// pack time and the kernel performs one multiply per (channel, token).
#define C32_I8_DQ_Q 164u
#define C32_I8_DQ_K 196u
#define C32_I8_DQ_V 228u
#define C32_I8_INV_Y 260u
// Static INT8 weight tiles for Q/K/V: 12 tiles of 1024 B appended to w8 after
// the parent's 32768 B (16 expand + 16 contract tiles).  Tile g holds the 8
// output channels 8g..8g+7 of one projection; the int8 code of (channel m,
// input k) sits at byte k*32 + m, which is the measured I8A K32 layout.
#define C32_I8_QKV_W 32768u
#define C32_I8_WQ (C32_I8_QKV_W + 0u*4096u)
#define C32_I8_WK (C32_I8_QKV_W + 1u*4096u)
#define C32_I8_WV (C32_I8_QKV_W + 2u*4096u)
// One static symmetric code point: real * inv, RNE, clamp to +-127.
float nr_i8_code(float16_t v, float inv) {
    precise float c = float(v) * inv;
    return clamp(roundEven(c), -127.0, 127.0);
}
// Real value of one int32 accumulator fragment (rows = output features, cols = tokens).
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
// X fragment rows are 8 channels, columns are 16 tokens (original tiled input layout).
void nr_i8_put_x(NRH_CH x, uint cbase, uint sgoff) {
    for (int i = 0; i < 4; ++i) {
        uvec2 rc = nrh_coord_CH(uint(i));
        sX8[sgoff + rc.y * 32u + cbase + rc.x] = int8_t(nr_i8_code(x[i], fsc[1]));
    }
}
// Activated E fragment rows are 8 features, columns are 16 tokens.
void nr_i8_put_e(NRH_CH e, uint fbase, uint sgoff) {
    for (int i = 0; i < 4; ++i) {
        uvec2 rc = nrh_coord_CH(uint(i));
        uint f = fbase + rc.x;
        sE8[sgoff + (f / 32u) * 512u + rc.y * 32u + (f % 32u)] =
            int8_t(nr_i8_code(e[i], fsc[3]));
    }
}
// R02 QKV input: the contract row Y (32 channels x 16 tokens per subgroup),
// quantized once per tensor into the I8B K32 tile the expand already uses
// (byte n*32 + k for channel k of token n).  Same code point, same rounding,
// same clamp as nr_i8_put_x / nr_i8_put_e; only the scale is the QKV input
// scale fsc[C32_I8_INV_Y] instead of the FFN input scale fsc[1].
void nr_i8_put_y(NRH_CH y, uint cbase, uint sgoff) {
    for (int i = 0; i < 4; ++i) {
        uvec2 rc = nrh_coord_CH(uint(i));
        sY8[sgoff + rc.y * 32u + cbase + rc.x] =
            int8_t(nr_i8_code(y[i], fsc[C32_I8_INV_Y]));
    }
}
#endif
