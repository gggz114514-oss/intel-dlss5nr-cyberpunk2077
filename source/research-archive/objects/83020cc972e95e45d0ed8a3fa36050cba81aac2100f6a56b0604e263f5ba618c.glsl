// c256_int8_common.glsl — push ABI, INT8 buffer layout and map-free address
// helpers for the C256 blocks 48..55 native INT8 candidate (VK-INT8-008).
//
// Buffer layout of candidates/.../c256-int8-v1/pack/c256_bNN_int8.bin
// (one buffer per block, appended to the v7 plan; existing buffers untouched):
//   0                  Wc int8  N=256  K=256   W[N/32][K/32][32][32]   65,536 B
//   65,536             We int8  N=1024 K=256                            262,144 B
//   327,680            Wm int8  N=256  K=128                            32,768 B
//   360,448            SC float32 block (ew,mw,alpha,sWe,sWm,sWc,scal,rs)
//   376,832            qX int8 canonical 32-channel-group (produced by the
//                      previous block's output epilogue / c3x_pre)   1,032,192 B
//   1,409,024          qA dump int8 (integer arm only)                4,128,768 B
//   5,537,792          total
//
// Element type rule (3.10): every cooperative-matrix load/store of INT8 data is
// handed an `int8_t[]` pointer. Nothing here is a float16_t view of int8 data.
#ifndef C256_INT8_COMMON_GLSL
#define C256_INT8_COMMON_GLSL

#define C256_WC_OFF     0u
#define C256_WE_OFF     65536u
#define C256_WM_OFF     327680u
#define C256_SC_OFF     360448u
#define C256_EW_OFF     (C256_SC_OFF + 0u)        // float[1024]
#define C256_MW_OFF     (C256_SC_OFF + 4096u)     // float[256]
#define C256_ALPHA_OFF  (C256_SC_OFF + 5120u)     // float[256]
#define C256_SWE_OFF    (C256_SC_OFF + 6144u)     // float[1024]  @366,592
#define C256_SWM_OFF    (C256_SC_OFF + 10240u)    // float[256]   @370,688
#define C256_SWC_OFF    (C256_SC_OFF + 11264u)    // float[256]   @371,712
#define C256_SCAL_OFF   (C256_SC_OFF + 12288u)    // float[32]    @372,736
#define C256_RS_OFF     (C256_SC_OFF + 12416u)    // float[256]   @372,864
#define C256_QX_OFF     376832u
#define C256_QX_BYTES   1032192u
#define C256_QA_OFF     (C256_QX_OFF + C256_QX_BYTES)   // 1409024
#define C256_QA_BYTES   4128768u
#define C256_BUF_BYTES  (C256_QA_OFF + C256_QA_BYTES)   // 5537792

// SC scalars
#define C256_SC_INV_X   0u
#define C256_SC_INV_A   1u
#define C256_SC_INV_M   2u
#define C256_SC_S_X     3u
#define C256_SC_S_A     4u
#define C256_SC_S_M     5u
#define C256_SC_ABS_X   6u
#define C256_SC_ABS_A   7u
#define C256_SC_ABS_M   8u

layout(push_constant) uniform PC {
    ivec4 p0;   // tiles_x=21, tiles_y=12, shift_x, shift_y (signed)
    ivec4 p1;   // grid_x, grid_y, single_mode, debug
    ivec4 p2;   // single_wx, single_wy, reserved, reserved
    ivec4 p3;   // we_half, wm_half, wc_half, wq_half   (half offsets, unused here)
    ivec4 p4;   // wo_half, rs_half, ars_half, bias_float
    ivec4 p5;   // scalar_float, M_half_base, Y_half_base, T_half_base
    ivec4 p6;   // input_half_base, output_half_base, debug_half_base, profile_id
    ivec4 p7;   // reserved
} pc;

#define C256_MAT_H  coopmat<float16_t, gl_ScopeSubgroup, 8, 16, gl_MatrixUseAccumulator>
#define C256_MA8    coopmat<int8_t,  gl_ScopeSubgroup, 8, 32, gl_MatrixUseA>
#define C256_MB8    coopmat<int8_t,  gl_ScopeSubgroup, 32, 16, gl_MatrixUseB>
#define C256_AC8    coopmat<int,     gl_ScopeSubgroup, 8, 16, gl_MatrixUseAccumulator>
#define C256_MF8    coopmat<float,   gl_ScopeSubgroup, 8, 16, gl_MatrixUseAccumulator>
#define C256_MQ8    coopmat<int8_t,  gl_ScopeSubgroup, 8, 16, gl_MatrixUseAccumulator>
#define C256_LROW   gl_CooperativeMatrixLayoutRowMajor
#define C256_LCOL   gl_CooperativeMatrixLayoutColumnMajor

// parent canonical half index, used only for the FP16 residual seed of contract
uint c256_img_half_index(uint t, uint c, uint wx, uint wy, out bool oob) {
    uint q = t >> 4u, s = t & 15u;
    int tx = 2 * int(wx) + pc.p0.z + int(q & 1u);
    int ty = 2 * int(wy) + pc.p0.w + int(q >> 1u);
    oob = (tx < 0 || ty < 0 || tx >= pc.p0.x || ty >= pc.p0.y);
    uint stx = uint(clamp(tx, 0, pc.p0.x - 1));
    uint sty = uint(clamp(ty, 0, pc.p0.y - 1));
    return (((sty * uint(pc.p0.x) + stx) * 16u + c / 16u) * 256u
            + s * 16u + c % 16u);
}

// qX/qA canonical INT8 layout: 32-channel groups, token slot stride 32 bytes.
// Returns the byte base of the M8xK32 fragment of token t (8 consecutive slots)
// in channel group g (channels 32g..32g+31). Only dereferenced when !oob.
uint c256_qx_frag_base(uint t, uint wx, uint wy, out bool oob) {
    uint q = t >> 4u, s = t & 15u;
    int tx = 2 * int(wx) + pc.p0.z + int(q & 1u);
    int ty = 2 * int(wy) + pc.p0.w + int(q >> 1u);
    oob = (tx < 0 || ty < 0 || tx >= pc.p0.x || ty >= pc.p0.y);
    uint stx = uint(clamp(tx, 0, pc.p0.x - 1));
    uint sty = uint(clamp(ty, 0, pc.p0.y - 1));
    uint tile = sty * uint(pc.p0.x) + stx;
    return tile * 4096u + s * 32u;     // 8 channel groups * 16 slots * 32 B
}

// half MpCubicSilu, byte-for-byte the parent helper
float16_t c256_act_h(float16_t x) {
    float16_t t = clamp(x, float16_t(-4.0), float16_t(4.0));
    float16_t u = fma(float16_t(-0.055908203125), abs(t), float16_t(0.447265625));
    return x * fma(t, u, float16_t(0.89453125));
}

// The single producer-side quantiser of this template. One multiply by the
// inverse step, RNE, clamp. `inv` must be 127/absmax.
float c256_code(float v, float inv) {
    precise float c = v * inv;
    return clamp(roundEven(c), -127.0, 127.0);
}

#endif
