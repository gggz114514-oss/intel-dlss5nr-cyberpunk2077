#version 460
#extension GL_GOOGLE_include_directive : require













#line 1 "D:/nr-work-20261011/_mochi/DLSSNR-AMD-main/windows/shaders/rdna4/include/coopmm.glsl"














#line 1 "D:/nr-work-20261011/_mochi/DLSSNR-AMD-main/windows/shaders/rdna4/include/coherent_act.glsl"











































































#line 16 "D:/nr-work-20261011/_mochi/DLSSNR-AMD-main/windows/shaders/rdna4/include/coopmm.glsl"
#extension GL_KHR_cooperative_matrix : require
#extension GL_KHR_memory_scope_semantics : require
#extension GL_KHR_shader_subgroup_basic : require
#extension GL_KHR_shader_subgroup_shuffle : require
#extension GL_EXT_float_e4m3 : require
#extension GL_EXT_shader_explicit_arithmetic_types_float16 : require



















































































































































































































































































































      floate4m3_t nr_quant_e4m3(float16_t v) {
    return floate4m3_t(clamp(v, float16_t(- 448.0), float16_t(448.0)));
}







































































































































































































































































fe4m3vec4 nr_convert_quad(f16vec2 a, f16vec2 b) { return fe4m3vec4(f16vec4(a, b)); }
fe4m3vec4 nr_convert_quad(vec2 a, vec2 b) { return fe4m3vec4(vec4(a, b)); }











fe4m3vec2 nr_quant_pair_bare(f16vec2 v) { return fe4m3vec2(v); }






fe4m3vec2 nr_quant_pair32(vec2 x) {



    return fe4m3vec2(nr_quant_e4m3(float16_t(x.x)), nr_quant_e4m3(float16_t(x.y)));
}





fe4m3vec4 nr_quant4_h(f16vec4 v) {




    return fe4m3vec4(clamp(v, f16vec4(- 448.0), f16vec4(448.0)));






}
fe4m3vec2 nr_quant2_h(f16vec2 v) {

    return fe4m3vec2(clamp(v, f16vec2(- 448.0), f16vec2(448.0)));



}





float nr_mp_cubic_silu(float x) {
    const float t = clamp(x, - 4.0, 4.0);
    return x * (- 0.055908203125 * abs(t) * t + 0.447265625 * t + 0.89453125);
}











































float nr_round_f16_e4m3(float x) {
    const uint u = floatBitsToUint(x);






























    return uintBitsToFloat( (u + 0x0FFFu + ( (u >> 13) & 1u)) & 0xFFFFE000u);

}
































float nr_round_f16_hw(float x) {
    return float(float16_t(x));
}

float nr_round_f16(float x) {
    const uint u = floatBitsToUint(x);
    const uint sgn = u & 0x80000000u;
    const int e = int( (u >> 23) & 0xFFu) - 127;
    if (e >= 128) return x;
    if (e > 15) return uintBitsToFloat(sgn | 0x7F800000u);
    const int shift = (e < - 14) ? (- 1 - e) : 13;
    if (shift > 24) return uintBitsToFloat(sgn);
    const uint m24 = (u & 0x7FFFFFu) | 0x800000u;
    const uint keep = m24 >> shift;
    const uint rest = m24 & ( (1u << uint(shift)) - 1u);
    const uint tie = 1u << uint(shift - 1);
    const uint r = keep + ( (rest > tie || (rest == tie && (keep & 1u) != 0u)) ? 1u : 0u);

    if (e == 15 && r == 2048u) return uintBitsToFloat(sgn | 0x7F800000u);



    const float v = ldexp(float(r), e - 23 + shift);
    return sgn != 0u ? - v : v;
}





















#line 17 "D:\nr-work-20261011\_mochi\DLSSNR-AMD-main\windows\shaders\rdna4\ffwd3_t.comp"
#line 1 "D:/nr-work-20261011/_mochi/DLSSNR-AMD-main/windows/shaders/rdna4/include/swin_math.glsl"






















f16vec2 nr_swin_act2(f16vec2 x) {
    const f16vec2 t = clamp(x, f16vec2(- 4.0hf), f16vec2(4.0hf));
    const f16vec2 u = fma(f16vec2(- 0.055908203125hf), abs(t), f16vec2(0.447265625hf));
    return x * fma(t, u, f16vec2(0.89453125hf));
}

float nr_swin_act(float x) {
    return float(nr_swin_act2(f16vec2(float16_t(x))).x);
}




float nr_swin_exp(float x) {


    const float16_t y = clamp(fma(float16_t(x), float16_t(0.044921875), float16_t(1.30078125)),
                                float16_t(1.03125), float16_t(1.5693359375));



    const uint h = packHalf2x16(vec2(float(y), 0.0)) & 0xffffu;
    return unpackHalf2x16( (h & 0x03ffu) << 5u).x;
}




float nr_vit_exp(float x) {
    const float16_t y = clamp(fma(float16_t(x), float16_t(0.08953857421875), float16_t(1.708984375)),
                                float16_t(1.439453125), float16_t(1.9775390625));
    const uint h = packHalf2x16(vec2(float(y), 0.0)) & 0xffffu;
    return unpackHalf2x16( (h & 0x03ffu) << 4u).x;
}


















f16vec2 nr_swin_exp2(vec2 x) {














    const f16vec2 y = clamp(fma(f16vec2(x), f16vec2(0.044921875hf), f16vec2(1.30078125hf)),
                           f16vec2(1.03125hf), f16vec2(1.5693359375hf));
    const uint h = packHalf2x16(vec2(y));

    const uint bits = (h << 5u) + 0x7FF88000u;
    return f16vec2(unpackHalf2x16(bits));

}










































































#line 18 "D:\nr-work-20261011\_mochi\DLSSNR-AMD-main\windows\shaders\rdna4\ffwd3_t.comp"























layout(local_size_x = 32 * 4) in;
layout(binding = 0, std430) buffer ActF16 {
         float16_t act_f16[];
};
layout(binding = 1, std430) buffer ActE4M3 {
          floate4m3_t act_e4m3[];
};
layout(binding = 2, std430) buffer ActF32 {
    float act_f32[];
};
layout(binding = 3, std430) readonly buffer WgtE4M3 {
          floate4m3_t wgt_e4m3[];
};

layout(binding = 3, std430) readonly buffer WPair4 { fe4m3vec4 wpair4[]; };

layout(binding = 4, std430) readonly buffer WgtF16 {
         float16_t wgt_f16[];
};
layout(binding = 5, std430) buffer ActE4M3x4 {
    fe4m3vec4 act_e4m3x4[];
};

#line 1 "D:/nr-work-20261011/_mochi/DLSSNR-AMD-main/windows/shaders/rdna4/include/nr_chain.glsl"



































































































#extension GL_KHR_memory_scope_semantics : require
#extension GL_KHR_shader_subgroup_ballot : require




layout(set = 0, binding = 0, std430) coherent buffer NrTChainU { uint nr_tc_u[]; };
layout(set = 0, binding = 3, std430) readonly buffer NrTChainW { uint nr_tc_w[]; };






































































#line 65 "D:\nr-work-20261011\_mochi\DLSSNR-AMD-main\windows\shaders\rdna4\ffwd3_t.comp"
#line 1 "D:/nr-work-20261011/_mochi/DLSSNR-AMD-main/windows/shaders/rdna4/include/occ_pad.glsl"











shared uint nr_occ_pad[ (21504) / 4];








#line 66 "D:\nr-work-20261011\_mochi\DLSSNR-AMD-main\windows\shaders\rdna4\ffwd3_t.comp"
 layout(push_constant) uniform Push {
    uint x_off, o_off, a_off, q0_off, q2_off, M, C;

                    uint tc_rec;
}
pc;



































































fe4m3vec2 nr_ffwd_quant(f16vec2 v) {



    return fe4m3vec2(clamp(v, f16vec2(- 448.0hf), f16vec2(448.0hf)));

}

fe4m3vec4 nr_ffwd_quant4(f16vec2 a, f16vec2 b) {




    return fe4m3vec4(clamp(f16vec4(a, b), f16vec4(- 448.0hf), f16vec4(448.0hf)));

}

#line 1 "D:/nr-work-20261011/_mochi/DLSSNR-AMD-main/windows/shaders/rdna4/include/nr_prof.glsl"















































#line 157 "D:\nr-work-20261011\_mochi\DLSSNR-AMD-main\windows\shaders\rdna4\ffwd3_t.comp"






























































































































void main() {


                  uint nr_tc_rec = pc.tc_rec; uint nr_tc_sig = 0xFFFFFFFFu; if (nr_tc_rec != 0xFFFFFFFFu && nr_tc_w[nr_tc_rec + 6u] != 0x54434852u) nr_tc_rec = 0xFFFFFFFFu; if (nr_tc_rec != 0xFFFFFFFFu) nr_tc_sig = nr_tc_w[nr_tc_rec + 3u];
                                                   { if (nr_tc_rec != 0xFFFFFFFFu && nr_tc_w[nr_tc_rec + 2u] != 0xFFFFFFFFu) { if (gl_SubgroupID == 0u) { const uint nr_twt = nr_tc_w[nr_tc_rec], nr_ttb = nr_tc_w[nr_tc_rec + 2u]; const uint nr_te = subgroupBroadcastFirst(atomicAdd(nr_tc_u[nr_tc_w[nr_tc_rec + 4u]], 0u)); uint nr_tb = (1u << 16); for (uint nr_ti = 0u; nr_ti < uint( (4 * ( (16u) / 16u))); ++ nr_ti) { const uint nr_tx = nr_tc_w[nr_ttb + uint(uint( ( ( (gl_WorkGroupID.x / 8u) * 4) * ( (16u) / 16u))) + nr_ti)]; if (nr_tx != 0xFFFFFFFFu) while (nr_tb != 0u && subgroupBroadcastFirst(atomicAdd(nr_tc_u[nr_twt + (nr_tx & 0xFFFFFu)], 0u)) < (nr_tx >> 20u) * nr_te) -- nr_tb; } if (nr_tb == 0u && subgroupElect()) atomicMax(nr_tc_u[nr_tc_w[nr_tc_rec + 5u]], 1u); } barrier(); memoryBarrier(gl_ScopeDevice, gl_StorageSemanticsBuffer, gl_SemanticsAcquire); } }
                   uint group = gl_WorkGroupID.x % 8u, tok = ( (gl_WorkGroupID.x / 8u) * 4 + ( (gl_LocalInvocationID.x) / 32u)) * (16u); if (tok >= pc.M) return;
    uint xbase = pc.x_off + (tok / 16u) * (pc.C / 16u) * 256u;
    uint agrp = pc.a_off + group * 64u * 512u, q0grp = pc.q0_off + group * 256u * 64u,
         q2grp = pc.q2_off + group * 64u * 256u;

              coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > acc1[4], acc3[4];
    for (int n = 0; n < 4; ++ n) {
        acc1[n] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0);
        acc3[n] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0);
    }

    const uint xl4 = (xbase + (gl_LocalInvocationID.x % 16u) * 16u
                      + ( (gl_LocalInvocationID.x % 32u) / 16u) * 8u) / 4u;
    uint aw4[2];
    for (int n = 0; n < 2; ++ n)
        aw4[n] = agrp / 4u + uint(n) * (pc.C / 16u) * 128u + (gl_LocalInvocationID.x % 32u) * 4u;

    for (uint k0 = 0u; k0 < pc.C; k0 += 128u) {

        const uint k04 = k0 * 4u, kw4 = (k0 / 16u) * 128u;

                        { coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > x; { const uint nrq = (xl4 + k04) + uint(0) * 64u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { x[v] = r0[v]; x[v + 4] = r1[v]; } } for (int n = 0; n < 2; ++ n) { const uint ix = (aw4[n] + kw4) + uint(0) * 128u; const fe4m3vec4 v0 = wpair4[ix], v1 = wpair4[ix + 1u], v2 = wpair4[ix + 2u], v3 = wpair4[ix + 3u]; coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > w0, w1; for (int c = 0; c < 4; ++ c) { w0[c] = v0[c]; w0[c + 4] = v1[c]; w1[c] = v2[c]; w1[c + 4] = v3[c]; } acc1[2 * n] = coopMatMulAdd(w0, x, acc1[2 * n]); acc1[2 * n + 1] = coopMatMulAdd(w1, x, acc1[2 * n + 1]); } } { coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > x; { const uint nrq = (xl4 + k04) + uint(1) * 64u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { x[v] = r0[v]; x[v + 4] = r1[v]; } } for (int n = 0; n < 2; ++ n) { const uint ix = (aw4[n] + kw4) + uint(1) * 128u; const fe4m3vec4 v0 = wpair4[ix], v1 = wpair4[ix + 1u], v2 = wpair4[ix + 2u], v3 = wpair4[ix + 3u]; coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > w0, w1; for (int c = 0; c < 4; ++ c) { w0[c] = v0[c]; w0[c + 4] = v1[c]; w1[c] = v2[c]; w1[c + 4] = v3[c]; } acc1[2 * n] = coopMatMulAdd(w0, x, acc1[2 * n]); acc1[2 * n + 1] = coopMatMulAdd(w1, x, acc1[2 * n + 1]); } } { coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > x; { const uint nrq = (xl4 + k04) + uint(2) * 64u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { x[v] = r0[v]; x[v + 4] = r1[v]; } } for (int n = 0; n < 2; ++ n) { const uint ix = (aw4[n] + kw4) + uint(2) * 128u; const fe4m3vec4 v0 = wpair4[ix], v1 = wpair4[ix + 1u], v2 = wpair4[ix + 2u], v3 = wpair4[ix + 3u]; coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > w0, w1; for (int c = 0; c < 4; ++ c) { w0[c] = v0[c]; w0[c + 4] = v1[c]; w1[c] = v2[c]; w1[c + 4] = v3[c]; } acc1[2 * n] = coopMatMulAdd(w0, x, acc1[2 * n]); acc1[2 * n + 1] = coopMatMulAdd(w1, x, acc1[2 * n + 1]); } } { coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > x; { const uint nrq = (xl4 + k04) + uint(3) * 64u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { x[v] = r0[v]; x[v + 4] = r1[v]; } } for (int n = 0; n < 2; ++ n) { const uint ix = (aw4[n] + kw4) + uint(3) * 128u; const fe4m3vec4 v0 = wpair4[ix], v1 = wpair4[ix + 1u], v2 = wpair4[ix + 2u], v3 = wpair4[ix + 3u]; coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > w0, w1; for (int c = 0; c < 4; ++ c) { w0[c] = v0[c]; w0[c + 4] = v1[c]; w1[c] = v2[c]; w1[c + 4] = v3[c]; } acc1[2 * n] = coopMatMulAdd(w0, x, acc1[2 * n]); acc1[2 * n + 1] = coopMatMulAdd(w1, x, acc1[2 * n + 1]); } } { coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > x; { const uint nrq = (xl4 + k04) + uint(4) * 64u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { x[v] = r0[v]; x[v + 4] = r1[v]; } } for (int n = 0; n < 2; ++ n) { const uint ix = (aw4[n] + kw4) + uint(4) * 128u; const fe4m3vec4 v0 = wpair4[ix], v1 = wpair4[ix + 1u], v2 = wpair4[ix + 2u], v3 = wpair4[ix + 3u]; coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > w0, w1; for (int c = 0; c < 4; ++ c) { w0[c] = v0[c]; w0[c + 4] = v1[c]; w1[c] = v2[c]; w1[c + 4] = v3[c]; } acc1[2 * n] = coopMatMulAdd(w0, x, acc1[2 * n]); acc1[2 * n + 1] = coopMatMulAdd(w1, x, acc1[2 * n + 1]); } } { coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > x; { const uint nrq = (xl4 + k04) + uint(5) * 64u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { x[v] = r0[v]; x[v + 4] = r1[v]; } } for (int n = 0; n < 2; ++ n) { const uint ix = (aw4[n] + kw4) + uint(5) * 128u; const fe4m3vec4 v0 = wpair4[ix], v1 = wpair4[ix + 1u], v2 = wpair4[ix + 2u], v3 = wpair4[ix + 3u]; coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > w0, w1; for (int c = 0; c < 4; ++ c) { w0[c] = v0[c]; w0[c + 4] = v1[c]; w1[c] = v2[c]; w1[c + 4] = v3[c]; } acc1[2 * n] = coopMatMulAdd(w0, x, acc1[2 * n]); acc1[2 * n + 1] = coopMatMulAdd(w1, x, acc1[2 * n + 1]); } } { coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > x; { const uint nrq = (xl4 + k04) + uint(6) * 64u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { x[v] = r0[v]; x[v + 4] = r1[v]; } } for (int n = 0; n < 2; ++ n) { const uint ix = (aw4[n] + kw4) + uint(6) * 128u; const fe4m3vec4 v0 = wpair4[ix], v1 = wpair4[ix + 1u], v2 = wpair4[ix + 2u], v3 = wpair4[ix + 3u]; coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > w0, w1; for (int c = 0; c < 4; ++ c) { w0[c] = v0[c]; w0[c + 4] = v1[c]; w1[c] = v2[c]; w1[c + 4] = v3[c]; } acc1[2 * n] = coopMatMulAdd(w0, x, acc1[2 * n]); acc1[2 * n + 1] = coopMatMulAdd(w1, x, acc1[2 * n + 1]); } } { coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > x; { const uint nrq = (xl4 + k04) + uint(7) * 64u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { x[v] = r0[v]; x[v + 4] = r1[v]; } } for (int n = 0; n < 2; ++ n) { const uint ix = (aw4[n] + kw4) + uint(7) * 128u; const fe4m3vec4 v0 = wpair4[ix], v1 = wpair4[ix + 1u], v2 = wpair4[ix + 2u], v3 = wpair4[ix + 3u]; coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > w0, w1; for (int c = 0; c < 4; ++ c) { w0[c] = v0[c]; w0[c + 4] = v1[c]; w1[c] = v2[c]; w1[c + 4] = v3[c]; } acc1[2 * n] = coopMatMulAdd(w0, x, acc1[2 * n]); acc1[2 * n + 1] = coopMatMulAdd(w1, x, acc1[2 * n + 1]); } }
    }

            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > r[4];
    for (int n = 0; n < 4; ++ n)






        for (int c = 0; c < 8; c += 2) {
            fe4m3vec2 q = nr_ffwd_quant(f16vec2(acc1[n][c], acc1[n][c + 1]));
            r[n][c] = q.x; r[n][c + 1] = q.y;
        }






    for (uint chunk = 0u; chunk < 4u; ++ chunk) {
        uint jbase = chunk * 64u;
                  coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > acc2[4];
        for (int n = 0; n < 4; ++ n)
            acc2[n] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0);
        for (uint k = 0u; k < 4u; ++ k)

            for (uint n = 0u; n < 4u; n += 2u) {
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > w0, w1;
                                                               { const uint ix = (q0grp) / 4u + ( (jbase + n * 16u) / 32u) * ( (64u) / 16u) * 128u + ( (k * 16u) / 16u) * 128u + (gl_LocalInvocationID.x % 32u) * 4u; const fe4m3vec4 v0 = wpair4[ix], v1 = wpair4[ix + 1u], v2 = wpair4[ix + 2u], v3 = wpair4[ix + 3u]; for (int c = 0; c < 4; ++ c) { w0[c] = v0[c]; w0[c + 4] = v1[c]; w1[c] = v2[c]; w1[c + 4] = v3[c]; } }
                                      acc2[n] = coopMatMulAdd(w0, r[k], acc2[n]); acc2[n + 1u] = coopMatMulAdd(w1, r[k], acc2[n + 1u]);
            }







                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > h[4];
        for (int n = 0; n < 4; ++ n)






            for (int c = 0; c < 8; c += 2) {
                fe4m3vec2 q = nr_ffwd_quant(nr_swin_act2(f16vec2(acc2[n][c], acc2[n][c + 1])));
                h[n][c] = q.x; h[n][c + 1] = q.y;
            }




        for (uint k = 0u; k < 4u; ++ k)

            for (uint n = 0u; n < 4u; n += 2u) {
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > w0, w1;
                                                                { const uint ix = (q2grp) / 4u + ( (n * 16u) / 32u) * ( (256u) / 16u) * 128u + ( (jbase + k * 16u) / 16u) * 128u + (gl_LocalInvocationID.x % 32u) * 4u; const fe4m3vec4 v0 = wpair4[ix], v1 = wpair4[ix + 1u], v2 = wpair4[ix + 2u], v3 = wpair4[ix + 3u]; for (int c = 0; c < 4; ++ c) { w0[c] = v0[c]; w0[c + 4] = v1[c]; w1[c] = v2[c]; w1[c + 4] = v3[c]; } }
                                      acc3[n] = coopMatMulAdd(w0, h[k], acc3[n]); acc3[n + 1u] = coopMatMulAdd(w1, h[k], acc3[n + 1u]);
            }







    }


    for (uint n = 0u; n < 4u; ++ n) {
                   coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > outv;






        for (int c = 0; c < 8; c += 2) {
            fe4m3vec2 q = nr_ffwd_quant(f16vec2(acc3[n][c], acc3[n][c + 1]));
            outv[c] = q.x; outv[c + 1] = q.y;
        }






                            coopMatStore(outv, act_e4m3, (pc.o_off + (tok / 16u) * (pc.C / 16u) * 256u + (group * 4u + n) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);
    }
                                           if (pc.C == 0u) { const uint nr_oi = (gl_WorkGroupID.x * 131u + gl_LocalInvocationIndex) % uint( (21504) / 4); nr_occ_pad[nr_oi] = nr_oi; barrier(); if (nr_occ_pad[ (nr_oi + 1u) % uint( (21504) / 4)] == 5u) act_f32[0] = 0.0; }

                                       { if (nr_tc_sig != 0xFFFFFFFFu) { memoryBarrier(gl_ScopeDevice, gl_StorageSemanticsBuffer, gl_SemanticsRelease); subgroupBarrier(); if (gl_SubgroupInvocationID < uint(1u)) atomicAdd(nr_tc_u[nr_tc_sig + uint(tok / 16u) + gl_SubgroupInvocationID], 1u, gl_ScopeDevice, gl_StorageSemanticsBuffer, gl_SemanticsRelease); } }

}

