// vit-qkv-int8-v1 common header: the sealed b3_04_vit_common.glsl (which reproduces the
// deployed vit_qkv.spv byte-exactly) with two INT8 views added, nothing else changed.
//
//   * binding 0 Weights gains an INT8 view of the same buffer/offset/bytes (element size
//     2B -> 1B) plus the typed tail the pack already carries: ws/ew/ac/ap/wg and the NEW
//     WQKV int8 segment + per-output-channel qkv alpha array.  This is the 3.10 rule:
//     an int8 cooperative-matrix load must never be handed a float16_t[] pointer.
//   * binding 4 Hidden gains the same INT8 treatment: it was DECLARED_UNUSED in every
//     deployed qkv pass, so the qY codes the contract pass writes (VIT_QY_OFF) live there.
#ifndef VIT_QKV_COMMON_GLSL
#define VIT_QKV_COMMON_GLSL

layout(set=0,binding=0,std430) readonly buffer Weights {
    int8_t    w8[9437184];   // WE|WC|WO int8 segments (0..9,437,184) - NOT 9,465,920:
                             // the first version of this header used the wqkv8 offset as
                             // the w8 size, which shifted every tail member by 73,728 B and
                             // made the B operand read zeros (all-zero QKV, arm qkv-diag-001).
    float     ws[16];        // 9,437,184
    float     ew[4096];      // 9,437,248
    float     ac[1024];      // 9,453,632
    float     ap[1024];      // 9,457,728
    float16_t wg[2048];      // 9,461,824
    int8_t    wqkv8[3145728];// 9,465,920
    float     aq[3072];      // 12,611,648
};
#define VIT_W8_WQKV 9465920u
#define VIT_QY_OFF  1474560u

layout(set=0,binding=1,std430) readonly buffer Scales { float scales[]; };
layout(set=0,binding=2,std430) readonly buffer Input { float16_t x[]; };
layout(set=0,binding=3,std430) buffer Output { float16_t o[]; };
layout(set=0,binding=4,std430) buffer Hidden { int8_t aHidden[]; };
layout(set=0,binding=5,std430) buffer Residual { float16_t y[]; };
layout(set=0,binding=6,std430) buffer QKV { float16_t qkv[]; };
layout(set=0,binding=7,std430) buffer Context { float16_t context[]; };
layout(set=0,binding=8,std430) buffer Debug { float16_t dbg[]; };
layout(set=0,binding=8,std430) buffer DebugFloat { float dbgf[]; };
layout(push_constant) uniform Push {
    uvec4 p0; // live tokens, padded keys (64), stage, debug
    uvec4 p1; // WE, WC, WQKV, WO half offsets
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
// B580 INT8 tuple (queried: M8/N16/K32 SINT8xSINT8->SINT32)
#define MA8 coopmat<int8_t,gl_ScopeSubgroup,8,32,gl_MatrixUseA>
#define MB8 coopmat<int8_t,gl_ScopeSubgroup,32,16,gl_MatrixUseB>
#define AC8 coopmat<int,gl_ScopeSubgroup,8,16,gl_MatrixUseAccumulator>
#define MF8 coopmat<float,gl_ScopeSubgroup,8,16,gl_MatrixUseAccumulator>

// W[N/32][K/16][32][16], offsets/strides in half elements (frozen FP16 convention).
uint vit_wbase(uint base, uint n, uint k, uint K) {
    return base + (n/32u)*(K/16u)*512u + (k/16u)*512u + (n%32u)*16u;
}
// W[N/32][K/32][32][32] int8, offsets in elements (= bytes); element (k,n) at n*32+k.
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
#endif
