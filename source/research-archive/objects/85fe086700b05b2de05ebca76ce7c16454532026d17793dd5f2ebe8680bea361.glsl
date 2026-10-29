#version 460
#extension GL_GOOGLE_include_directive : require
#extension GL_EXT_shader_explicit_arithmetic_types_int8 : require
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





















#line 5 "D:\nr-work-20261011\_mochi\DLSSNR-AMD-main\windows\shaders\rdna4\vit_attn.comp"
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










































































#line 6 "D:\nr-work-20261011\_mochi\DLSSNR-AMD-main\windows\shaders\rdna4\vit_attn.comp"


















layout(set = 0, binding = 0, std430) buffer ActE4M3 { floate4m3_t act_e4m3[]; };


layout(set = 0, binding = 0, std430) buffer ActE4M3v { uint act_v4[]; };



























layout(set = 0, binding = 1, std430) readonly buffer WgtF32 { float wgt_f32[]; };













layout(set = 0, binding = 2, std430) buffer ActE4M3x4 { fe4m3vec4 act_x4[]; };




layout(set = 0, binding = 2, std430) readonly buffer ActE4M3u { uint act_u2[]; };



#line 1 "D:/nr-work-20261011/_mochi/DLSSNR-AMD-main/windows/shaders/rdna4/include/nr_chain.glsl"

















































































































































































#line 79 "D:\nr-work-20261011\_mochi\DLSSNR-AMD-main\windows\shaders\rdna4\vit_attn.comp"
 layout(push_constant) uniform Push {
    uint x_off;
    uint o_off;
    uint tokens;
    uint s_off;
    uint mode;
    uint act_lo, act_hi;


} pc;

uint nr_at(uint base, uint token, uint ch, uint C) {
    return base + ( (token / 16u) * (C / 16u) + ch / 16u) * 256u
         + (token % 16u) * 16u + ch % 16u;
}















uint nr_at16(uint base, uint token, uint ch, uint C) {
    return base + token * C + (ch << 4u);
}
























#extension GL_EXT_shader_explicit_arithmetic_types_int16 : require

f16vec2 nr_vit_exp2(vec2 x) {

    const f16vec2 y0 = fma(f16vec2(x), f16vec2(float16_t(0.08953857421875)), f16vec2(float16_t(1.708984375)));
    const i16vec2 yb = min(max(float16BitsToInt16(y0), i16vec2(int16_t(0x3DC2))), i16vec2(int16_t(0x3FE9)));
    return unpackFloat2x16( (pack32(u16vec2(yb)) << 4u) + 0x3FFC4000u);









}









uint nr_out_ch(uint head, uint d) {
    return(d < (1024 / 32) / 2u) ? head * ( (1024 / 32) / 2u) + d
                            : uint(1024) / 2u + head * ( (1024 / 32) / 2u) + (d - (1024 / 32) / 2u);
}



























































































































































#extension GL_EXT_shader_explicit_arithmetic_types_int8 : require













































layout(local_size_x = (32 * 1)) in;








































shared float lds_qs[32];
shared float lds_ki[64];

#line 1 "D:/nr-work-20261011/_mochi/DLSSNR-AMD-main/windows/shaders/rdna4/include/nr_prof.glsl"















































#line 412 "D:\nr-work-20261011\_mochi\DLSSNR-AMD-main\windows\shaders\rdna4\vit_attn.comp"
 void main() {



    const uint q0 = gl_WorkGroupID.x * uint(32);
    const uint head = gl_WorkGroupID.y;
    const uint lane = gl_LocalInvocationID.x;
    if (q0 >= pc.tokens) { return; }

    const uint qbase = head * uint( (1024 / 32));
    const uint kbase = uint(1024) + qbase;
    const uint vbase = 2u * uint(1024) + qbase;
    const uint X3 = 3u * uint(1024);
    const bool norm = (pc.mode & 1u) != 0u;


    const uint jlast = (pc.tokens - 1u) & ~ 15u;
    const float ps = ( (pc.mode & 8u) != 0u) ? 256.0f : 1.0f;
























    const uint wave = lane / 32u, qb0 = wave * 16u * uint( (32 / (16 * 1)));
    const uint sl = gl_SubgroupInvocationID;





    const uint row0 = 8u * (sl / 16u), col = sl % 16u;
              coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > ctx[ (32 / (16 * 1))][2];
    for (int b = 0; b < (32 / (16 * 1)); ++ b) { ctx[b][0] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); ctx[b][1] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }







            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > qfr[ (32 / (16 * 1))][2];
    for (uint b = 0u; b < uint( (32 / (16 * 1))); ++ b)
        for (uint d = 0u; d < 2u; ++ d) {


                                                                                                 do { const uint nr_la = ( (nr_at16(pc.x_off, min(q0 + qb0 + b * 16u, jlast), qbase + d * 16u, X3)) + (gl_SubgroupInvocationID % 16u) * (16u) + (gl_SubgroupInvocationID / 16u) * 8u) / 4u; const u8vec4 nr_b0 = unpack8(act_v4[nr_la]), nr_b1 = unpack8(act_v4[nr_la + 1u]); for (int nr_i = 0; nr_i < 4; ++ nr_i) { qfr[b][d][nr_i] = uintBitsToFloate4m3EXT(nr_b0[nr_i]); qfr[b][d][nr_i + 4] = uintBitsToFloate4m3EXT(nr_b1[nr_i]); } } while (false);






        }
    f16vec2 part[ (32 / (16 * 1))][4];
    float den[ (32 / (16 * 1))];
    for (int b = 0; b < (32 / (16 * 1)); ++ b) den[b] = 0.0;



    const uint vkr = (sl & 3u) | ( (sl & 4u) << 1u) | ( (sl & 8u) >> 1u);
    const uint vkl4 = (vkr * 16u + (sl >> 4u) * 8u) >> 2;





    for (uint j0 = 0u; j0 < pc.tokens; j0 += uint(64)) {



















        if (j0 + uint(64) <= pc.tokens) {

            const uint kcb = nr_at16(pc.x_off, j0, kbase, X3), vcb = nr_at16(pc.x_off, j0, vbase, X3);


            const uint kc4 = (kcb >> 2) + vkl4;


#line 1 "D:/nr-work-20261011/_mochi/DLSSNR-AMD-main/windows/shaders/rdna4/include/vit_attn_vt_chunk.glsl"









        for (uint kb = 0u; kb < uint(64); kb += 16u) {

                    coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > kfr[2];
            for (uint d = 0u; d < 2u; ++ d) {

                {
                    const uint nrk = kc4 + kb * (X3 >> 2) + d * 64u;
                    const fe4m3vec4 r0 = uintBitsToFloate4m3EXT(unpack8(act_u2[nrk])), r1 = uintBitsToFloate4m3EXT(unpack8(act_u2[nrk + 1u]));
                    for (int v = 0; v < 4; ++ v) { kfr[d][v] = r0[v]; kfr[d][v + 4] = r1[v]; }
                }









            }




                    coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > vf[2];
            for (uint n = 0u; n < 2u; ++ n)

                                                                      coopMatLoad(vf[n], act_v4, (vcb + kb * X3 + n * 256u) / 4u, (16u) / 4u, gl_CooperativeMatrixLayoutColumnMajor);





            for (uint b = 0u; b < uint( (32 / (16 * 1))); ++ b) {
                          coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > lg = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0);
                for (uint d = 0u; d < 2u; ++ d) lg = coopMatMulAdd(kfr[d], qfr[b][d], lg);








                            coopmat < float16_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > ph;

                f16vec2 pv[4];
                for (int c = 0; c < lg.length(); c += 2) {




                    vec2 a = vec2(float(lg[c]), float(lg[c + 1]));










                    f16vec2 pp = nr_vit_exp2(a);




                    pv[c >> 1] = pp;




                    ph[c] = pp.x; ph[c + 1] = pp.y;

                }

























                {
                    const f16vec2 pa = pv[0] + pv[2], pz = pv[1] + pv[3];
                    part[b][0] = (kb == 0u) ? pa : part[b][0] + pa;
                    part[b][1] = (kb == 0u) ? pz : part[b][1] + pz;
                }
                if (kb + 16u == uint(64)) {
                    const bool lo = sl < 16u;
                    const f16vec2 o0 = unpackFloat2x16(subgroupShuffleXor(packFloat2x16(part[b][0]), 16u));
                    const f16vec2 o1 = unpackFloat2x16(subgroupShuffleXor(packFloat2x16(part[b][1]), 16u));
                    const f16vec2 p0 = lo ? part[b][0] : o0, p1 = lo ? part[b][1] : o1;
                    const f16vec2 p2 = lo ? o0 : part[b][0], p3 = lo ? o1 : part[b][1];
                    const f16vec2 s = ( (p0 + p1) + p2) + p3;
                    den[b] = float(float16_t(float16_t(den[b]) + float16_t(s.x + s.y)));
                }




















                           coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > pe = coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (ph);
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > pf;

                {


                    const bool lo = sl < 16u;
                    const uint d0 = pack32(floate4m3BitsToUintEXT(fe4m3vec4(pe[0], pe[1], pe[2], pe[3])));
                    const uint d1 = pack32(floate4m3BitsToUintEXT(fe4m3vec4(pe[4], pe[5], pe[6], pe[7])));
                    const uint x = subgroupShuffleXor(lo ? d1 : d0, 16u);
                    const fe4m3vec4 n0 = uintBitsToFloate4m3EXT(unpack8(lo ? d0 : x));
                    const fe4m3vec4 n1 = uintBitsToFloate4m3EXT(unpack8(lo ? x : d1));
                    for (int c = 0; c < 4; ++ c) { pf[c] = n0[c]; pf[c + 4] = n1[c]; }
                }




                for (uint n = 0u; n < 2u; ++ n) {
                                               ctx[b][n] = coopMatMulAdd(vf[n], pf, ctx[b][n]);





                }
            }
        }
#line 526 "D:\nr-work-20261011\_mochi\DLSSNR-AMD-main\windows\shaders\rdna4\vit_attn.comp"

        } else {

#line 1 "D:/nr-work-20261011/_mochi/DLSSNR-AMD-main/windows/shaders/rdna4/include/vit_attn_vt_chunk.glsl"









        for (uint kb = 0u; kb < uint(64); kb += 16u) {

                    coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > kfr[2];
            for (uint d = 0u; d < 2u; ++ d) {













                                                                                              do { const uint nr_la = ( (nr_at16(pc.x_off, min(j0 + kb, jlast), kbase + d * 16u, X3)) + (gl_SubgroupInvocationID % 16u) * (16u) + (gl_SubgroupInvocationID / 16u) * 8u) / 4u; const u8vec4 nr_b0 = unpack8(act_v4[nr_la]), nr_b1 = unpack8(act_v4[nr_la + 1u]); for (int nr_i = 0; nr_i < 4; ++ nr_i) { kfr[d][nr_i] = uintBitsToFloate4m3EXT(nr_b0[nr_i]); kfr[d][nr_i + 4] = uintBitsToFloate4m3EXT(nr_b1[nr_i]); } } while (false);

            }




                    coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > vf[2];
            for (uint n = 0u; n < 2u; ++ n)





                                                               coopMatLoad(vf[n], act_v4, (nr_at16(pc.x_off, min(j0 + kb, jlast), vbase + n * 16u, X3)) / 4u, (16u) / 4u, gl_CooperativeMatrixLayoutColumnMajor);

            for (uint b = 0u; b < uint( (32 / (16 * 1))); ++ b) {
                          coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > lg = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0);
                for (uint d = 0u; d < 2u; ++ d) lg = coopMatMulAdd(kfr[d], qfr[b][d], lg);








                            coopmat < float16_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > ph;

                f16vec2 pv[4];
                for (int c = 0; c < lg.length(); c += 2) {




                    vec2 a = vec2(float(lg[c]), float(lg[c + 1]));








                    if (j0 + kb >= pc.tokens) a = vec2(0.0);

                    f16vec2 pp = nr_vit_exp2(a);




                    pv[c >> 1] = pp;

                    const float16_t kin = float16_t(j0 + kb < pc.tokens ? 1.0 : 0.0);
                    ph[c] = pp.x * kin; ph[c + 1] = pp.y * kin;



                }








































                for (int c = 0; c < lg.length(); c += 2) {
                    const f16vec2 pv2 = pv[c >> 1];
                    const f16vec2 pair = pv2 +
                        unpackFloat2x16(subgroupShuffleXor(packFloat2x16(pv2), 16u));
                    part[b][c >> 1] = (kb == 0u) ? pair : part[b][c >> 1] + pair;
                }
                if (kb + 16u == uint(64)) {
                    const f16vec2 s = ( (part[b][0] + part[b][1]) + part[b][2]) + part[b][3];
                    den[b] = float(float16_t(float16_t(den[b]) + float16_t(s.x + s.y)));
                }









                           coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > pe = coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (ph);
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > pf;













                for (int c = 0; c < 8; ++ c) pf[c] = pe[c];


                for (uint n = 0u; n < 2u; ++ n) {
                                               ctx[b][n] = coopMatMulAdd(vf[n], pf, ctx[b][n]);





                }
            }
        }
#line 530 "D:\nr-work-20261011\_mochi\DLSSNR-AMD-main\windows\shaders\rdna4\vit_attn.comp"

        }





    }



    const uint pad_keys = ( (pc.tokens + uint(64) - 1u) / uint(64)) * uint(64) - pc.tokens;
    const float16_t padding = float16_t(float(pad_keys) * nr_vit_exp(0.0));
    for (uint b = 0u; b < uint( (32 / (16 * 1))); ++ b)
        den[b] = float(float16_t(float16_t(den[b]) - padding));

    const float floor_l = 6.198883056640625e-05
                        * ( ( (pc.mode & 12u) == 12u) ? 256.0f : 1.0f);



    for (uint b = 0u; b < uint( (32 / (16 * 1))); ++ b) {
        const uint q = q0 + qb0 + b * 16u + col;
        if (q >= pc.tokens) continue;
        const float16_t inv = float16_t(1.0 / max(den[b], floor_l));


        {
            for (uint n = 0u; n < 2u; ++ n) {
                      floate4m3_t qv[8];
                for (int c = 0; c < 8; ++ c)
                    qv[c] = nr_quant_e4m3(float16_t(float16_t(ctx[b][n][c]) * inv));
                const uint o4 = nr_at(pc.o_off, q, qbase + n * 16u + row0, uint(1024)) >> 2;
                act_x4[o4] = fe4m3vec4(qv[0], qv[1], qv[2], qv[3]);
                act_x4[o4 + 1u] = fe4m3vec4(qv[4], qv[5], qv[6], qv[7]);
            }
            continue;
        }

        for (uint n = 0u; n < 2u; ++ n)
            for (int c = 0; c < ctx[b][n].length(); ++ c) {
                const uint d0 = n * 16u + row0 + uint(c);
                const uint oc = ( (pc.mode & 2u) != 0u) ? nr_out_ch(head, d0) : qbase + d0;
                act_e4m3[nr_at(pc.o_off, q, oc, uint(1024))] =





                    nr_quant_e4m3(float16_t(float16_t(ctx[b][n][c]) * inv));

            }
    }


































































































































































































































































































}

