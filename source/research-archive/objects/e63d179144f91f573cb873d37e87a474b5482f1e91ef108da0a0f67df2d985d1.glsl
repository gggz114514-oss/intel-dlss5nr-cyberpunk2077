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
// C2: nr_i8_put_e deleted together with sE8 -- the E code word now
// goes straight into a register (c2_i8_pack in c2_i8_regk32.glsl).
#endif
