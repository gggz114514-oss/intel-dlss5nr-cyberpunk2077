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





















#line 4 "D:\nr-work-20261011\_mochi\DLSSNR-AMD-main\windows\shaders\rdna4\attn.comp"
#line 1 "D:/nr-work-20261011/_mochi/DLSSNR-AMD-main/windows/shaders/rdna4/include/swin_math.glsl"












#extension GL_EXT_shader_explicit_arithmetic_types_int16 : require

uint nr_clamp_h2_bits(f16vec2 y, int lo, int hi) {
    return pack32(u16vec2(min(max(float16BitsToInt16(y), i16vec2(int16_t(lo))), i16vec2(int16_t(hi)))));
}





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











    const uint h = nr_clamp_h2_bits(fma(f16vec2(x), f16vec2(0.044921875hf), f16vec2(1.30078125hf)),
                                  0x3C20, 0x3E47);





    const uint bits = (h << 5u) + 0x7FF88000u;
    return f16vec2(unpackHalf2x16(bits));

}










































































#line 5 "D:\nr-work-20261011\_mochi\DLSSNR-AMD-main\windows\shaders\rdna4\attn.comp"















































































































































































































































































































































































































































































































layout(local_size_x = (2 * 32)) in;

layout(set = 0, binding = 0, std430) buffer ActE4M3 { floate4m3_t act_e4m3[]; };
layout(set = 0, binding = 1, std430) buffer ActF32 { float act_f32[]; };
layout(set = 0, binding = 2, std430) readonly buffer WgtE4M3 { floate4m3_t wgt_e4m3[]; };
layout(set = 0, binding = 3, std430) readonly buffer WgtF32 { float wgt_f32[]; };
layout(set = 0, binding = 4, std430) buffer ActE4M3x4 { fe4m3vec4 act_e4m3x4[]; };

layout(set = 0, binding = 2, std430) readonly buffer WgtE4M3x4 { fe4m3vec4 wgt_e4m3x4[]; };






















#line 1 "D:/nr-work-20261011/_mochi/DLSSNR-AMD-main/windows/shaders/rdna4/include/nr_chain.glsl"



































































































#extension GL_KHR_memory_scope_semantics : require
#extension GL_KHR_shader_subgroup_ballot : require




layout(set = 0, binding = 0, std430) coherent buffer NrTChainU { uint nr_tc_u[]; };
layout(set = 0, binding = 2, std430) readonly buffer NrTChainW { uint nr_tc_w[]; };






































































#line 532 "D:\nr-work-20261011\_mochi\DLSSNR-AMD-main\windows\shaders\rdna4\attn.comp"
 layout(push_constant) uniform Push {
    uint x_off;
    uint o_off;
    uint w_off;
    uint b_off;
    uint s_off;
    uint C;
    uint wins_x;

    uint tiles_x, tiles_y;
    int shift, shift_y;


                    uint tc_rec;
} pc;





ivec2 nr_tile(uint q) {
    return 2 * ivec2(gl_WorkGroupID.xy) + ivec2(pc.shift, pc.shift_y)
           + ivec2(int(q & 1u), int(q >> 1));
}
bool nr_tile_oob(uint q) {
    ivec2 t = nr_tile(q);
    return any(lessThan(t, ivec2(0))) ||
           any(greaterThanEqual(t, ivec2(pc.tiles_x, pc.tiles_y)));
}
uint nr_tile_base(uint q) {
    ivec2 t = clamp(nr_tile(q), ivec2(0), ivec2(pc.tiles_x, pc.tiles_y) - 1);
    return(uint(t.y) * pc.tiles_x + uint(t.x)) * (pc.C / 16u) * 256u;
}






















































































shared floate4m3_t lds_q[1 * 64 * (32 + 0)];
shared floate4m3_t lds_k[1 * 64 * (32 + 0)];
shared floate4m3_t lds_v[1 * (32 * (64 + 0))];
shared floate4m3_t lds_p[2 * 16 * (64 + 0)];

























float nr_fast_exp(float x) {
    return nr_swin_exp(x);
}






















































































#extension GL_EXT_control_flow_attributes : require
#extension GL_KHR_shader_subgroup_ballot : require















































































fe4m3vec2 nr_attn_quant(f16vec2 v) {
















    return fe4m3vec2(clamp(v, f16vec2(- 448.0hf), f16vec2(448.0hf)));

}








fe4m3vec4 nr_attn_quant4(f16vec2 a, f16vec2 b) {









    return fe4m3vec4(clamp(f16vec4(a, b), f16vec4(- 448.0hf), f16vec4(448.0hf)));




}

#line 1 "D:/nr-work-20261011/_mochi/DLSSNR-AMD-main/windows/shaders/rdna4/include/nr_prof.glsl"















































#line 896 "D:\nr-work-20261011\_mochi\DLSSNR-AMD-main\windows\shaders\rdna4\attn.comp"
#line 1 "D:/nr-work-20261011/_mochi/DLSSNR-AMD-main/windows/shaders/rdna4/include/occ_pad.glsl"











shared uint nr_occ_pad[ (3072) / 4];








#line 897 "D:\nr-work-20261011\_mochi\DLSSNR-AMD-main\windows\shaders\rdna4\attn.comp"
 void main() {




















                  uint nr_tc_rec = pc.tc_rec; uint nr_tc_sig = 0xFFFFFFFFu; if (nr_tc_rec != 0xFFFFFFFFu && nr_tc_w[nr_tc_rec + 6u] != 0x54434852u) nr_tc_rec = 0xFFFFFFFFu; if (nr_tc_rec != 0xFFFFFFFFu) nr_tc_sig = nr_tc_w[nr_tc_rec + 3u];

                    if (nr_tc_rec != 0xFFFFFFFFu && nr_tc_w[nr_tc_rec + 2u] != 0xFFFFFFFFu) { if (gl_SubgroupID == 0u) { const uint nr_twt = nr_tc_w[nr_tc_rec], nr_ttb = nr_tc_w[nr_tc_rec + 2u]; const uint nr_te = subgroupBroadcastFirst(atomicAdd(nr_tc_u[nr_tc_w[nr_tc_rec + 4u]], 0u)); uint nr_tb = (1u << 16);
    for (uint nr_q = 0u; nr_q < 4u; ++ nr_q) {
        const ivec2 nr_t = nr_tile(nr_q);
        if (all(greaterThanEqual(nr_t, ivec2(0))) && all(lessThan(nr_t, ivec2(pc.tiles_x, pc.tiles_y))))
                                                                    { const uint nr_tx = nr_tc_w[nr_ttb + uint(uint(nr_t.y) * pc.tiles_x + uint(nr_t.x))]; if (nr_tx != 0xFFFFFFFFu) while (nr_tb != 0u && subgroupBroadcastFirst(atomicAdd(nr_tc_u[nr_twt + (nr_tx & 0xFFFFFu)], 0u)) < (nr_tx >> 20u) * nr_te) -- nr_tb; }
    }
                  if (nr_tb == 0u && subgroupElect()) atomicMax(nr_tc_u[nr_tc_w[nr_tc_rec + 5u]], 1u); } barrier(); memoryBarrier(gl_ScopeDevice, gl_StorageSemanticsBuffer, gl_SemanticsAcquire); }
    const uint tid = gl_LocalInvocationID.x;




    const uint wave = subgroupBroadcastFirst(tid / 32u);



    const uint lane = tid % 32u;
    const uint win = gl_WorkGroupID.y * pc.wins_x + gl_WorkGroupID.x;
    const uint tok0 = win * uint(64);








    const uint xbase = pc.x_off + (tok0 / 16u) * (pc.C / 16u) * 256u;


    const uint qkvw = (1 != 0) ? 0u : wave;
    const uint qb = qkvw * uint(64 * (32 + 0));
    const uint vb = qkvw * uint( (32 * (64 + 0)));
    const uint sb = wave * uint(4 * 16 * (16 + 0));
    const uint pb = wave * uint(16 * (64 + 0));

    const uint mtok0 = (1 != 0) ? wave * uint( (64 / 2)) : 0u;
    const uint i0beg = (1 != 0) ? wave * uint(16) : 0u;
    const uint i0inc = uint(16) * ( (1 != 0) ? uint(2) : 1u);








    for (uint hg = gl_WorkGroupID.z; hg < uint(16); hg += gl_NumWorkGroups.z) {
    const uint hbase = hg * uint( (16 / 16));
    for (uint hh = 0u; hh < uint( (16 / 16)); ++ hh) {
        const uint h = hbase + ( (1 != 0) ? hh : wave * uint( (16 / 16)) + hh);
        const uint hrow = h * 96u;


        for (uint part = 0u; part < uint( (6 / 6)); ++ part) {
            const uint wbase = pc.w_off
                + ( (hrow + part * uint(6) * 16u) / 16u) * (pc.C / 16u) * 256u;
            uint qabase[2], qbbase[6];






                                      qabase[0] = pc.x_off + nr_tile_base(mtok0 / 16u + uint(0)); qabase[1] = pc.x_off + nr_tile_base(mtok0 / 16u + uint(1));
                                      qbbase[0] = wbase + uint(0) * (pc.C / 16u) * 256u; qbbase[1] = wbase + uint(1) * (pc.C / 16u) * 256u; qbbase[2] = wbase + uint(2) * (pc.C / 16u) * 256u; qbbase[3] = wbase + uint(3) * (pc.C / 16u) * 256u; qbbase[4] = wbase + uint(4) * (pc.C / 16u) * 256u; qbbase[5] = wbase + uint(5) * (pc.C / 16u) * 256u;

            const uint nr_ql = (lane & 15u) * 16u + (lane >> 4u) * 8u;
            uint qal4[2], qbl4[6];
            for (int i = 0; i < 2; ++ i) qal4[i] = (qabase[i] + nr_ql) / 4u;
            for (int j = 0; j < 6; ++ j) qbl4[j] = (qbbase[j] + nr_ql) / 4u;

                      coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > qacc[2][6];
                                   { const int ii = 0; qacc[ii][0] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); qacc[ii][1] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); qacc[ii][2] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); qacc[ii][3] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); qacc[ii][4] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); qacc[ii][5] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); } { const int ii = 1; qacc[ii][0] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); qacc[ii][1] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); qacc[ii][2] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); qacc[ii][3] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); qacc[ii][4] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); qacc[ii][5] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }
                    coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > qfa[3][2];
                    coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > qfb[3][6];





                    coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > qfaB[3][2];
                    coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > qfbA[3][4];


















            const uint nr_ql2 = (nr_tile_oob(mtok0 / 16u) ? 0u : 1u)
                              | (nr_tile_oob(mtok0 / 16u + 1u) ? 0u : 2u);



            [[dont_flatten]] if (nr_ql2 == 3u) {

                           for (uint k0 = 0u; k0 < pc.C; k0 += uint( (8 * 16))) { const uint k04 = k0 * 4u; if ( (0) < (0 == 1 ? 3 : 3 - 1)) { const int cur = (0) % 3; const uint kkl = uint( ( (0) % 8) * 16); const uint kgl = k0 + kkl; if ( ( ( (3) >> (0)) & 1) != 0) { const uint nrq = (qal4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][0][v] = r0[v]; qfa[cur][0][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][0][v] = r0[v]; qfaB[cur][0][v + 4] = r1[v]; } } if ( ( ( (3) >> (1)) & 1) != 0) { const uint nrq = (qal4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][1][v] = r0[v]; qfa[cur][1][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][1][v] = r0[v]; qfaB[cur][1][v + 4] = r1[v]; } } { const uint nrq = (qbl4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][0][v] = r0[v]; qfb[cur][0][v + 4] = r1[v]; } if ( (0) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (0) % 4][v] = r0[v]; qfbA[cur][ (0) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][1][v] = r0[v]; qfb[cur][1][v + 4] = r1[v]; } if ( (1) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (1) % 4][v] = r0[v]; qfbA[cur][ (1) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[2] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][2][v] = r0[v]; qfb[cur][2][v + 4] = r1[v]; } if ( (2) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (2) % 4][v] = r0[v]; qfbA[cur][ (2) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[3] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][3][v] = r0[v]; qfb[cur][3][v + 4] = r1[v]; } if ( (3) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (3) % 4][v] = r0[v]; qfbA[cur][ (3) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[4] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][4][v] = r0[v]; qfb[cur][4][v + 4] = r1[v]; } if ( (4) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (4) % 4][v] = r0[v]; qfbA[cur][ (4) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[5] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][5][v] = r0[v]; qfb[cur][5][v + 4] = r1[v]; } if ( (5) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (5) % 4][v] = r0[v]; qfbA[cur][ (5) % 4][v + 4] = r1[v]; } } } if ( (1) < (0 == 1 ? 3 : 3 - 1)) { const int cur = (1) % 3; const uint kkl = uint( ( (1) % 8) * 16); const uint kgl = k0 + kkl; if ( ( ( (3) >> (0)) & 1) != 0) { const uint nrq = (qal4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][0][v] = r0[v]; qfa[cur][0][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][0][v] = r0[v]; qfaB[cur][0][v + 4] = r1[v]; } } if ( ( ( (3) >> (1)) & 1) != 0) { const uint nrq = (qal4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][1][v] = r0[v]; qfa[cur][1][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][1][v] = r0[v]; qfaB[cur][1][v + 4] = r1[v]; } } { const uint nrq = (qbl4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][0][v] = r0[v]; qfb[cur][0][v + 4] = r1[v]; } if ( (0) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (0) % 4][v] = r0[v]; qfbA[cur][ (0) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][1][v] = r0[v]; qfb[cur][1][v + 4] = r1[v]; } if ( (1) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (1) % 4][v] = r0[v]; qfbA[cur][ (1) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[2] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][2][v] = r0[v]; qfb[cur][2][v + 4] = r1[v]; } if ( (2) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (2) % 4][v] = r0[v]; qfbA[cur][ (2) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[3] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][3][v] = r0[v]; qfb[cur][3][v + 4] = r1[v]; } if ( (3) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (3) % 4][v] = r0[v]; qfbA[cur][ (3) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[4] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][4][v] = r0[v]; qfb[cur][4][v + 4] = r1[v]; } if ( (4) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (4) % 4][v] = r0[v]; qfbA[cur][ (4) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[5] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][5][v] = r0[v]; qfb[cur][5][v + 4] = r1[v]; } if ( (5) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (5) % 4][v] = r0[v]; qfbA[cur][ (5) % 4][v + 4] = r1[v]; } } } if ( (2) < (0 == 1 ? 3 : 3 - 1)) { const int cur = (2) % 3; const uint kkl = uint( ( (2) % 8) * 16); const uint kgl = k0 + kkl; if ( ( ( (3) >> (0)) & 1) != 0) { const uint nrq = (qal4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][0][v] = r0[v]; qfa[cur][0][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][0][v] = r0[v]; qfaB[cur][0][v + 4] = r1[v]; } } if ( ( ( (3) >> (1)) & 1) != 0) { const uint nrq = (qal4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][1][v] = r0[v]; qfa[cur][1][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][1][v] = r0[v]; qfaB[cur][1][v + 4] = r1[v]; } } { const uint nrq = (qbl4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][0][v] = r0[v]; qfb[cur][0][v + 4] = r1[v]; } if ( (0) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (0) % 4][v] = r0[v]; qfbA[cur][ (0) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][1][v] = r0[v]; qfb[cur][1][v + 4] = r1[v]; } if ( (1) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (1) % 4][v] = r0[v]; qfbA[cur][ (1) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[2] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][2][v] = r0[v]; qfb[cur][2][v + 4] = r1[v]; } if ( (2) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (2) % 4][v] = r0[v]; qfbA[cur][ (2) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[3] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][3][v] = r0[v]; qfb[cur][3][v + 4] = r1[v]; } if ( (3) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (3) % 4][v] = r0[v]; qfbA[cur][ (3) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[4] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][4][v] = r0[v]; qfb[cur][4][v + 4] = r1[v]; } if ( (4) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (4) % 4][v] = r0[v]; qfbA[cur][ (4) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[5] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][5][v] = r0[v]; qfb[cur][5][v + 4] = r1[v]; } if ( (5) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (5) % 4][v] = r0[v]; qfbA[cur][ (5) % 4][v + 4] = r1[v]; } } } if ( (3) < (0 == 1 ? 3 : 3 - 1)) { const int cur = (3) % 3; const uint kkl = uint( ( (3) % 8) * 16); const uint kgl = k0 + kkl; if ( ( ( (3) >> (0)) & 1) != 0) { const uint nrq = (qal4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][0][v] = r0[v]; qfa[cur][0][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][0][v] = r0[v]; qfaB[cur][0][v + 4] = r1[v]; } } if ( ( ( (3) >> (1)) & 1) != 0) { const uint nrq = (qal4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][1][v] = r0[v]; qfa[cur][1][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][1][v] = r0[v]; qfaB[cur][1][v + 4] = r1[v]; } } { const uint nrq = (qbl4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][0][v] = r0[v]; qfb[cur][0][v + 4] = r1[v]; } if ( (0) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (0) % 4][v] = r0[v]; qfbA[cur][ (0) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][1][v] = r0[v]; qfb[cur][1][v + 4] = r1[v]; } if ( (1) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (1) % 4][v] = r0[v]; qfbA[cur][ (1) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[2] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][2][v] = r0[v]; qfb[cur][2][v + 4] = r1[v]; } if ( (2) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (2) % 4][v] = r0[v]; qfbA[cur][ (2) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[3] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][3][v] = r0[v]; qfb[cur][3][v + 4] = r1[v]; } if ( (3) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (3) % 4][v] = r0[v]; qfbA[cur][ (3) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[4] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][4][v] = r0[v]; qfb[cur][4][v + 4] = r1[v]; } if ( (4) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (4) % 4][v] = r0[v]; qfbA[cur][ (4) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[5] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][5][v] = r0[v]; qfb[cur][5][v + 4] = r1[v]; } if ( (5) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (5) % 4][v] = r0[v]; qfbA[cur][ (5) % 4][v + 4] = r1[v]; } } } if ( (4) < (0 == 1 ? 3 : 3 - 1)) { const int cur = (4) % 3; const uint kkl = uint( ( (4) % 8) * 16); const uint kgl = k0 + kkl; if ( ( ( (3) >> (0)) & 1) != 0) { const uint nrq = (qal4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][0][v] = r0[v]; qfa[cur][0][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][0][v] = r0[v]; qfaB[cur][0][v + 4] = r1[v]; } } if ( ( ( (3) >> (1)) & 1) != 0) { const uint nrq = (qal4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][1][v] = r0[v]; qfa[cur][1][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][1][v] = r0[v]; qfaB[cur][1][v + 4] = r1[v]; } } { const uint nrq = (qbl4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][0][v] = r0[v]; qfb[cur][0][v + 4] = r1[v]; } if ( (0) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (0) % 4][v] = r0[v]; qfbA[cur][ (0) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][1][v] = r0[v]; qfb[cur][1][v + 4] = r1[v]; } if ( (1) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (1) % 4][v] = r0[v]; qfbA[cur][ (1) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[2] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][2][v] = r0[v]; qfb[cur][2][v + 4] = r1[v]; } if ( (2) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (2) % 4][v] = r0[v]; qfbA[cur][ (2) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[3] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][3][v] = r0[v]; qfb[cur][3][v + 4] = r1[v]; } if ( (3) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (3) % 4][v] = r0[v]; qfbA[cur][ (3) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[4] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][4][v] = r0[v]; qfb[cur][4][v + 4] = r1[v]; } if ( (4) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (4) % 4][v] = r0[v]; qfbA[cur][ (4) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[5] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][5][v] = r0[v]; qfb[cur][5][v + 4] = r1[v]; } if ( (5) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (5) % 4][v] = r0[v]; qfbA[cur][ (5) % 4][v + 4] = r1[v]; } } } if ( (5) < (0 == 1 ? 3 : 3 - 1)) { const int cur = (5) % 3; const uint kkl = uint( ( (5) % 8) * 16); const uint kgl = k0 + kkl; if ( ( ( (3) >> (0)) & 1) != 0) { const uint nrq = (qal4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][0][v] = r0[v]; qfa[cur][0][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][0][v] = r0[v]; qfaB[cur][0][v + 4] = r1[v]; } } if ( ( ( (3) >> (1)) & 1) != 0) { const uint nrq = (qal4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][1][v] = r0[v]; qfa[cur][1][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][1][v] = r0[v]; qfaB[cur][1][v + 4] = r1[v]; } } { const uint nrq = (qbl4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][0][v] = r0[v]; qfb[cur][0][v + 4] = r1[v]; } if ( (0) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (0) % 4][v] = r0[v]; qfbA[cur][ (0) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][1][v] = r0[v]; qfb[cur][1][v + 4] = r1[v]; } if ( (1) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (1) % 4][v] = r0[v]; qfbA[cur][ (1) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[2] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][2][v] = r0[v]; qfb[cur][2][v + 4] = r1[v]; } if ( (2) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (2) % 4][v] = r0[v]; qfbA[cur][ (2) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[3] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][3][v] = r0[v]; qfb[cur][3][v + 4] = r1[v]; } if ( (3) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (3) % 4][v] = r0[v]; qfbA[cur][ (3) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[4] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][4][v] = r0[v]; qfb[cur][4][v + 4] = r1[v]; } if ( (4) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (4) % 4][v] = r0[v]; qfbA[cur][ (4) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[5] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][5][v] = r0[v]; qfb[cur][5][v + 4] = r1[v]; } if ( (5) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (5) % 4][v] = r0[v]; qfbA[cur][ (5) % 4][v + 4] = r1[v]; } } } if ( (6) < (0 == 1 ? 3 : 3 - 1)) { const int cur = (6) % 3; const uint kkl = uint( ( (6) % 8) * 16); const uint kgl = k0 + kkl; if ( ( ( (3) >> (0)) & 1) != 0) { const uint nrq = (qal4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][0][v] = r0[v]; qfa[cur][0][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][0][v] = r0[v]; qfaB[cur][0][v + 4] = r1[v]; } } if ( ( ( (3) >> (1)) & 1) != 0) { const uint nrq = (qal4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][1][v] = r0[v]; qfa[cur][1][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][1][v] = r0[v]; qfaB[cur][1][v + 4] = r1[v]; } } { const uint nrq = (qbl4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][0][v] = r0[v]; qfb[cur][0][v + 4] = r1[v]; } if ( (0) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (0) % 4][v] = r0[v]; qfbA[cur][ (0) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][1][v] = r0[v]; qfb[cur][1][v + 4] = r1[v]; } if ( (1) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (1) % 4][v] = r0[v]; qfbA[cur][ (1) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[2] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][2][v] = r0[v]; qfb[cur][2][v + 4] = r1[v]; } if ( (2) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (2) % 4][v] = r0[v]; qfbA[cur][ (2) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[3] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][3][v] = r0[v]; qfb[cur][3][v + 4] = r1[v]; } if ( (3) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (3) % 4][v] = r0[v]; qfbA[cur][ (3) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[4] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][4][v] = r0[v]; qfb[cur][4][v + 4] = r1[v]; } if ( (4) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (4) % 4][v] = r0[v]; qfbA[cur][ (4) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[5] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][5][v] = r0[v]; qfb[cur][5][v + 4] = r1[v]; } if ( (5) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (5) % 4][v] = r0[v]; qfbA[cur][ (5) % 4][v + 4] = r1[v]; } } } if ( (7) < (0 == 1 ? 3 : 3 - 1)) { const int cur = (7) % 3; const uint kkl = uint( ( (7) % 8) * 16); const uint kgl = k0 + kkl; if ( ( ( (3) >> (0)) & 1) != 0) { const uint nrq = (qal4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][0][v] = r0[v]; qfa[cur][0][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][0][v] = r0[v]; qfaB[cur][0][v + 4] = r1[v]; } } if ( ( ( (3) >> (1)) & 1) != 0) { const uint nrq = (qal4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][1][v] = r0[v]; qfa[cur][1][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][1][v] = r0[v]; qfaB[cur][1][v + 4] = r1[v]; } } { const uint nrq = (qbl4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][0][v] = r0[v]; qfb[cur][0][v + 4] = r1[v]; } if ( (0) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (0) % 4][v] = r0[v]; qfbA[cur][ (0) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][1][v] = r0[v]; qfb[cur][1][v + 4] = r1[v]; } if ( (1) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (1) % 4][v] = r0[v]; qfbA[cur][ (1) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[2] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][2][v] = r0[v]; qfb[cur][2][v + 4] = r1[v]; } if ( (2) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (2) % 4][v] = r0[v]; qfbA[cur][ (2) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[3] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][3][v] = r0[v]; qfb[cur][3][v + 4] = r1[v]; } if ( (3) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (3) % 4][v] = r0[v]; qfbA[cur][ (3) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[4] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][4][v] = r0[v]; qfb[cur][4][v + 4] = r1[v]; } if ( (4) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (4) % 4][v] = r0[v]; qfbA[cur][ (4) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[5] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][5][v] = r0[v]; qfb[cur][5][v + 4] = r1[v]; } if ( (5) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (5) % 4][v] = r0[v]; qfbA[cur][ (5) % 4][v + 4] = r1[v]; } } } { const int pp = (0) % 3; const int cur = ( (0) + 3 - 1) % 3; const uint kkl = uint( ( ( (0) + 3 - 1) % 8) * 16); const uint kgl = k0 + kkl; if (0 == 0 && (0) + 3 - 1 < 8) { if ( ( ( (3) >> (0)) & 1) != 0) { const uint nrq = (qal4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][0][v] = r0[v]; qfa[cur][0][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][0][v] = r0[v]; qfaB[cur][0][v + 4] = r1[v]; } } if ( ( ( (3) >> (1)) & 1) != 0) { const uint nrq = (qal4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][1][v] = r0[v]; qfa[cur][1][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][1][v] = r0[v]; qfaB[cur][1][v + 4] = r1[v]; } } { const uint nrq = (qbl4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][0][v] = r0[v]; qfb[cur][0][v + 4] = r1[v]; } if ( (0) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (0) % 4][v] = r0[v]; qfbA[cur][ (0) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][1][v] = r0[v]; qfb[cur][1][v + 4] = r1[v]; } if ( (1) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (1) % 4][v] = r0[v]; qfbA[cur][ (1) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[2] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][2][v] = r0[v]; qfb[cur][2][v + 4] = r1[v]; } if ( (2) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (2) % 4][v] = r0[v]; qfbA[cur][ (2) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[3] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][3][v] = r0[v]; qfb[cur][3][v + 4] = r1[v]; } if ( (3) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (3) % 4][v] = r0[v]; qfbA[cur][ (3) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[4] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][4][v] = r0[v]; qfb[cur][4][v + 4] = r1[v]; } if ( (4) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (4) % 4][v] = r0[v]; qfbA[cur][ (4) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[5] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][5][v] = r0[v]; qfb[cur][5][v + 4] = r1[v]; } if ( (5) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (5) % 4][v] = r0[v]; qfbA[cur][ (5) % 4][v + 4] = r1[v]; } } } if (0 == 0) { if ( ( ( (3) >> (0)) & 1) != 0) { const int ii = 0; if ( (0) < 4) qacc[ii][0] = coopMatMulAdd(qfbA[pp][ (0) % 4], qfaB[pp][ii], qacc[ii][0]); else qacc[ii][0] = coopMatMulAdd(qfa[pp][ii], qfb[pp][0], qacc[ii][0]); if ( (1) < 4) qacc[ii][1] = coopMatMulAdd(qfbA[pp][ (1) % 4], qfaB[pp][ii], qacc[ii][1]); else qacc[ii][1] = coopMatMulAdd(qfa[pp][ii], qfb[pp][1], qacc[ii][1]); if ( (2) < 4) qacc[ii][2] = coopMatMulAdd(qfbA[pp][ (2) % 4], qfaB[pp][ii], qacc[ii][2]); else qacc[ii][2] = coopMatMulAdd(qfa[pp][ii], qfb[pp][2], qacc[ii][2]); if ( (3) < 4) qacc[ii][3] = coopMatMulAdd(qfbA[pp][ (3) % 4], qfaB[pp][ii], qacc[ii][3]); else qacc[ii][3] = coopMatMulAdd(qfa[pp][ii], qfb[pp][3], qacc[ii][3]); if ( (4) < 4) qacc[ii][4] = coopMatMulAdd(qfbA[pp][ (4) % 4], qfaB[pp][ii], qacc[ii][4]); else qacc[ii][4] = coopMatMulAdd(qfa[pp][ii], qfb[pp][4], qacc[ii][4]); if ( (5) < 4) qacc[ii][5] = coopMatMulAdd(qfbA[pp][ (5) % 4], qfaB[pp][ii], qacc[ii][5]); else qacc[ii][5] = coopMatMulAdd(qfa[pp][ii], qfb[pp][5], qacc[ii][5]); } if ( ( ( (3) >> (1)) & 1) != 0) { const int ii = 1; if ( (0) < 4) qacc[ii][0] = coopMatMulAdd(qfbA[pp][ (0) % 4], qfaB[pp][ii], qacc[ii][0]); else qacc[ii][0] = coopMatMulAdd(qfa[pp][ii], qfb[pp][0], qacc[ii][0]); if ( (1) < 4) qacc[ii][1] = coopMatMulAdd(qfbA[pp][ (1) % 4], qfaB[pp][ii], qacc[ii][1]); else qacc[ii][1] = coopMatMulAdd(qfa[pp][ii], qfb[pp][1], qacc[ii][1]); if ( (2) < 4) qacc[ii][2] = coopMatMulAdd(qfbA[pp][ (2) % 4], qfaB[pp][ii], qacc[ii][2]); else qacc[ii][2] = coopMatMulAdd(qfa[pp][ii], qfb[pp][2], qacc[ii][2]); if ( (3) < 4) qacc[ii][3] = coopMatMulAdd(qfbA[pp][ (3) % 4], qfaB[pp][ii], qacc[ii][3]); else qacc[ii][3] = coopMatMulAdd(qfa[pp][ii], qfb[pp][3], qacc[ii][3]); if ( (4) < 4) qacc[ii][4] = coopMatMulAdd(qfbA[pp][ (4) % 4], qfaB[pp][ii], qacc[ii][4]); else qacc[ii][4] = coopMatMulAdd(qfa[pp][ii], qfb[pp][4], qacc[ii][4]); if ( (5) < 4) qacc[ii][5] = coopMatMulAdd(qfbA[pp][ (5) % 4], qfaB[pp][ii], qacc[ii][5]); else qacc[ii][5] = coopMatMulAdd(qfa[pp][ii], qfb[pp][5], qacc[ii][5]); } } if (0 > 0 && ( (0) + 1) % 0 == 0) { { const int ii = 0; { for (int c = 0; c < qacc[ii][0].length(); ++ c) qacc[ii][0][c] = nr_round_f16_e4m3(qacc[ii][0][c]); } { for (int c = 0; c < qacc[ii][1].length(); ++ c) qacc[ii][1][c] = nr_round_f16_e4m3(qacc[ii][1][c]); } { for (int c = 0; c < qacc[ii][2].length(); ++ c) qacc[ii][2][c] = nr_round_f16_e4m3(qacc[ii][2][c]); } { for (int c = 0; c < qacc[ii][3].length(); ++ c) qacc[ii][3][c] = nr_round_f16_e4m3(qacc[ii][3][c]); } { for (int c = 0; c < qacc[ii][4].length(); ++ c) qacc[ii][4][c] = nr_round_f16_e4m3(qacc[ii][4][c]); } { for (int c = 0; c < qacc[ii][5].length(); ++ c) qacc[ii][5][c] = nr_round_f16_e4m3(qacc[ii][5][c]); } } { const int ii = 1; { for (int c = 0; c < qacc[ii][0].length(); ++ c) qacc[ii][0][c] = nr_round_f16_e4m3(qacc[ii][0][c]); } { for (int c = 0; c < qacc[ii][1].length(); ++ c) qacc[ii][1][c] = nr_round_f16_e4m3(qacc[ii][1][c]); } { for (int c = 0; c < qacc[ii][2].length(); ++ c) qacc[ii][2][c] = nr_round_f16_e4m3(qacc[ii][2][c]); } { for (int c = 0; c < qacc[ii][3].length(); ++ c) qacc[ii][3][c] = nr_round_f16_e4m3(qacc[ii][3][c]); } { for (int c = 0; c < qacc[ii][4].length(); ++ c) qacc[ii][4][c] = nr_round_f16_e4m3(qacc[ii][4][c]); } { for (int c = 0; c < qacc[ii][5].length(); ++ c) qacc[ii][5][c] = nr_round_f16_e4m3(qacc[ii][5][c]); } } } } { const int pp = (1) % 3; const int cur = ( (1) + 3 - 1) % 3; const uint kkl = uint( ( ( (1) + 3 - 1) % 8) * 16); const uint kgl = k0 + kkl; if (0 == 0 && (1) + 3 - 1 < 8) { if ( ( ( (3) >> (0)) & 1) != 0) { const uint nrq = (qal4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][0][v] = r0[v]; qfa[cur][0][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][0][v] = r0[v]; qfaB[cur][0][v + 4] = r1[v]; } } if ( ( ( (3) >> (1)) & 1) != 0) { const uint nrq = (qal4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][1][v] = r0[v]; qfa[cur][1][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][1][v] = r0[v]; qfaB[cur][1][v + 4] = r1[v]; } } { const uint nrq = (qbl4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][0][v] = r0[v]; qfb[cur][0][v + 4] = r1[v]; } if ( (0) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (0) % 4][v] = r0[v]; qfbA[cur][ (0) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][1][v] = r0[v]; qfb[cur][1][v + 4] = r1[v]; } if ( (1) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (1) % 4][v] = r0[v]; qfbA[cur][ (1) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[2] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][2][v] = r0[v]; qfb[cur][2][v + 4] = r1[v]; } if ( (2) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (2) % 4][v] = r0[v]; qfbA[cur][ (2) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[3] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][3][v] = r0[v]; qfb[cur][3][v + 4] = r1[v]; } if ( (3) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (3) % 4][v] = r0[v]; qfbA[cur][ (3) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[4] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][4][v] = r0[v]; qfb[cur][4][v + 4] = r1[v]; } if ( (4) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (4) % 4][v] = r0[v]; qfbA[cur][ (4) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[5] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][5][v] = r0[v]; qfb[cur][5][v + 4] = r1[v]; } if ( (5) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (5) % 4][v] = r0[v]; qfbA[cur][ (5) % 4][v + 4] = r1[v]; } } } if (0 == 0) { if ( ( ( (3) >> (0)) & 1) != 0) { const int ii = 0; if ( (0) < 4) qacc[ii][0] = coopMatMulAdd(qfbA[pp][ (0) % 4], qfaB[pp][ii], qacc[ii][0]); else qacc[ii][0] = coopMatMulAdd(qfa[pp][ii], qfb[pp][0], qacc[ii][0]); if ( (1) < 4) qacc[ii][1] = coopMatMulAdd(qfbA[pp][ (1) % 4], qfaB[pp][ii], qacc[ii][1]); else qacc[ii][1] = coopMatMulAdd(qfa[pp][ii], qfb[pp][1], qacc[ii][1]); if ( (2) < 4) qacc[ii][2] = coopMatMulAdd(qfbA[pp][ (2) % 4], qfaB[pp][ii], qacc[ii][2]); else qacc[ii][2] = coopMatMulAdd(qfa[pp][ii], qfb[pp][2], qacc[ii][2]); if ( (3) < 4) qacc[ii][3] = coopMatMulAdd(qfbA[pp][ (3) % 4], qfaB[pp][ii], qacc[ii][3]); else qacc[ii][3] = coopMatMulAdd(qfa[pp][ii], qfb[pp][3], qacc[ii][3]); if ( (4) < 4) qacc[ii][4] = coopMatMulAdd(qfbA[pp][ (4) % 4], qfaB[pp][ii], qacc[ii][4]); else qacc[ii][4] = coopMatMulAdd(qfa[pp][ii], qfb[pp][4], qacc[ii][4]); if ( (5) < 4) qacc[ii][5] = coopMatMulAdd(qfbA[pp][ (5) % 4], qfaB[pp][ii], qacc[ii][5]); else qacc[ii][5] = coopMatMulAdd(qfa[pp][ii], qfb[pp][5], qacc[ii][5]); } if ( ( ( (3) >> (1)) & 1) != 0) { const int ii = 1; if ( (0) < 4) qacc[ii][0] = coopMatMulAdd(qfbA[pp][ (0) % 4], qfaB[pp][ii], qacc[ii][0]); else qacc[ii][0] = coopMatMulAdd(qfa[pp][ii], qfb[pp][0], qacc[ii][0]); if ( (1) < 4) qacc[ii][1] = coopMatMulAdd(qfbA[pp][ (1) % 4], qfaB[pp][ii], qacc[ii][1]); else qacc[ii][1] = coopMatMulAdd(qfa[pp][ii], qfb[pp][1], qacc[ii][1]); if ( (2) < 4) qacc[ii][2] = coopMatMulAdd(qfbA[pp][ (2) % 4], qfaB[pp][ii], qacc[ii][2]); else qacc[ii][2] = coopMatMulAdd(qfa[pp][ii], qfb[pp][2], qacc[ii][2]); if ( (3) < 4) qacc[ii][3] = coopMatMulAdd(qfbA[pp][ (3) % 4], qfaB[pp][ii], qacc[ii][3]); else qacc[ii][3] = coopMatMulAdd(qfa[pp][ii], qfb[pp][3], qacc[ii][3]); if ( (4) < 4) qacc[ii][4] = coopMatMulAdd(qfbA[pp][ (4) % 4], qfaB[pp][ii], qacc[ii][4]); else qacc[ii][4] = coopMatMulAdd(qfa[pp][ii], qfb[pp][4], qacc[ii][4]); if ( (5) < 4) qacc[ii][5] = coopMatMulAdd(qfbA[pp][ (5) % 4], qfaB[pp][ii], qacc[ii][5]); else qacc[ii][5] = coopMatMulAdd(qfa[pp][ii], qfb[pp][5], qacc[ii][5]); } } if (0 > 0 && ( (1) + 1) % 0 == 0) { { const int ii = 0; { for (int c = 0; c < qacc[ii][0].length(); ++ c) qacc[ii][0][c] = nr_round_f16_e4m3(qacc[ii][0][c]); } { for (int c = 0; c < qacc[ii][1].length(); ++ c) qacc[ii][1][c] = nr_round_f16_e4m3(qacc[ii][1][c]); } { for (int c = 0; c < qacc[ii][2].length(); ++ c) qacc[ii][2][c] = nr_round_f16_e4m3(qacc[ii][2][c]); } { for (int c = 0; c < qacc[ii][3].length(); ++ c) qacc[ii][3][c] = nr_round_f16_e4m3(qacc[ii][3][c]); } { for (int c = 0; c < qacc[ii][4].length(); ++ c) qacc[ii][4][c] = nr_round_f16_e4m3(qacc[ii][4][c]); } { for (int c = 0; c < qacc[ii][5].length(); ++ c) qacc[ii][5][c] = nr_round_f16_e4m3(qacc[ii][5][c]); } } { const int ii = 1; { for (int c = 0; c < qacc[ii][0].length(); ++ c) qacc[ii][0][c] = nr_round_f16_e4m3(qacc[ii][0][c]); } { for (int c = 0; c < qacc[ii][1].length(); ++ c) qacc[ii][1][c] = nr_round_f16_e4m3(qacc[ii][1][c]); } { for (int c = 0; c < qacc[ii][2].length(); ++ c) qacc[ii][2][c] = nr_round_f16_e4m3(qacc[ii][2][c]); } { for (int c = 0; c < qacc[ii][3].length(); ++ c) qacc[ii][3][c] = nr_round_f16_e4m3(qacc[ii][3][c]); } { for (int c = 0; c < qacc[ii][4].length(); ++ c) qacc[ii][4][c] = nr_round_f16_e4m3(qacc[ii][4][c]); } { for (int c = 0; c < qacc[ii][5].length(); ++ c) qacc[ii][5][c] = nr_round_f16_e4m3(qacc[ii][5][c]); } } } } { const int pp = (2) % 3; const int cur = ( (2) + 3 - 1) % 3; const uint kkl = uint( ( ( (2) + 3 - 1) % 8) * 16); const uint kgl = k0 + kkl; if (0 == 0 && (2) + 3 - 1 < 8) { if ( ( ( (3) >> (0)) & 1) != 0) { const uint nrq = (qal4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][0][v] = r0[v]; qfa[cur][0][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][0][v] = r0[v]; qfaB[cur][0][v + 4] = r1[v]; } } if ( ( ( (3) >> (1)) & 1) != 0) { const uint nrq = (qal4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][1][v] = r0[v]; qfa[cur][1][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][1][v] = r0[v]; qfaB[cur][1][v + 4] = r1[v]; } } { const uint nrq = (qbl4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][0][v] = r0[v]; qfb[cur][0][v + 4] = r1[v]; } if ( (0) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (0) % 4][v] = r0[v]; qfbA[cur][ (0) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][1][v] = r0[v]; qfb[cur][1][v + 4] = r1[v]; } if ( (1) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (1) % 4][v] = r0[v]; qfbA[cur][ (1) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[2] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][2][v] = r0[v]; qfb[cur][2][v + 4] = r1[v]; } if ( (2) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (2) % 4][v] = r0[v]; qfbA[cur][ (2) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[3] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][3][v] = r0[v]; qfb[cur][3][v + 4] = r1[v]; } if ( (3) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (3) % 4][v] = r0[v]; qfbA[cur][ (3) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[4] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][4][v] = r0[v]; qfb[cur][4][v + 4] = r1[v]; } if ( (4) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (4) % 4][v] = r0[v]; qfbA[cur][ (4) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[5] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][5][v] = r0[v]; qfb[cur][5][v + 4] = r1[v]; } if ( (5) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (5) % 4][v] = r0[v]; qfbA[cur][ (5) % 4][v + 4] = r1[v]; } } } if (0 == 0) { if ( ( ( (3) >> (0)) & 1) != 0) { const int ii = 0; if ( (0) < 4) qacc[ii][0] = coopMatMulAdd(qfbA[pp][ (0) % 4], qfaB[pp][ii], qacc[ii][0]); else qacc[ii][0] = coopMatMulAdd(qfa[pp][ii], qfb[pp][0], qacc[ii][0]); if ( (1) < 4) qacc[ii][1] = coopMatMulAdd(qfbA[pp][ (1) % 4], qfaB[pp][ii], qacc[ii][1]); else qacc[ii][1] = coopMatMulAdd(qfa[pp][ii], qfb[pp][1], qacc[ii][1]); if ( (2) < 4) qacc[ii][2] = coopMatMulAdd(qfbA[pp][ (2) % 4], qfaB[pp][ii], qacc[ii][2]); else qacc[ii][2] = coopMatMulAdd(qfa[pp][ii], qfb[pp][2], qacc[ii][2]); if ( (3) < 4) qacc[ii][3] = coopMatMulAdd(qfbA[pp][ (3) % 4], qfaB[pp][ii], qacc[ii][3]); else qacc[ii][3] = coopMatMulAdd(qfa[pp][ii], qfb[pp][3], qacc[ii][3]); if ( (4) < 4) qacc[ii][4] = coopMatMulAdd(qfbA[pp][ (4) % 4], qfaB[pp][ii], qacc[ii][4]); else qacc[ii][4] = coopMatMulAdd(qfa[pp][ii], qfb[pp][4], qacc[ii][4]); if ( (5) < 4) qacc[ii][5] = coopMatMulAdd(qfbA[pp][ (5) % 4], qfaB[pp][ii], qacc[ii][5]); else qacc[ii][5] = coopMatMulAdd(qfa[pp][ii], qfb[pp][5], qacc[ii][5]); } if ( ( ( (3) >> (1)) & 1) != 0) { const int ii = 1; if ( (0) < 4) qacc[ii][0] = coopMatMulAdd(qfbA[pp][ (0) % 4], qfaB[pp][ii], qacc[ii][0]); else qacc[ii][0] = coopMatMulAdd(qfa[pp][ii], qfb[pp][0], qacc[ii][0]); if ( (1) < 4) qacc[ii][1] = coopMatMulAdd(qfbA[pp][ (1) % 4], qfaB[pp][ii], qacc[ii][1]); else qacc[ii][1] = coopMatMulAdd(qfa[pp][ii], qfb[pp][1], qacc[ii][1]); if ( (2) < 4) qacc[ii][2] = coopMatMulAdd(qfbA[pp][ (2) % 4], qfaB[pp][ii], qacc[ii][2]); else qacc[ii][2] = coopMatMulAdd(qfa[pp][ii], qfb[pp][2], qacc[ii][2]); if ( (3) < 4) qacc[ii][3] = coopMatMulAdd(qfbA[pp][ (3) % 4], qfaB[pp][ii], qacc[ii][3]); else qacc[ii][3] = coopMatMulAdd(qfa[pp][ii], qfb[pp][3], qacc[ii][3]); if ( (4) < 4) qacc[ii][4] = coopMatMulAdd(qfbA[pp][ (4) % 4], qfaB[pp][ii], qacc[ii][4]); else qacc[ii][4] = coopMatMulAdd(qfa[pp][ii], qfb[pp][4], qacc[ii][4]); if ( (5) < 4) qacc[ii][5] = coopMatMulAdd(qfbA[pp][ (5) % 4], qfaB[pp][ii], qacc[ii][5]); else qacc[ii][5] = coopMatMulAdd(qfa[pp][ii], qfb[pp][5], qacc[ii][5]); } } if (0 > 0 && ( (2) + 1) % 0 == 0) { { const int ii = 0; { for (int c = 0; c < qacc[ii][0].length(); ++ c) qacc[ii][0][c] = nr_round_f16_e4m3(qacc[ii][0][c]); } { for (int c = 0; c < qacc[ii][1].length(); ++ c) qacc[ii][1][c] = nr_round_f16_e4m3(qacc[ii][1][c]); } { for (int c = 0; c < qacc[ii][2].length(); ++ c) qacc[ii][2][c] = nr_round_f16_e4m3(qacc[ii][2][c]); } { for (int c = 0; c < qacc[ii][3].length(); ++ c) qacc[ii][3][c] = nr_round_f16_e4m3(qacc[ii][3][c]); } { for (int c = 0; c < qacc[ii][4].length(); ++ c) qacc[ii][4][c] = nr_round_f16_e4m3(qacc[ii][4][c]); } { for (int c = 0; c < qacc[ii][5].length(); ++ c) qacc[ii][5][c] = nr_round_f16_e4m3(qacc[ii][5][c]); } } { const int ii = 1; { for (int c = 0; c < qacc[ii][0].length(); ++ c) qacc[ii][0][c] = nr_round_f16_e4m3(qacc[ii][0][c]); } { for (int c = 0; c < qacc[ii][1].length(); ++ c) qacc[ii][1][c] = nr_round_f16_e4m3(qacc[ii][1][c]); } { for (int c = 0; c < qacc[ii][2].length(); ++ c) qacc[ii][2][c] = nr_round_f16_e4m3(qacc[ii][2][c]); } { for (int c = 0; c < qacc[ii][3].length(); ++ c) qacc[ii][3][c] = nr_round_f16_e4m3(qacc[ii][3][c]); } { for (int c = 0; c < qacc[ii][4].length(); ++ c) qacc[ii][4][c] = nr_round_f16_e4m3(qacc[ii][4][c]); } { for (int c = 0; c < qacc[ii][5].length(); ++ c) qacc[ii][5][c] = nr_round_f16_e4m3(qacc[ii][5][c]); } } } } { const int pp = (3) % 3; const int cur = ( (3) + 3 - 1) % 3; const uint kkl = uint( ( ( (3) + 3 - 1) % 8) * 16); const uint kgl = k0 + kkl; if (0 == 0 && (3) + 3 - 1 < 8) { if ( ( ( (3) >> (0)) & 1) != 0) { const uint nrq = (qal4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][0][v] = r0[v]; qfa[cur][0][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][0][v] = r0[v]; qfaB[cur][0][v + 4] = r1[v]; } } if ( ( ( (3) >> (1)) & 1) != 0) { const uint nrq = (qal4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][1][v] = r0[v]; qfa[cur][1][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][1][v] = r0[v]; qfaB[cur][1][v + 4] = r1[v]; } } { const uint nrq = (qbl4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][0][v] = r0[v]; qfb[cur][0][v + 4] = r1[v]; } if ( (0) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (0) % 4][v] = r0[v]; qfbA[cur][ (0) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][1][v] = r0[v]; qfb[cur][1][v + 4] = r1[v]; } if ( (1) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (1) % 4][v] = r0[v]; qfbA[cur][ (1) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[2] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][2][v] = r0[v]; qfb[cur][2][v + 4] = r1[v]; } if ( (2) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (2) % 4][v] = r0[v]; qfbA[cur][ (2) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[3] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][3][v] = r0[v]; qfb[cur][3][v + 4] = r1[v]; } if ( (3) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (3) % 4][v] = r0[v]; qfbA[cur][ (3) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[4] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][4][v] = r0[v]; qfb[cur][4][v + 4] = r1[v]; } if ( (4) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (4) % 4][v] = r0[v]; qfbA[cur][ (4) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[5] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][5][v] = r0[v]; qfb[cur][5][v + 4] = r1[v]; } if ( (5) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (5) % 4][v] = r0[v]; qfbA[cur][ (5) % 4][v + 4] = r1[v]; } } } if (0 == 0) { if ( ( ( (3) >> (0)) & 1) != 0) { const int ii = 0; if ( (0) < 4) qacc[ii][0] = coopMatMulAdd(qfbA[pp][ (0) % 4], qfaB[pp][ii], qacc[ii][0]); else qacc[ii][0] = coopMatMulAdd(qfa[pp][ii], qfb[pp][0], qacc[ii][0]); if ( (1) < 4) qacc[ii][1] = coopMatMulAdd(qfbA[pp][ (1) % 4], qfaB[pp][ii], qacc[ii][1]); else qacc[ii][1] = coopMatMulAdd(qfa[pp][ii], qfb[pp][1], qacc[ii][1]); if ( (2) < 4) qacc[ii][2] = coopMatMulAdd(qfbA[pp][ (2) % 4], qfaB[pp][ii], qacc[ii][2]); else qacc[ii][2] = coopMatMulAdd(qfa[pp][ii], qfb[pp][2], qacc[ii][2]); if ( (3) < 4) qacc[ii][3] = coopMatMulAdd(qfbA[pp][ (3) % 4], qfaB[pp][ii], qacc[ii][3]); else qacc[ii][3] = coopMatMulAdd(qfa[pp][ii], qfb[pp][3], qacc[ii][3]); if ( (4) < 4) qacc[ii][4] = coopMatMulAdd(qfbA[pp][ (4) % 4], qfaB[pp][ii], qacc[ii][4]); else qacc[ii][4] = coopMatMulAdd(qfa[pp][ii], qfb[pp][4], qacc[ii][4]); if ( (5) < 4) qacc[ii][5] = coopMatMulAdd(qfbA[pp][ (5) % 4], qfaB[pp][ii], qacc[ii][5]); else qacc[ii][5] = coopMatMulAdd(qfa[pp][ii], qfb[pp][5], qacc[ii][5]); } if ( ( ( (3) >> (1)) & 1) != 0) { const int ii = 1; if ( (0) < 4) qacc[ii][0] = coopMatMulAdd(qfbA[pp][ (0) % 4], qfaB[pp][ii], qacc[ii][0]); else qacc[ii][0] = coopMatMulAdd(qfa[pp][ii], qfb[pp][0], qacc[ii][0]); if ( (1) < 4) qacc[ii][1] = coopMatMulAdd(qfbA[pp][ (1) % 4], qfaB[pp][ii], qacc[ii][1]); else qacc[ii][1] = coopMatMulAdd(qfa[pp][ii], qfb[pp][1], qacc[ii][1]); if ( (2) < 4) qacc[ii][2] = coopMatMulAdd(qfbA[pp][ (2) % 4], qfaB[pp][ii], qacc[ii][2]); else qacc[ii][2] = coopMatMulAdd(qfa[pp][ii], qfb[pp][2], qacc[ii][2]); if ( (3) < 4) qacc[ii][3] = coopMatMulAdd(qfbA[pp][ (3) % 4], qfaB[pp][ii], qacc[ii][3]); else qacc[ii][3] = coopMatMulAdd(qfa[pp][ii], qfb[pp][3], qacc[ii][3]); if ( (4) < 4) qacc[ii][4] = coopMatMulAdd(qfbA[pp][ (4) % 4], qfaB[pp][ii], qacc[ii][4]); else qacc[ii][4] = coopMatMulAdd(qfa[pp][ii], qfb[pp][4], qacc[ii][4]); if ( (5) < 4) qacc[ii][5] = coopMatMulAdd(qfbA[pp][ (5) % 4], qfaB[pp][ii], qacc[ii][5]); else qacc[ii][5] = coopMatMulAdd(qfa[pp][ii], qfb[pp][5], qacc[ii][5]); } } if (0 > 0 && ( (3) + 1) % 0 == 0) { { const int ii = 0; { for (int c = 0; c < qacc[ii][0].length(); ++ c) qacc[ii][0][c] = nr_round_f16_e4m3(qacc[ii][0][c]); } { for (int c = 0; c < qacc[ii][1].length(); ++ c) qacc[ii][1][c] = nr_round_f16_e4m3(qacc[ii][1][c]); } { for (int c = 0; c < qacc[ii][2].length(); ++ c) qacc[ii][2][c] = nr_round_f16_e4m3(qacc[ii][2][c]); } { for (int c = 0; c < qacc[ii][3].length(); ++ c) qacc[ii][3][c] = nr_round_f16_e4m3(qacc[ii][3][c]); } { for (int c = 0; c < qacc[ii][4].length(); ++ c) qacc[ii][4][c] = nr_round_f16_e4m3(qacc[ii][4][c]); } { for (int c = 0; c < qacc[ii][5].length(); ++ c) qacc[ii][5][c] = nr_round_f16_e4m3(qacc[ii][5][c]); } } { const int ii = 1; { for (int c = 0; c < qacc[ii][0].length(); ++ c) qacc[ii][0][c] = nr_round_f16_e4m3(qacc[ii][0][c]); } { for (int c = 0; c < qacc[ii][1].length(); ++ c) qacc[ii][1][c] = nr_round_f16_e4m3(qacc[ii][1][c]); } { for (int c = 0; c < qacc[ii][2].length(); ++ c) qacc[ii][2][c] = nr_round_f16_e4m3(qacc[ii][2][c]); } { for (int c = 0; c < qacc[ii][3].length(); ++ c) qacc[ii][3][c] = nr_round_f16_e4m3(qacc[ii][3][c]); } { for (int c = 0; c < qacc[ii][4].length(); ++ c) qacc[ii][4][c] = nr_round_f16_e4m3(qacc[ii][4][c]); } { for (int c = 0; c < qacc[ii][5].length(); ++ c) qacc[ii][5][c] = nr_round_f16_e4m3(qacc[ii][5][c]); } } } } { const int pp = (4) % 3; const int cur = ( (4) + 3 - 1) % 3; const uint kkl = uint( ( ( (4) + 3 - 1) % 8) * 16); const uint kgl = k0 + kkl; if (0 == 0 && (4) + 3 - 1 < 8) { if ( ( ( (3) >> (0)) & 1) != 0) { const uint nrq = (qal4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][0][v] = r0[v]; qfa[cur][0][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][0][v] = r0[v]; qfaB[cur][0][v + 4] = r1[v]; } } if ( ( ( (3) >> (1)) & 1) != 0) { const uint nrq = (qal4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][1][v] = r0[v]; qfa[cur][1][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][1][v] = r0[v]; qfaB[cur][1][v + 4] = r1[v]; } } { const uint nrq = (qbl4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][0][v] = r0[v]; qfb[cur][0][v + 4] = r1[v]; } if ( (0) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (0) % 4][v] = r0[v]; qfbA[cur][ (0) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][1][v] = r0[v]; qfb[cur][1][v + 4] = r1[v]; } if ( (1) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (1) % 4][v] = r0[v]; qfbA[cur][ (1) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[2] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][2][v] = r0[v]; qfb[cur][2][v + 4] = r1[v]; } if ( (2) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (2) % 4][v] = r0[v]; qfbA[cur][ (2) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[3] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][3][v] = r0[v]; qfb[cur][3][v + 4] = r1[v]; } if ( (3) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (3) % 4][v] = r0[v]; qfbA[cur][ (3) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[4] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][4][v] = r0[v]; qfb[cur][4][v + 4] = r1[v]; } if ( (4) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (4) % 4][v] = r0[v]; qfbA[cur][ (4) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[5] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][5][v] = r0[v]; qfb[cur][5][v + 4] = r1[v]; } if ( (5) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (5) % 4][v] = r0[v]; qfbA[cur][ (5) % 4][v + 4] = r1[v]; } } } if (0 == 0) { if ( ( ( (3) >> (0)) & 1) != 0) { const int ii = 0; if ( (0) < 4) qacc[ii][0] = coopMatMulAdd(qfbA[pp][ (0) % 4], qfaB[pp][ii], qacc[ii][0]); else qacc[ii][0] = coopMatMulAdd(qfa[pp][ii], qfb[pp][0], qacc[ii][0]); if ( (1) < 4) qacc[ii][1] = coopMatMulAdd(qfbA[pp][ (1) % 4], qfaB[pp][ii], qacc[ii][1]); else qacc[ii][1] = coopMatMulAdd(qfa[pp][ii], qfb[pp][1], qacc[ii][1]); if ( (2) < 4) qacc[ii][2] = coopMatMulAdd(qfbA[pp][ (2) % 4], qfaB[pp][ii], qacc[ii][2]); else qacc[ii][2] = coopMatMulAdd(qfa[pp][ii], qfb[pp][2], qacc[ii][2]); if ( (3) < 4) qacc[ii][3] = coopMatMulAdd(qfbA[pp][ (3) % 4], qfaB[pp][ii], qacc[ii][3]); else qacc[ii][3] = coopMatMulAdd(qfa[pp][ii], qfb[pp][3], qacc[ii][3]); if ( (4) < 4) qacc[ii][4] = coopMatMulAdd(qfbA[pp][ (4) % 4], qfaB[pp][ii], qacc[ii][4]); else qacc[ii][4] = coopMatMulAdd(qfa[pp][ii], qfb[pp][4], qacc[ii][4]); if ( (5) < 4) qacc[ii][5] = coopMatMulAdd(qfbA[pp][ (5) % 4], qfaB[pp][ii], qacc[ii][5]); else qacc[ii][5] = coopMatMulAdd(qfa[pp][ii], qfb[pp][5], qacc[ii][5]); } if ( ( ( (3) >> (1)) & 1) != 0) { const int ii = 1; if ( (0) < 4) qacc[ii][0] = coopMatMulAdd(qfbA[pp][ (0) % 4], qfaB[pp][ii], qacc[ii][0]); else qacc[ii][0] = coopMatMulAdd(qfa[pp][ii], qfb[pp][0], qacc[ii][0]); if ( (1) < 4) qacc[ii][1] = coopMatMulAdd(qfbA[pp][ (1) % 4], qfaB[pp][ii], qacc[ii][1]); else qacc[ii][1] = coopMatMulAdd(qfa[pp][ii], qfb[pp][1], qacc[ii][1]); if ( (2) < 4) qacc[ii][2] = coopMatMulAdd(qfbA[pp][ (2) % 4], qfaB[pp][ii], qacc[ii][2]); else qacc[ii][2] = coopMatMulAdd(qfa[pp][ii], qfb[pp][2], qacc[ii][2]); if ( (3) < 4) qacc[ii][3] = coopMatMulAdd(qfbA[pp][ (3) % 4], qfaB[pp][ii], qacc[ii][3]); else qacc[ii][3] = coopMatMulAdd(qfa[pp][ii], qfb[pp][3], qacc[ii][3]); if ( (4) < 4) qacc[ii][4] = coopMatMulAdd(qfbA[pp][ (4) % 4], qfaB[pp][ii], qacc[ii][4]); else qacc[ii][4] = coopMatMulAdd(qfa[pp][ii], qfb[pp][4], qacc[ii][4]); if ( (5) < 4) qacc[ii][5] = coopMatMulAdd(qfbA[pp][ (5) % 4], qfaB[pp][ii], qacc[ii][5]); else qacc[ii][5] = coopMatMulAdd(qfa[pp][ii], qfb[pp][5], qacc[ii][5]); } } if (0 > 0 && ( (4) + 1) % 0 == 0) { { const int ii = 0; { for (int c = 0; c < qacc[ii][0].length(); ++ c) qacc[ii][0][c] = nr_round_f16_e4m3(qacc[ii][0][c]); } { for (int c = 0; c < qacc[ii][1].length(); ++ c) qacc[ii][1][c] = nr_round_f16_e4m3(qacc[ii][1][c]); } { for (int c = 0; c < qacc[ii][2].length(); ++ c) qacc[ii][2][c] = nr_round_f16_e4m3(qacc[ii][2][c]); } { for (int c = 0; c < qacc[ii][3].length(); ++ c) qacc[ii][3][c] = nr_round_f16_e4m3(qacc[ii][3][c]); } { for (int c = 0; c < qacc[ii][4].length(); ++ c) qacc[ii][4][c] = nr_round_f16_e4m3(qacc[ii][4][c]); } { for (int c = 0; c < qacc[ii][5].length(); ++ c) qacc[ii][5][c] = nr_round_f16_e4m3(qacc[ii][5][c]); } } { const int ii = 1; { for (int c = 0; c < qacc[ii][0].length(); ++ c) qacc[ii][0][c] = nr_round_f16_e4m3(qacc[ii][0][c]); } { for (int c = 0; c < qacc[ii][1].length(); ++ c) qacc[ii][1][c] = nr_round_f16_e4m3(qacc[ii][1][c]); } { for (int c = 0; c < qacc[ii][2].length(); ++ c) qacc[ii][2][c] = nr_round_f16_e4m3(qacc[ii][2][c]); } { for (int c = 0; c < qacc[ii][3].length(); ++ c) qacc[ii][3][c] = nr_round_f16_e4m3(qacc[ii][3][c]); } { for (int c = 0; c < qacc[ii][4].length(); ++ c) qacc[ii][4][c] = nr_round_f16_e4m3(qacc[ii][4][c]); } { for (int c = 0; c < qacc[ii][5].length(); ++ c) qacc[ii][5][c] = nr_round_f16_e4m3(qacc[ii][5][c]); } } } } { const int pp = (5) % 3; const int cur = ( (5) + 3 - 1) % 3; const uint kkl = uint( ( ( (5) + 3 - 1) % 8) * 16); const uint kgl = k0 + kkl; if (0 == 0 && (5) + 3 - 1 < 8) { if ( ( ( (3) >> (0)) & 1) != 0) { const uint nrq = (qal4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][0][v] = r0[v]; qfa[cur][0][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][0][v] = r0[v]; qfaB[cur][0][v + 4] = r1[v]; } } if ( ( ( (3) >> (1)) & 1) != 0) { const uint nrq = (qal4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][1][v] = r0[v]; qfa[cur][1][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][1][v] = r0[v]; qfaB[cur][1][v + 4] = r1[v]; } } { const uint nrq = (qbl4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][0][v] = r0[v]; qfb[cur][0][v + 4] = r1[v]; } if ( (0) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (0) % 4][v] = r0[v]; qfbA[cur][ (0) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][1][v] = r0[v]; qfb[cur][1][v + 4] = r1[v]; } if ( (1) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (1) % 4][v] = r0[v]; qfbA[cur][ (1) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[2] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][2][v] = r0[v]; qfb[cur][2][v + 4] = r1[v]; } if ( (2) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (2) % 4][v] = r0[v]; qfbA[cur][ (2) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[3] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][3][v] = r0[v]; qfb[cur][3][v + 4] = r1[v]; } if ( (3) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (3) % 4][v] = r0[v]; qfbA[cur][ (3) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[4] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][4][v] = r0[v]; qfb[cur][4][v + 4] = r1[v]; } if ( (4) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (4) % 4][v] = r0[v]; qfbA[cur][ (4) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[5] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][5][v] = r0[v]; qfb[cur][5][v + 4] = r1[v]; } if ( (5) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (5) % 4][v] = r0[v]; qfbA[cur][ (5) % 4][v + 4] = r1[v]; } } } if (0 == 0) { if ( ( ( (3) >> (0)) & 1) != 0) { const int ii = 0; if ( (0) < 4) qacc[ii][0] = coopMatMulAdd(qfbA[pp][ (0) % 4], qfaB[pp][ii], qacc[ii][0]); else qacc[ii][0] = coopMatMulAdd(qfa[pp][ii], qfb[pp][0], qacc[ii][0]); if ( (1) < 4) qacc[ii][1] = coopMatMulAdd(qfbA[pp][ (1) % 4], qfaB[pp][ii], qacc[ii][1]); else qacc[ii][1] = coopMatMulAdd(qfa[pp][ii], qfb[pp][1], qacc[ii][1]); if ( (2) < 4) qacc[ii][2] = coopMatMulAdd(qfbA[pp][ (2) % 4], qfaB[pp][ii], qacc[ii][2]); else qacc[ii][2] = coopMatMulAdd(qfa[pp][ii], qfb[pp][2], qacc[ii][2]); if ( (3) < 4) qacc[ii][3] = coopMatMulAdd(qfbA[pp][ (3) % 4], qfaB[pp][ii], qacc[ii][3]); else qacc[ii][3] = coopMatMulAdd(qfa[pp][ii], qfb[pp][3], qacc[ii][3]); if ( (4) < 4) qacc[ii][4] = coopMatMulAdd(qfbA[pp][ (4) % 4], qfaB[pp][ii], qacc[ii][4]); else qacc[ii][4] = coopMatMulAdd(qfa[pp][ii], qfb[pp][4], qacc[ii][4]); if ( (5) < 4) qacc[ii][5] = coopMatMulAdd(qfbA[pp][ (5) % 4], qfaB[pp][ii], qacc[ii][5]); else qacc[ii][5] = coopMatMulAdd(qfa[pp][ii], qfb[pp][5], qacc[ii][5]); } if ( ( ( (3) >> (1)) & 1) != 0) { const int ii = 1; if ( (0) < 4) qacc[ii][0] = coopMatMulAdd(qfbA[pp][ (0) % 4], qfaB[pp][ii], qacc[ii][0]); else qacc[ii][0] = coopMatMulAdd(qfa[pp][ii], qfb[pp][0], qacc[ii][0]); if ( (1) < 4) qacc[ii][1] = coopMatMulAdd(qfbA[pp][ (1) % 4], qfaB[pp][ii], qacc[ii][1]); else qacc[ii][1] = coopMatMulAdd(qfa[pp][ii], qfb[pp][1], qacc[ii][1]); if ( (2) < 4) qacc[ii][2] = coopMatMulAdd(qfbA[pp][ (2) % 4], qfaB[pp][ii], qacc[ii][2]); else qacc[ii][2] = coopMatMulAdd(qfa[pp][ii], qfb[pp][2], qacc[ii][2]); if ( (3) < 4) qacc[ii][3] = coopMatMulAdd(qfbA[pp][ (3) % 4], qfaB[pp][ii], qacc[ii][3]); else qacc[ii][3] = coopMatMulAdd(qfa[pp][ii], qfb[pp][3], qacc[ii][3]); if ( (4) < 4) qacc[ii][4] = coopMatMulAdd(qfbA[pp][ (4) % 4], qfaB[pp][ii], qacc[ii][4]); else qacc[ii][4] = coopMatMulAdd(qfa[pp][ii], qfb[pp][4], qacc[ii][4]); if ( (5) < 4) qacc[ii][5] = coopMatMulAdd(qfbA[pp][ (5) % 4], qfaB[pp][ii], qacc[ii][5]); else qacc[ii][5] = coopMatMulAdd(qfa[pp][ii], qfb[pp][5], qacc[ii][5]); } } if (0 > 0 && ( (5) + 1) % 0 == 0) { { const int ii = 0; { for (int c = 0; c < qacc[ii][0].length(); ++ c) qacc[ii][0][c] = nr_round_f16_e4m3(qacc[ii][0][c]); } { for (int c = 0; c < qacc[ii][1].length(); ++ c) qacc[ii][1][c] = nr_round_f16_e4m3(qacc[ii][1][c]); } { for (int c = 0; c < qacc[ii][2].length(); ++ c) qacc[ii][2][c] = nr_round_f16_e4m3(qacc[ii][2][c]); } { for (int c = 0; c < qacc[ii][3].length(); ++ c) qacc[ii][3][c] = nr_round_f16_e4m3(qacc[ii][3][c]); } { for (int c = 0; c < qacc[ii][4].length(); ++ c) qacc[ii][4][c] = nr_round_f16_e4m3(qacc[ii][4][c]); } { for (int c = 0; c < qacc[ii][5].length(); ++ c) qacc[ii][5][c] = nr_round_f16_e4m3(qacc[ii][5][c]); } } { const int ii = 1; { for (int c = 0; c < qacc[ii][0].length(); ++ c) qacc[ii][0][c] = nr_round_f16_e4m3(qacc[ii][0][c]); } { for (int c = 0; c < qacc[ii][1].length(); ++ c) qacc[ii][1][c] = nr_round_f16_e4m3(qacc[ii][1][c]); } { for (int c = 0; c < qacc[ii][2].length(); ++ c) qacc[ii][2][c] = nr_round_f16_e4m3(qacc[ii][2][c]); } { for (int c = 0; c < qacc[ii][3].length(); ++ c) qacc[ii][3][c] = nr_round_f16_e4m3(qacc[ii][3][c]); } { for (int c = 0; c < qacc[ii][4].length(); ++ c) qacc[ii][4][c] = nr_round_f16_e4m3(qacc[ii][4][c]); } { for (int c = 0; c < qacc[ii][5].length(); ++ c) qacc[ii][5][c] = nr_round_f16_e4m3(qacc[ii][5][c]); } } } } { const int pp = (6) % 3; const int cur = ( (6) + 3 - 1) % 3; const uint kkl = uint( ( ( (6) + 3 - 1) % 8) * 16); const uint kgl = k0 + kkl; if (0 == 0 && (6) + 3 - 1 < 8) { if ( ( ( (3) >> (0)) & 1) != 0) { const uint nrq = (qal4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][0][v] = r0[v]; qfa[cur][0][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][0][v] = r0[v]; qfaB[cur][0][v + 4] = r1[v]; } } if ( ( ( (3) >> (1)) & 1) != 0) { const uint nrq = (qal4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][1][v] = r0[v]; qfa[cur][1][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][1][v] = r0[v]; qfaB[cur][1][v + 4] = r1[v]; } } { const uint nrq = (qbl4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][0][v] = r0[v]; qfb[cur][0][v + 4] = r1[v]; } if ( (0) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (0) % 4][v] = r0[v]; qfbA[cur][ (0) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][1][v] = r0[v]; qfb[cur][1][v + 4] = r1[v]; } if ( (1) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (1) % 4][v] = r0[v]; qfbA[cur][ (1) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[2] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][2][v] = r0[v]; qfb[cur][2][v + 4] = r1[v]; } if ( (2) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (2) % 4][v] = r0[v]; qfbA[cur][ (2) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[3] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][3][v] = r0[v]; qfb[cur][3][v + 4] = r1[v]; } if ( (3) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (3) % 4][v] = r0[v]; qfbA[cur][ (3) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[4] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][4][v] = r0[v]; qfb[cur][4][v + 4] = r1[v]; } if ( (4) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (4) % 4][v] = r0[v]; qfbA[cur][ (4) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[5] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][5][v] = r0[v]; qfb[cur][5][v + 4] = r1[v]; } if ( (5) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (5) % 4][v] = r0[v]; qfbA[cur][ (5) % 4][v + 4] = r1[v]; } } } if (0 == 0) { if ( ( ( (3) >> (0)) & 1) != 0) { const int ii = 0; if ( (0) < 4) qacc[ii][0] = coopMatMulAdd(qfbA[pp][ (0) % 4], qfaB[pp][ii], qacc[ii][0]); else qacc[ii][0] = coopMatMulAdd(qfa[pp][ii], qfb[pp][0], qacc[ii][0]); if ( (1) < 4) qacc[ii][1] = coopMatMulAdd(qfbA[pp][ (1) % 4], qfaB[pp][ii], qacc[ii][1]); else qacc[ii][1] = coopMatMulAdd(qfa[pp][ii], qfb[pp][1], qacc[ii][1]); if ( (2) < 4) qacc[ii][2] = coopMatMulAdd(qfbA[pp][ (2) % 4], qfaB[pp][ii], qacc[ii][2]); else qacc[ii][2] = coopMatMulAdd(qfa[pp][ii], qfb[pp][2], qacc[ii][2]); if ( (3) < 4) qacc[ii][3] = coopMatMulAdd(qfbA[pp][ (3) % 4], qfaB[pp][ii], qacc[ii][3]); else qacc[ii][3] = coopMatMulAdd(qfa[pp][ii], qfb[pp][3], qacc[ii][3]); if ( (4) < 4) qacc[ii][4] = coopMatMulAdd(qfbA[pp][ (4) % 4], qfaB[pp][ii], qacc[ii][4]); else qacc[ii][4] = coopMatMulAdd(qfa[pp][ii], qfb[pp][4], qacc[ii][4]); if ( (5) < 4) qacc[ii][5] = coopMatMulAdd(qfbA[pp][ (5) % 4], qfaB[pp][ii], qacc[ii][5]); else qacc[ii][5] = coopMatMulAdd(qfa[pp][ii], qfb[pp][5], qacc[ii][5]); } if ( ( ( (3) >> (1)) & 1) != 0) { const int ii = 1; if ( (0) < 4) qacc[ii][0] = coopMatMulAdd(qfbA[pp][ (0) % 4], qfaB[pp][ii], qacc[ii][0]); else qacc[ii][0] = coopMatMulAdd(qfa[pp][ii], qfb[pp][0], qacc[ii][0]); if ( (1) < 4) qacc[ii][1] = coopMatMulAdd(qfbA[pp][ (1) % 4], qfaB[pp][ii], qacc[ii][1]); else qacc[ii][1] = coopMatMulAdd(qfa[pp][ii], qfb[pp][1], qacc[ii][1]); if ( (2) < 4) qacc[ii][2] = coopMatMulAdd(qfbA[pp][ (2) % 4], qfaB[pp][ii], qacc[ii][2]); else qacc[ii][2] = coopMatMulAdd(qfa[pp][ii], qfb[pp][2], qacc[ii][2]); if ( (3) < 4) qacc[ii][3] = coopMatMulAdd(qfbA[pp][ (3) % 4], qfaB[pp][ii], qacc[ii][3]); else qacc[ii][3] = coopMatMulAdd(qfa[pp][ii], qfb[pp][3], qacc[ii][3]); if ( (4) < 4) qacc[ii][4] = coopMatMulAdd(qfbA[pp][ (4) % 4], qfaB[pp][ii], qacc[ii][4]); else qacc[ii][4] = coopMatMulAdd(qfa[pp][ii], qfb[pp][4], qacc[ii][4]); if ( (5) < 4) qacc[ii][5] = coopMatMulAdd(qfbA[pp][ (5) % 4], qfaB[pp][ii], qacc[ii][5]); else qacc[ii][5] = coopMatMulAdd(qfa[pp][ii], qfb[pp][5], qacc[ii][5]); } } if (0 > 0 && ( (6) + 1) % 0 == 0) { { const int ii = 0; { for (int c = 0; c < qacc[ii][0].length(); ++ c) qacc[ii][0][c] = nr_round_f16_e4m3(qacc[ii][0][c]); } { for (int c = 0; c < qacc[ii][1].length(); ++ c) qacc[ii][1][c] = nr_round_f16_e4m3(qacc[ii][1][c]); } { for (int c = 0; c < qacc[ii][2].length(); ++ c) qacc[ii][2][c] = nr_round_f16_e4m3(qacc[ii][2][c]); } { for (int c = 0; c < qacc[ii][3].length(); ++ c) qacc[ii][3][c] = nr_round_f16_e4m3(qacc[ii][3][c]); } { for (int c = 0; c < qacc[ii][4].length(); ++ c) qacc[ii][4][c] = nr_round_f16_e4m3(qacc[ii][4][c]); } { for (int c = 0; c < qacc[ii][5].length(); ++ c) qacc[ii][5][c] = nr_round_f16_e4m3(qacc[ii][5][c]); } } { const int ii = 1; { for (int c = 0; c < qacc[ii][0].length(); ++ c) qacc[ii][0][c] = nr_round_f16_e4m3(qacc[ii][0][c]); } { for (int c = 0; c < qacc[ii][1].length(); ++ c) qacc[ii][1][c] = nr_round_f16_e4m3(qacc[ii][1][c]); } { for (int c = 0; c < qacc[ii][2].length(); ++ c) qacc[ii][2][c] = nr_round_f16_e4m3(qacc[ii][2][c]); } { for (int c = 0; c < qacc[ii][3].length(); ++ c) qacc[ii][3][c] = nr_round_f16_e4m3(qacc[ii][3][c]); } { for (int c = 0; c < qacc[ii][4].length(); ++ c) qacc[ii][4][c] = nr_round_f16_e4m3(qacc[ii][4][c]); } { for (int c = 0; c < qacc[ii][5].length(); ++ c) qacc[ii][5][c] = nr_round_f16_e4m3(qacc[ii][5][c]); } } } } { const int pp = (7) % 3; const int cur = ( (7) + 3 - 1) % 3; const uint kkl = uint( ( ( (7) + 3 - 1) % 8) * 16); const uint kgl = k0 + kkl; if (0 == 0 && (7) + 3 - 1 < 8) { if ( ( ( (3) >> (0)) & 1) != 0) { const uint nrq = (qal4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][0][v] = r0[v]; qfa[cur][0][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][0][v] = r0[v]; qfaB[cur][0][v + 4] = r1[v]; } } if ( ( ( (3) >> (1)) & 1) != 0) { const uint nrq = (qal4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][1][v] = r0[v]; qfa[cur][1][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][1][v] = r0[v]; qfaB[cur][1][v + 4] = r1[v]; } } { const uint nrq = (qbl4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][0][v] = r0[v]; qfb[cur][0][v + 4] = r1[v]; } if ( (0) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (0) % 4][v] = r0[v]; qfbA[cur][ (0) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][1][v] = r0[v]; qfb[cur][1][v + 4] = r1[v]; } if ( (1) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (1) % 4][v] = r0[v]; qfbA[cur][ (1) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[2] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][2][v] = r0[v]; qfb[cur][2][v + 4] = r1[v]; } if ( (2) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (2) % 4][v] = r0[v]; qfbA[cur][ (2) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[3] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][3][v] = r0[v]; qfb[cur][3][v + 4] = r1[v]; } if ( (3) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (3) % 4][v] = r0[v]; qfbA[cur][ (3) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[4] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][4][v] = r0[v]; qfb[cur][4][v + 4] = r1[v]; } if ( (4) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (4) % 4][v] = r0[v]; qfbA[cur][ (4) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[5] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][5][v] = r0[v]; qfb[cur][5][v + 4] = r1[v]; } if ( (5) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (5) % 4][v] = r0[v]; qfbA[cur][ (5) % 4][v + 4] = r1[v]; } } } if (0 == 0) { if ( ( ( (3) >> (0)) & 1) != 0) { const int ii = 0; if ( (0) < 4) qacc[ii][0] = coopMatMulAdd(qfbA[pp][ (0) % 4], qfaB[pp][ii], qacc[ii][0]); else qacc[ii][0] = coopMatMulAdd(qfa[pp][ii], qfb[pp][0], qacc[ii][0]); if ( (1) < 4) qacc[ii][1] = coopMatMulAdd(qfbA[pp][ (1) % 4], qfaB[pp][ii], qacc[ii][1]); else qacc[ii][1] = coopMatMulAdd(qfa[pp][ii], qfb[pp][1], qacc[ii][1]); if ( (2) < 4) qacc[ii][2] = coopMatMulAdd(qfbA[pp][ (2) % 4], qfaB[pp][ii], qacc[ii][2]); else qacc[ii][2] = coopMatMulAdd(qfa[pp][ii], qfb[pp][2], qacc[ii][2]); if ( (3) < 4) qacc[ii][3] = coopMatMulAdd(qfbA[pp][ (3) % 4], qfaB[pp][ii], qacc[ii][3]); else qacc[ii][3] = coopMatMulAdd(qfa[pp][ii], qfb[pp][3], qacc[ii][3]); if ( (4) < 4) qacc[ii][4] = coopMatMulAdd(qfbA[pp][ (4) % 4], qfaB[pp][ii], qacc[ii][4]); else qacc[ii][4] = coopMatMulAdd(qfa[pp][ii], qfb[pp][4], qacc[ii][4]); if ( (5) < 4) qacc[ii][5] = coopMatMulAdd(qfbA[pp][ (5) % 4], qfaB[pp][ii], qacc[ii][5]); else qacc[ii][5] = coopMatMulAdd(qfa[pp][ii], qfb[pp][5], qacc[ii][5]); } if ( ( ( (3) >> (1)) & 1) != 0) { const int ii = 1; if ( (0) < 4) qacc[ii][0] = coopMatMulAdd(qfbA[pp][ (0) % 4], qfaB[pp][ii], qacc[ii][0]); else qacc[ii][0] = coopMatMulAdd(qfa[pp][ii], qfb[pp][0], qacc[ii][0]); if ( (1) < 4) qacc[ii][1] = coopMatMulAdd(qfbA[pp][ (1) % 4], qfaB[pp][ii], qacc[ii][1]); else qacc[ii][1] = coopMatMulAdd(qfa[pp][ii], qfb[pp][1], qacc[ii][1]); if ( (2) < 4) qacc[ii][2] = coopMatMulAdd(qfbA[pp][ (2) % 4], qfaB[pp][ii], qacc[ii][2]); else qacc[ii][2] = coopMatMulAdd(qfa[pp][ii], qfb[pp][2], qacc[ii][2]); if ( (3) < 4) qacc[ii][3] = coopMatMulAdd(qfbA[pp][ (3) % 4], qfaB[pp][ii], qacc[ii][3]); else qacc[ii][3] = coopMatMulAdd(qfa[pp][ii], qfb[pp][3], qacc[ii][3]); if ( (4) < 4) qacc[ii][4] = coopMatMulAdd(qfbA[pp][ (4) % 4], qfaB[pp][ii], qacc[ii][4]); else qacc[ii][4] = coopMatMulAdd(qfa[pp][ii], qfb[pp][4], qacc[ii][4]); if ( (5) < 4) qacc[ii][5] = coopMatMulAdd(qfbA[pp][ (5) % 4], qfaB[pp][ii], qacc[ii][5]); else qacc[ii][5] = coopMatMulAdd(qfa[pp][ii], qfb[pp][5], qacc[ii][5]); } } if (0 > 0 && ( (7) + 1) % 0 == 0) { { const int ii = 0; { for (int c = 0; c < qacc[ii][0].length(); ++ c) qacc[ii][0][c] = nr_round_f16_e4m3(qacc[ii][0][c]); } { for (int c = 0; c < qacc[ii][1].length(); ++ c) qacc[ii][1][c] = nr_round_f16_e4m3(qacc[ii][1][c]); } { for (int c = 0; c < qacc[ii][2].length(); ++ c) qacc[ii][2][c] = nr_round_f16_e4m3(qacc[ii][2][c]); } { for (int c = 0; c < qacc[ii][3].length(); ++ c) qacc[ii][3][c] = nr_round_f16_e4m3(qacc[ii][3][c]); } { for (int c = 0; c < qacc[ii][4].length(); ++ c) qacc[ii][4][c] = nr_round_f16_e4m3(qacc[ii][4][c]); } { for (int c = 0; c < qacc[ii][5].length(); ++ c) qacc[ii][5][c] = nr_round_f16_e4m3(qacc[ii][5][c]); } } { const int ii = 1; { for (int c = 0; c < qacc[ii][0].length(); ++ c) qacc[ii][0][c] = nr_round_f16_e4m3(qacc[ii][0][c]); } { for (int c = 0; c < qacc[ii][1].length(); ++ c) qacc[ii][1][c] = nr_round_f16_e4m3(qacc[ii][1][c]); } { for (int c = 0; c < qacc[ii][2].length(); ++ c) qacc[ii][2][c] = nr_round_f16_e4m3(qacc[ii][2][c]); } { for (int c = 0; c < qacc[ii][3].length(); ++ c) qacc[ii][3][c] = nr_round_f16_e4m3(qacc[ii][3][c]); } { for (int c = 0; c < qacc[ii][4].length(); ++ c) qacc[ii][4][c] = nr_round_f16_e4m3(qacc[ii][4][c]); } { for (int c = 0; c < qacc[ii][5].length(); ++ c) qacc[ii][5][c] = nr_round_f16_e4m3(qacc[ii][5][c]); } } } } }
#line 1 "D:/nr-work-20261011/_mochi/DLSSNR-AMD-main/windows/shaders/rdna4/include/attn_qkv_epi.glsl"










            for (int i = 0; i < 2; ++ i) {
                           coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > vfr0, vfr1, qf0, qf1, kf0, kf1;

                [[dont_flatten]] if ( ( ( ( (3) >> (i)) & 1) == 0) || nr_tile_oob(mtok0 / 16u + uint(i))) {



                    const f16vec2 zscale = f16vec2(float16_t(wgt_f32[pc.s_off + h]), float16_t(1.0));
                    precise f16vec2 zs = f16vec2(0.0hf) * zscale;
                    const fe4m3vec2 zq = nr_attn_quant(zs), zv = nr_attn_quant(f16vec2(0.0hf));
                    for (int cc = 0; cc < 8; ++ cc) {
                        qf0[cc] = zq.x; qf1[cc] = zq.x; kf0[cc] = zq.y; kf1[cc] = zq.y;
                        vfr0[cc] = zv.x; vfr1[cc] = zv.y;
                    }
                } else {
                    for (int cc = 0; cc < 8; ++ cc) {
                        const fe4m3vec2 v = nr_attn_quant(f16vec2(qacc[i][4][cc], qacc[i][5][cc]));
                        vfr0[cc] = v.x; vfr1[cc] = v.y;
                    }
                    f16vec2 qk0[8], qk1[8];
                    precise f16vec2 t[8];
                    for (int c = 0; c < 8; ++ c) {
                        qk0[c] = f16vec2(float16_t(qacc[i][0][c]), float16_t(qacc[i][2][c]));
                        qk1[c] = f16vec2(float16_t(qacc[i][1][c]), float16_t(qacc[i][3][c]));
                        precise f16vec2 sq0 = qk0[c] * qk0[c], sq1 = qk1[c] * qk1[c];
                        precise f16vec2 sum = sq0 + sq1;
                        t[c] = sum + unpackFloat2x16(subgroupShuffleXor(packFloat2x16(sum), 16u));
                    }
                    precise f16vec2 u0 = t[0] + t[4], u1 = t[1] + t[5], u2 = t[2] + t[6], u3 = t[3] + t[7];
                    precise f16vec2 v0 = u0 + u2, v1 = u1 + u3;
                    precise f16vec2 w = v0 + v1;
                    const f16vec2 norm = f16vec2(
                             float16_t(inversesqrt(float(max(w.x, float16_t(0.000062))))),
                             float16_t(inversesqrt(float(max(w.y, float16_t(0.000062))))));
                    const f16vec2 scale = f16vec2(float16_t(wgt_f32[pc.s_off + h]), float16_t(1.0));
                    for (int c = 0; c < 8; ++ c) {
                        precise f16vec2 n0 = qk0[c] * norm, n1 = qk1[c] * norm;
                        precise f16vec2 scaled0 = n0 * scale, scaled1 = n1 * scale;
                        const fe4m3vec2 q0 = nr_attn_quant(scaled0), q1 = nr_attn_quant(scaled1);
                        qf0[c] = q0.x; kf0[c] = q0.y; qf1[c] = q1.x; kf1[c] = q1.y;
                    }
                }

                const uint tb = mtok0 + uint(i) * 16u;
                                                                               coopMatStore(qf0, lds_q, (qb + tb * uint( (32 + 0))), (uint( (32 + 0))), gl_CooperativeMatrixLayoutColumnMajor);
                                                                                     coopMatStore(qf1, lds_q, (qb + tb * uint( (32 + 0)) + 16u), (uint( (32 + 0))), gl_CooperativeMatrixLayoutColumnMajor);
                                                                               coopMatStore(kf0, lds_k, (qb + tb * uint( (32 + 0))), (uint( (32 + 0))), gl_CooperativeMatrixLayoutColumnMajor);
                                                                                     coopMatStore(kf1, lds_k, (qb + tb * uint( (32 + 0)) + 16u), (uint( (32 + 0))), gl_CooperativeMatrixLayoutColumnMajor);
                                                                                 coopMatStore(vfr0, lds_v, (vb + ( (0u) * uint( (64 + 0)) + (tb))), (uint( (64 + 0))), gl_CooperativeMatrixLayoutColumnMajor);
                                                                                  coopMatStore(vfr1, lds_v, (vb + ( (16u) * uint( (64 + 0)) + (tb))), (uint( (64 + 0))), gl_CooperativeMatrixLayoutColumnMajor);
            }
#line 1030 "D:\nr-work-20261011\_mochi\DLSSNR-AMD-main\windows\shaders\rdna4\attn.comp"

            } else[[dont_flatten]] if (nr_ql2 == 1u) {

                           for (uint k0 = 0u; k0 < pc.C; k0 += uint( (8 * 16))) { const uint k04 = k0 * 4u; if ( (0) < (0 == 1 ? 3 : 3 - 1)) { const int cur = (0) % 3; const uint kkl = uint( ( (0) % 8) * 16); const uint kgl = k0 + kkl; if ( ( ( (1) >> (0)) & 1) != 0) { const uint nrq = (qal4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][0][v] = r0[v]; qfa[cur][0][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][0][v] = r0[v]; qfaB[cur][0][v + 4] = r1[v]; } } if ( ( ( (1) >> (1)) & 1) != 0) { const uint nrq = (qal4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][1][v] = r0[v]; qfa[cur][1][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][1][v] = r0[v]; qfaB[cur][1][v + 4] = r1[v]; } } { const uint nrq = (qbl4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][0][v] = r0[v]; qfb[cur][0][v + 4] = r1[v]; } if ( (0) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (0) % 4][v] = r0[v]; qfbA[cur][ (0) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][1][v] = r0[v]; qfb[cur][1][v + 4] = r1[v]; } if ( (1) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (1) % 4][v] = r0[v]; qfbA[cur][ (1) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[2] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][2][v] = r0[v]; qfb[cur][2][v + 4] = r1[v]; } if ( (2) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (2) % 4][v] = r0[v]; qfbA[cur][ (2) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[3] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][3][v] = r0[v]; qfb[cur][3][v + 4] = r1[v]; } if ( (3) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (3) % 4][v] = r0[v]; qfbA[cur][ (3) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[4] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][4][v] = r0[v]; qfb[cur][4][v + 4] = r1[v]; } if ( (4) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (4) % 4][v] = r0[v]; qfbA[cur][ (4) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[5] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][5][v] = r0[v]; qfb[cur][5][v + 4] = r1[v]; } if ( (5) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (5) % 4][v] = r0[v]; qfbA[cur][ (5) % 4][v + 4] = r1[v]; } } } if ( (1) < (0 == 1 ? 3 : 3 - 1)) { const int cur = (1) % 3; const uint kkl = uint( ( (1) % 8) * 16); const uint kgl = k0 + kkl; if ( ( ( (1) >> (0)) & 1) != 0) { const uint nrq = (qal4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][0][v] = r0[v]; qfa[cur][0][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][0][v] = r0[v]; qfaB[cur][0][v + 4] = r1[v]; } } if ( ( ( (1) >> (1)) & 1) != 0) { const uint nrq = (qal4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][1][v] = r0[v]; qfa[cur][1][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][1][v] = r0[v]; qfaB[cur][1][v + 4] = r1[v]; } } { const uint nrq = (qbl4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][0][v] = r0[v]; qfb[cur][0][v + 4] = r1[v]; } if ( (0) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (0) % 4][v] = r0[v]; qfbA[cur][ (0) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][1][v] = r0[v]; qfb[cur][1][v + 4] = r1[v]; } if ( (1) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (1) % 4][v] = r0[v]; qfbA[cur][ (1) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[2] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][2][v] = r0[v]; qfb[cur][2][v + 4] = r1[v]; } if ( (2) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (2) % 4][v] = r0[v]; qfbA[cur][ (2) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[3] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][3][v] = r0[v]; qfb[cur][3][v + 4] = r1[v]; } if ( (3) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (3) % 4][v] = r0[v]; qfbA[cur][ (3) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[4] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][4][v] = r0[v]; qfb[cur][4][v + 4] = r1[v]; } if ( (4) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (4) % 4][v] = r0[v]; qfbA[cur][ (4) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[5] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][5][v] = r0[v]; qfb[cur][5][v + 4] = r1[v]; } if ( (5) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (5) % 4][v] = r0[v]; qfbA[cur][ (5) % 4][v + 4] = r1[v]; } } } if ( (2) < (0 == 1 ? 3 : 3 - 1)) { const int cur = (2) % 3; const uint kkl = uint( ( (2) % 8) * 16); const uint kgl = k0 + kkl; if ( ( ( (1) >> (0)) & 1) != 0) { const uint nrq = (qal4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][0][v] = r0[v]; qfa[cur][0][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][0][v] = r0[v]; qfaB[cur][0][v + 4] = r1[v]; } } if ( ( ( (1) >> (1)) & 1) != 0) { const uint nrq = (qal4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][1][v] = r0[v]; qfa[cur][1][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][1][v] = r0[v]; qfaB[cur][1][v + 4] = r1[v]; } } { const uint nrq = (qbl4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][0][v] = r0[v]; qfb[cur][0][v + 4] = r1[v]; } if ( (0) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (0) % 4][v] = r0[v]; qfbA[cur][ (0) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][1][v] = r0[v]; qfb[cur][1][v + 4] = r1[v]; } if ( (1) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (1) % 4][v] = r0[v]; qfbA[cur][ (1) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[2] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][2][v] = r0[v]; qfb[cur][2][v + 4] = r1[v]; } if ( (2) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (2) % 4][v] = r0[v]; qfbA[cur][ (2) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[3] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][3][v] = r0[v]; qfb[cur][3][v + 4] = r1[v]; } if ( (3) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (3) % 4][v] = r0[v]; qfbA[cur][ (3) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[4] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][4][v] = r0[v]; qfb[cur][4][v + 4] = r1[v]; } if ( (4) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (4) % 4][v] = r0[v]; qfbA[cur][ (4) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[5] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][5][v] = r0[v]; qfb[cur][5][v + 4] = r1[v]; } if ( (5) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (5) % 4][v] = r0[v]; qfbA[cur][ (5) % 4][v + 4] = r1[v]; } } } if ( (3) < (0 == 1 ? 3 : 3 - 1)) { const int cur = (3) % 3; const uint kkl = uint( ( (3) % 8) * 16); const uint kgl = k0 + kkl; if ( ( ( (1) >> (0)) & 1) != 0) { const uint nrq = (qal4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][0][v] = r0[v]; qfa[cur][0][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][0][v] = r0[v]; qfaB[cur][0][v + 4] = r1[v]; } } if ( ( ( (1) >> (1)) & 1) != 0) { const uint nrq = (qal4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][1][v] = r0[v]; qfa[cur][1][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][1][v] = r0[v]; qfaB[cur][1][v + 4] = r1[v]; } } { const uint nrq = (qbl4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][0][v] = r0[v]; qfb[cur][0][v + 4] = r1[v]; } if ( (0) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (0) % 4][v] = r0[v]; qfbA[cur][ (0) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][1][v] = r0[v]; qfb[cur][1][v + 4] = r1[v]; } if ( (1) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (1) % 4][v] = r0[v]; qfbA[cur][ (1) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[2] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][2][v] = r0[v]; qfb[cur][2][v + 4] = r1[v]; } if ( (2) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (2) % 4][v] = r0[v]; qfbA[cur][ (2) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[3] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][3][v] = r0[v]; qfb[cur][3][v + 4] = r1[v]; } if ( (3) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (3) % 4][v] = r0[v]; qfbA[cur][ (3) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[4] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][4][v] = r0[v]; qfb[cur][4][v + 4] = r1[v]; } if ( (4) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (4) % 4][v] = r0[v]; qfbA[cur][ (4) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[5] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][5][v] = r0[v]; qfb[cur][5][v + 4] = r1[v]; } if ( (5) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (5) % 4][v] = r0[v]; qfbA[cur][ (5) % 4][v + 4] = r1[v]; } } } if ( (4) < (0 == 1 ? 3 : 3 - 1)) { const int cur = (4) % 3; const uint kkl = uint( ( (4) % 8) * 16); const uint kgl = k0 + kkl; if ( ( ( (1) >> (0)) & 1) != 0) { const uint nrq = (qal4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][0][v] = r0[v]; qfa[cur][0][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][0][v] = r0[v]; qfaB[cur][0][v + 4] = r1[v]; } } if ( ( ( (1) >> (1)) & 1) != 0) { const uint nrq = (qal4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][1][v] = r0[v]; qfa[cur][1][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][1][v] = r0[v]; qfaB[cur][1][v + 4] = r1[v]; } } { const uint nrq = (qbl4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][0][v] = r0[v]; qfb[cur][0][v + 4] = r1[v]; } if ( (0) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (0) % 4][v] = r0[v]; qfbA[cur][ (0) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][1][v] = r0[v]; qfb[cur][1][v + 4] = r1[v]; } if ( (1) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (1) % 4][v] = r0[v]; qfbA[cur][ (1) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[2] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][2][v] = r0[v]; qfb[cur][2][v + 4] = r1[v]; } if ( (2) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (2) % 4][v] = r0[v]; qfbA[cur][ (2) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[3] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][3][v] = r0[v]; qfb[cur][3][v + 4] = r1[v]; } if ( (3) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (3) % 4][v] = r0[v]; qfbA[cur][ (3) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[4] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][4][v] = r0[v]; qfb[cur][4][v + 4] = r1[v]; } if ( (4) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (4) % 4][v] = r0[v]; qfbA[cur][ (4) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[5] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][5][v] = r0[v]; qfb[cur][5][v + 4] = r1[v]; } if ( (5) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (5) % 4][v] = r0[v]; qfbA[cur][ (5) % 4][v + 4] = r1[v]; } } } if ( (5) < (0 == 1 ? 3 : 3 - 1)) { const int cur = (5) % 3; const uint kkl = uint( ( (5) % 8) * 16); const uint kgl = k0 + kkl; if ( ( ( (1) >> (0)) & 1) != 0) { const uint nrq = (qal4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][0][v] = r0[v]; qfa[cur][0][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][0][v] = r0[v]; qfaB[cur][0][v + 4] = r1[v]; } } if ( ( ( (1) >> (1)) & 1) != 0) { const uint nrq = (qal4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][1][v] = r0[v]; qfa[cur][1][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][1][v] = r0[v]; qfaB[cur][1][v + 4] = r1[v]; } } { const uint nrq = (qbl4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][0][v] = r0[v]; qfb[cur][0][v + 4] = r1[v]; } if ( (0) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (0) % 4][v] = r0[v]; qfbA[cur][ (0) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][1][v] = r0[v]; qfb[cur][1][v + 4] = r1[v]; } if ( (1) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (1) % 4][v] = r0[v]; qfbA[cur][ (1) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[2] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][2][v] = r0[v]; qfb[cur][2][v + 4] = r1[v]; } if ( (2) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (2) % 4][v] = r0[v]; qfbA[cur][ (2) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[3] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][3][v] = r0[v]; qfb[cur][3][v + 4] = r1[v]; } if ( (3) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (3) % 4][v] = r0[v]; qfbA[cur][ (3) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[4] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][4][v] = r0[v]; qfb[cur][4][v + 4] = r1[v]; } if ( (4) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (4) % 4][v] = r0[v]; qfbA[cur][ (4) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[5] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][5][v] = r0[v]; qfb[cur][5][v + 4] = r1[v]; } if ( (5) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (5) % 4][v] = r0[v]; qfbA[cur][ (5) % 4][v + 4] = r1[v]; } } } if ( (6) < (0 == 1 ? 3 : 3 - 1)) { const int cur = (6) % 3; const uint kkl = uint( ( (6) % 8) * 16); const uint kgl = k0 + kkl; if ( ( ( (1) >> (0)) & 1) != 0) { const uint nrq = (qal4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][0][v] = r0[v]; qfa[cur][0][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][0][v] = r0[v]; qfaB[cur][0][v + 4] = r1[v]; } } if ( ( ( (1) >> (1)) & 1) != 0) { const uint nrq = (qal4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][1][v] = r0[v]; qfa[cur][1][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][1][v] = r0[v]; qfaB[cur][1][v + 4] = r1[v]; } } { const uint nrq = (qbl4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][0][v] = r0[v]; qfb[cur][0][v + 4] = r1[v]; } if ( (0) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (0) % 4][v] = r0[v]; qfbA[cur][ (0) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][1][v] = r0[v]; qfb[cur][1][v + 4] = r1[v]; } if ( (1) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (1) % 4][v] = r0[v]; qfbA[cur][ (1) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[2] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][2][v] = r0[v]; qfb[cur][2][v + 4] = r1[v]; } if ( (2) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (2) % 4][v] = r0[v]; qfbA[cur][ (2) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[3] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][3][v] = r0[v]; qfb[cur][3][v + 4] = r1[v]; } if ( (3) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (3) % 4][v] = r0[v]; qfbA[cur][ (3) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[4] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][4][v] = r0[v]; qfb[cur][4][v + 4] = r1[v]; } if ( (4) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (4) % 4][v] = r0[v]; qfbA[cur][ (4) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[5] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][5][v] = r0[v]; qfb[cur][5][v + 4] = r1[v]; } if ( (5) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (5) % 4][v] = r0[v]; qfbA[cur][ (5) % 4][v + 4] = r1[v]; } } } if ( (7) < (0 == 1 ? 3 : 3 - 1)) { const int cur = (7) % 3; const uint kkl = uint( ( (7) % 8) * 16); const uint kgl = k0 + kkl; if ( ( ( (1) >> (0)) & 1) != 0) { const uint nrq = (qal4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][0][v] = r0[v]; qfa[cur][0][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][0][v] = r0[v]; qfaB[cur][0][v + 4] = r1[v]; } } if ( ( ( (1) >> (1)) & 1) != 0) { const uint nrq = (qal4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][1][v] = r0[v]; qfa[cur][1][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][1][v] = r0[v]; qfaB[cur][1][v + 4] = r1[v]; } } { const uint nrq = (qbl4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][0][v] = r0[v]; qfb[cur][0][v + 4] = r1[v]; } if ( (0) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (0) % 4][v] = r0[v]; qfbA[cur][ (0) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][1][v] = r0[v]; qfb[cur][1][v + 4] = r1[v]; } if ( (1) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (1) % 4][v] = r0[v]; qfbA[cur][ (1) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[2] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][2][v] = r0[v]; qfb[cur][2][v + 4] = r1[v]; } if ( (2) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (2) % 4][v] = r0[v]; qfbA[cur][ (2) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[3] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][3][v] = r0[v]; qfb[cur][3][v + 4] = r1[v]; } if ( (3) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (3) % 4][v] = r0[v]; qfbA[cur][ (3) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[4] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][4][v] = r0[v]; qfb[cur][4][v + 4] = r1[v]; } if ( (4) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (4) % 4][v] = r0[v]; qfbA[cur][ (4) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[5] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][5][v] = r0[v]; qfb[cur][5][v + 4] = r1[v]; } if ( (5) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (5) % 4][v] = r0[v]; qfbA[cur][ (5) % 4][v + 4] = r1[v]; } } } { const int pp = (0) % 3; const int cur = ( (0) + 3 - 1) % 3; const uint kkl = uint( ( ( (0) + 3 - 1) % 8) * 16); const uint kgl = k0 + kkl; if (0 == 0 && (0) + 3 - 1 < 8) { if ( ( ( (1) >> (0)) & 1) != 0) { const uint nrq = (qal4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][0][v] = r0[v]; qfa[cur][0][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][0][v] = r0[v]; qfaB[cur][0][v + 4] = r1[v]; } } if ( ( ( (1) >> (1)) & 1) != 0) { const uint nrq = (qal4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][1][v] = r0[v]; qfa[cur][1][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][1][v] = r0[v]; qfaB[cur][1][v + 4] = r1[v]; } } { const uint nrq = (qbl4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][0][v] = r0[v]; qfb[cur][0][v + 4] = r1[v]; } if ( (0) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (0) % 4][v] = r0[v]; qfbA[cur][ (0) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][1][v] = r0[v]; qfb[cur][1][v + 4] = r1[v]; } if ( (1) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (1) % 4][v] = r0[v]; qfbA[cur][ (1) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[2] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][2][v] = r0[v]; qfb[cur][2][v + 4] = r1[v]; } if ( (2) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (2) % 4][v] = r0[v]; qfbA[cur][ (2) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[3] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][3][v] = r0[v]; qfb[cur][3][v + 4] = r1[v]; } if ( (3) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (3) % 4][v] = r0[v]; qfbA[cur][ (3) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[4] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][4][v] = r0[v]; qfb[cur][4][v + 4] = r1[v]; } if ( (4) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (4) % 4][v] = r0[v]; qfbA[cur][ (4) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[5] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][5][v] = r0[v]; qfb[cur][5][v + 4] = r1[v]; } if ( (5) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (5) % 4][v] = r0[v]; qfbA[cur][ (5) % 4][v + 4] = r1[v]; } } } if (0 == 0) { if ( ( ( (1) >> (0)) & 1) != 0) { const int ii = 0; if ( (0) < 4) qacc[ii][0] = coopMatMulAdd(qfbA[pp][ (0) % 4], qfaB[pp][ii], qacc[ii][0]); else qacc[ii][0] = coopMatMulAdd(qfa[pp][ii], qfb[pp][0], qacc[ii][0]); if ( (1) < 4) qacc[ii][1] = coopMatMulAdd(qfbA[pp][ (1) % 4], qfaB[pp][ii], qacc[ii][1]); else qacc[ii][1] = coopMatMulAdd(qfa[pp][ii], qfb[pp][1], qacc[ii][1]); if ( (2) < 4) qacc[ii][2] = coopMatMulAdd(qfbA[pp][ (2) % 4], qfaB[pp][ii], qacc[ii][2]); else qacc[ii][2] = coopMatMulAdd(qfa[pp][ii], qfb[pp][2], qacc[ii][2]); if ( (3) < 4) qacc[ii][3] = coopMatMulAdd(qfbA[pp][ (3) % 4], qfaB[pp][ii], qacc[ii][3]); else qacc[ii][3] = coopMatMulAdd(qfa[pp][ii], qfb[pp][3], qacc[ii][3]); if ( (4) < 4) qacc[ii][4] = coopMatMulAdd(qfbA[pp][ (4) % 4], qfaB[pp][ii], qacc[ii][4]); else qacc[ii][4] = coopMatMulAdd(qfa[pp][ii], qfb[pp][4], qacc[ii][4]); if ( (5) < 4) qacc[ii][5] = coopMatMulAdd(qfbA[pp][ (5) % 4], qfaB[pp][ii], qacc[ii][5]); else qacc[ii][5] = coopMatMulAdd(qfa[pp][ii], qfb[pp][5], qacc[ii][5]); } if ( ( ( (1) >> (1)) & 1) != 0) { const int ii = 1; if ( (0) < 4) qacc[ii][0] = coopMatMulAdd(qfbA[pp][ (0) % 4], qfaB[pp][ii], qacc[ii][0]); else qacc[ii][0] = coopMatMulAdd(qfa[pp][ii], qfb[pp][0], qacc[ii][0]); if ( (1) < 4) qacc[ii][1] = coopMatMulAdd(qfbA[pp][ (1) % 4], qfaB[pp][ii], qacc[ii][1]); else qacc[ii][1] = coopMatMulAdd(qfa[pp][ii], qfb[pp][1], qacc[ii][1]); if ( (2) < 4) qacc[ii][2] = coopMatMulAdd(qfbA[pp][ (2) % 4], qfaB[pp][ii], qacc[ii][2]); else qacc[ii][2] = coopMatMulAdd(qfa[pp][ii], qfb[pp][2], qacc[ii][2]); if ( (3) < 4) qacc[ii][3] = coopMatMulAdd(qfbA[pp][ (3) % 4], qfaB[pp][ii], qacc[ii][3]); else qacc[ii][3] = coopMatMulAdd(qfa[pp][ii], qfb[pp][3], qacc[ii][3]); if ( (4) < 4) qacc[ii][4] = coopMatMulAdd(qfbA[pp][ (4) % 4], qfaB[pp][ii], qacc[ii][4]); else qacc[ii][4] = coopMatMulAdd(qfa[pp][ii], qfb[pp][4], qacc[ii][4]); if ( (5) < 4) qacc[ii][5] = coopMatMulAdd(qfbA[pp][ (5) % 4], qfaB[pp][ii], qacc[ii][5]); else qacc[ii][5] = coopMatMulAdd(qfa[pp][ii], qfb[pp][5], qacc[ii][5]); } } if (0 > 0 && ( (0) + 1) % 0 == 0) { { const int ii = 0; { for (int c = 0; c < qacc[ii][0].length(); ++ c) qacc[ii][0][c] = nr_round_f16_e4m3(qacc[ii][0][c]); } { for (int c = 0; c < qacc[ii][1].length(); ++ c) qacc[ii][1][c] = nr_round_f16_e4m3(qacc[ii][1][c]); } { for (int c = 0; c < qacc[ii][2].length(); ++ c) qacc[ii][2][c] = nr_round_f16_e4m3(qacc[ii][2][c]); } { for (int c = 0; c < qacc[ii][3].length(); ++ c) qacc[ii][3][c] = nr_round_f16_e4m3(qacc[ii][3][c]); } { for (int c = 0; c < qacc[ii][4].length(); ++ c) qacc[ii][4][c] = nr_round_f16_e4m3(qacc[ii][4][c]); } { for (int c = 0; c < qacc[ii][5].length(); ++ c) qacc[ii][5][c] = nr_round_f16_e4m3(qacc[ii][5][c]); } } { const int ii = 1; { for (int c = 0; c < qacc[ii][0].length(); ++ c) qacc[ii][0][c] = nr_round_f16_e4m3(qacc[ii][0][c]); } { for (int c = 0; c < qacc[ii][1].length(); ++ c) qacc[ii][1][c] = nr_round_f16_e4m3(qacc[ii][1][c]); } { for (int c = 0; c < qacc[ii][2].length(); ++ c) qacc[ii][2][c] = nr_round_f16_e4m3(qacc[ii][2][c]); } { for (int c = 0; c < qacc[ii][3].length(); ++ c) qacc[ii][3][c] = nr_round_f16_e4m3(qacc[ii][3][c]); } { for (int c = 0; c < qacc[ii][4].length(); ++ c) qacc[ii][4][c] = nr_round_f16_e4m3(qacc[ii][4][c]); } { for (int c = 0; c < qacc[ii][5].length(); ++ c) qacc[ii][5][c] = nr_round_f16_e4m3(qacc[ii][5][c]); } } } } { const int pp = (1) % 3; const int cur = ( (1) + 3 - 1) % 3; const uint kkl = uint( ( ( (1) + 3 - 1) % 8) * 16); const uint kgl = k0 + kkl; if (0 == 0 && (1) + 3 - 1 < 8) { if ( ( ( (1) >> (0)) & 1) != 0) { const uint nrq = (qal4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][0][v] = r0[v]; qfa[cur][0][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][0][v] = r0[v]; qfaB[cur][0][v + 4] = r1[v]; } } if ( ( ( (1) >> (1)) & 1) != 0) { const uint nrq = (qal4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][1][v] = r0[v]; qfa[cur][1][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][1][v] = r0[v]; qfaB[cur][1][v + 4] = r1[v]; } } { const uint nrq = (qbl4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][0][v] = r0[v]; qfb[cur][0][v + 4] = r1[v]; } if ( (0) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (0) % 4][v] = r0[v]; qfbA[cur][ (0) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][1][v] = r0[v]; qfb[cur][1][v + 4] = r1[v]; } if ( (1) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (1) % 4][v] = r0[v]; qfbA[cur][ (1) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[2] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][2][v] = r0[v]; qfb[cur][2][v + 4] = r1[v]; } if ( (2) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (2) % 4][v] = r0[v]; qfbA[cur][ (2) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[3] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][3][v] = r0[v]; qfb[cur][3][v + 4] = r1[v]; } if ( (3) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (3) % 4][v] = r0[v]; qfbA[cur][ (3) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[4] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][4][v] = r0[v]; qfb[cur][4][v + 4] = r1[v]; } if ( (4) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (4) % 4][v] = r0[v]; qfbA[cur][ (4) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[5] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][5][v] = r0[v]; qfb[cur][5][v + 4] = r1[v]; } if ( (5) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (5) % 4][v] = r0[v]; qfbA[cur][ (5) % 4][v + 4] = r1[v]; } } } if (0 == 0) { if ( ( ( (1) >> (0)) & 1) != 0) { const int ii = 0; if ( (0) < 4) qacc[ii][0] = coopMatMulAdd(qfbA[pp][ (0) % 4], qfaB[pp][ii], qacc[ii][0]); else qacc[ii][0] = coopMatMulAdd(qfa[pp][ii], qfb[pp][0], qacc[ii][0]); if ( (1) < 4) qacc[ii][1] = coopMatMulAdd(qfbA[pp][ (1) % 4], qfaB[pp][ii], qacc[ii][1]); else qacc[ii][1] = coopMatMulAdd(qfa[pp][ii], qfb[pp][1], qacc[ii][1]); if ( (2) < 4) qacc[ii][2] = coopMatMulAdd(qfbA[pp][ (2) % 4], qfaB[pp][ii], qacc[ii][2]); else qacc[ii][2] = coopMatMulAdd(qfa[pp][ii], qfb[pp][2], qacc[ii][2]); if ( (3) < 4) qacc[ii][3] = coopMatMulAdd(qfbA[pp][ (3) % 4], qfaB[pp][ii], qacc[ii][3]); else qacc[ii][3] = coopMatMulAdd(qfa[pp][ii], qfb[pp][3], qacc[ii][3]); if ( (4) < 4) qacc[ii][4] = coopMatMulAdd(qfbA[pp][ (4) % 4], qfaB[pp][ii], qacc[ii][4]); else qacc[ii][4] = coopMatMulAdd(qfa[pp][ii], qfb[pp][4], qacc[ii][4]); if ( (5) < 4) qacc[ii][5] = coopMatMulAdd(qfbA[pp][ (5) % 4], qfaB[pp][ii], qacc[ii][5]); else qacc[ii][5] = coopMatMulAdd(qfa[pp][ii], qfb[pp][5], qacc[ii][5]); } if ( ( ( (1) >> (1)) & 1) != 0) { const int ii = 1; if ( (0) < 4) qacc[ii][0] = coopMatMulAdd(qfbA[pp][ (0) % 4], qfaB[pp][ii], qacc[ii][0]); else qacc[ii][0] = coopMatMulAdd(qfa[pp][ii], qfb[pp][0], qacc[ii][0]); if ( (1) < 4) qacc[ii][1] = coopMatMulAdd(qfbA[pp][ (1) % 4], qfaB[pp][ii], qacc[ii][1]); else qacc[ii][1] = coopMatMulAdd(qfa[pp][ii], qfb[pp][1], qacc[ii][1]); if ( (2) < 4) qacc[ii][2] = coopMatMulAdd(qfbA[pp][ (2) % 4], qfaB[pp][ii], qacc[ii][2]); else qacc[ii][2] = coopMatMulAdd(qfa[pp][ii], qfb[pp][2], qacc[ii][2]); if ( (3) < 4) qacc[ii][3] = coopMatMulAdd(qfbA[pp][ (3) % 4], qfaB[pp][ii], qacc[ii][3]); else qacc[ii][3] = coopMatMulAdd(qfa[pp][ii], qfb[pp][3], qacc[ii][3]); if ( (4) < 4) qacc[ii][4] = coopMatMulAdd(qfbA[pp][ (4) % 4], qfaB[pp][ii], qacc[ii][4]); else qacc[ii][4] = coopMatMulAdd(qfa[pp][ii], qfb[pp][4], qacc[ii][4]); if ( (5) < 4) qacc[ii][5] = coopMatMulAdd(qfbA[pp][ (5) % 4], qfaB[pp][ii], qacc[ii][5]); else qacc[ii][5] = coopMatMulAdd(qfa[pp][ii], qfb[pp][5], qacc[ii][5]); } } if (0 > 0 && ( (1) + 1) % 0 == 0) { { const int ii = 0; { for (int c = 0; c < qacc[ii][0].length(); ++ c) qacc[ii][0][c] = nr_round_f16_e4m3(qacc[ii][0][c]); } { for (int c = 0; c < qacc[ii][1].length(); ++ c) qacc[ii][1][c] = nr_round_f16_e4m3(qacc[ii][1][c]); } { for (int c = 0; c < qacc[ii][2].length(); ++ c) qacc[ii][2][c] = nr_round_f16_e4m3(qacc[ii][2][c]); } { for (int c = 0; c < qacc[ii][3].length(); ++ c) qacc[ii][3][c] = nr_round_f16_e4m3(qacc[ii][3][c]); } { for (int c = 0; c < qacc[ii][4].length(); ++ c) qacc[ii][4][c] = nr_round_f16_e4m3(qacc[ii][4][c]); } { for (int c = 0; c < qacc[ii][5].length(); ++ c) qacc[ii][5][c] = nr_round_f16_e4m3(qacc[ii][5][c]); } } { const int ii = 1; { for (int c = 0; c < qacc[ii][0].length(); ++ c) qacc[ii][0][c] = nr_round_f16_e4m3(qacc[ii][0][c]); } { for (int c = 0; c < qacc[ii][1].length(); ++ c) qacc[ii][1][c] = nr_round_f16_e4m3(qacc[ii][1][c]); } { for (int c = 0; c < qacc[ii][2].length(); ++ c) qacc[ii][2][c] = nr_round_f16_e4m3(qacc[ii][2][c]); } { for (int c = 0; c < qacc[ii][3].length(); ++ c) qacc[ii][3][c] = nr_round_f16_e4m3(qacc[ii][3][c]); } { for (int c = 0; c < qacc[ii][4].length(); ++ c) qacc[ii][4][c] = nr_round_f16_e4m3(qacc[ii][4][c]); } { for (int c = 0; c < qacc[ii][5].length(); ++ c) qacc[ii][5][c] = nr_round_f16_e4m3(qacc[ii][5][c]); } } } } { const int pp = (2) % 3; const int cur = ( (2) + 3 - 1) % 3; const uint kkl = uint( ( ( (2) + 3 - 1) % 8) * 16); const uint kgl = k0 + kkl; if (0 == 0 && (2) + 3 - 1 < 8) { if ( ( ( (1) >> (0)) & 1) != 0) { const uint nrq = (qal4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][0][v] = r0[v]; qfa[cur][0][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][0][v] = r0[v]; qfaB[cur][0][v + 4] = r1[v]; } } if ( ( ( (1) >> (1)) & 1) != 0) { const uint nrq = (qal4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][1][v] = r0[v]; qfa[cur][1][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][1][v] = r0[v]; qfaB[cur][1][v + 4] = r1[v]; } } { const uint nrq = (qbl4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][0][v] = r0[v]; qfb[cur][0][v + 4] = r1[v]; } if ( (0) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (0) % 4][v] = r0[v]; qfbA[cur][ (0) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][1][v] = r0[v]; qfb[cur][1][v + 4] = r1[v]; } if ( (1) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (1) % 4][v] = r0[v]; qfbA[cur][ (1) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[2] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][2][v] = r0[v]; qfb[cur][2][v + 4] = r1[v]; } if ( (2) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (2) % 4][v] = r0[v]; qfbA[cur][ (2) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[3] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][3][v] = r0[v]; qfb[cur][3][v + 4] = r1[v]; } if ( (3) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (3) % 4][v] = r0[v]; qfbA[cur][ (3) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[4] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][4][v] = r0[v]; qfb[cur][4][v + 4] = r1[v]; } if ( (4) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (4) % 4][v] = r0[v]; qfbA[cur][ (4) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[5] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][5][v] = r0[v]; qfb[cur][5][v + 4] = r1[v]; } if ( (5) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (5) % 4][v] = r0[v]; qfbA[cur][ (5) % 4][v + 4] = r1[v]; } } } if (0 == 0) { if ( ( ( (1) >> (0)) & 1) != 0) { const int ii = 0; if ( (0) < 4) qacc[ii][0] = coopMatMulAdd(qfbA[pp][ (0) % 4], qfaB[pp][ii], qacc[ii][0]); else qacc[ii][0] = coopMatMulAdd(qfa[pp][ii], qfb[pp][0], qacc[ii][0]); if ( (1) < 4) qacc[ii][1] = coopMatMulAdd(qfbA[pp][ (1) % 4], qfaB[pp][ii], qacc[ii][1]); else qacc[ii][1] = coopMatMulAdd(qfa[pp][ii], qfb[pp][1], qacc[ii][1]); if ( (2) < 4) qacc[ii][2] = coopMatMulAdd(qfbA[pp][ (2) % 4], qfaB[pp][ii], qacc[ii][2]); else qacc[ii][2] = coopMatMulAdd(qfa[pp][ii], qfb[pp][2], qacc[ii][2]); if ( (3) < 4) qacc[ii][3] = coopMatMulAdd(qfbA[pp][ (3) % 4], qfaB[pp][ii], qacc[ii][3]); else qacc[ii][3] = coopMatMulAdd(qfa[pp][ii], qfb[pp][3], qacc[ii][3]); if ( (4) < 4) qacc[ii][4] = coopMatMulAdd(qfbA[pp][ (4) % 4], qfaB[pp][ii], qacc[ii][4]); else qacc[ii][4] = coopMatMulAdd(qfa[pp][ii], qfb[pp][4], qacc[ii][4]); if ( (5) < 4) qacc[ii][5] = coopMatMulAdd(qfbA[pp][ (5) % 4], qfaB[pp][ii], qacc[ii][5]); else qacc[ii][5] = coopMatMulAdd(qfa[pp][ii], qfb[pp][5], qacc[ii][5]); } if ( ( ( (1) >> (1)) & 1) != 0) { const int ii = 1; if ( (0) < 4) qacc[ii][0] = coopMatMulAdd(qfbA[pp][ (0) % 4], qfaB[pp][ii], qacc[ii][0]); else qacc[ii][0] = coopMatMulAdd(qfa[pp][ii], qfb[pp][0], qacc[ii][0]); if ( (1) < 4) qacc[ii][1] = coopMatMulAdd(qfbA[pp][ (1) % 4], qfaB[pp][ii], qacc[ii][1]); else qacc[ii][1] = coopMatMulAdd(qfa[pp][ii], qfb[pp][1], qacc[ii][1]); if ( (2) < 4) qacc[ii][2] = coopMatMulAdd(qfbA[pp][ (2) % 4], qfaB[pp][ii], qacc[ii][2]); else qacc[ii][2] = coopMatMulAdd(qfa[pp][ii], qfb[pp][2], qacc[ii][2]); if ( (3) < 4) qacc[ii][3] = coopMatMulAdd(qfbA[pp][ (3) % 4], qfaB[pp][ii], qacc[ii][3]); else qacc[ii][3] = coopMatMulAdd(qfa[pp][ii], qfb[pp][3], qacc[ii][3]); if ( (4) < 4) qacc[ii][4] = coopMatMulAdd(qfbA[pp][ (4) % 4], qfaB[pp][ii], qacc[ii][4]); else qacc[ii][4] = coopMatMulAdd(qfa[pp][ii], qfb[pp][4], qacc[ii][4]); if ( (5) < 4) qacc[ii][5] = coopMatMulAdd(qfbA[pp][ (5) % 4], qfaB[pp][ii], qacc[ii][5]); else qacc[ii][5] = coopMatMulAdd(qfa[pp][ii], qfb[pp][5], qacc[ii][5]); } } if (0 > 0 && ( (2) + 1) % 0 == 0) { { const int ii = 0; { for (int c = 0; c < qacc[ii][0].length(); ++ c) qacc[ii][0][c] = nr_round_f16_e4m3(qacc[ii][0][c]); } { for (int c = 0; c < qacc[ii][1].length(); ++ c) qacc[ii][1][c] = nr_round_f16_e4m3(qacc[ii][1][c]); } { for (int c = 0; c < qacc[ii][2].length(); ++ c) qacc[ii][2][c] = nr_round_f16_e4m3(qacc[ii][2][c]); } { for (int c = 0; c < qacc[ii][3].length(); ++ c) qacc[ii][3][c] = nr_round_f16_e4m3(qacc[ii][3][c]); } { for (int c = 0; c < qacc[ii][4].length(); ++ c) qacc[ii][4][c] = nr_round_f16_e4m3(qacc[ii][4][c]); } { for (int c = 0; c < qacc[ii][5].length(); ++ c) qacc[ii][5][c] = nr_round_f16_e4m3(qacc[ii][5][c]); } } { const int ii = 1; { for (int c = 0; c < qacc[ii][0].length(); ++ c) qacc[ii][0][c] = nr_round_f16_e4m3(qacc[ii][0][c]); } { for (int c = 0; c < qacc[ii][1].length(); ++ c) qacc[ii][1][c] = nr_round_f16_e4m3(qacc[ii][1][c]); } { for (int c = 0; c < qacc[ii][2].length(); ++ c) qacc[ii][2][c] = nr_round_f16_e4m3(qacc[ii][2][c]); } { for (int c = 0; c < qacc[ii][3].length(); ++ c) qacc[ii][3][c] = nr_round_f16_e4m3(qacc[ii][3][c]); } { for (int c = 0; c < qacc[ii][4].length(); ++ c) qacc[ii][4][c] = nr_round_f16_e4m3(qacc[ii][4][c]); } { for (int c = 0; c < qacc[ii][5].length(); ++ c) qacc[ii][5][c] = nr_round_f16_e4m3(qacc[ii][5][c]); } } } } { const int pp = (3) % 3; const int cur = ( (3) + 3 - 1) % 3; const uint kkl = uint( ( ( (3) + 3 - 1) % 8) * 16); const uint kgl = k0 + kkl; if (0 == 0 && (3) + 3 - 1 < 8) { if ( ( ( (1) >> (0)) & 1) != 0) { const uint nrq = (qal4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][0][v] = r0[v]; qfa[cur][0][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][0][v] = r0[v]; qfaB[cur][0][v + 4] = r1[v]; } } if ( ( ( (1) >> (1)) & 1) != 0) { const uint nrq = (qal4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][1][v] = r0[v]; qfa[cur][1][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][1][v] = r0[v]; qfaB[cur][1][v + 4] = r1[v]; } } { const uint nrq = (qbl4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][0][v] = r0[v]; qfb[cur][0][v + 4] = r1[v]; } if ( (0) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (0) % 4][v] = r0[v]; qfbA[cur][ (0) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][1][v] = r0[v]; qfb[cur][1][v + 4] = r1[v]; } if ( (1) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (1) % 4][v] = r0[v]; qfbA[cur][ (1) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[2] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][2][v] = r0[v]; qfb[cur][2][v + 4] = r1[v]; } if ( (2) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (2) % 4][v] = r0[v]; qfbA[cur][ (2) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[3] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][3][v] = r0[v]; qfb[cur][3][v + 4] = r1[v]; } if ( (3) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (3) % 4][v] = r0[v]; qfbA[cur][ (3) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[4] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][4][v] = r0[v]; qfb[cur][4][v + 4] = r1[v]; } if ( (4) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (4) % 4][v] = r0[v]; qfbA[cur][ (4) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[5] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][5][v] = r0[v]; qfb[cur][5][v + 4] = r1[v]; } if ( (5) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (5) % 4][v] = r0[v]; qfbA[cur][ (5) % 4][v + 4] = r1[v]; } } } if (0 == 0) { if ( ( ( (1) >> (0)) & 1) != 0) { const int ii = 0; if ( (0) < 4) qacc[ii][0] = coopMatMulAdd(qfbA[pp][ (0) % 4], qfaB[pp][ii], qacc[ii][0]); else qacc[ii][0] = coopMatMulAdd(qfa[pp][ii], qfb[pp][0], qacc[ii][0]); if ( (1) < 4) qacc[ii][1] = coopMatMulAdd(qfbA[pp][ (1) % 4], qfaB[pp][ii], qacc[ii][1]); else qacc[ii][1] = coopMatMulAdd(qfa[pp][ii], qfb[pp][1], qacc[ii][1]); if ( (2) < 4) qacc[ii][2] = coopMatMulAdd(qfbA[pp][ (2) % 4], qfaB[pp][ii], qacc[ii][2]); else qacc[ii][2] = coopMatMulAdd(qfa[pp][ii], qfb[pp][2], qacc[ii][2]); if ( (3) < 4) qacc[ii][3] = coopMatMulAdd(qfbA[pp][ (3) % 4], qfaB[pp][ii], qacc[ii][3]); else qacc[ii][3] = coopMatMulAdd(qfa[pp][ii], qfb[pp][3], qacc[ii][3]); if ( (4) < 4) qacc[ii][4] = coopMatMulAdd(qfbA[pp][ (4) % 4], qfaB[pp][ii], qacc[ii][4]); else qacc[ii][4] = coopMatMulAdd(qfa[pp][ii], qfb[pp][4], qacc[ii][4]); if ( (5) < 4) qacc[ii][5] = coopMatMulAdd(qfbA[pp][ (5) % 4], qfaB[pp][ii], qacc[ii][5]); else qacc[ii][5] = coopMatMulAdd(qfa[pp][ii], qfb[pp][5], qacc[ii][5]); } if ( ( ( (1) >> (1)) & 1) != 0) { const int ii = 1; if ( (0) < 4) qacc[ii][0] = coopMatMulAdd(qfbA[pp][ (0) % 4], qfaB[pp][ii], qacc[ii][0]); else qacc[ii][0] = coopMatMulAdd(qfa[pp][ii], qfb[pp][0], qacc[ii][0]); if ( (1) < 4) qacc[ii][1] = coopMatMulAdd(qfbA[pp][ (1) % 4], qfaB[pp][ii], qacc[ii][1]); else qacc[ii][1] = coopMatMulAdd(qfa[pp][ii], qfb[pp][1], qacc[ii][1]); if ( (2) < 4) qacc[ii][2] = coopMatMulAdd(qfbA[pp][ (2) % 4], qfaB[pp][ii], qacc[ii][2]); else qacc[ii][2] = coopMatMulAdd(qfa[pp][ii], qfb[pp][2], qacc[ii][2]); if ( (3) < 4) qacc[ii][3] = coopMatMulAdd(qfbA[pp][ (3) % 4], qfaB[pp][ii], qacc[ii][3]); else qacc[ii][3] = coopMatMulAdd(qfa[pp][ii], qfb[pp][3], qacc[ii][3]); if ( (4) < 4) qacc[ii][4] = coopMatMulAdd(qfbA[pp][ (4) % 4], qfaB[pp][ii], qacc[ii][4]); else qacc[ii][4] = coopMatMulAdd(qfa[pp][ii], qfb[pp][4], qacc[ii][4]); if ( (5) < 4) qacc[ii][5] = coopMatMulAdd(qfbA[pp][ (5) % 4], qfaB[pp][ii], qacc[ii][5]); else qacc[ii][5] = coopMatMulAdd(qfa[pp][ii], qfb[pp][5], qacc[ii][5]); } } if (0 > 0 && ( (3) + 1) % 0 == 0) { { const int ii = 0; { for (int c = 0; c < qacc[ii][0].length(); ++ c) qacc[ii][0][c] = nr_round_f16_e4m3(qacc[ii][0][c]); } { for (int c = 0; c < qacc[ii][1].length(); ++ c) qacc[ii][1][c] = nr_round_f16_e4m3(qacc[ii][1][c]); } { for (int c = 0; c < qacc[ii][2].length(); ++ c) qacc[ii][2][c] = nr_round_f16_e4m3(qacc[ii][2][c]); } { for (int c = 0; c < qacc[ii][3].length(); ++ c) qacc[ii][3][c] = nr_round_f16_e4m3(qacc[ii][3][c]); } { for (int c = 0; c < qacc[ii][4].length(); ++ c) qacc[ii][4][c] = nr_round_f16_e4m3(qacc[ii][4][c]); } { for (int c = 0; c < qacc[ii][5].length(); ++ c) qacc[ii][5][c] = nr_round_f16_e4m3(qacc[ii][5][c]); } } { const int ii = 1; { for (int c = 0; c < qacc[ii][0].length(); ++ c) qacc[ii][0][c] = nr_round_f16_e4m3(qacc[ii][0][c]); } { for (int c = 0; c < qacc[ii][1].length(); ++ c) qacc[ii][1][c] = nr_round_f16_e4m3(qacc[ii][1][c]); } { for (int c = 0; c < qacc[ii][2].length(); ++ c) qacc[ii][2][c] = nr_round_f16_e4m3(qacc[ii][2][c]); } { for (int c = 0; c < qacc[ii][3].length(); ++ c) qacc[ii][3][c] = nr_round_f16_e4m3(qacc[ii][3][c]); } { for (int c = 0; c < qacc[ii][4].length(); ++ c) qacc[ii][4][c] = nr_round_f16_e4m3(qacc[ii][4][c]); } { for (int c = 0; c < qacc[ii][5].length(); ++ c) qacc[ii][5][c] = nr_round_f16_e4m3(qacc[ii][5][c]); } } } } { const int pp = (4) % 3; const int cur = ( (4) + 3 - 1) % 3; const uint kkl = uint( ( ( (4) + 3 - 1) % 8) * 16); const uint kgl = k0 + kkl; if (0 == 0 && (4) + 3 - 1 < 8) { if ( ( ( (1) >> (0)) & 1) != 0) { const uint nrq = (qal4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][0][v] = r0[v]; qfa[cur][0][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][0][v] = r0[v]; qfaB[cur][0][v + 4] = r1[v]; } } if ( ( ( (1) >> (1)) & 1) != 0) { const uint nrq = (qal4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][1][v] = r0[v]; qfa[cur][1][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][1][v] = r0[v]; qfaB[cur][1][v + 4] = r1[v]; } } { const uint nrq = (qbl4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][0][v] = r0[v]; qfb[cur][0][v + 4] = r1[v]; } if ( (0) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (0) % 4][v] = r0[v]; qfbA[cur][ (0) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][1][v] = r0[v]; qfb[cur][1][v + 4] = r1[v]; } if ( (1) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (1) % 4][v] = r0[v]; qfbA[cur][ (1) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[2] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][2][v] = r0[v]; qfb[cur][2][v + 4] = r1[v]; } if ( (2) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (2) % 4][v] = r0[v]; qfbA[cur][ (2) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[3] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][3][v] = r0[v]; qfb[cur][3][v + 4] = r1[v]; } if ( (3) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (3) % 4][v] = r0[v]; qfbA[cur][ (3) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[4] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][4][v] = r0[v]; qfb[cur][4][v + 4] = r1[v]; } if ( (4) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (4) % 4][v] = r0[v]; qfbA[cur][ (4) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[5] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][5][v] = r0[v]; qfb[cur][5][v + 4] = r1[v]; } if ( (5) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (5) % 4][v] = r0[v]; qfbA[cur][ (5) % 4][v + 4] = r1[v]; } } } if (0 == 0) { if ( ( ( (1) >> (0)) & 1) != 0) { const int ii = 0; if ( (0) < 4) qacc[ii][0] = coopMatMulAdd(qfbA[pp][ (0) % 4], qfaB[pp][ii], qacc[ii][0]); else qacc[ii][0] = coopMatMulAdd(qfa[pp][ii], qfb[pp][0], qacc[ii][0]); if ( (1) < 4) qacc[ii][1] = coopMatMulAdd(qfbA[pp][ (1) % 4], qfaB[pp][ii], qacc[ii][1]); else qacc[ii][1] = coopMatMulAdd(qfa[pp][ii], qfb[pp][1], qacc[ii][1]); if ( (2) < 4) qacc[ii][2] = coopMatMulAdd(qfbA[pp][ (2) % 4], qfaB[pp][ii], qacc[ii][2]); else qacc[ii][2] = coopMatMulAdd(qfa[pp][ii], qfb[pp][2], qacc[ii][2]); if ( (3) < 4) qacc[ii][3] = coopMatMulAdd(qfbA[pp][ (3) % 4], qfaB[pp][ii], qacc[ii][3]); else qacc[ii][3] = coopMatMulAdd(qfa[pp][ii], qfb[pp][3], qacc[ii][3]); if ( (4) < 4) qacc[ii][4] = coopMatMulAdd(qfbA[pp][ (4) % 4], qfaB[pp][ii], qacc[ii][4]); else qacc[ii][4] = coopMatMulAdd(qfa[pp][ii], qfb[pp][4], qacc[ii][4]); if ( (5) < 4) qacc[ii][5] = coopMatMulAdd(qfbA[pp][ (5) % 4], qfaB[pp][ii], qacc[ii][5]); else qacc[ii][5] = coopMatMulAdd(qfa[pp][ii], qfb[pp][5], qacc[ii][5]); } if ( ( ( (1) >> (1)) & 1) != 0) { const int ii = 1; if ( (0) < 4) qacc[ii][0] = coopMatMulAdd(qfbA[pp][ (0) % 4], qfaB[pp][ii], qacc[ii][0]); else qacc[ii][0] = coopMatMulAdd(qfa[pp][ii], qfb[pp][0], qacc[ii][0]); if ( (1) < 4) qacc[ii][1] = coopMatMulAdd(qfbA[pp][ (1) % 4], qfaB[pp][ii], qacc[ii][1]); else qacc[ii][1] = coopMatMulAdd(qfa[pp][ii], qfb[pp][1], qacc[ii][1]); if ( (2) < 4) qacc[ii][2] = coopMatMulAdd(qfbA[pp][ (2) % 4], qfaB[pp][ii], qacc[ii][2]); else qacc[ii][2] = coopMatMulAdd(qfa[pp][ii], qfb[pp][2], qacc[ii][2]); if ( (3) < 4) qacc[ii][3] = coopMatMulAdd(qfbA[pp][ (3) % 4], qfaB[pp][ii], qacc[ii][3]); else qacc[ii][3] = coopMatMulAdd(qfa[pp][ii], qfb[pp][3], qacc[ii][3]); if ( (4) < 4) qacc[ii][4] = coopMatMulAdd(qfbA[pp][ (4) % 4], qfaB[pp][ii], qacc[ii][4]); else qacc[ii][4] = coopMatMulAdd(qfa[pp][ii], qfb[pp][4], qacc[ii][4]); if ( (5) < 4) qacc[ii][5] = coopMatMulAdd(qfbA[pp][ (5) % 4], qfaB[pp][ii], qacc[ii][5]); else qacc[ii][5] = coopMatMulAdd(qfa[pp][ii], qfb[pp][5], qacc[ii][5]); } } if (0 > 0 && ( (4) + 1) % 0 == 0) { { const int ii = 0; { for (int c = 0; c < qacc[ii][0].length(); ++ c) qacc[ii][0][c] = nr_round_f16_e4m3(qacc[ii][0][c]); } { for (int c = 0; c < qacc[ii][1].length(); ++ c) qacc[ii][1][c] = nr_round_f16_e4m3(qacc[ii][1][c]); } { for (int c = 0; c < qacc[ii][2].length(); ++ c) qacc[ii][2][c] = nr_round_f16_e4m3(qacc[ii][2][c]); } { for (int c = 0; c < qacc[ii][3].length(); ++ c) qacc[ii][3][c] = nr_round_f16_e4m3(qacc[ii][3][c]); } { for (int c = 0; c < qacc[ii][4].length(); ++ c) qacc[ii][4][c] = nr_round_f16_e4m3(qacc[ii][4][c]); } { for (int c = 0; c < qacc[ii][5].length(); ++ c) qacc[ii][5][c] = nr_round_f16_e4m3(qacc[ii][5][c]); } } { const int ii = 1; { for (int c = 0; c < qacc[ii][0].length(); ++ c) qacc[ii][0][c] = nr_round_f16_e4m3(qacc[ii][0][c]); } { for (int c = 0; c < qacc[ii][1].length(); ++ c) qacc[ii][1][c] = nr_round_f16_e4m3(qacc[ii][1][c]); } { for (int c = 0; c < qacc[ii][2].length(); ++ c) qacc[ii][2][c] = nr_round_f16_e4m3(qacc[ii][2][c]); } { for (int c = 0; c < qacc[ii][3].length(); ++ c) qacc[ii][3][c] = nr_round_f16_e4m3(qacc[ii][3][c]); } { for (int c = 0; c < qacc[ii][4].length(); ++ c) qacc[ii][4][c] = nr_round_f16_e4m3(qacc[ii][4][c]); } { for (int c = 0; c < qacc[ii][5].length(); ++ c) qacc[ii][5][c] = nr_round_f16_e4m3(qacc[ii][5][c]); } } } } { const int pp = (5) % 3; const int cur = ( (5) + 3 - 1) % 3; const uint kkl = uint( ( ( (5) + 3 - 1) % 8) * 16); const uint kgl = k0 + kkl; if (0 == 0 && (5) + 3 - 1 < 8) { if ( ( ( (1) >> (0)) & 1) != 0) { const uint nrq = (qal4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][0][v] = r0[v]; qfa[cur][0][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][0][v] = r0[v]; qfaB[cur][0][v + 4] = r1[v]; } } if ( ( ( (1) >> (1)) & 1) != 0) { const uint nrq = (qal4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][1][v] = r0[v]; qfa[cur][1][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][1][v] = r0[v]; qfaB[cur][1][v + 4] = r1[v]; } } { const uint nrq = (qbl4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][0][v] = r0[v]; qfb[cur][0][v + 4] = r1[v]; } if ( (0) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (0) % 4][v] = r0[v]; qfbA[cur][ (0) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][1][v] = r0[v]; qfb[cur][1][v + 4] = r1[v]; } if ( (1) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (1) % 4][v] = r0[v]; qfbA[cur][ (1) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[2] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][2][v] = r0[v]; qfb[cur][2][v + 4] = r1[v]; } if ( (2) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (2) % 4][v] = r0[v]; qfbA[cur][ (2) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[3] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][3][v] = r0[v]; qfb[cur][3][v + 4] = r1[v]; } if ( (3) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (3) % 4][v] = r0[v]; qfbA[cur][ (3) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[4] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][4][v] = r0[v]; qfb[cur][4][v + 4] = r1[v]; } if ( (4) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (4) % 4][v] = r0[v]; qfbA[cur][ (4) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[5] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][5][v] = r0[v]; qfb[cur][5][v + 4] = r1[v]; } if ( (5) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (5) % 4][v] = r0[v]; qfbA[cur][ (5) % 4][v + 4] = r1[v]; } } } if (0 == 0) { if ( ( ( (1) >> (0)) & 1) != 0) { const int ii = 0; if ( (0) < 4) qacc[ii][0] = coopMatMulAdd(qfbA[pp][ (0) % 4], qfaB[pp][ii], qacc[ii][0]); else qacc[ii][0] = coopMatMulAdd(qfa[pp][ii], qfb[pp][0], qacc[ii][0]); if ( (1) < 4) qacc[ii][1] = coopMatMulAdd(qfbA[pp][ (1) % 4], qfaB[pp][ii], qacc[ii][1]); else qacc[ii][1] = coopMatMulAdd(qfa[pp][ii], qfb[pp][1], qacc[ii][1]); if ( (2) < 4) qacc[ii][2] = coopMatMulAdd(qfbA[pp][ (2) % 4], qfaB[pp][ii], qacc[ii][2]); else qacc[ii][2] = coopMatMulAdd(qfa[pp][ii], qfb[pp][2], qacc[ii][2]); if ( (3) < 4) qacc[ii][3] = coopMatMulAdd(qfbA[pp][ (3) % 4], qfaB[pp][ii], qacc[ii][3]); else qacc[ii][3] = coopMatMulAdd(qfa[pp][ii], qfb[pp][3], qacc[ii][3]); if ( (4) < 4) qacc[ii][4] = coopMatMulAdd(qfbA[pp][ (4) % 4], qfaB[pp][ii], qacc[ii][4]); else qacc[ii][4] = coopMatMulAdd(qfa[pp][ii], qfb[pp][4], qacc[ii][4]); if ( (5) < 4) qacc[ii][5] = coopMatMulAdd(qfbA[pp][ (5) % 4], qfaB[pp][ii], qacc[ii][5]); else qacc[ii][5] = coopMatMulAdd(qfa[pp][ii], qfb[pp][5], qacc[ii][5]); } if ( ( ( (1) >> (1)) & 1) != 0) { const int ii = 1; if ( (0) < 4) qacc[ii][0] = coopMatMulAdd(qfbA[pp][ (0) % 4], qfaB[pp][ii], qacc[ii][0]); else qacc[ii][0] = coopMatMulAdd(qfa[pp][ii], qfb[pp][0], qacc[ii][0]); if ( (1) < 4) qacc[ii][1] = coopMatMulAdd(qfbA[pp][ (1) % 4], qfaB[pp][ii], qacc[ii][1]); else qacc[ii][1] = coopMatMulAdd(qfa[pp][ii], qfb[pp][1], qacc[ii][1]); if ( (2) < 4) qacc[ii][2] = coopMatMulAdd(qfbA[pp][ (2) % 4], qfaB[pp][ii], qacc[ii][2]); else qacc[ii][2] = coopMatMulAdd(qfa[pp][ii], qfb[pp][2], qacc[ii][2]); if ( (3) < 4) qacc[ii][3] = coopMatMulAdd(qfbA[pp][ (3) % 4], qfaB[pp][ii], qacc[ii][3]); else qacc[ii][3] = coopMatMulAdd(qfa[pp][ii], qfb[pp][3], qacc[ii][3]); if ( (4) < 4) qacc[ii][4] = coopMatMulAdd(qfbA[pp][ (4) % 4], qfaB[pp][ii], qacc[ii][4]); else qacc[ii][4] = coopMatMulAdd(qfa[pp][ii], qfb[pp][4], qacc[ii][4]); if ( (5) < 4) qacc[ii][5] = coopMatMulAdd(qfbA[pp][ (5) % 4], qfaB[pp][ii], qacc[ii][5]); else qacc[ii][5] = coopMatMulAdd(qfa[pp][ii], qfb[pp][5], qacc[ii][5]); } } if (0 > 0 && ( (5) + 1) % 0 == 0) { { const int ii = 0; { for (int c = 0; c < qacc[ii][0].length(); ++ c) qacc[ii][0][c] = nr_round_f16_e4m3(qacc[ii][0][c]); } { for (int c = 0; c < qacc[ii][1].length(); ++ c) qacc[ii][1][c] = nr_round_f16_e4m3(qacc[ii][1][c]); } { for (int c = 0; c < qacc[ii][2].length(); ++ c) qacc[ii][2][c] = nr_round_f16_e4m3(qacc[ii][2][c]); } { for (int c = 0; c < qacc[ii][3].length(); ++ c) qacc[ii][3][c] = nr_round_f16_e4m3(qacc[ii][3][c]); } { for (int c = 0; c < qacc[ii][4].length(); ++ c) qacc[ii][4][c] = nr_round_f16_e4m3(qacc[ii][4][c]); } { for (int c = 0; c < qacc[ii][5].length(); ++ c) qacc[ii][5][c] = nr_round_f16_e4m3(qacc[ii][5][c]); } } { const int ii = 1; { for (int c = 0; c < qacc[ii][0].length(); ++ c) qacc[ii][0][c] = nr_round_f16_e4m3(qacc[ii][0][c]); } { for (int c = 0; c < qacc[ii][1].length(); ++ c) qacc[ii][1][c] = nr_round_f16_e4m3(qacc[ii][1][c]); } { for (int c = 0; c < qacc[ii][2].length(); ++ c) qacc[ii][2][c] = nr_round_f16_e4m3(qacc[ii][2][c]); } { for (int c = 0; c < qacc[ii][3].length(); ++ c) qacc[ii][3][c] = nr_round_f16_e4m3(qacc[ii][3][c]); } { for (int c = 0; c < qacc[ii][4].length(); ++ c) qacc[ii][4][c] = nr_round_f16_e4m3(qacc[ii][4][c]); } { for (int c = 0; c < qacc[ii][5].length(); ++ c) qacc[ii][5][c] = nr_round_f16_e4m3(qacc[ii][5][c]); } } } } { const int pp = (6) % 3; const int cur = ( (6) + 3 - 1) % 3; const uint kkl = uint( ( ( (6) + 3 - 1) % 8) * 16); const uint kgl = k0 + kkl; if (0 == 0 && (6) + 3 - 1 < 8) { if ( ( ( (1) >> (0)) & 1) != 0) { const uint nrq = (qal4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][0][v] = r0[v]; qfa[cur][0][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][0][v] = r0[v]; qfaB[cur][0][v + 4] = r1[v]; } } if ( ( ( (1) >> (1)) & 1) != 0) { const uint nrq = (qal4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][1][v] = r0[v]; qfa[cur][1][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][1][v] = r0[v]; qfaB[cur][1][v + 4] = r1[v]; } } { const uint nrq = (qbl4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][0][v] = r0[v]; qfb[cur][0][v + 4] = r1[v]; } if ( (0) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (0) % 4][v] = r0[v]; qfbA[cur][ (0) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][1][v] = r0[v]; qfb[cur][1][v + 4] = r1[v]; } if ( (1) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (1) % 4][v] = r0[v]; qfbA[cur][ (1) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[2] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][2][v] = r0[v]; qfb[cur][2][v + 4] = r1[v]; } if ( (2) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (2) % 4][v] = r0[v]; qfbA[cur][ (2) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[3] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][3][v] = r0[v]; qfb[cur][3][v + 4] = r1[v]; } if ( (3) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (3) % 4][v] = r0[v]; qfbA[cur][ (3) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[4] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][4][v] = r0[v]; qfb[cur][4][v + 4] = r1[v]; } if ( (4) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (4) % 4][v] = r0[v]; qfbA[cur][ (4) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[5] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][5][v] = r0[v]; qfb[cur][5][v + 4] = r1[v]; } if ( (5) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (5) % 4][v] = r0[v]; qfbA[cur][ (5) % 4][v + 4] = r1[v]; } } } if (0 == 0) { if ( ( ( (1) >> (0)) & 1) != 0) { const int ii = 0; if ( (0) < 4) qacc[ii][0] = coopMatMulAdd(qfbA[pp][ (0) % 4], qfaB[pp][ii], qacc[ii][0]); else qacc[ii][0] = coopMatMulAdd(qfa[pp][ii], qfb[pp][0], qacc[ii][0]); if ( (1) < 4) qacc[ii][1] = coopMatMulAdd(qfbA[pp][ (1) % 4], qfaB[pp][ii], qacc[ii][1]); else qacc[ii][1] = coopMatMulAdd(qfa[pp][ii], qfb[pp][1], qacc[ii][1]); if ( (2) < 4) qacc[ii][2] = coopMatMulAdd(qfbA[pp][ (2) % 4], qfaB[pp][ii], qacc[ii][2]); else qacc[ii][2] = coopMatMulAdd(qfa[pp][ii], qfb[pp][2], qacc[ii][2]); if ( (3) < 4) qacc[ii][3] = coopMatMulAdd(qfbA[pp][ (3) % 4], qfaB[pp][ii], qacc[ii][3]); else qacc[ii][3] = coopMatMulAdd(qfa[pp][ii], qfb[pp][3], qacc[ii][3]); if ( (4) < 4) qacc[ii][4] = coopMatMulAdd(qfbA[pp][ (4) % 4], qfaB[pp][ii], qacc[ii][4]); else qacc[ii][4] = coopMatMulAdd(qfa[pp][ii], qfb[pp][4], qacc[ii][4]); if ( (5) < 4) qacc[ii][5] = coopMatMulAdd(qfbA[pp][ (5) % 4], qfaB[pp][ii], qacc[ii][5]); else qacc[ii][5] = coopMatMulAdd(qfa[pp][ii], qfb[pp][5], qacc[ii][5]); } if ( ( ( (1) >> (1)) & 1) != 0) { const int ii = 1; if ( (0) < 4) qacc[ii][0] = coopMatMulAdd(qfbA[pp][ (0) % 4], qfaB[pp][ii], qacc[ii][0]); else qacc[ii][0] = coopMatMulAdd(qfa[pp][ii], qfb[pp][0], qacc[ii][0]); if ( (1) < 4) qacc[ii][1] = coopMatMulAdd(qfbA[pp][ (1) % 4], qfaB[pp][ii], qacc[ii][1]); else qacc[ii][1] = coopMatMulAdd(qfa[pp][ii], qfb[pp][1], qacc[ii][1]); if ( (2) < 4) qacc[ii][2] = coopMatMulAdd(qfbA[pp][ (2) % 4], qfaB[pp][ii], qacc[ii][2]); else qacc[ii][2] = coopMatMulAdd(qfa[pp][ii], qfb[pp][2], qacc[ii][2]); if ( (3) < 4) qacc[ii][3] = coopMatMulAdd(qfbA[pp][ (3) % 4], qfaB[pp][ii], qacc[ii][3]); else qacc[ii][3] = coopMatMulAdd(qfa[pp][ii], qfb[pp][3], qacc[ii][3]); if ( (4) < 4) qacc[ii][4] = coopMatMulAdd(qfbA[pp][ (4) % 4], qfaB[pp][ii], qacc[ii][4]); else qacc[ii][4] = coopMatMulAdd(qfa[pp][ii], qfb[pp][4], qacc[ii][4]); if ( (5) < 4) qacc[ii][5] = coopMatMulAdd(qfbA[pp][ (5) % 4], qfaB[pp][ii], qacc[ii][5]); else qacc[ii][5] = coopMatMulAdd(qfa[pp][ii], qfb[pp][5], qacc[ii][5]); } } if (0 > 0 && ( (6) + 1) % 0 == 0) { { const int ii = 0; { for (int c = 0; c < qacc[ii][0].length(); ++ c) qacc[ii][0][c] = nr_round_f16_e4m3(qacc[ii][0][c]); } { for (int c = 0; c < qacc[ii][1].length(); ++ c) qacc[ii][1][c] = nr_round_f16_e4m3(qacc[ii][1][c]); } { for (int c = 0; c < qacc[ii][2].length(); ++ c) qacc[ii][2][c] = nr_round_f16_e4m3(qacc[ii][2][c]); } { for (int c = 0; c < qacc[ii][3].length(); ++ c) qacc[ii][3][c] = nr_round_f16_e4m3(qacc[ii][3][c]); } { for (int c = 0; c < qacc[ii][4].length(); ++ c) qacc[ii][4][c] = nr_round_f16_e4m3(qacc[ii][4][c]); } { for (int c = 0; c < qacc[ii][5].length(); ++ c) qacc[ii][5][c] = nr_round_f16_e4m3(qacc[ii][5][c]); } } { const int ii = 1; { for (int c = 0; c < qacc[ii][0].length(); ++ c) qacc[ii][0][c] = nr_round_f16_e4m3(qacc[ii][0][c]); } { for (int c = 0; c < qacc[ii][1].length(); ++ c) qacc[ii][1][c] = nr_round_f16_e4m3(qacc[ii][1][c]); } { for (int c = 0; c < qacc[ii][2].length(); ++ c) qacc[ii][2][c] = nr_round_f16_e4m3(qacc[ii][2][c]); } { for (int c = 0; c < qacc[ii][3].length(); ++ c) qacc[ii][3][c] = nr_round_f16_e4m3(qacc[ii][3][c]); } { for (int c = 0; c < qacc[ii][4].length(); ++ c) qacc[ii][4][c] = nr_round_f16_e4m3(qacc[ii][4][c]); } { for (int c = 0; c < qacc[ii][5].length(); ++ c) qacc[ii][5][c] = nr_round_f16_e4m3(qacc[ii][5][c]); } } } } { const int pp = (7) % 3; const int cur = ( (7) + 3 - 1) % 3; const uint kkl = uint( ( ( (7) + 3 - 1) % 8) * 16); const uint kgl = k0 + kkl; if (0 == 0 && (7) + 3 - 1 < 8) { if ( ( ( (1) >> (0)) & 1) != 0) { const uint nrq = (qal4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][0][v] = r0[v]; qfa[cur][0][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][0][v] = r0[v]; qfaB[cur][0][v + 4] = r1[v]; } } if ( ( ( (1) >> (1)) & 1) != 0) { const uint nrq = (qal4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][1][v] = r0[v]; qfa[cur][1][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][1][v] = r0[v]; qfaB[cur][1][v + 4] = r1[v]; } } { const uint nrq = (qbl4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][0][v] = r0[v]; qfb[cur][0][v + 4] = r1[v]; } if ( (0) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (0) % 4][v] = r0[v]; qfbA[cur][ (0) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][1][v] = r0[v]; qfb[cur][1][v + 4] = r1[v]; } if ( (1) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (1) % 4][v] = r0[v]; qfbA[cur][ (1) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[2] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][2][v] = r0[v]; qfb[cur][2][v + 4] = r1[v]; } if ( (2) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (2) % 4][v] = r0[v]; qfbA[cur][ (2) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[3] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][3][v] = r0[v]; qfb[cur][3][v + 4] = r1[v]; } if ( (3) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (3) % 4][v] = r0[v]; qfbA[cur][ (3) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[4] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][4][v] = r0[v]; qfb[cur][4][v + 4] = r1[v]; } if ( (4) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (4) % 4][v] = r0[v]; qfbA[cur][ (4) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[5] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][5][v] = r0[v]; qfb[cur][5][v + 4] = r1[v]; } if ( (5) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (5) % 4][v] = r0[v]; qfbA[cur][ (5) % 4][v + 4] = r1[v]; } } } if (0 == 0) { if ( ( ( (1) >> (0)) & 1) != 0) { const int ii = 0; if ( (0) < 4) qacc[ii][0] = coopMatMulAdd(qfbA[pp][ (0) % 4], qfaB[pp][ii], qacc[ii][0]); else qacc[ii][0] = coopMatMulAdd(qfa[pp][ii], qfb[pp][0], qacc[ii][0]); if ( (1) < 4) qacc[ii][1] = coopMatMulAdd(qfbA[pp][ (1) % 4], qfaB[pp][ii], qacc[ii][1]); else qacc[ii][1] = coopMatMulAdd(qfa[pp][ii], qfb[pp][1], qacc[ii][1]); if ( (2) < 4) qacc[ii][2] = coopMatMulAdd(qfbA[pp][ (2) % 4], qfaB[pp][ii], qacc[ii][2]); else qacc[ii][2] = coopMatMulAdd(qfa[pp][ii], qfb[pp][2], qacc[ii][2]); if ( (3) < 4) qacc[ii][3] = coopMatMulAdd(qfbA[pp][ (3) % 4], qfaB[pp][ii], qacc[ii][3]); else qacc[ii][3] = coopMatMulAdd(qfa[pp][ii], qfb[pp][3], qacc[ii][3]); if ( (4) < 4) qacc[ii][4] = coopMatMulAdd(qfbA[pp][ (4) % 4], qfaB[pp][ii], qacc[ii][4]); else qacc[ii][4] = coopMatMulAdd(qfa[pp][ii], qfb[pp][4], qacc[ii][4]); if ( (5) < 4) qacc[ii][5] = coopMatMulAdd(qfbA[pp][ (5) % 4], qfaB[pp][ii], qacc[ii][5]); else qacc[ii][5] = coopMatMulAdd(qfa[pp][ii], qfb[pp][5], qacc[ii][5]); } if ( ( ( (1) >> (1)) & 1) != 0) { const int ii = 1; if ( (0) < 4) qacc[ii][0] = coopMatMulAdd(qfbA[pp][ (0) % 4], qfaB[pp][ii], qacc[ii][0]); else qacc[ii][0] = coopMatMulAdd(qfa[pp][ii], qfb[pp][0], qacc[ii][0]); if ( (1) < 4) qacc[ii][1] = coopMatMulAdd(qfbA[pp][ (1) % 4], qfaB[pp][ii], qacc[ii][1]); else qacc[ii][1] = coopMatMulAdd(qfa[pp][ii], qfb[pp][1], qacc[ii][1]); if ( (2) < 4) qacc[ii][2] = coopMatMulAdd(qfbA[pp][ (2) % 4], qfaB[pp][ii], qacc[ii][2]); else qacc[ii][2] = coopMatMulAdd(qfa[pp][ii], qfb[pp][2], qacc[ii][2]); if ( (3) < 4) qacc[ii][3] = coopMatMulAdd(qfbA[pp][ (3) % 4], qfaB[pp][ii], qacc[ii][3]); else qacc[ii][3] = coopMatMulAdd(qfa[pp][ii], qfb[pp][3], qacc[ii][3]); if ( (4) < 4) qacc[ii][4] = coopMatMulAdd(qfbA[pp][ (4) % 4], qfaB[pp][ii], qacc[ii][4]); else qacc[ii][4] = coopMatMulAdd(qfa[pp][ii], qfb[pp][4], qacc[ii][4]); if ( (5) < 4) qacc[ii][5] = coopMatMulAdd(qfbA[pp][ (5) % 4], qfaB[pp][ii], qacc[ii][5]); else qacc[ii][5] = coopMatMulAdd(qfa[pp][ii], qfb[pp][5], qacc[ii][5]); } } if (0 > 0 && ( (7) + 1) % 0 == 0) { { const int ii = 0; { for (int c = 0; c < qacc[ii][0].length(); ++ c) qacc[ii][0][c] = nr_round_f16_e4m3(qacc[ii][0][c]); } { for (int c = 0; c < qacc[ii][1].length(); ++ c) qacc[ii][1][c] = nr_round_f16_e4m3(qacc[ii][1][c]); } { for (int c = 0; c < qacc[ii][2].length(); ++ c) qacc[ii][2][c] = nr_round_f16_e4m3(qacc[ii][2][c]); } { for (int c = 0; c < qacc[ii][3].length(); ++ c) qacc[ii][3][c] = nr_round_f16_e4m3(qacc[ii][3][c]); } { for (int c = 0; c < qacc[ii][4].length(); ++ c) qacc[ii][4][c] = nr_round_f16_e4m3(qacc[ii][4][c]); } { for (int c = 0; c < qacc[ii][5].length(); ++ c) qacc[ii][5][c] = nr_round_f16_e4m3(qacc[ii][5][c]); } } { const int ii = 1; { for (int c = 0; c < qacc[ii][0].length(); ++ c) qacc[ii][0][c] = nr_round_f16_e4m3(qacc[ii][0][c]); } { for (int c = 0; c < qacc[ii][1].length(); ++ c) qacc[ii][1][c] = nr_round_f16_e4m3(qacc[ii][1][c]); } { for (int c = 0; c < qacc[ii][2].length(); ++ c) qacc[ii][2][c] = nr_round_f16_e4m3(qacc[ii][2][c]); } { for (int c = 0; c < qacc[ii][3].length(); ++ c) qacc[ii][3][c] = nr_round_f16_e4m3(qacc[ii][3][c]); } { for (int c = 0; c < qacc[ii][4].length(); ++ c) qacc[ii][4][c] = nr_round_f16_e4m3(qacc[ii][4][c]); } { for (int c = 0; c < qacc[ii][5].length(); ++ c) qacc[ii][5][c] = nr_round_f16_e4m3(qacc[ii][5][c]); } } } } }
#line 1 "D:/nr-work-20261011/_mochi/DLSSNR-AMD-main/windows/shaders/rdna4/include/attn_qkv_epi.glsl"










            for (int i = 0; i < 2; ++ i) {
                           coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > vfr0, vfr1, qf0, qf1, kf0, kf1;

                [[dont_flatten]] if ( ( ( ( (1) >> (i)) & 1) == 0) || nr_tile_oob(mtok0 / 16u + uint(i))) {



                    const f16vec2 zscale = f16vec2(float16_t(wgt_f32[pc.s_off + h]), float16_t(1.0));
                    precise f16vec2 zs = f16vec2(0.0hf) * zscale;
                    const fe4m3vec2 zq = nr_attn_quant(zs), zv = nr_attn_quant(f16vec2(0.0hf));
                    for (int cc = 0; cc < 8; ++ cc) {
                        qf0[cc] = zq.x; qf1[cc] = zq.x; kf0[cc] = zq.y; kf1[cc] = zq.y;
                        vfr0[cc] = zv.x; vfr1[cc] = zv.y;
                    }
                } else {
                    for (int cc = 0; cc < 8; ++ cc) {
                        const fe4m3vec2 v = nr_attn_quant(f16vec2(qacc[i][4][cc], qacc[i][5][cc]));
                        vfr0[cc] = v.x; vfr1[cc] = v.y;
                    }
                    f16vec2 qk0[8], qk1[8];
                    precise f16vec2 t[8];
                    for (int c = 0; c < 8; ++ c) {
                        qk0[c] = f16vec2(float16_t(qacc[i][0][c]), float16_t(qacc[i][2][c]));
                        qk1[c] = f16vec2(float16_t(qacc[i][1][c]), float16_t(qacc[i][3][c]));
                        precise f16vec2 sq0 = qk0[c] * qk0[c], sq1 = qk1[c] * qk1[c];
                        precise f16vec2 sum = sq0 + sq1;
                        t[c] = sum + unpackFloat2x16(subgroupShuffleXor(packFloat2x16(sum), 16u));
                    }
                    precise f16vec2 u0 = t[0] + t[4], u1 = t[1] + t[5], u2 = t[2] + t[6], u3 = t[3] + t[7];
                    precise f16vec2 v0 = u0 + u2, v1 = u1 + u3;
                    precise f16vec2 w = v0 + v1;
                    const f16vec2 norm = f16vec2(
                             float16_t(inversesqrt(float(max(w.x, float16_t(0.000062))))),
                             float16_t(inversesqrt(float(max(w.y, float16_t(0.000062))))));
                    const f16vec2 scale = f16vec2(float16_t(wgt_f32[pc.s_off + h]), float16_t(1.0));
                    for (int c = 0; c < 8; ++ c) {
                        precise f16vec2 n0 = qk0[c] * norm, n1 = qk1[c] * norm;
                        precise f16vec2 scaled0 = n0 * scale, scaled1 = n1 * scale;
                        const fe4m3vec2 q0 = nr_attn_quant(scaled0), q1 = nr_attn_quant(scaled1);
                        qf0[c] = q0.x; kf0[c] = q0.y; qf1[c] = q1.x; kf1[c] = q1.y;
                    }
                }

                const uint tb = mtok0 + uint(i) * 16u;
                                                                               coopMatStore(qf0, lds_q, (qb + tb * uint( (32 + 0))), (uint( (32 + 0))), gl_CooperativeMatrixLayoutColumnMajor);
                                                                                     coopMatStore(qf1, lds_q, (qb + tb * uint( (32 + 0)) + 16u), (uint( (32 + 0))), gl_CooperativeMatrixLayoutColumnMajor);
                                                                               coopMatStore(kf0, lds_k, (qb + tb * uint( (32 + 0))), (uint( (32 + 0))), gl_CooperativeMatrixLayoutColumnMajor);
                                                                                     coopMatStore(kf1, lds_k, (qb + tb * uint( (32 + 0)) + 16u), (uint( (32 + 0))), gl_CooperativeMatrixLayoutColumnMajor);
                                                                                 coopMatStore(vfr0, lds_v, (vb + ( (0u) * uint( (64 + 0)) + (tb))), (uint( (64 + 0))), gl_CooperativeMatrixLayoutColumnMajor);
                                                                                  coopMatStore(vfr1, lds_v, (vb + ( (16u) * uint( (64 + 0)) + (tb))), (uint( (64 + 0))), gl_CooperativeMatrixLayoutColumnMajor);
            }
#line 1035 "D:\nr-work-20261011\_mochi\DLSSNR-AMD-main\windows\shaders\rdna4\attn.comp"

            } else[[dont_flatten]] if (nr_ql2 == 2u) {

                           for (uint k0 = 0u; k0 < pc.C; k0 += uint( (8 * 16))) { const uint k04 = k0 * 4u; if ( (0) < (0 == 1 ? 3 : 3 - 1)) { const int cur = (0) % 3; const uint kkl = uint( ( (0) % 8) * 16); const uint kgl = k0 + kkl; if ( ( ( (2) >> (0)) & 1) != 0) { const uint nrq = (qal4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][0][v] = r0[v]; qfa[cur][0][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][0][v] = r0[v]; qfaB[cur][0][v + 4] = r1[v]; } } if ( ( ( (2) >> (1)) & 1) != 0) { const uint nrq = (qal4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][1][v] = r0[v]; qfa[cur][1][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][1][v] = r0[v]; qfaB[cur][1][v + 4] = r1[v]; } } { const uint nrq = (qbl4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][0][v] = r0[v]; qfb[cur][0][v + 4] = r1[v]; } if ( (0) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (0) % 4][v] = r0[v]; qfbA[cur][ (0) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][1][v] = r0[v]; qfb[cur][1][v + 4] = r1[v]; } if ( (1) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (1) % 4][v] = r0[v]; qfbA[cur][ (1) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[2] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][2][v] = r0[v]; qfb[cur][2][v + 4] = r1[v]; } if ( (2) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (2) % 4][v] = r0[v]; qfbA[cur][ (2) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[3] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][3][v] = r0[v]; qfb[cur][3][v + 4] = r1[v]; } if ( (3) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (3) % 4][v] = r0[v]; qfbA[cur][ (3) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[4] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][4][v] = r0[v]; qfb[cur][4][v + 4] = r1[v]; } if ( (4) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (4) % 4][v] = r0[v]; qfbA[cur][ (4) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[5] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][5][v] = r0[v]; qfb[cur][5][v + 4] = r1[v]; } if ( (5) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (5) % 4][v] = r0[v]; qfbA[cur][ (5) % 4][v + 4] = r1[v]; } } } if ( (1) < (0 == 1 ? 3 : 3 - 1)) { const int cur = (1) % 3; const uint kkl = uint( ( (1) % 8) * 16); const uint kgl = k0 + kkl; if ( ( ( (2) >> (0)) & 1) != 0) { const uint nrq = (qal4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][0][v] = r0[v]; qfa[cur][0][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][0][v] = r0[v]; qfaB[cur][0][v + 4] = r1[v]; } } if ( ( ( (2) >> (1)) & 1) != 0) { const uint nrq = (qal4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][1][v] = r0[v]; qfa[cur][1][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][1][v] = r0[v]; qfaB[cur][1][v + 4] = r1[v]; } } { const uint nrq = (qbl4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][0][v] = r0[v]; qfb[cur][0][v + 4] = r1[v]; } if ( (0) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (0) % 4][v] = r0[v]; qfbA[cur][ (0) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][1][v] = r0[v]; qfb[cur][1][v + 4] = r1[v]; } if ( (1) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (1) % 4][v] = r0[v]; qfbA[cur][ (1) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[2] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][2][v] = r0[v]; qfb[cur][2][v + 4] = r1[v]; } if ( (2) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (2) % 4][v] = r0[v]; qfbA[cur][ (2) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[3] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][3][v] = r0[v]; qfb[cur][3][v + 4] = r1[v]; } if ( (3) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (3) % 4][v] = r0[v]; qfbA[cur][ (3) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[4] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][4][v] = r0[v]; qfb[cur][4][v + 4] = r1[v]; } if ( (4) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (4) % 4][v] = r0[v]; qfbA[cur][ (4) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[5] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][5][v] = r0[v]; qfb[cur][5][v + 4] = r1[v]; } if ( (5) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (5) % 4][v] = r0[v]; qfbA[cur][ (5) % 4][v + 4] = r1[v]; } } } if ( (2) < (0 == 1 ? 3 : 3 - 1)) { const int cur = (2) % 3; const uint kkl = uint( ( (2) % 8) * 16); const uint kgl = k0 + kkl; if ( ( ( (2) >> (0)) & 1) != 0) { const uint nrq = (qal4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][0][v] = r0[v]; qfa[cur][0][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][0][v] = r0[v]; qfaB[cur][0][v + 4] = r1[v]; } } if ( ( ( (2) >> (1)) & 1) != 0) { const uint nrq = (qal4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][1][v] = r0[v]; qfa[cur][1][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][1][v] = r0[v]; qfaB[cur][1][v + 4] = r1[v]; } } { const uint nrq = (qbl4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][0][v] = r0[v]; qfb[cur][0][v + 4] = r1[v]; } if ( (0) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (0) % 4][v] = r0[v]; qfbA[cur][ (0) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][1][v] = r0[v]; qfb[cur][1][v + 4] = r1[v]; } if ( (1) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (1) % 4][v] = r0[v]; qfbA[cur][ (1) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[2] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][2][v] = r0[v]; qfb[cur][2][v + 4] = r1[v]; } if ( (2) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (2) % 4][v] = r0[v]; qfbA[cur][ (2) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[3] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][3][v] = r0[v]; qfb[cur][3][v + 4] = r1[v]; } if ( (3) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (3) % 4][v] = r0[v]; qfbA[cur][ (3) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[4] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][4][v] = r0[v]; qfb[cur][4][v + 4] = r1[v]; } if ( (4) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (4) % 4][v] = r0[v]; qfbA[cur][ (4) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[5] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][5][v] = r0[v]; qfb[cur][5][v + 4] = r1[v]; } if ( (5) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (5) % 4][v] = r0[v]; qfbA[cur][ (5) % 4][v + 4] = r1[v]; } } } if ( (3) < (0 == 1 ? 3 : 3 - 1)) { const int cur = (3) % 3; const uint kkl = uint( ( (3) % 8) * 16); const uint kgl = k0 + kkl; if ( ( ( (2) >> (0)) & 1) != 0) { const uint nrq = (qal4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][0][v] = r0[v]; qfa[cur][0][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][0][v] = r0[v]; qfaB[cur][0][v + 4] = r1[v]; } } if ( ( ( (2) >> (1)) & 1) != 0) { const uint nrq = (qal4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][1][v] = r0[v]; qfa[cur][1][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][1][v] = r0[v]; qfaB[cur][1][v + 4] = r1[v]; } } { const uint nrq = (qbl4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][0][v] = r0[v]; qfb[cur][0][v + 4] = r1[v]; } if ( (0) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (0) % 4][v] = r0[v]; qfbA[cur][ (0) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][1][v] = r0[v]; qfb[cur][1][v + 4] = r1[v]; } if ( (1) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (1) % 4][v] = r0[v]; qfbA[cur][ (1) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[2] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][2][v] = r0[v]; qfb[cur][2][v + 4] = r1[v]; } if ( (2) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (2) % 4][v] = r0[v]; qfbA[cur][ (2) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[3] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][3][v] = r0[v]; qfb[cur][3][v + 4] = r1[v]; } if ( (3) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (3) % 4][v] = r0[v]; qfbA[cur][ (3) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[4] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][4][v] = r0[v]; qfb[cur][4][v + 4] = r1[v]; } if ( (4) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (4) % 4][v] = r0[v]; qfbA[cur][ (4) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[5] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][5][v] = r0[v]; qfb[cur][5][v + 4] = r1[v]; } if ( (5) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (5) % 4][v] = r0[v]; qfbA[cur][ (5) % 4][v + 4] = r1[v]; } } } if ( (4) < (0 == 1 ? 3 : 3 - 1)) { const int cur = (4) % 3; const uint kkl = uint( ( (4) % 8) * 16); const uint kgl = k0 + kkl; if ( ( ( (2) >> (0)) & 1) != 0) { const uint nrq = (qal4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][0][v] = r0[v]; qfa[cur][0][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][0][v] = r0[v]; qfaB[cur][0][v + 4] = r1[v]; } } if ( ( ( (2) >> (1)) & 1) != 0) { const uint nrq = (qal4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][1][v] = r0[v]; qfa[cur][1][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][1][v] = r0[v]; qfaB[cur][1][v + 4] = r1[v]; } } { const uint nrq = (qbl4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][0][v] = r0[v]; qfb[cur][0][v + 4] = r1[v]; } if ( (0) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (0) % 4][v] = r0[v]; qfbA[cur][ (0) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][1][v] = r0[v]; qfb[cur][1][v + 4] = r1[v]; } if ( (1) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (1) % 4][v] = r0[v]; qfbA[cur][ (1) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[2] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][2][v] = r0[v]; qfb[cur][2][v + 4] = r1[v]; } if ( (2) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (2) % 4][v] = r0[v]; qfbA[cur][ (2) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[3] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][3][v] = r0[v]; qfb[cur][3][v + 4] = r1[v]; } if ( (3) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (3) % 4][v] = r0[v]; qfbA[cur][ (3) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[4] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][4][v] = r0[v]; qfb[cur][4][v + 4] = r1[v]; } if ( (4) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (4) % 4][v] = r0[v]; qfbA[cur][ (4) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[5] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][5][v] = r0[v]; qfb[cur][5][v + 4] = r1[v]; } if ( (5) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (5) % 4][v] = r0[v]; qfbA[cur][ (5) % 4][v + 4] = r1[v]; } } } if ( (5) < (0 == 1 ? 3 : 3 - 1)) { const int cur = (5) % 3; const uint kkl = uint( ( (5) % 8) * 16); const uint kgl = k0 + kkl; if ( ( ( (2) >> (0)) & 1) != 0) { const uint nrq = (qal4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][0][v] = r0[v]; qfa[cur][0][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][0][v] = r0[v]; qfaB[cur][0][v + 4] = r1[v]; } } if ( ( ( (2) >> (1)) & 1) != 0) { const uint nrq = (qal4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][1][v] = r0[v]; qfa[cur][1][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][1][v] = r0[v]; qfaB[cur][1][v + 4] = r1[v]; } } { const uint nrq = (qbl4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][0][v] = r0[v]; qfb[cur][0][v + 4] = r1[v]; } if ( (0) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (0) % 4][v] = r0[v]; qfbA[cur][ (0) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][1][v] = r0[v]; qfb[cur][1][v + 4] = r1[v]; } if ( (1) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (1) % 4][v] = r0[v]; qfbA[cur][ (1) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[2] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][2][v] = r0[v]; qfb[cur][2][v + 4] = r1[v]; } if ( (2) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (2) % 4][v] = r0[v]; qfbA[cur][ (2) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[3] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][3][v] = r0[v]; qfb[cur][3][v + 4] = r1[v]; } if ( (3) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (3) % 4][v] = r0[v]; qfbA[cur][ (3) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[4] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][4][v] = r0[v]; qfb[cur][4][v + 4] = r1[v]; } if ( (4) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (4) % 4][v] = r0[v]; qfbA[cur][ (4) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[5] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][5][v] = r0[v]; qfb[cur][5][v + 4] = r1[v]; } if ( (5) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (5) % 4][v] = r0[v]; qfbA[cur][ (5) % 4][v + 4] = r1[v]; } } } if ( (6) < (0 == 1 ? 3 : 3 - 1)) { const int cur = (6) % 3; const uint kkl = uint( ( (6) % 8) * 16); const uint kgl = k0 + kkl; if ( ( ( (2) >> (0)) & 1) != 0) { const uint nrq = (qal4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][0][v] = r0[v]; qfa[cur][0][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][0][v] = r0[v]; qfaB[cur][0][v + 4] = r1[v]; } } if ( ( ( (2) >> (1)) & 1) != 0) { const uint nrq = (qal4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][1][v] = r0[v]; qfa[cur][1][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][1][v] = r0[v]; qfaB[cur][1][v + 4] = r1[v]; } } { const uint nrq = (qbl4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][0][v] = r0[v]; qfb[cur][0][v + 4] = r1[v]; } if ( (0) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (0) % 4][v] = r0[v]; qfbA[cur][ (0) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][1][v] = r0[v]; qfb[cur][1][v + 4] = r1[v]; } if ( (1) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (1) % 4][v] = r0[v]; qfbA[cur][ (1) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[2] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][2][v] = r0[v]; qfb[cur][2][v + 4] = r1[v]; } if ( (2) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (2) % 4][v] = r0[v]; qfbA[cur][ (2) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[3] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][3][v] = r0[v]; qfb[cur][3][v + 4] = r1[v]; } if ( (3) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (3) % 4][v] = r0[v]; qfbA[cur][ (3) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[4] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][4][v] = r0[v]; qfb[cur][4][v + 4] = r1[v]; } if ( (4) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (4) % 4][v] = r0[v]; qfbA[cur][ (4) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[5] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][5][v] = r0[v]; qfb[cur][5][v + 4] = r1[v]; } if ( (5) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (5) % 4][v] = r0[v]; qfbA[cur][ (5) % 4][v + 4] = r1[v]; } } } if ( (7) < (0 == 1 ? 3 : 3 - 1)) { const int cur = (7) % 3; const uint kkl = uint( ( (7) % 8) * 16); const uint kgl = k0 + kkl; if ( ( ( (2) >> (0)) & 1) != 0) { const uint nrq = (qal4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][0][v] = r0[v]; qfa[cur][0][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][0][v] = r0[v]; qfaB[cur][0][v + 4] = r1[v]; } } if ( ( ( (2) >> (1)) & 1) != 0) { const uint nrq = (qal4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][1][v] = r0[v]; qfa[cur][1][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][1][v] = r0[v]; qfaB[cur][1][v + 4] = r1[v]; } } { const uint nrq = (qbl4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][0][v] = r0[v]; qfb[cur][0][v + 4] = r1[v]; } if ( (0) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (0) % 4][v] = r0[v]; qfbA[cur][ (0) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][1][v] = r0[v]; qfb[cur][1][v + 4] = r1[v]; } if ( (1) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (1) % 4][v] = r0[v]; qfbA[cur][ (1) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[2] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][2][v] = r0[v]; qfb[cur][2][v + 4] = r1[v]; } if ( (2) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (2) % 4][v] = r0[v]; qfbA[cur][ (2) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[3] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][3][v] = r0[v]; qfb[cur][3][v + 4] = r1[v]; } if ( (3) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (3) % 4][v] = r0[v]; qfbA[cur][ (3) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[4] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][4][v] = r0[v]; qfb[cur][4][v + 4] = r1[v]; } if ( (4) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (4) % 4][v] = r0[v]; qfbA[cur][ (4) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[5] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][5][v] = r0[v]; qfb[cur][5][v + 4] = r1[v]; } if ( (5) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (5) % 4][v] = r0[v]; qfbA[cur][ (5) % 4][v + 4] = r1[v]; } } } { const int pp = (0) % 3; const int cur = ( (0) + 3 - 1) % 3; const uint kkl = uint( ( ( (0) + 3 - 1) % 8) * 16); const uint kgl = k0 + kkl; if (0 == 0 && (0) + 3 - 1 < 8) { if ( ( ( (2) >> (0)) & 1) != 0) { const uint nrq = (qal4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][0][v] = r0[v]; qfa[cur][0][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][0][v] = r0[v]; qfaB[cur][0][v + 4] = r1[v]; } } if ( ( ( (2) >> (1)) & 1) != 0) { const uint nrq = (qal4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][1][v] = r0[v]; qfa[cur][1][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][1][v] = r0[v]; qfaB[cur][1][v + 4] = r1[v]; } } { const uint nrq = (qbl4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][0][v] = r0[v]; qfb[cur][0][v + 4] = r1[v]; } if ( (0) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (0) % 4][v] = r0[v]; qfbA[cur][ (0) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][1][v] = r0[v]; qfb[cur][1][v + 4] = r1[v]; } if ( (1) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (1) % 4][v] = r0[v]; qfbA[cur][ (1) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[2] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][2][v] = r0[v]; qfb[cur][2][v + 4] = r1[v]; } if ( (2) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (2) % 4][v] = r0[v]; qfbA[cur][ (2) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[3] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][3][v] = r0[v]; qfb[cur][3][v + 4] = r1[v]; } if ( (3) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (3) % 4][v] = r0[v]; qfbA[cur][ (3) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[4] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][4][v] = r0[v]; qfb[cur][4][v + 4] = r1[v]; } if ( (4) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (4) % 4][v] = r0[v]; qfbA[cur][ (4) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[5] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][5][v] = r0[v]; qfb[cur][5][v + 4] = r1[v]; } if ( (5) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (5) % 4][v] = r0[v]; qfbA[cur][ (5) % 4][v + 4] = r1[v]; } } } if (0 == 0) { if ( ( ( (2) >> (0)) & 1) != 0) { const int ii = 0; if ( (0) < 4) qacc[ii][0] = coopMatMulAdd(qfbA[pp][ (0) % 4], qfaB[pp][ii], qacc[ii][0]); else qacc[ii][0] = coopMatMulAdd(qfa[pp][ii], qfb[pp][0], qacc[ii][0]); if ( (1) < 4) qacc[ii][1] = coopMatMulAdd(qfbA[pp][ (1) % 4], qfaB[pp][ii], qacc[ii][1]); else qacc[ii][1] = coopMatMulAdd(qfa[pp][ii], qfb[pp][1], qacc[ii][1]); if ( (2) < 4) qacc[ii][2] = coopMatMulAdd(qfbA[pp][ (2) % 4], qfaB[pp][ii], qacc[ii][2]); else qacc[ii][2] = coopMatMulAdd(qfa[pp][ii], qfb[pp][2], qacc[ii][2]); if ( (3) < 4) qacc[ii][3] = coopMatMulAdd(qfbA[pp][ (3) % 4], qfaB[pp][ii], qacc[ii][3]); else qacc[ii][3] = coopMatMulAdd(qfa[pp][ii], qfb[pp][3], qacc[ii][3]); if ( (4) < 4) qacc[ii][4] = coopMatMulAdd(qfbA[pp][ (4) % 4], qfaB[pp][ii], qacc[ii][4]); else qacc[ii][4] = coopMatMulAdd(qfa[pp][ii], qfb[pp][4], qacc[ii][4]); if ( (5) < 4) qacc[ii][5] = coopMatMulAdd(qfbA[pp][ (5) % 4], qfaB[pp][ii], qacc[ii][5]); else qacc[ii][5] = coopMatMulAdd(qfa[pp][ii], qfb[pp][5], qacc[ii][5]); } if ( ( ( (2) >> (1)) & 1) != 0) { const int ii = 1; if ( (0) < 4) qacc[ii][0] = coopMatMulAdd(qfbA[pp][ (0) % 4], qfaB[pp][ii], qacc[ii][0]); else qacc[ii][0] = coopMatMulAdd(qfa[pp][ii], qfb[pp][0], qacc[ii][0]); if ( (1) < 4) qacc[ii][1] = coopMatMulAdd(qfbA[pp][ (1) % 4], qfaB[pp][ii], qacc[ii][1]); else qacc[ii][1] = coopMatMulAdd(qfa[pp][ii], qfb[pp][1], qacc[ii][1]); if ( (2) < 4) qacc[ii][2] = coopMatMulAdd(qfbA[pp][ (2) % 4], qfaB[pp][ii], qacc[ii][2]); else qacc[ii][2] = coopMatMulAdd(qfa[pp][ii], qfb[pp][2], qacc[ii][2]); if ( (3) < 4) qacc[ii][3] = coopMatMulAdd(qfbA[pp][ (3) % 4], qfaB[pp][ii], qacc[ii][3]); else qacc[ii][3] = coopMatMulAdd(qfa[pp][ii], qfb[pp][3], qacc[ii][3]); if ( (4) < 4) qacc[ii][4] = coopMatMulAdd(qfbA[pp][ (4) % 4], qfaB[pp][ii], qacc[ii][4]); else qacc[ii][4] = coopMatMulAdd(qfa[pp][ii], qfb[pp][4], qacc[ii][4]); if ( (5) < 4) qacc[ii][5] = coopMatMulAdd(qfbA[pp][ (5) % 4], qfaB[pp][ii], qacc[ii][5]); else qacc[ii][5] = coopMatMulAdd(qfa[pp][ii], qfb[pp][5], qacc[ii][5]); } } if (0 > 0 && ( (0) + 1) % 0 == 0) { { const int ii = 0; { for (int c = 0; c < qacc[ii][0].length(); ++ c) qacc[ii][0][c] = nr_round_f16_e4m3(qacc[ii][0][c]); } { for (int c = 0; c < qacc[ii][1].length(); ++ c) qacc[ii][1][c] = nr_round_f16_e4m3(qacc[ii][1][c]); } { for (int c = 0; c < qacc[ii][2].length(); ++ c) qacc[ii][2][c] = nr_round_f16_e4m3(qacc[ii][2][c]); } { for (int c = 0; c < qacc[ii][3].length(); ++ c) qacc[ii][3][c] = nr_round_f16_e4m3(qacc[ii][3][c]); } { for (int c = 0; c < qacc[ii][4].length(); ++ c) qacc[ii][4][c] = nr_round_f16_e4m3(qacc[ii][4][c]); } { for (int c = 0; c < qacc[ii][5].length(); ++ c) qacc[ii][5][c] = nr_round_f16_e4m3(qacc[ii][5][c]); } } { const int ii = 1; { for (int c = 0; c < qacc[ii][0].length(); ++ c) qacc[ii][0][c] = nr_round_f16_e4m3(qacc[ii][0][c]); } { for (int c = 0; c < qacc[ii][1].length(); ++ c) qacc[ii][1][c] = nr_round_f16_e4m3(qacc[ii][1][c]); } { for (int c = 0; c < qacc[ii][2].length(); ++ c) qacc[ii][2][c] = nr_round_f16_e4m3(qacc[ii][2][c]); } { for (int c = 0; c < qacc[ii][3].length(); ++ c) qacc[ii][3][c] = nr_round_f16_e4m3(qacc[ii][3][c]); } { for (int c = 0; c < qacc[ii][4].length(); ++ c) qacc[ii][4][c] = nr_round_f16_e4m3(qacc[ii][4][c]); } { for (int c = 0; c < qacc[ii][5].length(); ++ c) qacc[ii][5][c] = nr_round_f16_e4m3(qacc[ii][5][c]); } } } } { const int pp = (1) % 3; const int cur = ( (1) + 3 - 1) % 3; const uint kkl = uint( ( ( (1) + 3 - 1) % 8) * 16); const uint kgl = k0 + kkl; if (0 == 0 && (1) + 3 - 1 < 8) { if ( ( ( (2) >> (0)) & 1) != 0) { const uint nrq = (qal4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][0][v] = r0[v]; qfa[cur][0][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][0][v] = r0[v]; qfaB[cur][0][v + 4] = r1[v]; } } if ( ( ( (2) >> (1)) & 1) != 0) { const uint nrq = (qal4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][1][v] = r0[v]; qfa[cur][1][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][1][v] = r0[v]; qfaB[cur][1][v + 4] = r1[v]; } } { const uint nrq = (qbl4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][0][v] = r0[v]; qfb[cur][0][v + 4] = r1[v]; } if ( (0) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (0) % 4][v] = r0[v]; qfbA[cur][ (0) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][1][v] = r0[v]; qfb[cur][1][v + 4] = r1[v]; } if ( (1) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (1) % 4][v] = r0[v]; qfbA[cur][ (1) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[2] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][2][v] = r0[v]; qfb[cur][2][v + 4] = r1[v]; } if ( (2) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (2) % 4][v] = r0[v]; qfbA[cur][ (2) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[3] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][3][v] = r0[v]; qfb[cur][3][v + 4] = r1[v]; } if ( (3) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (3) % 4][v] = r0[v]; qfbA[cur][ (3) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[4] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][4][v] = r0[v]; qfb[cur][4][v + 4] = r1[v]; } if ( (4) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (4) % 4][v] = r0[v]; qfbA[cur][ (4) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[5] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][5][v] = r0[v]; qfb[cur][5][v + 4] = r1[v]; } if ( (5) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (5) % 4][v] = r0[v]; qfbA[cur][ (5) % 4][v + 4] = r1[v]; } } } if (0 == 0) { if ( ( ( (2) >> (0)) & 1) != 0) { const int ii = 0; if ( (0) < 4) qacc[ii][0] = coopMatMulAdd(qfbA[pp][ (0) % 4], qfaB[pp][ii], qacc[ii][0]); else qacc[ii][0] = coopMatMulAdd(qfa[pp][ii], qfb[pp][0], qacc[ii][0]); if ( (1) < 4) qacc[ii][1] = coopMatMulAdd(qfbA[pp][ (1) % 4], qfaB[pp][ii], qacc[ii][1]); else qacc[ii][1] = coopMatMulAdd(qfa[pp][ii], qfb[pp][1], qacc[ii][1]); if ( (2) < 4) qacc[ii][2] = coopMatMulAdd(qfbA[pp][ (2) % 4], qfaB[pp][ii], qacc[ii][2]); else qacc[ii][2] = coopMatMulAdd(qfa[pp][ii], qfb[pp][2], qacc[ii][2]); if ( (3) < 4) qacc[ii][3] = coopMatMulAdd(qfbA[pp][ (3) % 4], qfaB[pp][ii], qacc[ii][3]); else qacc[ii][3] = coopMatMulAdd(qfa[pp][ii], qfb[pp][3], qacc[ii][3]); if ( (4) < 4) qacc[ii][4] = coopMatMulAdd(qfbA[pp][ (4) % 4], qfaB[pp][ii], qacc[ii][4]); else qacc[ii][4] = coopMatMulAdd(qfa[pp][ii], qfb[pp][4], qacc[ii][4]); if ( (5) < 4) qacc[ii][5] = coopMatMulAdd(qfbA[pp][ (5) % 4], qfaB[pp][ii], qacc[ii][5]); else qacc[ii][5] = coopMatMulAdd(qfa[pp][ii], qfb[pp][5], qacc[ii][5]); } if ( ( ( (2) >> (1)) & 1) != 0) { const int ii = 1; if ( (0) < 4) qacc[ii][0] = coopMatMulAdd(qfbA[pp][ (0) % 4], qfaB[pp][ii], qacc[ii][0]); else qacc[ii][0] = coopMatMulAdd(qfa[pp][ii], qfb[pp][0], qacc[ii][0]); if ( (1) < 4) qacc[ii][1] = coopMatMulAdd(qfbA[pp][ (1) % 4], qfaB[pp][ii], qacc[ii][1]); else qacc[ii][1] = coopMatMulAdd(qfa[pp][ii], qfb[pp][1], qacc[ii][1]); if ( (2) < 4) qacc[ii][2] = coopMatMulAdd(qfbA[pp][ (2) % 4], qfaB[pp][ii], qacc[ii][2]); else qacc[ii][2] = coopMatMulAdd(qfa[pp][ii], qfb[pp][2], qacc[ii][2]); if ( (3) < 4) qacc[ii][3] = coopMatMulAdd(qfbA[pp][ (3) % 4], qfaB[pp][ii], qacc[ii][3]); else qacc[ii][3] = coopMatMulAdd(qfa[pp][ii], qfb[pp][3], qacc[ii][3]); if ( (4) < 4) qacc[ii][4] = coopMatMulAdd(qfbA[pp][ (4) % 4], qfaB[pp][ii], qacc[ii][4]); else qacc[ii][4] = coopMatMulAdd(qfa[pp][ii], qfb[pp][4], qacc[ii][4]); if ( (5) < 4) qacc[ii][5] = coopMatMulAdd(qfbA[pp][ (5) % 4], qfaB[pp][ii], qacc[ii][5]); else qacc[ii][5] = coopMatMulAdd(qfa[pp][ii], qfb[pp][5], qacc[ii][5]); } } if (0 > 0 && ( (1) + 1) % 0 == 0) { { const int ii = 0; { for (int c = 0; c < qacc[ii][0].length(); ++ c) qacc[ii][0][c] = nr_round_f16_e4m3(qacc[ii][0][c]); } { for (int c = 0; c < qacc[ii][1].length(); ++ c) qacc[ii][1][c] = nr_round_f16_e4m3(qacc[ii][1][c]); } { for (int c = 0; c < qacc[ii][2].length(); ++ c) qacc[ii][2][c] = nr_round_f16_e4m3(qacc[ii][2][c]); } { for (int c = 0; c < qacc[ii][3].length(); ++ c) qacc[ii][3][c] = nr_round_f16_e4m3(qacc[ii][3][c]); } { for (int c = 0; c < qacc[ii][4].length(); ++ c) qacc[ii][4][c] = nr_round_f16_e4m3(qacc[ii][4][c]); } { for (int c = 0; c < qacc[ii][5].length(); ++ c) qacc[ii][5][c] = nr_round_f16_e4m3(qacc[ii][5][c]); } } { const int ii = 1; { for (int c = 0; c < qacc[ii][0].length(); ++ c) qacc[ii][0][c] = nr_round_f16_e4m3(qacc[ii][0][c]); } { for (int c = 0; c < qacc[ii][1].length(); ++ c) qacc[ii][1][c] = nr_round_f16_e4m3(qacc[ii][1][c]); } { for (int c = 0; c < qacc[ii][2].length(); ++ c) qacc[ii][2][c] = nr_round_f16_e4m3(qacc[ii][2][c]); } { for (int c = 0; c < qacc[ii][3].length(); ++ c) qacc[ii][3][c] = nr_round_f16_e4m3(qacc[ii][3][c]); } { for (int c = 0; c < qacc[ii][4].length(); ++ c) qacc[ii][4][c] = nr_round_f16_e4m3(qacc[ii][4][c]); } { for (int c = 0; c < qacc[ii][5].length(); ++ c) qacc[ii][5][c] = nr_round_f16_e4m3(qacc[ii][5][c]); } } } } { const int pp = (2) % 3; const int cur = ( (2) + 3 - 1) % 3; const uint kkl = uint( ( ( (2) + 3 - 1) % 8) * 16); const uint kgl = k0 + kkl; if (0 == 0 && (2) + 3 - 1 < 8) { if ( ( ( (2) >> (0)) & 1) != 0) { const uint nrq = (qal4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][0][v] = r0[v]; qfa[cur][0][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][0][v] = r0[v]; qfaB[cur][0][v + 4] = r1[v]; } } if ( ( ( (2) >> (1)) & 1) != 0) { const uint nrq = (qal4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][1][v] = r0[v]; qfa[cur][1][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][1][v] = r0[v]; qfaB[cur][1][v + 4] = r1[v]; } } { const uint nrq = (qbl4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][0][v] = r0[v]; qfb[cur][0][v + 4] = r1[v]; } if ( (0) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (0) % 4][v] = r0[v]; qfbA[cur][ (0) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][1][v] = r0[v]; qfb[cur][1][v + 4] = r1[v]; } if ( (1) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (1) % 4][v] = r0[v]; qfbA[cur][ (1) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[2] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][2][v] = r0[v]; qfb[cur][2][v + 4] = r1[v]; } if ( (2) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (2) % 4][v] = r0[v]; qfbA[cur][ (2) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[3] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][3][v] = r0[v]; qfb[cur][3][v + 4] = r1[v]; } if ( (3) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (3) % 4][v] = r0[v]; qfbA[cur][ (3) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[4] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][4][v] = r0[v]; qfb[cur][4][v + 4] = r1[v]; } if ( (4) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (4) % 4][v] = r0[v]; qfbA[cur][ (4) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[5] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][5][v] = r0[v]; qfb[cur][5][v + 4] = r1[v]; } if ( (5) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (5) % 4][v] = r0[v]; qfbA[cur][ (5) % 4][v + 4] = r1[v]; } } } if (0 == 0) { if ( ( ( (2) >> (0)) & 1) != 0) { const int ii = 0; if ( (0) < 4) qacc[ii][0] = coopMatMulAdd(qfbA[pp][ (0) % 4], qfaB[pp][ii], qacc[ii][0]); else qacc[ii][0] = coopMatMulAdd(qfa[pp][ii], qfb[pp][0], qacc[ii][0]); if ( (1) < 4) qacc[ii][1] = coopMatMulAdd(qfbA[pp][ (1) % 4], qfaB[pp][ii], qacc[ii][1]); else qacc[ii][1] = coopMatMulAdd(qfa[pp][ii], qfb[pp][1], qacc[ii][1]); if ( (2) < 4) qacc[ii][2] = coopMatMulAdd(qfbA[pp][ (2) % 4], qfaB[pp][ii], qacc[ii][2]); else qacc[ii][2] = coopMatMulAdd(qfa[pp][ii], qfb[pp][2], qacc[ii][2]); if ( (3) < 4) qacc[ii][3] = coopMatMulAdd(qfbA[pp][ (3) % 4], qfaB[pp][ii], qacc[ii][3]); else qacc[ii][3] = coopMatMulAdd(qfa[pp][ii], qfb[pp][3], qacc[ii][3]); if ( (4) < 4) qacc[ii][4] = coopMatMulAdd(qfbA[pp][ (4) % 4], qfaB[pp][ii], qacc[ii][4]); else qacc[ii][4] = coopMatMulAdd(qfa[pp][ii], qfb[pp][4], qacc[ii][4]); if ( (5) < 4) qacc[ii][5] = coopMatMulAdd(qfbA[pp][ (5) % 4], qfaB[pp][ii], qacc[ii][5]); else qacc[ii][5] = coopMatMulAdd(qfa[pp][ii], qfb[pp][5], qacc[ii][5]); } if ( ( ( (2) >> (1)) & 1) != 0) { const int ii = 1; if ( (0) < 4) qacc[ii][0] = coopMatMulAdd(qfbA[pp][ (0) % 4], qfaB[pp][ii], qacc[ii][0]); else qacc[ii][0] = coopMatMulAdd(qfa[pp][ii], qfb[pp][0], qacc[ii][0]); if ( (1) < 4) qacc[ii][1] = coopMatMulAdd(qfbA[pp][ (1) % 4], qfaB[pp][ii], qacc[ii][1]); else qacc[ii][1] = coopMatMulAdd(qfa[pp][ii], qfb[pp][1], qacc[ii][1]); if ( (2) < 4) qacc[ii][2] = coopMatMulAdd(qfbA[pp][ (2) % 4], qfaB[pp][ii], qacc[ii][2]); else qacc[ii][2] = coopMatMulAdd(qfa[pp][ii], qfb[pp][2], qacc[ii][2]); if ( (3) < 4) qacc[ii][3] = coopMatMulAdd(qfbA[pp][ (3) % 4], qfaB[pp][ii], qacc[ii][3]); else qacc[ii][3] = coopMatMulAdd(qfa[pp][ii], qfb[pp][3], qacc[ii][3]); if ( (4) < 4) qacc[ii][4] = coopMatMulAdd(qfbA[pp][ (4) % 4], qfaB[pp][ii], qacc[ii][4]); else qacc[ii][4] = coopMatMulAdd(qfa[pp][ii], qfb[pp][4], qacc[ii][4]); if ( (5) < 4) qacc[ii][5] = coopMatMulAdd(qfbA[pp][ (5) % 4], qfaB[pp][ii], qacc[ii][5]); else qacc[ii][5] = coopMatMulAdd(qfa[pp][ii], qfb[pp][5], qacc[ii][5]); } } if (0 > 0 && ( (2) + 1) % 0 == 0) { { const int ii = 0; { for (int c = 0; c < qacc[ii][0].length(); ++ c) qacc[ii][0][c] = nr_round_f16_e4m3(qacc[ii][0][c]); } { for (int c = 0; c < qacc[ii][1].length(); ++ c) qacc[ii][1][c] = nr_round_f16_e4m3(qacc[ii][1][c]); } { for (int c = 0; c < qacc[ii][2].length(); ++ c) qacc[ii][2][c] = nr_round_f16_e4m3(qacc[ii][2][c]); } { for (int c = 0; c < qacc[ii][3].length(); ++ c) qacc[ii][3][c] = nr_round_f16_e4m3(qacc[ii][3][c]); } { for (int c = 0; c < qacc[ii][4].length(); ++ c) qacc[ii][4][c] = nr_round_f16_e4m3(qacc[ii][4][c]); } { for (int c = 0; c < qacc[ii][5].length(); ++ c) qacc[ii][5][c] = nr_round_f16_e4m3(qacc[ii][5][c]); } } { const int ii = 1; { for (int c = 0; c < qacc[ii][0].length(); ++ c) qacc[ii][0][c] = nr_round_f16_e4m3(qacc[ii][0][c]); } { for (int c = 0; c < qacc[ii][1].length(); ++ c) qacc[ii][1][c] = nr_round_f16_e4m3(qacc[ii][1][c]); } { for (int c = 0; c < qacc[ii][2].length(); ++ c) qacc[ii][2][c] = nr_round_f16_e4m3(qacc[ii][2][c]); } { for (int c = 0; c < qacc[ii][3].length(); ++ c) qacc[ii][3][c] = nr_round_f16_e4m3(qacc[ii][3][c]); } { for (int c = 0; c < qacc[ii][4].length(); ++ c) qacc[ii][4][c] = nr_round_f16_e4m3(qacc[ii][4][c]); } { for (int c = 0; c < qacc[ii][5].length(); ++ c) qacc[ii][5][c] = nr_round_f16_e4m3(qacc[ii][5][c]); } } } } { const int pp = (3) % 3; const int cur = ( (3) + 3 - 1) % 3; const uint kkl = uint( ( ( (3) + 3 - 1) % 8) * 16); const uint kgl = k0 + kkl; if (0 == 0 && (3) + 3 - 1 < 8) { if ( ( ( (2) >> (0)) & 1) != 0) { const uint nrq = (qal4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][0][v] = r0[v]; qfa[cur][0][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][0][v] = r0[v]; qfaB[cur][0][v + 4] = r1[v]; } } if ( ( ( (2) >> (1)) & 1) != 0) { const uint nrq = (qal4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][1][v] = r0[v]; qfa[cur][1][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][1][v] = r0[v]; qfaB[cur][1][v + 4] = r1[v]; } } { const uint nrq = (qbl4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][0][v] = r0[v]; qfb[cur][0][v + 4] = r1[v]; } if ( (0) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (0) % 4][v] = r0[v]; qfbA[cur][ (0) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][1][v] = r0[v]; qfb[cur][1][v + 4] = r1[v]; } if ( (1) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (1) % 4][v] = r0[v]; qfbA[cur][ (1) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[2] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][2][v] = r0[v]; qfb[cur][2][v + 4] = r1[v]; } if ( (2) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (2) % 4][v] = r0[v]; qfbA[cur][ (2) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[3] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][3][v] = r0[v]; qfb[cur][3][v + 4] = r1[v]; } if ( (3) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (3) % 4][v] = r0[v]; qfbA[cur][ (3) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[4] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][4][v] = r0[v]; qfb[cur][4][v + 4] = r1[v]; } if ( (4) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (4) % 4][v] = r0[v]; qfbA[cur][ (4) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[5] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][5][v] = r0[v]; qfb[cur][5][v + 4] = r1[v]; } if ( (5) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (5) % 4][v] = r0[v]; qfbA[cur][ (5) % 4][v + 4] = r1[v]; } } } if (0 == 0) { if ( ( ( (2) >> (0)) & 1) != 0) { const int ii = 0; if ( (0) < 4) qacc[ii][0] = coopMatMulAdd(qfbA[pp][ (0) % 4], qfaB[pp][ii], qacc[ii][0]); else qacc[ii][0] = coopMatMulAdd(qfa[pp][ii], qfb[pp][0], qacc[ii][0]); if ( (1) < 4) qacc[ii][1] = coopMatMulAdd(qfbA[pp][ (1) % 4], qfaB[pp][ii], qacc[ii][1]); else qacc[ii][1] = coopMatMulAdd(qfa[pp][ii], qfb[pp][1], qacc[ii][1]); if ( (2) < 4) qacc[ii][2] = coopMatMulAdd(qfbA[pp][ (2) % 4], qfaB[pp][ii], qacc[ii][2]); else qacc[ii][2] = coopMatMulAdd(qfa[pp][ii], qfb[pp][2], qacc[ii][2]); if ( (3) < 4) qacc[ii][3] = coopMatMulAdd(qfbA[pp][ (3) % 4], qfaB[pp][ii], qacc[ii][3]); else qacc[ii][3] = coopMatMulAdd(qfa[pp][ii], qfb[pp][3], qacc[ii][3]); if ( (4) < 4) qacc[ii][4] = coopMatMulAdd(qfbA[pp][ (4) % 4], qfaB[pp][ii], qacc[ii][4]); else qacc[ii][4] = coopMatMulAdd(qfa[pp][ii], qfb[pp][4], qacc[ii][4]); if ( (5) < 4) qacc[ii][5] = coopMatMulAdd(qfbA[pp][ (5) % 4], qfaB[pp][ii], qacc[ii][5]); else qacc[ii][5] = coopMatMulAdd(qfa[pp][ii], qfb[pp][5], qacc[ii][5]); } if ( ( ( (2) >> (1)) & 1) != 0) { const int ii = 1; if ( (0) < 4) qacc[ii][0] = coopMatMulAdd(qfbA[pp][ (0) % 4], qfaB[pp][ii], qacc[ii][0]); else qacc[ii][0] = coopMatMulAdd(qfa[pp][ii], qfb[pp][0], qacc[ii][0]); if ( (1) < 4) qacc[ii][1] = coopMatMulAdd(qfbA[pp][ (1) % 4], qfaB[pp][ii], qacc[ii][1]); else qacc[ii][1] = coopMatMulAdd(qfa[pp][ii], qfb[pp][1], qacc[ii][1]); if ( (2) < 4) qacc[ii][2] = coopMatMulAdd(qfbA[pp][ (2) % 4], qfaB[pp][ii], qacc[ii][2]); else qacc[ii][2] = coopMatMulAdd(qfa[pp][ii], qfb[pp][2], qacc[ii][2]); if ( (3) < 4) qacc[ii][3] = coopMatMulAdd(qfbA[pp][ (3) % 4], qfaB[pp][ii], qacc[ii][3]); else qacc[ii][3] = coopMatMulAdd(qfa[pp][ii], qfb[pp][3], qacc[ii][3]); if ( (4) < 4) qacc[ii][4] = coopMatMulAdd(qfbA[pp][ (4) % 4], qfaB[pp][ii], qacc[ii][4]); else qacc[ii][4] = coopMatMulAdd(qfa[pp][ii], qfb[pp][4], qacc[ii][4]); if ( (5) < 4) qacc[ii][5] = coopMatMulAdd(qfbA[pp][ (5) % 4], qfaB[pp][ii], qacc[ii][5]); else qacc[ii][5] = coopMatMulAdd(qfa[pp][ii], qfb[pp][5], qacc[ii][5]); } } if (0 > 0 && ( (3) + 1) % 0 == 0) { { const int ii = 0; { for (int c = 0; c < qacc[ii][0].length(); ++ c) qacc[ii][0][c] = nr_round_f16_e4m3(qacc[ii][0][c]); } { for (int c = 0; c < qacc[ii][1].length(); ++ c) qacc[ii][1][c] = nr_round_f16_e4m3(qacc[ii][1][c]); } { for (int c = 0; c < qacc[ii][2].length(); ++ c) qacc[ii][2][c] = nr_round_f16_e4m3(qacc[ii][2][c]); } { for (int c = 0; c < qacc[ii][3].length(); ++ c) qacc[ii][3][c] = nr_round_f16_e4m3(qacc[ii][3][c]); } { for (int c = 0; c < qacc[ii][4].length(); ++ c) qacc[ii][4][c] = nr_round_f16_e4m3(qacc[ii][4][c]); } { for (int c = 0; c < qacc[ii][5].length(); ++ c) qacc[ii][5][c] = nr_round_f16_e4m3(qacc[ii][5][c]); } } { const int ii = 1; { for (int c = 0; c < qacc[ii][0].length(); ++ c) qacc[ii][0][c] = nr_round_f16_e4m3(qacc[ii][0][c]); } { for (int c = 0; c < qacc[ii][1].length(); ++ c) qacc[ii][1][c] = nr_round_f16_e4m3(qacc[ii][1][c]); } { for (int c = 0; c < qacc[ii][2].length(); ++ c) qacc[ii][2][c] = nr_round_f16_e4m3(qacc[ii][2][c]); } { for (int c = 0; c < qacc[ii][3].length(); ++ c) qacc[ii][3][c] = nr_round_f16_e4m3(qacc[ii][3][c]); } { for (int c = 0; c < qacc[ii][4].length(); ++ c) qacc[ii][4][c] = nr_round_f16_e4m3(qacc[ii][4][c]); } { for (int c = 0; c < qacc[ii][5].length(); ++ c) qacc[ii][5][c] = nr_round_f16_e4m3(qacc[ii][5][c]); } } } } { const int pp = (4) % 3; const int cur = ( (4) + 3 - 1) % 3; const uint kkl = uint( ( ( (4) + 3 - 1) % 8) * 16); const uint kgl = k0 + kkl; if (0 == 0 && (4) + 3 - 1 < 8) { if ( ( ( (2) >> (0)) & 1) != 0) { const uint nrq = (qal4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][0][v] = r0[v]; qfa[cur][0][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][0][v] = r0[v]; qfaB[cur][0][v + 4] = r1[v]; } } if ( ( ( (2) >> (1)) & 1) != 0) { const uint nrq = (qal4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][1][v] = r0[v]; qfa[cur][1][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][1][v] = r0[v]; qfaB[cur][1][v + 4] = r1[v]; } } { const uint nrq = (qbl4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][0][v] = r0[v]; qfb[cur][0][v + 4] = r1[v]; } if ( (0) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (0) % 4][v] = r0[v]; qfbA[cur][ (0) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][1][v] = r0[v]; qfb[cur][1][v + 4] = r1[v]; } if ( (1) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (1) % 4][v] = r0[v]; qfbA[cur][ (1) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[2] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][2][v] = r0[v]; qfb[cur][2][v + 4] = r1[v]; } if ( (2) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (2) % 4][v] = r0[v]; qfbA[cur][ (2) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[3] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][3][v] = r0[v]; qfb[cur][3][v + 4] = r1[v]; } if ( (3) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (3) % 4][v] = r0[v]; qfbA[cur][ (3) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[4] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][4][v] = r0[v]; qfb[cur][4][v + 4] = r1[v]; } if ( (4) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (4) % 4][v] = r0[v]; qfbA[cur][ (4) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[5] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][5][v] = r0[v]; qfb[cur][5][v + 4] = r1[v]; } if ( (5) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (5) % 4][v] = r0[v]; qfbA[cur][ (5) % 4][v + 4] = r1[v]; } } } if (0 == 0) { if ( ( ( (2) >> (0)) & 1) != 0) { const int ii = 0; if ( (0) < 4) qacc[ii][0] = coopMatMulAdd(qfbA[pp][ (0) % 4], qfaB[pp][ii], qacc[ii][0]); else qacc[ii][0] = coopMatMulAdd(qfa[pp][ii], qfb[pp][0], qacc[ii][0]); if ( (1) < 4) qacc[ii][1] = coopMatMulAdd(qfbA[pp][ (1) % 4], qfaB[pp][ii], qacc[ii][1]); else qacc[ii][1] = coopMatMulAdd(qfa[pp][ii], qfb[pp][1], qacc[ii][1]); if ( (2) < 4) qacc[ii][2] = coopMatMulAdd(qfbA[pp][ (2) % 4], qfaB[pp][ii], qacc[ii][2]); else qacc[ii][2] = coopMatMulAdd(qfa[pp][ii], qfb[pp][2], qacc[ii][2]); if ( (3) < 4) qacc[ii][3] = coopMatMulAdd(qfbA[pp][ (3) % 4], qfaB[pp][ii], qacc[ii][3]); else qacc[ii][3] = coopMatMulAdd(qfa[pp][ii], qfb[pp][3], qacc[ii][3]); if ( (4) < 4) qacc[ii][4] = coopMatMulAdd(qfbA[pp][ (4) % 4], qfaB[pp][ii], qacc[ii][4]); else qacc[ii][4] = coopMatMulAdd(qfa[pp][ii], qfb[pp][4], qacc[ii][4]); if ( (5) < 4) qacc[ii][5] = coopMatMulAdd(qfbA[pp][ (5) % 4], qfaB[pp][ii], qacc[ii][5]); else qacc[ii][5] = coopMatMulAdd(qfa[pp][ii], qfb[pp][5], qacc[ii][5]); } if ( ( ( (2) >> (1)) & 1) != 0) { const int ii = 1; if ( (0) < 4) qacc[ii][0] = coopMatMulAdd(qfbA[pp][ (0) % 4], qfaB[pp][ii], qacc[ii][0]); else qacc[ii][0] = coopMatMulAdd(qfa[pp][ii], qfb[pp][0], qacc[ii][0]); if ( (1) < 4) qacc[ii][1] = coopMatMulAdd(qfbA[pp][ (1) % 4], qfaB[pp][ii], qacc[ii][1]); else qacc[ii][1] = coopMatMulAdd(qfa[pp][ii], qfb[pp][1], qacc[ii][1]); if ( (2) < 4) qacc[ii][2] = coopMatMulAdd(qfbA[pp][ (2) % 4], qfaB[pp][ii], qacc[ii][2]); else qacc[ii][2] = coopMatMulAdd(qfa[pp][ii], qfb[pp][2], qacc[ii][2]); if ( (3) < 4) qacc[ii][3] = coopMatMulAdd(qfbA[pp][ (3) % 4], qfaB[pp][ii], qacc[ii][3]); else qacc[ii][3] = coopMatMulAdd(qfa[pp][ii], qfb[pp][3], qacc[ii][3]); if ( (4) < 4) qacc[ii][4] = coopMatMulAdd(qfbA[pp][ (4) % 4], qfaB[pp][ii], qacc[ii][4]); else qacc[ii][4] = coopMatMulAdd(qfa[pp][ii], qfb[pp][4], qacc[ii][4]); if ( (5) < 4) qacc[ii][5] = coopMatMulAdd(qfbA[pp][ (5) % 4], qfaB[pp][ii], qacc[ii][5]); else qacc[ii][5] = coopMatMulAdd(qfa[pp][ii], qfb[pp][5], qacc[ii][5]); } } if (0 > 0 && ( (4) + 1) % 0 == 0) { { const int ii = 0; { for (int c = 0; c < qacc[ii][0].length(); ++ c) qacc[ii][0][c] = nr_round_f16_e4m3(qacc[ii][0][c]); } { for (int c = 0; c < qacc[ii][1].length(); ++ c) qacc[ii][1][c] = nr_round_f16_e4m3(qacc[ii][1][c]); } { for (int c = 0; c < qacc[ii][2].length(); ++ c) qacc[ii][2][c] = nr_round_f16_e4m3(qacc[ii][2][c]); } { for (int c = 0; c < qacc[ii][3].length(); ++ c) qacc[ii][3][c] = nr_round_f16_e4m3(qacc[ii][3][c]); } { for (int c = 0; c < qacc[ii][4].length(); ++ c) qacc[ii][4][c] = nr_round_f16_e4m3(qacc[ii][4][c]); } { for (int c = 0; c < qacc[ii][5].length(); ++ c) qacc[ii][5][c] = nr_round_f16_e4m3(qacc[ii][5][c]); } } { const int ii = 1; { for (int c = 0; c < qacc[ii][0].length(); ++ c) qacc[ii][0][c] = nr_round_f16_e4m3(qacc[ii][0][c]); } { for (int c = 0; c < qacc[ii][1].length(); ++ c) qacc[ii][1][c] = nr_round_f16_e4m3(qacc[ii][1][c]); } { for (int c = 0; c < qacc[ii][2].length(); ++ c) qacc[ii][2][c] = nr_round_f16_e4m3(qacc[ii][2][c]); } { for (int c = 0; c < qacc[ii][3].length(); ++ c) qacc[ii][3][c] = nr_round_f16_e4m3(qacc[ii][3][c]); } { for (int c = 0; c < qacc[ii][4].length(); ++ c) qacc[ii][4][c] = nr_round_f16_e4m3(qacc[ii][4][c]); } { for (int c = 0; c < qacc[ii][5].length(); ++ c) qacc[ii][5][c] = nr_round_f16_e4m3(qacc[ii][5][c]); } } } } { const int pp = (5) % 3; const int cur = ( (5) + 3 - 1) % 3; const uint kkl = uint( ( ( (5) + 3 - 1) % 8) * 16); const uint kgl = k0 + kkl; if (0 == 0 && (5) + 3 - 1 < 8) { if ( ( ( (2) >> (0)) & 1) != 0) { const uint nrq = (qal4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][0][v] = r0[v]; qfa[cur][0][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][0][v] = r0[v]; qfaB[cur][0][v + 4] = r1[v]; } } if ( ( ( (2) >> (1)) & 1) != 0) { const uint nrq = (qal4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][1][v] = r0[v]; qfa[cur][1][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][1][v] = r0[v]; qfaB[cur][1][v + 4] = r1[v]; } } { const uint nrq = (qbl4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][0][v] = r0[v]; qfb[cur][0][v + 4] = r1[v]; } if ( (0) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (0) % 4][v] = r0[v]; qfbA[cur][ (0) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][1][v] = r0[v]; qfb[cur][1][v + 4] = r1[v]; } if ( (1) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (1) % 4][v] = r0[v]; qfbA[cur][ (1) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[2] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][2][v] = r0[v]; qfb[cur][2][v + 4] = r1[v]; } if ( (2) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (2) % 4][v] = r0[v]; qfbA[cur][ (2) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[3] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][3][v] = r0[v]; qfb[cur][3][v + 4] = r1[v]; } if ( (3) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (3) % 4][v] = r0[v]; qfbA[cur][ (3) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[4] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][4][v] = r0[v]; qfb[cur][4][v + 4] = r1[v]; } if ( (4) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (4) % 4][v] = r0[v]; qfbA[cur][ (4) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[5] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][5][v] = r0[v]; qfb[cur][5][v + 4] = r1[v]; } if ( (5) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (5) % 4][v] = r0[v]; qfbA[cur][ (5) % 4][v + 4] = r1[v]; } } } if (0 == 0) { if ( ( ( (2) >> (0)) & 1) != 0) { const int ii = 0; if ( (0) < 4) qacc[ii][0] = coopMatMulAdd(qfbA[pp][ (0) % 4], qfaB[pp][ii], qacc[ii][0]); else qacc[ii][0] = coopMatMulAdd(qfa[pp][ii], qfb[pp][0], qacc[ii][0]); if ( (1) < 4) qacc[ii][1] = coopMatMulAdd(qfbA[pp][ (1) % 4], qfaB[pp][ii], qacc[ii][1]); else qacc[ii][1] = coopMatMulAdd(qfa[pp][ii], qfb[pp][1], qacc[ii][1]); if ( (2) < 4) qacc[ii][2] = coopMatMulAdd(qfbA[pp][ (2) % 4], qfaB[pp][ii], qacc[ii][2]); else qacc[ii][2] = coopMatMulAdd(qfa[pp][ii], qfb[pp][2], qacc[ii][2]); if ( (3) < 4) qacc[ii][3] = coopMatMulAdd(qfbA[pp][ (3) % 4], qfaB[pp][ii], qacc[ii][3]); else qacc[ii][3] = coopMatMulAdd(qfa[pp][ii], qfb[pp][3], qacc[ii][3]); if ( (4) < 4) qacc[ii][4] = coopMatMulAdd(qfbA[pp][ (4) % 4], qfaB[pp][ii], qacc[ii][4]); else qacc[ii][4] = coopMatMulAdd(qfa[pp][ii], qfb[pp][4], qacc[ii][4]); if ( (5) < 4) qacc[ii][5] = coopMatMulAdd(qfbA[pp][ (5) % 4], qfaB[pp][ii], qacc[ii][5]); else qacc[ii][5] = coopMatMulAdd(qfa[pp][ii], qfb[pp][5], qacc[ii][5]); } if ( ( ( (2) >> (1)) & 1) != 0) { const int ii = 1; if ( (0) < 4) qacc[ii][0] = coopMatMulAdd(qfbA[pp][ (0) % 4], qfaB[pp][ii], qacc[ii][0]); else qacc[ii][0] = coopMatMulAdd(qfa[pp][ii], qfb[pp][0], qacc[ii][0]); if ( (1) < 4) qacc[ii][1] = coopMatMulAdd(qfbA[pp][ (1) % 4], qfaB[pp][ii], qacc[ii][1]); else qacc[ii][1] = coopMatMulAdd(qfa[pp][ii], qfb[pp][1], qacc[ii][1]); if ( (2) < 4) qacc[ii][2] = coopMatMulAdd(qfbA[pp][ (2) % 4], qfaB[pp][ii], qacc[ii][2]); else qacc[ii][2] = coopMatMulAdd(qfa[pp][ii], qfb[pp][2], qacc[ii][2]); if ( (3) < 4) qacc[ii][3] = coopMatMulAdd(qfbA[pp][ (3) % 4], qfaB[pp][ii], qacc[ii][3]); else qacc[ii][3] = coopMatMulAdd(qfa[pp][ii], qfb[pp][3], qacc[ii][3]); if ( (4) < 4) qacc[ii][4] = coopMatMulAdd(qfbA[pp][ (4) % 4], qfaB[pp][ii], qacc[ii][4]); else qacc[ii][4] = coopMatMulAdd(qfa[pp][ii], qfb[pp][4], qacc[ii][4]); if ( (5) < 4) qacc[ii][5] = coopMatMulAdd(qfbA[pp][ (5) % 4], qfaB[pp][ii], qacc[ii][5]); else qacc[ii][5] = coopMatMulAdd(qfa[pp][ii], qfb[pp][5], qacc[ii][5]); } } if (0 > 0 && ( (5) + 1) % 0 == 0) { { const int ii = 0; { for (int c = 0; c < qacc[ii][0].length(); ++ c) qacc[ii][0][c] = nr_round_f16_e4m3(qacc[ii][0][c]); } { for (int c = 0; c < qacc[ii][1].length(); ++ c) qacc[ii][1][c] = nr_round_f16_e4m3(qacc[ii][1][c]); } { for (int c = 0; c < qacc[ii][2].length(); ++ c) qacc[ii][2][c] = nr_round_f16_e4m3(qacc[ii][2][c]); } { for (int c = 0; c < qacc[ii][3].length(); ++ c) qacc[ii][3][c] = nr_round_f16_e4m3(qacc[ii][3][c]); } { for (int c = 0; c < qacc[ii][4].length(); ++ c) qacc[ii][4][c] = nr_round_f16_e4m3(qacc[ii][4][c]); } { for (int c = 0; c < qacc[ii][5].length(); ++ c) qacc[ii][5][c] = nr_round_f16_e4m3(qacc[ii][5][c]); } } { const int ii = 1; { for (int c = 0; c < qacc[ii][0].length(); ++ c) qacc[ii][0][c] = nr_round_f16_e4m3(qacc[ii][0][c]); } { for (int c = 0; c < qacc[ii][1].length(); ++ c) qacc[ii][1][c] = nr_round_f16_e4m3(qacc[ii][1][c]); } { for (int c = 0; c < qacc[ii][2].length(); ++ c) qacc[ii][2][c] = nr_round_f16_e4m3(qacc[ii][2][c]); } { for (int c = 0; c < qacc[ii][3].length(); ++ c) qacc[ii][3][c] = nr_round_f16_e4m3(qacc[ii][3][c]); } { for (int c = 0; c < qacc[ii][4].length(); ++ c) qacc[ii][4][c] = nr_round_f16_e4m3(qacc[ii][4][c]); } { for (int c = 0; c < qacc[ii][5].length(); ++ c) qacc[ii][5][c] = nr_round_f16_e4m3(qacc[ii][5][c]); } } } } { const int pp = (6) % 3; const int cur = ( (6) + 3 - 1) % 3; const uint kkl = uint( ( ( (6) + 3 - 1) % 8) * 16); const uint kgl = k0 + kkl; if (0 == 0 && (6) + 3 - 1 < 8) { if ( ( ( (2) >> (0)) & 1) != 0) { const uint nrq = (qal4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][0][v] = r0[v]; qfa[cur][0][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][0][v] = r0[v]; qfaB[cur][0][v + 4] = r1[v]; } } if ( ( ( (2) >> (1)) & 1) != 0) { const uint nrq = (qal4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][1][v] = r0[v]; qfa[cur][1][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][1][v] = r0[v]; qfaB[cur][1][v + 4] = r1[v]; } } { const uint nrq = (qbl4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][0][v] = r0[v]; qfb[cur][0][v + 4] = r1[v]; } if ( (0) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (0) % 4][v] = r0[v]; qfbA[cur][ (0) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][1][v] = r0[v]; qfb[cur][1][v + 4] = r1[v]; } if ( (1) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (1) % 4][v] = r0[v]; qfbA[cur][ (1) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[2] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][2][v] = r0[v]; qfb[cur][2][v + 4] = r1[v]; } if ( (2) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (2) % 4][v] = r0[v]; qfbA[cur][ (2) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[3] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][3][v] = r0[v]; qfb[cur][3][v + 4] = r1[v]; } if ( (3) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (3) % 4][v] = r0[v]; qfbA[cur][ (3) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[4] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][4][v] = r0[v]; qfb[cur][4][v + 4] = r1[v]; } if ( (4) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (4) % 4][v] = r0[v]; qfbA[cur][ (4) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[5] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][5][v] = r0[v]; qfb[cur][5][v + 4] = r1[v]; } if ( (5) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (5) % 4][v] = r0[v]; qfbA[cur][ (5) % 4][v + 4] = r1[v]; } } } if (0 == 0) { if ( ( ( (2) >> (0)) & 1) != 0) { const int ii = 0; if ( (0) < 4) qacc[ii][0] = coopMatMulAdd(qfbA[pp][ (0) % 4], qfaB[pp][ii], qacc[ii][0]); else qacc[ii][0] = coopMatMulAdd(qfa[pp][ii], qfb[pp][0], qacc[ii][0]); if ( (1) < 4) qacc[ii][1] = coopMatMulAdd(qfbA[pp][ (1) % 4], qfaB[pp][ii], qacc[ii][1]); else qacc[ii][1] = coopMatMulAdd(qfa[pp][ii], qfb[pp][1], qacc[ii][1]); if ( (2) < 4) qacc[ii][2] = coopMatMulAdd(qfbA[pp][ (2) % 4], qfaB[pp][ii], qacc[ii][2]); else qacc[ii][2] = coopMatMulAdd(qfa[pp][ii], qfb[pp][2], qacc[ii][2]); if ( (3) < 4) qacc[ii][3] = coopMatMulAdd(qfbA[pp][ (3) % 4], qfaB[pp][ii], qacc[ii][3]); else qacc[ii][3] = coopMatMulAdd(qfa[pp][ii], qfb[pp][3], qacc[ii][3]); if ( (4) < 4) qacc[ii][4] = coopMatMulAdd(qfbA[pp][ (4) % 4], qfaB[pp][ii], qacc[ii][4]); else qacc[ii][4] = coopMatMulAdd(qfa[pp][ii], qfb[pp][4], qacc[ii][4]); if ( (5) < 4) qacc[ii][5] = coopMatMulAdd(qfbA[pp][ (5) % 4], qfaB[pp][ii], qacc[ii][5]); else qacc[ii][5] = coopMatMulAdd(qfa[pp][ii], qfb[pp][5], qacc[ii][5]); } if ( ( ( (2) >> (1)) & 1) != 0) { const int ii = 1; if ( (0) < 4) qacc[ii][0] = coopMatMulAdd(qfbA[pp][ (0) % 4], qfaB[pp][ii], qacc[ii][0]); else qacc[ii][0] = coopMatMulAdd(qfa[pp][ii], qfb[pp][0], qacc[ii][0]); if ( (1) < 4) qacc[ii][1] = coopMatMulAdd(qfbA[pp][ (1) % 4], qfaB[pp][ii], qacc[ii][1]); else qacc[ii][1] = coopMatMulAdd(qfa[pp][ii], qfb[pp][1], qacc[ii][1]); if ( (2) < 4) qacc[ii][2] = coopMatMulAdd(qfbA[pp][ (2) % 4], qfaB[pp][ii], qacc[ii][2]); else qacc[ii][2] = coopMatMulAdd(qfa[pp][ii], qfb[pp][2], qacc[ii][2]); if ( (3) < 4) qacc[ii][3] = coopMatMulAdd(qfbA[pp][ (3) % 4], qfaB[pp][ii], qacc[ii][3]); else qacc[ii][3] = coopMatMulAdd(qfa[pp][ii], qfb[pp][3], qacc[ii][3]); if ( (4) < 4) qacc[ii][4] = coopMatMulAdd(qfbA[pp][ (4) % 4], qfaB[pp][ii], qacc[ii][4]); else qacc[ii][4] = coopMatMulAdd(qfa[pp][ii], qfb[pp][4], qacc[ii][4]); if ( (5) < 4) qacc[ii][5] = coopMatMulAdd(qfbA[pp][ (5) % 4], qfaB[pp][ii], qacc[ii][5]); else qacc[ii][5] = coopMatMulAdd(qfa[pp][ii], qfb[pp][5], qacc[ii][5]); } } if (0 > 0 && ( (6) + 1) % 0 == 0) { { const int ii = 0; { for (int c = 0; c < qacc[ii][0].length(); ++ c) qacc[ii][0][c] = nr_round_f16_e4m3(qacc[ii][0][c]); } { for (int c = 0; c < qacc[ii][1].length(); ++ c) qacc[ii][1][c] = nr_round_f16_e4m3(qacc[ii][1][c]); } { for (int c = 0; c < qacc[ii][2].length(); ++ c) qacc[ii][2][c] = nr_round_f16_e4m3(qacc[ii][2][c]); } { for (int c = 0; c < qacc[ii][3].length(); ++ c) qacc[ii][3][c] = nr_round_f16_e4m3(qacc[ii][3][c]); } { for (int c = 0; c < qacc[ii][4].length(); ++ c) qacc[ii][4][c] = nr_round_f16_e4m3(qacc[ii][4][c]); } { for (int c = 0; c < qacc[ii][5].length(); ++ c) qacc[ii][5][c] = nr_round_f16_e4m3(qacc[ii][5][c]); } } { const int ii = 1; { for (int c = 0; c < qacc[ii][0].length(); ++ c) qacc[ii][0][c] = nr_round_f16_e4m3(qacc[ii][0][c]); } { for (int c = 0; c < qacc[ii][1].length(); ++ c) qacc[ii][1][c] = nr_round_f16_e4m3(qacc[ii][1][c]); } { for (int c = 0; c < qacc[ii][2].length(); ++ c) qacc[ii][2][c] = nr_round_f16_e4m3(qacc[ii][2][c]); } { for (int c = 0; c < qacc[ii][3].length(); ++ c) qacc[ii][3][c] = nr_round_f16_e4m3(qacc[ii][3][c]); } { for (int c = 0; c < qacc[ii][4].length(); ++ c) qacc[ii][4][c] = nr_round_f16_e4m3(qacc[ii][4][c]); } { for (int c = 0; c < qacc[ii][5].length(); ++ c) qacc[ii][5][c] = nr_round_f16_e4m3(qacc[ii][5][c]); } } } } { const int pp = (7) % 3; const int cur = ( (7) + 3 - 1) % 3; const uint kkl = uint( ( ( (7) + 3 - 1) % 8) * 16); const uint kgl = k0 + kkl; if (0 == 0 && (7) + 3 - 1 < 8) { if ( ( ( (2) >> (0)) & 1) != 0) { const uint nrq = (qal4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][0][v] = r0[v]; qfa[cur][0][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][0][v] = r0[v]; qfaB[cur][0][v + 4] = r1[v]; } } if ( ( ( (2) >> (1)) & 1) != 0) { const uint nrq = (qal4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = act_e4m3x4[nrq], r1 = act_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfa[cur][1][v] = r0[v]; qfa[cur][1][v + 4] = r1[v]; } for (int v = 0; v < 4; ++ v) { qfaB[cur][1][v] = r0[v]; qfaB[cur][1][v + 4] = r1[v]; } } { const uint nrq = (qbl4[0] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][0][v] = r0[v]; qfb[cur][0][v + 4] = r1[v]; } if ( (0) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (0) % 4][v] = r0[v]; qfbA[cur][ (0) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[1] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][1][v] = r0[v]; qfb[cur][1][v + 4] = r1[v]; } if ( (1) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (1) % 4][v] = r0[v]; qfbA[cur][ (1) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[2] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][2][v] = r0[v]; qfb[cur][2][v + 4] = r1[v]; } if ( (2) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (2) % 4][v] = r0[v]; qfbA[cur][ (2) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[3] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][3][v] = r0[v]; qfb[cur][3][v + 4] = r1[v]; } if ( (3) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (3) % 4][v] = r0[v]; qfbA[cur][ (3) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[4] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][4][v] = r0[v]; qfb[cur][4][v + 4] = r1[v]; } if ( (4) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (4) % 4][v] = r0[v]; qfbA[cur][ (4) % 4][v + 4] = r1[v]; } } { const uint nrq = (qbl4[5] + k04) + kkl * 4u; const fe4m3vec4 r0 = wgt_e4m3x4[nrq], r1 = wgt_e4m3x4[nrq + 1u]; for (int v = 0; v < 4; ++ v) { qfb[cur][5][v] = r0[v]; qfb[cur][5][v + 4] = r1[v]; } if ( (5) < 4) for (int v = 0; v < 4; ++ v) { qfbA[cur][ (5) % 4][v] = r0[v]; qfbA[cur][ (5) % 4][v + 4] = r1[v]; } } } if (0 == 0) { if ( ( ( (2) >> (0)) & 1) != 0) { const int ii = 0; if ( (0) < 4) qacc[ii][0] = coopMatMulAdd(qfbA[pp][ (0) % 4], qfaB[pp][ii], qacc[ii][0]); else qacc[ii][0] = coopMatMulAdd(qfa[pp][ii], qfb[pp][0], qacc[ii][0]); if ( (1) < 4) qacc[ii][1] = coopMatMulAdd(qfbA[pp][ (1) % 4], qfaB[pp][ii], qacc[ii][1]); else qacc[ii][1] = coopMatMulAdd(qfa[pp][ii], qfb[pp][1], qacc[ii][1]); if ( (2) < 4) qacc[ii][2] = coopMatMulAdd(qfbA[pp][ (2) % 4], qfaB[pp][ii], qacc[ii][2]); else qacc[ii][2] = coopMatMulAdd(qfa[pp][ii], qfb[pp][2], qacc[ii][2]); if ( (3) < 4) qacc[ii][3] = coopMatMulAdd(qfbA[pp][ (3) % 4], qfaB[pp][ii], qacc[ii][3]); else qacc[ii][3] = coopMatMulAdd(qfa[pp][ii], qfb[pp][3], qacc[ii][3]); if ( (4) < 4) qacc[ii][4] = coopMatMulAdd(qfbA[pp][ (4) % 4], qfaB[pp][ii], qacc[ii][4]); else qacc[ii][4] = coopMatMulAdd(qfa[pp][ii], qfb[pp][4], qacc[ii][4]); if ( (5) < 4) qacc[ii][5] = coopMatMulAdd(qfbA[pp][ (5) % 4], qfaB[pp][ii], qacc[ii][5]); else qacc[ii][5] = coopMatMulAdd(qfa[pp][ii], qfb[pp][5], qacc[ii][5]); } if ( ( ( (2) >> (1)) & 1) != 0) { const int ii = 1; if ( (0) < 4) qacc[ii][0] = coopMatMulAdd(qfbA[pp][ (0) % 4], qfaB[pp][ii], qacc[ii][0]); else qacc[ii][0] = coopMatMulAdd(qfa[pp][ii], qfb[pp][0], qacc[ii][0]); if ( (1) < 4) qacc[ii][1] = coopMatMulAdd(qfbA[pp][ (1) % 4], qfaB[pp][ii], qacc[ii][1]); else qacc[ii][1] = coopMatMulAdd(qfa[pp][ii], qfb[pp][1], qacc[ii][1]); if ( (2) < 4) qacc[ii][2] = coopMatMulAdd(qfbA[pp][ (2) % 4], qfaB[pp][ii], qacc[ii][2]); else qacc[ii][2] = coopMatMulAdd(qfa[pp][ii], qfb[pp][2], qacc[ii][2]); if ( (3) < 4) qacc[ii][3] = coopMatMulAdd(qfbA[pp][ (3) % 4], qfaB[pp][ii], qacc[ii][3]); else qacc[ii][3] = coopMatMulAdd(qfa[pp][ii], qfb[pp][3], qacc[ii][3]); if ( (4) < 4) qacc[ii][4] = coopMatMulAdd(qfbA[pp][ (4) % 4], qfaB[pp][ii], qacc[ii][4]); else qacc[ii][4] = coopMatMulAdd(qfa[pp][ii], qfb[pp][4], qacc[ii][4]); if ( (5) < 4) qacc[ii][5] = coopMatMulAdd(qfbA[pp][ (5) % 4], qfaB[pp][ii], qacc[ii][5]); else qacc[ii][5] = coopMatMulAdd(qfa[pp][ii], qfb[pp][5], qacc[ii][5]); } } if (0 > 0 && ( (7) + 1) % 0 == 0) { { const int ii = 0; { for (int c = 0; c < qacc[ii][0].length(); ++ c) qacc[ii][0][c] = nr_round_f16_e4m3(qacc[ii][0][c]); } { for (int c = 0; c < qacc[ii][1].length(); ++ c) qacc[ii][1][c] = nr_round_f16_e4m3(qacc[ii][1][c]); } { for (int c = 0; c < qacc[ii][2].length(); ++ c) qacc[ii][2][c] = nr_round_f16_e4m3(qacc[ii][2][c]); } { for (int c = 0; c < qacc[ii][3].length(); ++ c) qacc[ii][3][c] = nr_round_f16_e4m3(qacc[ii][3][c]); } { for (int c = 0; c < qacc[ii][4].length(); ++ c) qacc[ii][4][c] = nr_round_f16_e4m3(qacc[ii][4][c]); } { for (int c = 0; c < qacc[ii][5].length(); ++ c) qacc[ii][5][c] = nr_round_f16_e4m3(qacc[ii][5][c]); } } { const int ii = 1; { for (int c = 0; c < qacc[ii][0].length(); ++ c) qacc[ii][0][c] = nr_round_f16_e4m3(qacc[ii][0][c]); } { for (int c = 0; c < qacc[ii][1].length(); ++ c) qacc[ii][1][c] = nr_round_f16_e4m3(qacc[ii][1][c]); } { for (int c = 0; c < qacc[ii][2].length(); ++ c) qacc[ii][2][c] = nr_round_f16_e4m3(qacc[ii][2][c]); } { for (int c = 0; c < qacc[ii][3].length(); ++ c) qacc[ii][3][c] = nr_round_f16_e4m3(qacc[ii][3][c]); } { for (int c = 0; c < qacc[ii][4].length(); ++ c) qacc[ii][4][c] = nr_round_f16_e4m3(qacc[ii][4][c]); } { for (int c = 0; c < qacc[ii][5].length(); ++ c) qacc[ii][5][c] = nr_round_f16_e4m3(qacc[ii][5][c]); } } } } }
#line 1 "D:/nr-work-20261011/_mochi/DLSSNR-AMD-main/windows/shaders/rdna4/include/attn_qkv_epi.glsl"










            for (int i = 0; i < 2; ++ i) {
                           coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > vfr0, vfr1, qf0, qf1, kf0, kf1;

                [[dont_flatten]] if ( ( ( ( (2) >> (i)) & 1) == 0) || nr_tile_oob(mtok0 / 16u + uint(i))) {



                    const f16vec2 zscale = f16vec2(float16_t(wgt_f32[pc.s_off + h]), float16_t(1.0));
                    precise f16vec2 zs = f16vec2(0.0hf) * zscale;
                    const fe4m3vec2 zq = nr_attn_quant(zs), zv = nr_attn_quant(f16vec2(0.0hf));
                    for (int cc = 0; cc < 8; ++ cc) {
                        qf0[cc] = zq.x; qf1[cc] = zq.x; kf0[cc] = zq.y; kf1[cc] = zq.y;
                        vfr0[cc] = zv.x; vfr1[cc] = zv.y;
                    }
                } else {
                    for (int cc = 0; cc < 8; ++ cc) {
                        const fe4m3vec2 v = nr_attn_quant(f16vec2(qacc[i][4][cc], qacc[i][5][cc]));
                        vfr0[cc] = v.x; vfr1[cc] = v.y;
                    }
                    f16vec2 qk0[8], qk1[8];
                    precise f16vec2 t[8];
                    for (int c = 0; c < 8; ++ c) {
                        qk0[c] = f16vec2(float16_t(qacc[i][0][c]), float16_t(qacc[i][2][c]));
                        qk1[c] = f16vec2(float16_t(qacc[i][1][c]), float16_t(qacc[i][3][c]));
                        precise f16vec2 sq0 = qk0[c] * qk0[c], sq1 = qk1[c] * qk1[c];
                        precise f16vec2 sum = sq0 + sq1;
                        t[c] = sum + unpackFloat2x16(subgroupShuffleXor(packFloat2x16(sum), 16u));
                    }
                    precise f16vec2 u0 = t[0] + t[4], u1 = t[1] + t[5], u2 = t[2] + t[6], u3 = t[3] + t[7];
                    precise f16vec2 v0 = u0 + u2, v1 = u1 + u3;
                    precise f16vec2 w = v0 + v1;
                    const f16vec2 norm = f16vec2(
                             float16_t(inversesqrt(float(max(w.x, float16_t(0.000062))))),
                             float16_t(inversesqrt(float(max(w.y, float16_t(0.000062))))));
                    const f16vec2 scale = f16vec2(float16_t(wgt_f32[pc.s_off + h]), float16_t(1.0));
                    for (int c = 0; c < 8; ++ c) {
                        precise f16vec2 n0 = qk0[c] * norm, n1 = qk1[c] * norm;
                        precise f16vec2 scaled0 = n0 * scale, scaled1 = n1 * scale;
                        const fe4m3vec2 q0 = nr_attn_quant(scaled0), q1 = nr_attn_quant(scaled1);
                        qf0[c] = q0.x; kf0[c] = q0.y; qf1[c] = q1.x; kf1[c] = q1.y;
                    }
                }

                const uint tb = mtok0 + uint(i) * 16u;
                                                                               coopMatStore(qf0, lds_q, (qb + tb * uint( (32 + 0))), (uint( (32 + 0))), gl_CooperativeMatrixLayoutColumnMajor);
                                                                                     coopMatStore(qf1, lds_q, (qb + tb * uint( (32 + 0)) + 16u), (uint( (32 + 0))), gl_CooperativeMatrixLayoutColumnMajor);
                                                                               coopMatStore(kf0, lds_k, (qb + tb * uint( (32 + 0))), (uint( (32 + 0))), gl_CooperativeMatrixLayoutColumnMajor);
                                                                                     coopMatStore(kf1, lds_k, (qb + tb * uint( (32 + 0)) + 16u), (uint( (32 + 0))), gl_CooperativeMatrixLayoutColumnMajor);
                                                                                 coopMatStore(vfr0, lds_v, (vb + ( (0u) * uint( (64 + 0)) + (tb))), (uint( (64 + 0))), gl_CooperativeMatrixLayoutColumnMajor);
                                                                                  coopMatStore(vfr1, lds_v, (vb + ( (16u) * uint( (64 + 0)) + (tb))), (uint( (64 + 0))), gl_CooperativeMatrixLayoutColumnMajor);
            }
#line 1040 "D:\nr-work-20261011\_mochi\DLSSNR-AMD-main\windows\shaders\rdna4\attn.comp"

            } else {

#line 1 "D:/nr-work-20261011/_mochi/DLSSNR-AMD-main/windows/shaders/rdna4/include/attn_qkv_epi.glsl"










            for (int i = 0; i < 2; ++ i) {
                           coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > vfr0, vfr1, qf0, qf1, kf0, kf1;

                [[dont_flatten]] if ( ( ( ( (0) >> (i)) & 1) == 0) || nr_tile_oob(mtok0 / 16u + uint(i))) {



                    const f16vec2 zscale = f16vec2(float16_t(wgt_f32[pc.s_off + h]), float16_t(1.0));
                    precise f16vec2 zs = f16vec2(0.0hf) * zscale;
                    const fe4m3vec2 zq = nr_attn_quant(zs), zv = nr_attn_quant(f16vec2(0.0hf));
                    for (int cc = 0; cc < 8; ++ cc) {
                        qf0[cc] = zq.x; qf1[cc] = zq.x; kf0[cc] = zq.y; kf1[cc] = zq.y;
                        vfr0[cc] = zv.x; vfr1[cc] = zv.y;
                    }
                } else {
                    for (int cc = 0; cc < 8; ++ cc) {
                        const fe4m3vec2 v = nr_attn_quant(f16vec2(qacc[i][4][cc], qacc[i][5][cc]));
                        vfr0[cc] = v.x; vfr1[cc] = v.y;
                    }
                    f16vec2 qk0[8], qk1[8];
                    precise f16vec2 t[8];
                    for (int c = 0; c < 8; ++ c) {
                        qk0[c] = f16vec2(float16_t(qacc[i][0][c]), float16_t(qacc[i][2][c]));
                        qk1[c] = f16vec2(float16_t(qacc[i][1][c]), float16_t(qacc[i][3][c]));
                        precise f16vec2 sq0 = qk0[c] * qk0[c], sq1 = qk1[c] * qk1[c];
                        precise f16vec2 sum = sq0 + sq1;
                        t[c] = sum + unpackFloat2x16(subgroupShuffleXor(packFloat2x16(sum), 16u));
                    }
                    precise f16vec2 u0 = t[0] + t[4], u1 = t[1] + t[5], u2 = t[2] + t[6], u3 = t[3] + t[7];
                    precise f16vec2 v0 = u0 + u2, v1 = u1 + u3;
                    precise f16vec2 w = v0 + v1;
                    const f16vec2 norm = f16vec2(
                             float16_t(inversesqrt(float(max(w.x, float16_t(0.000062))))),
                             float16_t(inversesqrt(float(max(w.y, float16_t(0.000062))))));
                    const f16vec2 scale = f16vec2(float16_t(wgt_f32[pc.s_off + h]), float16_t(1.0));
                    for (int c = 0; c < 8; ++ c) {
                        precise f16vec2 n0 = qk0[c] * norm, n1 = qk1[c] * norm;
                        precise f16vec2 scaled0 = n0 * scale, scaled1 = n1 * scale;
                        const fe4m3vec2 q0 = nr_attn_quant(scaled0), q1 = nr_attn_quant(scaled1);
                        qf0[c] = q0.x; kf0[c] = q0.y; qf1[c] = q1.x; kf1[c] = q1.y;
                    }
                }

                const uint tb = mtok0 + uint(i) * 16u;
                                                                               coopMatStore(qf0, lds_q, (qb + tb * uint( (32 + 0))), (uint( (32 + 0))), gl_CooperativeMatrixLayoutColumnMajor);
                                                                                     coopMatStore(qf1, lds_q, (qb + tb * uint( (32 + 0)) + 16u), (uint( (32 + 0))), gl_CooperativeMatrixLayoutColumnMajor);
                                                                               coopMatStore(kf0, lds_k, (qb + tb * uint( (32 + 0))), (uint( (32 + 0))), gl_CooperativeMatrixLayoutColumnMajor);
                                                                                     coopMatStore(kf1, lds_k, (qb + tb * uint( (32 + 0)) + 16u), (uint( (32 + 0))), gl_CooperativeMatrixLayoutColumnMajor);
                                                                                 coopMatStore(vfr0, lds_v, (vb + ( (0u) * uint( (64 + 0)) + (tb))), (uint( (64 + 0))), gl_CooperativeMatrixLayoutColumnMajor);
                                                                                  coopMatStore(vfr1, lds_v, (vb + ( (16u) * uint( (64 + 0)) + (tb))), (uint( (64 + 0))), gl_CooperativeMatrixLayoutColumnMajor);
            }
#line 1044 "D:\nr-work-20261011\_mochi\DLSSNR-AMD-main\windows\shaders\rdna4\attn.comp"

            }



































































































































































        }

                  barrier();







































        for (uint i0 = i0beg; i0 < uint(64); i0 += i0inc) {




                      coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > lg[4];









            for (int n = 0; n < 4; ++ n) lg[n] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0);

            for (uint d = 0u; d < uint(32); d += 16u) {
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > qf;
                                                                           coopMatLoad(qf, lds_q, (qb + i0 * uint( (32 + 0)) + d), (uint( (32 + 0))), gl_CooperativeMatrixLayoutColumnMajor);
                for (int n = 0; n < 4; ++ n) {
                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > kf;

                                         coopMatLoad(kf, lds_k, (qb + uint(n) * 16u * uint( (32 + 0)) + d), (uint( (32 + 0))), gl_CooperativeMatrixLayoutRowMajor);
                                        lg[n] = coopMatMulAdd(kf, qf, lg[n]);
                }
            }
            float den[8];
            for (int c = 0; c < 8; ++ c) den[c] = 0.0;

            for (int n = 0; n < 4; ++ n)
                for (int c = 0; c < 8; c += 2) {
                    const uint query = i0 + lane % 16u;
                    const uint key = uint(n) * 16u + 8u * (lane / 16u) + uint(c);
                    const uint bo = pc.b_off + (h * 64u + query) * 64u + key;
                    const f16vec2 e2 = nr_swin_exp2(vec2(lg[n][c] + wgt_f32[bo],
                                                         lg[n][c + 1] + wgt_f32[bo + 1u]));
                    const float ex = float(e2.x), ey = float(e2.y);
                    lg[n][c] = ex; lg[n][c + 1] = ey;
                    den[c] += ex; den[c + 1] += ey;
                }
            if (false)

            for (int n = 0; n < 4; ++ n)
                for (int c = 0; c < 8; ++ c) {



                    const uint query = i0 + lane % 16u;
                    const uint key = uint(n) * 16u + 8u * (lane / 16u) + uint(c);
                    const float ex = nr_fast_exp(lg[n][c]
                        + wgt_f32[pc.b_off + (h * 64u + query) * 64u + key]);

                    lg[n][c] = ex;
                    den[c] += ex;
                }
            precise float sum = ( (den[0] + den[1]) + (den[2] + den[3]))
                              + ( (den[4] + den[5]) + (den[6] + den[7]));
            sum = sum + subgroupShuffleXor(sum, 16u);
            const float inv = 1.0 / max(sum, float(6.103515625e-05));
                    coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > pf[4];
            for (int n = 0; n < 4; ++ n)
                for (int c = 0; c < 8; ++ c)
                    pf[n][c] = floate4m3_t(float16_t(lg[n][c] * inv));
            for (uint n = 0u; n < 2u; ++ n) {
                          coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > ctx = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0);
                for (uint j = 0u; j < 4u; ++ j) {
                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > vf;
                                                                                      coopMatLoad(vf, lds_v, (vb + ( (n * 16u) * uint( (64 + 0)) + (j * 16u))), (uint( (64 + 0))), gl_CooperativeMatrixLayoutRowMajor);
                                         ctx = coopMatMulAdd(vf, pf[j], ctx);
                }
                           coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > result;

                for (int c = 0; c < 8; c += 2) {
                    const fe4m3vec2 q = nr_attn_quant(f16vec2(ctx[c], ctx[c + 1]));
                    result[c] = q.x; result[c + 1] = q.y;
                }





                if (! nr_tile_oob(i0 / 16u))

                                                                                    coopMatStore(result, act_e4m3, (pc.o_off + nr_tile_base(i0 / 16u) + (h * 2u + n) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);




            }
        }







































































































































































































































                  barrier();
    }
    }

                        { if (nr_tc_sig != 0xFFFFFFFFu) { memoryBarrier(gl_ScopeDevice, gl_StorageSemanticsBuffer, gl_SemanticsRelease); barrier(); if (gl_LocalInvocationIndex == 0u) atomicAdd(nr_tc_u[nr_tc_sig + uint(win)], 1u, gl_ScopeDevice, gl_StorageSemanticsBuffer, gl_SemanticsRelease); } }
                                           if (pc.C == 0u) { const uint nr_oi = (gl_WorkGroupID.x * 131u + gl_LocalInvocationIndex) % uint( (3072) / 4); nr_occ_pad[nr_oi] = nr_oi; barrier(); if (nr_occ_pad[ (nr_oi + 1u) % uint( (3072) / 4)] == 5u) act_f32[0] = 0.0; }

}

