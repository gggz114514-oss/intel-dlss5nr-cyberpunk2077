// R15 ViT attention QK-INT8 candidate header.
// Derived from the parent vit_common.glsl published by plan-x5-vit-fixed.txt.
// Parent bytes are unchanged except the two marked edits (R15-1 tail members,
// R15-2 QK fragment offsets); the VIT_W8/VIT_A8/VIT_T8 macro structure, the
// push layout, MA/MB/MC/RM/CM, vit_cubic/vit_exp/vit_exp2/vit_code are verbatim.
//
// DIFF vs candidates/amd-netorg-t2-20261018/vit-companion-direct-epilogue-v1/source/vit_common.glsl
// (and the identical copy under vit-pden-register-handoff-v3-m05expair/source/):
//   * binding 0 Weights: macro-selected. VIT_W8=1 declares an INT8 VIEW of the same
//     buffer (same set/offset/byte count, element size 2B -> 1B) plus four typed
//     tail members: the scale header, the three per-channel dequant arrays and the
//     (copied) residual gain vectors.
//     This is the 3.10 rule: an int8 cooperative-matrix load/store must never be
//     handed a `float16_t[]` pointer, or glslang scales the base address by 2 while
//     the matrix access steps bytes.
//   * binding 4 Hidden and binding 7 Context: same macro treatment (VIT_A8 / VIT_T8)
//     for the qA and qT writers/readers.
//   * everything else unchanged: bindings, push layout, RM/CM, vit_cubic, vit_exp.
#ifndef VIT_COMMON_GLSL
#define VIT_COMMON_GLSL
#ifndef VIT_W8
#define VIT_W8 0
#endif
#ifndef VIT_A8
#define VIT_A8 0
#endif
#ifndef VIT_T8
#define VIT_T8 0
#endif

#if VIT_W8
// INT8 weight region: WE | WC | WO packed W[N/32][K/32][32][32] int8 (element size 1,
// total N*K bytes per segment), laid out inside the first 9,437,184 bytes of the
// unchanged 25,169,920-byte block weights buffer. The FP16 WQKV segment
// (byte 16,777,216) and the FP16 residual gain vectors (byte 25,165,824) are kept
// verbatim so the untouched d118 qkv kernel and the FP16 gain readers still work.
//   WE base 0, WC base 4,194,304, WO base 8,388,608.
// Scales  (std430 float, 4B aligned)  at byte 9,437,184:
//   ws[0..2] = sWE sWC sWO   per-tensor STEPS (absmax/127), informational; the
//              kernels use the per-channel dequant arrays below instead.
//   ws[3..5] = sX sA sT      per-tensor STEPS (absmax/127) of the three activation
//              edges; used only as dequant factors (ew = sX*sWE[n] etc).
//   ws[6..7] reserved (would hold sA*sWC / sT*sWO if alpha were per-tensor)
//   ws[8..10] = 127/absmax   INVERSE steps: the kernel-side quantiser multiplies by
//              these (code = roundEven(v * inv)). Keeping both conventions explicit
//              because mixing them is a silent 1/s^2 error.
//   ew[4096] at +64   : sX*sWE[n]  (expand   per-output-channel dequant, 1 mul/comp)
//   ac[1024] at +16448: sA*sWC[n]  (contract per-output-channel alpha)
//   ap[1024] at +20544: sT*sWO[n]  (projection per-output-channel alpha)
//   wg[2048] at +24640: half copies of the FP16 residual gain vectors
//     wg[0..1024) = contract root gain (push p2.x segment)
//     wg[1024..2048) = projection gain (push p2.y segment)
layout(set=0,binding=0,std430) readonly buffer Weights {
    int8_t    w8[9437184];
    float     ws[16];
    float     ew[4096];
    float     ac[1024];
    float     ap[1024];
    float16_t wg[2048];
    // ---- R15-1: qkv-int8 pack tail (declared so qi/qp land on the packer offsets)
    int8_t    wqkv8[3145728]; // 9,465,920
    float     aq[3072];       // 12,611,648
    float     qi[64];         // 12,623,936  127/absmax(Q) [0..31], 127/absmax(K) [32..63]
    float     qp[32];         // 12,624,192  sQ_h*sK_h = (absmaxQ/127)*(absmaxK/127)
};
#define VIT_W8_WE 0u
#define VIT_W8_WC 4194304u
#define VIT_W8_WO 8388608u
#define VIT_GAIN_C(col) float(wg[(col)])
#define VIT_GAIN_P(col) float(wg[1024u+(col)])
// ---- R15-2: QK int8 fragment offsets inside binding 4 (vit_blockNN_A).
// The parent leaves [1,769,472, 2,359,296) of that 2,359,296-byte buffer free
// (qA [0,1,179,648), qX [1,179,648,1,474,560), qY [1,474,560,1,769,472)).
// Layout [head][token][dim]: head stride 288*32 = 9,216 B, token stride 32 B,
// which is the only layout that makes both int8 coopMatLoads contiguous
// (A RowMajor stride 32, B ColumnMajor stride 32).
#define QK_Q_OFF 1769472u
#define QK_K_OFF 2064384u
#define QK_HEAD_STRIDE 9216u
#else
layout(set=0,binding=0,std430) readonly buffer Weights { float16_t w[]; };
#define VIT_GAIN_C(col) float(w[pc.p2.x+(col)])
#define VIT_GAIN_P(col) float(w[pc.p2.y+(col)])
#endif

layout(set=0,binding=1,std430) readonly buffer Scales { float scales[]; };
layout(set=0,binding=2,std430) readonly buffer Input { float16_t x[]; };
layout(set=0,binding=3,std430) buffer Output { float16_t o[]; };
#if VIT_A8
layout(set=0,binding=4,std430) buffer Hidden { int8_t aHidden[]; };
#else
layout(set=0,binding=4,std430) buffer Hidden { float16_t aHidden[]; };
#endif
layout(set=0,binding=5,std430) buffer Residual { float16_t y[]; };
layout(set=0,binding=6,std430) buffer QKV { float16_t qkv[]; };
#if VIT_T8
layout(set=0,binding=7,std430) buffer Context { int8_t context[]; };
#else
layout(set=0,binding=7,std430) buffer Context { float16_t context[]; };
#endif
layout(set=0,binding=8,std430) buffer Debug { float16_t dbg[]; };
layout(set=0,binding=8,std430) buffer DebugFloat { float dbgf[]; };
layout(push_constant) uniform Push {
    uvec4 p0; // live tokens, padded keys (64), stage, debug
    uvec4 p1; // WE, WC, WQKV, WO half offsets (FP16 kernels only; INT8 variants use VIT_W8_*)
    uvec4 p2; // FF skip, out skip half offsets, scale float offset, block
    uvec4 p3; // debug E half, QKV0 half, logits float, exponentials half
    uvec4 p4; // denominator half, numerator half, inverse half, reserved
    uvec4 p5; // input, output, hidden, Y half bases
    uvec4 p6; // QKV, context, debug half bases, reserved
    uvec4 p7; // debug bytes, profile=1, reserved, reserved
} pc;
#define MA coopmat<float16_t,gl_ScopeSubgroup,8,16,gl_MatrixUseA>
#define MB coopmat<float16_t,gl_ScopeSubgroup,16,16,gl_MatrixUseB>
#define MC coopmat<float,gl_ScopeSubgroup,8,16,gl_MatrixUseAccumulator>
#define RM gl_CooperativeMatrixLayoutRowMajor
#define CM gl_CooperativeMatrixLayoutColumnMajor
// INT8 tuples (B580: INT8->INT32 uses K=32; verified by this candidate's compile probe).
#define MA8 coopmat<int8_t,gl_ScopeSubgroup,8,32,gl_MatrixUseA>
#define MB8 coopmat<int8_t,gl_ScopeSubgroup,32,16,gl_MatrixUseB>
#define AC8 coopmat<int,gl_ScopeSubgroup,8,16,gl_MatrixUseAccumulator>
#define MQ8 coopmat<int8_t,gl_ScopeSubgroup,8,16,gl_MatrixUseAccumulator>
#define MF8 coopmat<float,gl_ScopeSubgroup,8,16,gl_MatrixUseAccumulator>

// W[N/32][K/16][32][16], offsets/strides in half elements.
uint vit_wbase(uint base, uint n, uint k, uint K) {
    return base + (n/32u)*(K/16u)*512u + (k/16u)*512u + (n%32u)*16u;
}
// INT8: W[N/32][K/32][32][32], offsets/strides in int8 elements (= bytes).
//
// SPEC CORRECTION (not a silent change): registry/VIT-GEMM-SHAPES.json int8_shape_note
// states the tile as "W[N/32][K/32][32][16] int8". That tile holds 32*16 = 512 bytes =
// N*K/2, i.e. it covers only half of a K=32 segment and cannot be addressed with a single
// stride. The corrected layout is W[N/32][K/32][32][32]: exactly 1024 B per tile, each
// segment exactly N*K bytes, loaded ColumnMajor with stride 32 (element (k,n) at
// n*32 + k). Accepted by team-lead on 2026-10-19 as deviation D1; the original spec text
// is wrong and must not be restored.
uint vit_wbase8(uint base, uint n, uint k, uint K) {
    return base + (n/32u)*(K/32u)*1024u + (k/32u)*1024u + (n%32u)*32u;
}
float16_t vit_cubic(float16_t z) {
    precise float16_t t=clamp(z,float16_t(-4.0),float16_t(4.0));
    precise float16_t u=fma(float16_t(-0.055908203125),abs(t),float16_t(0.447265625));
    precise float16_t v=fma(t,u,float16_t(0.89453125));
    return z*v;
}
float16_t vit_exp(float16_t z) {
    precise float16_t v=clamp(fma(z,float16_t(0.08953857421875),float16_t(1.708984375)),
                              float16_t(1.439453125),float16_t(1.9775390625));
    uint h=packHalf2x16(vec2(float(v),0.0))&0xffffu;
    return float16_t(unpackHalf2x16((h&0x3ffu)<<4u).x);
}
f16vec2 vit_exp2(f16vec2 xy) {
    precise f16vec2 v=clamp(fma(xy,f16vec2(float16_t(0.08953857421875)),f16vec2(float16_t(1.708984375))),
                            f16vec2(float16_t(1.439453125)),f16vec2(float16_t(1.9775390625)));
    uint h=packFloat2x16(v);
    return unpackFloat2x16((h&0x3ff03ffu)<<4u);
}
// Producer-side requant, one definition for every INT8 store point of this template:
// multiply by the INVERSE step -> clamp -> RNE -> int8. No pre-rounded half fold, no
// compensation term. `inv` must be 127/absmax (ws[8..10]), never absmax/127.
float vit_code(float v, float inv) {
    precise float c = v * inv;
    return clamp(roundEven(c), -127.0, 127.0);
}
#endif
