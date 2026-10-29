// c64_int8_common.glsl — C64 (84x48 tile / 42x24 window) FFN INT8 ABI.
//
// Private family copy (VK-INT8-ZCODE-COVERAGE-FIRST-EXECUTION-V2 §7 / 工单 B2).
// Derived from candidates/codex-sol-int8-long-008-20261019/c128-diffusion-v1/
// source/pilot_common.glsl (math identity: static symmetric INT8 operands,
// int32 accumulate, float dequant, one half narrowing) and the C64 FP16
// geometry of candidates/amd-netorg-direction-corrections-workbuddy-20261017/
// c3-r07-twodispatch/source/nb05_swin_c64_common.glsl.
//
// Push-constant ABI is the *parent* C64 ABI (unchanged PASS pushes):
//   p0 = tiles_x=84, tiles_y=48, shift_x, shift_y (signed)
//   p1 = grid_x, grid_y, single_mode, debug
//   p3 = we_half, wm_half, wc_half, wq_half        (FP16 pack offsets, diagnostic)
//   p4 = wo_half, rs_half, ars_half, bias_float    (FP16 residual scale offset)
//   p5/p6/p7 kept for ABI compatibility, unused here.
//
// Bindings (subset of the parent 8-binding ABI; unused indices are still bound
// by the plan):
//   0 weights  : int8 W8, row-major [N][K] (expand 256x64, mid 64x128, contract 64x64)
//   1 scales   : f32 table, offsets declared below
//   2 qX       : int8 token-major (tile*16+slot)*64+c
//   4 dotdump  : float (diagnostic only, p7.x != 0)
//   5 qM       : int8 window-major (w*64+m)*64+c
//   6 Y        : float16 window-major (w*64+m)*64+c
//
// Scale table offsets (floats):
//   0 sX, 1 invSX, 2 invSA, 3 invSM
//   16  expand  sX*sWe[256]
//   272 mid     sA*sWm[64]
//   336 contract sM*sWc[64]
//   400 residual sX*rs[64]
//   total 464 floats = 1856 B
#ifndef C64_INT8_COMMON_GLSL
#define C64_INT8_COMMON_GLSL

#extension GL_EXT_shader_explicit_arithmetic_types_int8 : require
#extension GL_EXT_shader_8bit_storage : require

#define QT int8_t
#define KS 32u
#define MA coopmat<int8_t, gl_ScopeSubgroup, 8, 32, gl_MatrixUseA>
#define MB coopmat<int8_t, gl_ScopeSubgroup, 32, 16, gl_MatrixUseB>
#define ACC coopmat<int, gl_ScopeSubgroup, 8, 16, gl_MatrixUseAccumulator>
#define MF coopmat<float, gl_ScopeSubgroup, 8, 16, gl_MatrixUseAccumulator>
#define MH coopmat<float16_t, gl_ScopeSubgroup, 8, 16, gl_MatrixUseAccumulator>
#define MQ coopmat<QT, gl_ScopeSubgroup, 8, 16, gl_MatrixUseAccumulator>
#define ZERO 0
#define ROW gl_CooperativeMatrixLayoutRowMajor
#define COL gl_CooperativeMatrixLayoutColumnMajor

#define SC_EXPAND 16u
#define SC_MID 272u
#define SC_CONTRACT 336u
#define SC_RESID 400u
#define SC_NFLOAT 464u

layout(set = 0, binding = 0) readonly buffer Weights { QT qw[]; };
layout(set = 0, binding = 1) readonly buffer Scales { float sc[]; };
layout(set = 0, binding = 2) readonly buffer PackedEntry { QT gx[]; };
layout(set = 0, binding = 4) buffer DotDump { float dd[]; };
layout(set = 0, binding = 5) buffer Mid { QT gm[]; };
layout(set = 0, binding = 6) buffer Output { float16_t gy[]; };

layout(push_constant) uniform PC { ivec4 p0; ivec4 p1; ivec4 p2; ivec4 p3;
    ivec4 p4; ivec4 p5; ivec4 p6; ivec4 p7; } pc;

// Window token t -> int8 qX index.  One M8 row block always lies inside one
// 16-slot tile, so the returned base is valid for a 64-wide row-major load.
uint qx_addr(uint t, uint c, uint wx, uint wy, out bool oob) {
    uint q = t >> 4u, s = t & 15u;
    int tx = 2 * int(wx) + pc.p0.z + int(q & 1u);
    int ty = 2 * int(wy) + pc.p0.w + int(q >> 1u);
    oob = (tx < 0 || ty < 0 || tx >= pc.p0.x || ty >= pc.p0.y);
    // No address is dereferenced when OOB; 0 avoids unsigned wrap.
    if (oob) return 0u;
    return (uint(ty) * uint(pc.p0.x) + uint(tx)) * 1024u + s * 64u + c;
}

MA load_entry_A(uint base, uint k, bool oob) {
    MA x;
    if (oob) x = MA(QT(0));
    else coopMatLoad(x, gx, base + k, 64u, ROW);
    return x;
}

MQ load_entry_q(uint base, uint k, bool oob) {
    MQ x;
    if (oob) x = MQ(QT(0));
    else coopMatLoad(x, gx, base + k, 64u, ROW);
    return x;
}

float rounded_code(float x, float invs) {
    precise float scaled = x * invs;
    return clamp(roundEven(scaled), -127.0, 127.0);
}

// Same half tree as the parent c64_act_h / pilot act (MpCubicSilu).
float16_t act_h(float16_t x) {
    float16_t t = clamp(x, float16_t(-4.0), float16_t(4.0));
    float16_t u = fma(float16_t(-0.055908203125), abs(t), float16_t(0.447265625));
    return x * fma(t, u, float16_t(0.89453125));
}

// Column scales are loaded as broadcast fragments (stride 0, ROW): element
// (i,j) reads sc[base+j], i.e. the true per-output-column scale.  This is the
// validated c128-diffusion-v1 / c128-b56 form; no lane-map assumption.
MQ requant_act(ACC a, MF multiplier, float invs) {
    MF f = MF(a);
    for (int i = 0; i < f.length(); ++i) {
        precise float realv = f[i] * multiplier[i];
        float16_t h = act_h(float16_t(realv));
        f[i] = rounded_code(float(h), invs);
    }
    return MQ(f);
}

MQ requant_linear(ACC a, MF multiplier, float invs) {
    MF f = MF(a);
    for (int i = 0; i < f.length(); ++i) {
        precise float realv = f[i] * multiplier[i];
        f[i] = rounded_code(realv, invs);
    }
    return MQ(f);
}

void dumpdot(ACC a, uint off, uint row, uint col, uint stride) {
    // Diagnostic only (production pushes p7.x = 0).
    if (pc.p7.x != 0 && gl_WorkGroupID.x == 1u && gl_WorkGroupID.y == 1u) {
        MF f = MF(a);
        coopMatStore(f, dd, off + row * stride + col, stride, ROW);
    }
}

#endif
