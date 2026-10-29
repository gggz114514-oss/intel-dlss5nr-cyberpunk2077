#version 460
#extension GL_GOOGLE_include_directive : require
#extension GL_KHR_shader_subgroup_shuffle : require
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































































































































































































































































































































































































































      floate4m3_t nr_quant_e4m3(float v) {


    return floate4m3_t(clamp(v, - 448.0, 448.0) + v * 0.0);





}
      floate4m3_t nr_quant_e4m3(float16_t v) { return nr_quant_e4m3(float(v)); }









































































vec2 nr_e4m3_range(vec2 x) {
    return clamp(x, vec2(- 448.0), vec2(448.0)) + x * 0.0;
}

fe4m3vec2 nr_quant_pair(f16vec2 v) {



    return fe4m3vec2(nr_e4m3_range(vec2(v)));






}

















fe4m3vec2 nr_quant_pair32(vec2 x) {

    return fe4m3vec2(nr_e4m3_range(x));





}






fe4m3vec4 nr_quant_quad(f16vec2 a, f16vec2 b) {



    const vec4 x = vec4(vec2(a), vec2(b));
    return fe4m3vec4(clamp(x, vec4(- 448.0), vec4(448.0)) + x * 0.0);
}
fe4m3vec4 nr_quant_quad32(vec2 a, vec2 b) {



    const vec4 x = vec4(a, b);
    return fe4m3vec4(clamp(x, vec4(- 448.0), vec4(448.0)) + x * 0.0);
}












fe4m3vec4 nr_convert_quad(f16vec2 a, f16vec2 b) { return fe4m3vec4(f16vec4(a, b)); }
fe4m3vec4 nr_convert_quad(vec2 a, vec2 b) { return fe4m3vec4(vec4(a, b)); }











fe4m3vec2 nr_quant_pair_bare(f16vec2 v) { return fe4m3vec2(v); }

















fe4m3vec4 nr_quant4_h(f16vec4 v) {






    const vec4 x = vec4(v);
    return fe4m3vec4(clamp(x, vec4(- 448.0), vec4(448.0)) + x * 0.0);



}
fe4m3vec2 nr_quant2_h(f16vec2 v) {



    return fe4m3vec2(nr_quant_e4m3(v.x), nr_quant_e4m3(v.y));

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





















#line 164 "D:\nr-work-20261011\_mochi\DLSSNR-AMD-main\windows\shaders\rdna4\fswin_t.comp"
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

















f16vec2 nr_swin_exp_baked(vec2 x, vec2 bias) {











    const f16vec2 y = clamp(f16vec2(fma(x, vec2(0.044921875), bias)),
                         f16vec2(1.03125hf), f16vec2(1.5693359375hf));
    const uint h = packFloat2x16(y);

    return unpackFloat2x16( (h << 5u) + 0x7FF88000u);
}











     float16_t nr_swin_probability_sum(f16vec2 probability[4][4]) {
    f16vec2 part[4];
    { { const int c = 0;  {
        part[c] = f16vec2(0.0hf);
        { { const int j = 0;  {
            f16vec2 x = probability[j][c];

            part[c] = part[c] + x;





        } }{ const int j = 1;  {
            f16vec2 x = probability[j][c];

            part[c] = part[c] + x;





        } }{ const int j = 2;  {
            f16vec2 x = probability[j][c];

            part[c] = part[c] + x;





        } }{ const int j = 3;  {
            f16vec2 x = probability[j][c];

            part[c] = part[c] + x;





        } } }
    } }{ const int c = 1;  {
        part[c] = f16vec2(0.0hf);
        { { const int j = 0;  {
            f16vec2 x = probability[j][c];

            part[c] = part[c] + x;





        } }{ const int j = 1;  {
            f16vec2 x = probability[j][c];

            part[c] = part[c] + x;





        } }{ const int j = 2;  {
            f16vec2 x = probability[j][c];

            part[c] = part[c] + x;





        } }{ const int j = 3;  {
            f16vec2 x = probability[j][c];

            part[c] = part[c] + x;





        } } }
    } }{ const int c = 2;  {
        part[c] = f16vec2(0.0hf);
        { { const int j = 0;  {
            f16vec2 x = probability[j][c];

            part[c] = part[c] + x;





        } }{ const int j = 1;  {
            f16vec2 x = probability[j][c];

            part[c] = part[c] + x;





        } }{ const int j = 2;  {
            f16vec2 x = probability[j][c];

            part[c] = part[c] + x;





        } }{ const int j = 3;  {
            f16vec2 x = probability[j][c];

            part[c] = part[c] + x;





        } } }
    } }{ const int c = 3;  {
        part[c] = f16vec2(0.0hf);
        { { const int j = 0;  {
            f16vec2 x = probability[j][c];

            part[c] = part[c] + x;





        } }{ const int j = 1;  {
            f16vec2 x = probability[j][c];

            part[c] = part[c] + x;





        } }{ const int j = 2;  {
            f16vec2 x = probability[j][c];

            part[c] = part[c] + x;





        } }{ const int j = 3;  {
            f16vec2 x = probability[j][c];

            part[c] = part[c] + x;





        } } }
    } } }
    f16vec2 total = ( (part[0] + part[1]) + part[2]) + part[3];



    uint other = subgroupShuffleXor(packFloat2x16(total), 16u);
    total = total + unpackFloat2x16(other);

         float16_t sum = float16_t(total.x + total.y);
    return sum;
}



#line 165 "D:\nr-work-20261011\_mochi\DLSSNR-AMD-main\windows\shaders\rdna4\fswin_t.comp"






































































































































































































































































































































































































































































































































































































































































































































































































































































































































fe4m3vec2 nr_qscale_fast(vec2 value, float norm, float16_t scale) {







    return fe4m3vec2(value * (norm * float(scale)));



}
fe4m3vec2 nr_kscale_fast(vec2 value, float norm) {







    return fe4m3vec2(value * norm);



}


fe4m3vec4 nr_qscale_fast4(vec2 va, float na, float16_t sa, vec2 vb, float nb, float16_t sb) {



    return fe4m3vec4(vec4(va * (na * float(sa)), vb * (nb * float(sb))));




}
fe4m3vec4 nr_kscale_fast4(vec2 va, float na, vec2 vb, float nb) {



    return fe4m3vec4(vec4(va * na, vb * nb));




}

























































































































































































































































































































































layout(local_size_x = (32 * 4)) in;





















layout(set = 0, binding = 0, std430) buffer ActE4M3 { floate4m3_t act_e4m3[]; };








layout(set = 0, binding = 0, std430) buffer ActE4M3v { uint act_v4[]; };


































vec2 nr_e4f2_pick(vec4 v, int c) { return(c & 2) != 0 ? v.zw : v.xy; }


uint nr_e4m3x4_bits(fe4m3vec4 v) {
    return pack32(u8vec4(floate4m3BitsToUintEXT(v.x), floate4m3BitsToUintEXT(v.y),
                         floate4m3BitsToUintEXT(v.z), floate4m3BitsToUintEXT(v.w)));
}









layout(set = 0, binding = 1, std430) buffer ActF16 { float16_t act_f16[]; };
layout(set = 0, binding = 2, std430) readonly buffer WgtE4M3 { floate4m3_t wgt_e4m3[]; };
layout(set = 0, binding = 3, std430) readonly buffer WgtF32 { float wgt_f32[]; };






















layout(set = 0, binding = 2, std430) readonly buffer WgtE4M3w { uvec2 wgt_w8[]; };





layout(set = 0, binding = 4, std430) readonly buffer WgtF16 { float16_t wgt_f16[]; };






layout(set = 0, binding = 4, std430) readonly buffer WgtU32 { uint wgt_u32[]; };






















f16vec2 nr_residual_scale(uint off) {



    return f16vec2(wgt_f32[off], wgt_f32[off + 1u]);

}




layout(set = 0, binding = 4, std430) readonly buffer WExpandPair4 { fe4m3vec4 wexpand_pair4[]; };









layout(set = 0, binding = 4, std430) readonly buffer WExpandPairU { uvec2 wexpand_u2[]; };



















































































































































































































































































































































































































layout(push_constant) uniform Push {
    uint x_off, o_off, e_off, ct_off, qkv_off, op_off, b_off,
         rs_off, ars_off, s_off, rsd_off, ard_off,
         mid_off;

    uint tiles_x, tiles_y;
    int shift, shift_y;




































} pc;




















uint nr_tile_base(uint q) {




    int tx = 2 * int( (gl_WorkGroupID.x)) + pc.shift + int(q & 1u);
    int ty = 2 * int( (gl_WorkGroupID.y)) + pc.shift_y + int(q >> 1);
    tx = clamp(tx, 0, int(pc.tiles_x) - 1); ty = clamp(ty, 0, int(pc.tiles_y) - 1);
    return(uint(ty) * pc.tiles_x + uint(tx)) * uint(128 / 16) * 256u;

}
bool nr_tile_oob(uint q) {








    int tx = 2 * int( (gl_WorkGroupID.x)) + pc.shift + int(q & 1u);
    int ty = 2 * int( (gl_WorkGroupID.y)) + pc.shift_y + int(q >> 1);
    return tx < 0 || ty < 0 || tx >= int(pc.tiles_x) || ty >= int(pc.tiles_y);

}



















































































































































shared floate4m3_t lds_x[64 * 128];
shared floate4m3_t lds_y[64 * 128];











































































































#extension GL_EXT_control_flow_attributes : require









































float nr_act_horner(float x) {
    const float t = clamp(x, - 4.0, 4.0);
    const float u = fma(- 0.055908203125, abs(t), 0.447265625);
    return x * fma(t, u, 0.89453125);
}



















float nr_act_horner_b(float x) {
    const float t = clamp(x, - 4.0, 4.0);

    const float u = fma(abs(t), - 0.055908203125, 0.447265625);




    const float w = fma(u, t, 0.89453125);






    return x * w;

}
























float nr_act_pick(float x, int c) {
    return(bitCount(uint(c) & uint(0)) & 1) != 0 ? nr_act_horner_b(x) : nr_act_horner(x);
}


float nr_act(float x) {
    return nr_swin_act(x);
}


f16vec2 nr_act2(f16vec2 x) {
    return nr_swin_act2(x);
}







































































































float nr_fast_exp(float x) {
    return nr_swin_exp(x);
}































































































#line 1 "D:/nr-work-20261011/_mochi/DLSSNR-AMD-main/windows/shaders/rdna4/include/nr_prof.glsl"















































#line 2696 "D:\nr-work-20261011\_mochi\DLSSNR-AMD-main\windows\shaders\rdna4\fswin_t.comp"
 void main() {


















































    const uint tid = gl_LocalInvocationID.x, wave = ( (tid) / 32u), lane = tid % 32u;





























































































































































































































































































































































































































































































































































































#line 1 "D:/nr-work-20261011/_mochi/DLSSNR-AMD-main/windows/shaders/rdna4/include/fswin_body.glsl"





    const uint wbase = (gl_WorkGroupID.x) * uint(64 * 128);

    const uint tok0 = 0u;
    const int nrhw_h = int(wave);









    const uint nr_opaque = gl_WorkGroupID.z;








    const uint rbase = 8u * (lane / 16u);
























































































































































    uint tbase[ (64 / 16)];
    { { const int m = 0; 

        tbase[m] = pc.x_off + nr_tile_base( (tok0 + uint(m) * 16u) / 16u); }{ const int m = 1; 

        tbase[m] = pc.x_off + nr_tile_base( (tok0 + uint(m) * 16u) / 16u); }{ const int m = 2; 

        tbase[m] = pc.x_off + nr_tile_base( (tok0 + uint(m) * 16u) / 16u); }{ const int m = 3; 

        tbase[m] = pc.x_off + nr_tile_base( (tok0 + uint(m) * 16u) / 16u); } }













































    { { const int m = 0; 
        { { const int d = 0;  {
            const uint k = uint(nrhw_h * ( (128 / 4) / 16) + d);
                    coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > src;

























































                                                       coopMatLoad(src, act_v4, (tbase[m] + k * 256u) / 4u, (16u) / 4u, gl_CooperativeMatrixLayoutColumnMajor);

                       coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > dst;
            { { const int j = 0;  dst[j] = src[j]; }{ const int j = 1;  dst[j] = src[j]; }{ const int j = 2;  dst[j] = src[j]; }{ const int j = 3;  dst[j] = src[j]; }{ const int j = 4;  dst[j] = src[j]; }{ const int j = 5;  dst[j] = src[j]; }{ const int j = 6;  dst[j] = src[j]; }{ const int j = 7;  dst[j] = src[j]; } }


            if (nr_tile_oob(uint(m)))
                { { const int j = 0;  dst[j] = floate4m3_t(0.0); }{ const int j = 1;  dst[j] = floate4m3_t(0.0); }{ const int j = 2;  dst[j] = floate4m3_t(0.0); }{ const int j = 3;  dst[j] = floate4m3_t(0.0); }{ const int j = 4;  dst[j] = floate4m3_t(0.0); }{ const int j = 5;  dst[j] = floate4m3_t(0.0); }{ const int j = 6;  dst[j] = floate4m3_t(0.0); }{ const int j = 7;  dst[j] = floate4m3_t(0.0); } }

                                                                                        coopMatStore(dst, lds_x, ( (uint(m) * uint( (128 / 16)) + k) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);
        } }{ const int d = 1;  {
            const uint k = uint(nrhw_h * ( (128 / 4) / 16) + d);
                    coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > src;

























































                                                       coopMatLoad(src, act_v4, (tbase[m] + k * 256u) / 4u, (16u) / 4u, gl_CooperativeMatrixLayoutColumnMajor);

                       coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > dst;
            { { const int j = 0;  dst[j] = src[j]; }{ const int j = 1;  dst[j] = src[j]; }{ const int j = 2;  dst[j] = src[j]; }{ const int j = 3;  dst[j] = src[j]; }{ const int j = 4;  dst[j] = src[j]; }{ const int j = 5;  dst[j] = src[j]; }{ const int j = 6;  dst[j] = src[j]; }{ const int j = 7;  dst[j] = src[j]; } }


            if (nr_tile_oob(uint(m)))
                { { const int j = 0;  dst[j] = floate4m3_t(0.0); }{ const int j = 1;  dst[j] = floate4m3_t(0.0); }{ const int j = 2;  dst[j] = floate4m3_t(0.0); }{ const int j = 3;  dst[j] = floate4m3_t(0.0); }{ const int j = 4;  dst[j] = floate4m3_t(0.0); }{ const int j = 5;  dst[j] = floate4m3_t(0.0); }{ const int j = 6;  dst[j] = floate4m3_t(0.0); }{ const int j = 7;  dst[j] = floate4m3_t(0.0); } }

                                                                                        coopMatStore(dst, lds_x, ( (uint(m) * uint( (128 / 16)) + k) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);
        } } } }{ const int m = 1; 
        { { const int d = 0;  {
            const uint k = uint(nrhw_h * ( (128 / 4) / 16) + d);
                    coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > src;

























































                                                       coopMatLoad(src, act_v4, (tbase[m] + k * 256u) / 4u, (16u) / 4u, gl_CooperativeMatrixLayoutColumnMajor);

                       coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > dst;
            { { const int j = 0;  dst[j] = src[j]; }{ const int j = 1;  dst[j] = src[j]; }{ const int j = 2;  dst[j] = src[j]; }{ const int j = 3;  dst[j] = src[j]; }{ const int j = 4;  dst[j] = src[j]; }{ const int j = 5;  dst[j] = src[j]; }{ const int j = 6;  dst[j] = src[j]; }{ const int j = 7;  dst[j] = src[j]; } }


            if (nr_tile_oob(uint(m)))
                { { const int j = 0;  dst[j] = floate4m3_t(0.0); }{ const int j = 1;  dst[j] = floate4m3_t(0.0); }{ const int j = 2;  dst[j] = floate4m3_t(0.0); }{ const int j = 3;  dst[j] = floate4m3_t(0.0); }{ const int j = 4;  dst[j] = floate4m3_t(0.0); }{ const int j = 5;  dst[j] = floate4m3_t(0.0); }{ const int j = 6;  dst[j] = floate4m3_t(0.0); }{ const int j = 7;  dst[j] = floate4m3_t(0.0); } }

                                                                                        coopMatStore(dst, lds_x, ( (uint(m) * uint( (128 / 16)) + k) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);
        } }{ const int d = 1;  {
            const uint k = uint(nrhw_h * ( (128 / 4) / 16) + d);
                    coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > src;

























































                                                       coopMatLoad(src, act_v4, (tbase[m] + k * 256u) / 4u, (16u) / 4u, gl_CooperativeMatrixLayoutColumnMajor);

                       coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > dst;
            { { const int j = 0;  dst[j] = src[j]; }{ const int j = 1;  dst[j] = src[j]; }{ const int j = 2;  dst[j] = src[j]; }{ const int j = 3;  dst[j] = src[j]; }{ const int j = 4;  dst[j] = src[j]; }{ const int j = 5;  dst[j] = src[j]; }{ const int j = 6;  dst[j] = src[j]; }{ const int j = 7;  dst[j] = src[j]; } }


            if (nr_tile_oob(uint(m)))
                { { const int j = 0;  dst[j] = floate4m3_t(0.0); }{ const int j = 1;  dst[j] = floate4m3_t(0.0); }{ const int j = 2;  dst[j] = floate4m3_t(0.0); }{ const int j = 3;  dst[j] = floate4m3_t(0.0); }{ const int j = 4;  dst[j] = floate4m3_t(0.0); }{ const int j = 5;  dst[j] = floate4m3_t(0.0); }{ const int j = 6;  dst[j] = floate4m3_t(0.0); }{ const int j = 7;  dst[j] = floate4m3_t(0.0); } }

                                                                                        coopMatStore(dst, lds_x, ( (uint(m) * uint( (128 / 16)) + k) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);
        } } } }{ const int m = 2; 
        { { const int d = 0;  {
            const uint k = uint(nrhw_h * ( (128 / 4) / 16) + d);
                    coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > src;

























































                                                       coopMatLoad(src, act_v4, (tbase[m] + k * 256u) / 4u, (16u) / 4u, gl_CooperativeMatrixLayoutColumnMajor);

                       coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > dst;
            { { const int j = 0;  dst[j] = src[j]; }{ const int j = 1;  dst[j] = src[j]; }{ const int j = 2;  dst[j] = src[j]; }{ const int j = 3;  dst[j] = src[j]; }{ const int j = 4;  dst[j] = src[j]; }{ const int j = 5;  dst[j] = src[j]; }{ const int j = 6;  dst[j] = src[j]; }{ const int j = 7;  dst[j] = src[j]; } }


            if (nr_tile_oob(uint(m)))
                { { const int j = 0;  dst[j] = floate4m3_t(0.0); }{ const int j = 1;  dst[j] = floate4m3_t(0.0); }{ const int j = 2;  dst[j] = floate4m3_t(0.0); }{ const int j = 3;  dst[j] = floate4m3_t(0.0); }{ const int j = 4;  dst[j] = floate4m3_t(0.0); }{ const int j = 5;  dst[j] = floate4m3_t(0.0); }{ const int j = 6;  dst[j] = floate4m3_t(0.0); }{ const int j = 7;  dst[j] = floate4m3_t(0.0); } }

                                                                                        coopMatStore(dst, lds_x, ( (uint(m) * uint( (128 / 16)) + k) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);
        } }{ const int d = 1;  {
            const uint k = uint(nrhw_h * ( (128 / 4) / 16) + d);
                    coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > src;

























































                                                       coopMatLoad(src, act_v4, (tbase[m] + k * 256u) / 4u, (16u) / 4u, gl_CooperativeMatrixLayoutColumnMajor);

                       coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > dst;
            { { const int j = 0;  dst[j] = src[j]; }{ const int j = 1;  dst[j] = src[j]; }{ const int j = 2;  dst[j] = src[j]; }{ const int j = 3;  dst[j] = src[j]; }{ const int j = 4;  dst[j] = src[j]; }{ const int j = 5;  dst[j] = src[j]; }{ const int j = 6;  dst[j] = src[j]; }{ const int j = 7;  dst[j] = src[j]; } }


            if (nr_tile_oob(uint(m)))
                { { const int j = 0;  dst[j] = floate4m3_t(0.0); }{ const int j = 1;  dst[j] = floate4m3_t(0.0); }{ const int j = 2;  dst[j] = floate4m3_t(0.0); }{ const int j = 3;  dst[j] = floate4m3_t(0.0); }{ const int j = 4;  dst[j] = floate4m3_t(0.0); }{ const int j = 5;  dst[j] = floate4m3_t(0.0); }{ const int j = 6;  dst[j] = floate4m3_t(0.0); }{ const int j = 7;  dst[j] = floate4m3_t(0.0); } }

                                                                                        coopMatStore(dst, lds_x, ( (uint(m) * uint( (128 / 16)) + k) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);
        } } } }{ const int m = 3; 
        { { const int d = 0;  {
            const uint k = uint(nrhw_h * ( (128 / 4) / 16) + d);
                    coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > src;

























































                                                       coopMatLoad(src, act_v4, (tbase[m] + k * 256u) / 4u, (16u) / 4u, gl_CooperativeMatrixLayoutColumnMajor);

                       coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > dst;
            { { const int j = 0;  dst[j] = src[j]; }{ const int j = 1;  dst[j] = src[j]; }{ const int j = 2;  dst[j] = src[j]; }{ const int j = 3;  dst[j] = src[j]; }{ const int j = 4;  dst[j] = src[j]; }{ const int j = 5;  dst[j] = src[j]; }{ const int j = 6;  dst[j] = src[j]; }{ const int j = 7;  dst[j] = src[j]; } }


            if (nr_tile_oob(uint(m)))
                { { const int j = 0;  dst[j] = floate4m3_t(0.0); }{ const int j = 1;  dst[j] = floate4m3_t(0.0); }{ const int j = 2;  dst[j] = floate4m3_t(0.0); }{ const int j = 3;  dst[j] = floate4m3_t(0.0); }{ const int j = 4;  dst[j] = floate4m3_t(0.0); }{ const int j = 5;  dst[j] = floate4m3_t(0.0); }{ const int j = 6;  dst[j] = floate4m3_t(0.0); }{ const int j = 7;  dst[j] = floate4m3_t(0.0); } }

                                                                                        coopMatStore(dst, lds_x, ( (uint(m) * uint( (128 / 16)) + k) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);
        } }{ const int d = 1;  {
            const uint k = uint(nrhw_h * ( (128 / 4) / 16) + d);
                    coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > src;

























































                                                       coopMatLoad(src, act_v4, (tbase[m] + k * 256u) / 4u, (16u) / 4u, gl_CooperativeMatrixLayoutColumnMajor);

                       coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > dst;
            { { const int j = 0;  dst[j] = src[j]; }{ const int j = 1;  dst[j] = src[j]; }{ const int j = 2;  dst[j] = src[j]; }{ const int j = 3;  dst[j] = src[j]; }{ const int j = 4;  dst[j] = src[j]; }{ const int j = 5;  dst[j] = src[j]; }{ const int j = 6;  dst[j] = src[j]; }{ const int j = 7;  dst[j] = src[j]; } }


            if (nr_tile_oob(uint(m)))
                { { const int j = 0;  dst[j] = floate4m3_t(0.0); }{ const int j = 1;  dst[j] = floate4m3_t(0.0); }{ const int j = 2;  dst[j] = floate4m3_t(0.0); }{ const int j = 3;  dst[j] = floate4m3_t(0.0); }{ const int j = 4;  dst[j] = floate4m3_t(0.0); }{ const int j = 5;  dst[j] = floate4m3_t(0.0); }{ const int j = 6;  dst[j] = floate4m3_t(0.0); }{ const int j = 7;  dst[j] = floate4m3_t(0.0); } }

                                                                                        coopMatStore(dst, lds_x, ( (uint(m) * uint( (128 / 16)) + k) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);
        } } } } }
    barrier();
































































































































































































    {
        const int g = nrhw_h;




                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > eqg[ (64 / 16)][ ( ( (4 * 128) / 4) / 16)];













































































































        { { const int h = 0;  {
                  coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > a[4][ (64 / 16)];
            { { const int p = 0; 
                { { const int m = 0;  a[p][m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int m = 1;  a[p][m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int m = 2;  a[p][m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int m = 3;  a[p][m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); } } }{ const int p = 1; 
                { { const int m = 0;  a[p][m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int m = 1;  a[p][m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int m = 2;  a[p][m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int m = 3;  a[p][m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); } } }{ const int p = 2; 
                { { const int m = 0;  a[p][m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int m = 1;  a[p][m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int m = 2;  a[p][m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int m = 3;  a[p][m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); } } }{ const int p = 3; 
                { { const int m = 0;  a[p][m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int m = 1;  a[p][m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int m = 2;  a[p][m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int m = 3;  a[p][m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); } } } }
            { { const int k = 0;  {
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > xbk[ (64 / 16)];
                { { const int m = 0; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 1; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 2; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 3; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); } }




                { { const int p = 0;  {
                    const uint q = pc.e_off / 4u + uint( (g * ( ( (4 * 128) / 4) / 16) + h + p) / 2) * uint( (128 / 16)) * 128u
                        + uint(k) * 128u + lane * 4u;
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                    { { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 1;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 2;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 3;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); } }
                    { { const int m = 0;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 1;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 2;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 3;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); } }
                } }{ const int p = 2;  {
                    const uint q = pc.e_off / 4u + uint( (g * ( ( (4 * 128) / 4) / 16) + h + p) / 2) * uint( (128 / 16)) * 128u
                        + uint(k) * 128u + lane * 4u;
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                    { { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 1;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 2;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 3;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); } }
                    { { const int m = 0;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 1;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 2;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 3;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); } }
                } } }









                if (0 > 0 && (k + 1) % 0 == 0)
                    { { const int p = 0; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } }{ const int p = 1; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } }{ const int p = 2; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } }{ const int p = 3; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } } }
            } }{ const int k = 1;  {
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > xbk[ (64 / 16)];
                { { const int m = 0; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 1; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 2; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 3; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); } }




                { { const int p = 0;  {
                    const uint q = pc.e_off / 4u + uint( (g * ( ( (4 * 128) / 4) / 16) + h + p) / 2) * uint( (128 / 16)) * 128u
                        + uint(k) * 128u + lane * 4u;
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                    { { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 1;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 2;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 3;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); } }
                    { { const int m = 0;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 1;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 2;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 3;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); } }
                } }{ const int p = 2;  {
                    const uint q = pc.e_off / 4u + uint( (g * ( ( (4 * 128) / 4) / 16) + h + p) / 2) * uint( (128 / 16)) * 128u
                        + uint(k) * 128u + lane * 4u;
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                    { { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 1;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 2;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 3;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); } }
                    { { const int m = 0;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 1;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 2;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 3;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); } }
                } } }









                if (0 > 0 && (k + 1) % 0 == 0)
                    { { const int p = 0; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } }{ const int p = 1; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } }{ const int p = 2; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } }{ const int p = 3; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } } }
            } }{ const int k = 2;  {
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > xbk[ (64 / 16)];
                { { const int m = 0; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 1; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 2; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 3; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); } }




                { { const int p = 0;  {
                    const uint q = pc.e_off / 4u + uint( (g * ( ( (4 * 128) / 4) / 16) + h + p) / 2) * uint( (128 / 16)) * 128u
                        + uint(k) * 128u + lane * 4u;
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                    { { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 1;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 2;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 3;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); } }
                    { { const int m = 0;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 1;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 2;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 3;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); } }
                } }{ const int p = 2;  {
                    const uint q = pc.e_off / 4u + uint( (g * ( ( (4 * 128) / 4) / 16) + h + p) / 2) * uint( (128 / 16)) * 128u
                        + uint(k) * 128u + lane * 4u;
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                    { { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 1;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 2;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 3;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); } }
                    { { const int m = 0;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 1;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 2;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 3;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); } }
                } } }









                if (0 > 0 && (k + 1) % 0 == 0)
                    { { const int p = 0; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } }{ const int p = 1; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } }{ const int p = 2; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } }{ const int p = 3; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } } }
            } }{ const int k = 3;  {
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > xbk[ (64 / 16)];
                { { const int m = 0; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 1; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 2; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 3; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); } }




                { { const int p = 0;  {
                    const uint q = pc.e_off / 4u + uint( (g * ( ( (4 * 128) / 4) / 16) + h + p) / 2) * uint( (128 / 16)) * 128u
                        + uint(k) * 128u + lane * 4u;
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                    { { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 1;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 2;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 3;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); } }
                    { { const int m = 0;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 1;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 2;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 3;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); } }
                } }{ const int p = 2;  {
                    const uint q = pc.e_off / 4u + uint( (g * ( ( (4 * 128) / 4) / 16) + h + p) / 2) * uint( (128 / 16)) * 128u
                        + uint(k) * 128u + lane * 4u;
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                    { { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 1;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 2;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 3;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); } }
                    { { const int m = 0;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 1;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 2;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 3;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); } }
                } } }









                if (0 > 0 && (k + 1) % 0 == 0)
                    { { const int p = 0; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } }{ const int p = 1; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } }{ const int p = 2; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } }{ const int p = 3; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } } }
            } }{ const int k = 4;  {
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > xbk[ (64 / 16)];
                { { const int m = 0; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 1; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 2; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 3; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); } }




                { { const int p = 0;  {
                    const uint q = pc.e_off / 4u + uint( (g * ( ( (4 * 128) / 4) / 16) + h + p) / 2) * uint( (128 / 16)) * 128u
                        + uint(k) * 128u + lane * 4u;
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                    { { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 1;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 2;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 3;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); } }
                    { { const int m = 0;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 1;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 2;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 3;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); } }
                } }{ const int p = 2;  {
                    const uint q = pc.e_off / 4u + uint( (g * ( ( (4 * 128) / 4) / 16) + h + p) / 2) * uint( (128 / 16)) * 128u
                        + uint(k) * 128u + lane * 4u;
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                    { { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 1;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 2;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 3;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); } }
                    { { const int m = 0;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 1;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 2;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 3;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); } }
                } } }









                if (0 > 0 && (k + 1) % 0 == 0)
                    { { const int p = 0; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } }{ const int p = 1; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } }{ const int p = 2; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } }{ const int p = 3; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } } }
            } }{ const int k = 5;  {
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > xbk[ (64 / 16)];
                { { const int m = 0; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 1; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 2; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 3; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); } }




                { { const int p = 0;  {
                    const uint q = pc.e_off / 4u + uint( (g * ( ( (4 * 128) / 4) / 16) + h + p) / 2) * uint( (128 / 16)) * 128u
                        + uint(k) * 128u + lane * 4u;
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                    { { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 1;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 2;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 3;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); } }
                    { { const int m = 0;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 1;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 2;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 3;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); } }
                } }{ const int p = 2;  {
                    const uint q = pc.e_off / 4u + uint( (g * ( ( (4 * 128) / 4) / 16) + h + p) / 2) * uint( (128 / 16)) * 128u
                        + uint(k) * 128u + lane * 4u;
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                    { { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 1;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 2;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 3;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); } }
                    { { const int m = 0;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 1;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 2;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 3;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); } }
                } } }









                if (0 > 0 && (k + 1) % 0 == 0)
                    { { const int p = 0; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } }{ const int p = 1; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } }{ const int p = 2; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } }{ const int p = 3; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } } }
            } }{ const int k = 6;  {
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > xbk[ (64 / 16)];
                { { const int m = 0; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 1; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 2; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 3; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); } }




                { { const int p = 0;  {
                    const uint q = pc.e_off / 4u + uint( (g * ( ( (4 * 128) / 4) / 16) + h + p) / 2) * uint( (128 / 16)) * 128u
                        + uint(k) * 128u + lane * 4u;
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                    { { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 1;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 2;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 3;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); } }
                    { { const int m = 0;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 1;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 2;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 3;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); } }
                } }{ const int p = 2;  {
                    const uint q = pc.e_off / 4u + uint( (g * ( ( (4 * 128) / 4) / 16) + h + p) / 2) * uint( (128 / 16)) * 128u
                        + uint(k) * 128u + lane * 4u;
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                    { { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 1;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 2;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 3;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); } }
                    { { const int m = 0;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 1;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 2;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 3;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); } }
                } } }









                if (0 > 0 && (k + 1) % 0 == 0)
                    { { const int p = 0; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } }{ const int p = 1; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } }{ const int p = 2; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } }{ const int p = 3; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } } }
            } }{ const int k = 7;  {
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > xbk[ (64 / 16)];
                { { const int m = 0; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 1; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 2; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 3; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); } }




                { { const int p = 0;  {
                    const uint q = pc.e_off / 4u + uint( (g * ( ( (4 * 128) / 4) / 16) + h + p) / 2) * uint( (128 / 16)) * 128u
                        + uint(k) * 128u + lane * 4u;
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                    { { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 1;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 2;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 3;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); } }
                    { { const int m = 0;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 1;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 2;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 3;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); } }
                } }{ const int p = 2;  {
                    const uint q = pc.e_off / 4u + uint( (g * ( ( (4 * 128) / 4) / 16) + h + p) / 2) * uint( (128 / 16)) * 128u
                        + uint(k) * 128u + lane * 4u;
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                    { { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 1;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 2;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 3;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); } }
                    { { const int m = 0;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 1;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 2;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 3;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); } }
                } } }









                if (0 > 0 && (k + 1) % 0 == 0)
                    { { const int p = 0; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } }{ const int p = 1; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } }{ const int p = 2; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } }{ const int p = 3; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } } }
            } } }
            { { const int p = 0; 
            { { const int m = 0; 






                { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} } } }{ const int m = 1; 






                { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} } } }{ const int m = 2; 






                { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} } } }{ const int m = 3; 






                { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} } } } } }{ const int p = 1; 
            { { const int m = 0; 






                { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} } } }{ const int m = 1; 






                { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} } } }{ const int m = 2; 






                { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} } } }{ const int m = 3; 






                { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} } } } } }{ const int p = 2; 
            { { const int m = 0; 






                { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} } } }{ const int m = 1; 






                { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} } } }{ const int m = 2; 






                { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} } } }{ const int m = 3; 






                { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} } } } } }{ const int p = 3; 
            { { const int m = 0; 






                { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} } } }{ const int m = 1; 






                { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} } } }{ const int m = 2; 






                { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} } } }{ const int m = 3; 






                { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} } } } } } }































        } }{ const int h = 4;  {
                  coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > a[4][ (64 / 16)];
            { { const int p = 0; 
                { { const int m = 0;  a[p][m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int m = 1;  a[p][m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int m = 2;  a[p][m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int m = 3;  a[p][m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); } } }{ const int p = 1; 
                { { const int m = 0;  a[p][m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int m = 1;  a[p][m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int m = 2;  a[p][m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int m = 3;  a[p][m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); } } }{ const int p = 2; 
                { { const int m = 0;  a[p][m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int m = 1;  a[p][m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int m = 2;  a[p][m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int m = 3;  a[p][m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); } } }{ const int p = 3; 
                { { const int m = 0;  a[p][m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int m = 1;  a[p][m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int m = 2;  a[p][m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int m = 3;  a[p][m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); } } } }
            { { const int k = 0;  {
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > xbk[ (64 / 16)];
                { { const int m = 0; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 1; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 2; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 3; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); } }




                { { const int p = 0;  {
                    const uint q = pc.e_off / 4u + uint( (g * ( ( (4 * 128) / 4) / 16) + h + p) / 2) * uint( (128 / 16)) * 128u
                        + uint(k) * 128u + lane * 4u;
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                    { { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 1;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 2;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 3;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); } }
                    { { const int m = 0;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 1;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 2;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 3;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); } }
                } }{ const int p = 2;  {
                    const uint q = pc.e_off / 4u + uint( (g * ( ( (4 * 128) / 4) / 16) + h + p) / 2) * uint( (128 / 16)) * 128u
                        + uint(k) * 128u + lane * 4u;
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                    { { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 1;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 2;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 3;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); } }
                    { { const int m = 0;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 1;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 2;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 3;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); } }
                } } }









                if (0 > 0 && (k + 1) % 0 == 0)
                    { { const int p = 0; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } }{ const int p = 1; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } }{ const int p = 2; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } }{ const int p = 3; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } } }
            } }{ const int k = 1;  {
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > xbk[ (64 / 16)];
                { { const int m = 0; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 1; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 2; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 3; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); } }




                { { const int p = 0;  {
                    const uint q = pc.e_off / 4u + uint( (g * ( ( (4 * 128) / 4) / 16) + h + p) / 2) * uint( (128 / 16)) * 128u
                        + uint(k) * 128u + lane * 4u;
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                    { { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 1;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 2;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 3;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); } }
                    { { const int m = 0;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 1;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 2;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 3;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); } }
                } }{ const int p = 2;  {
                    const uint q = pc.e_off / 4u + uint( (g * ( ( (4 * 128) / 4) / 16) + h + p) / 2) * uint( (128 / 16)) * 128u
                        + uint(k) * 128u + lane * 4u;
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                    { { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 1;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 2;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 3;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); } }
                    { { const int m = 0;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 1;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 2;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 3;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); } }
                } } }









                if (0 > 0 && (k + 1) % 0 == 0)
                    { { const int p = 0; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } }{ const int p = 1; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } }{ const int p = 2; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } }{ const int p = 3; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } } }
            } }{ const int k = 2;  {
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > xbk[ (64 / 16)];
                { { const int m = 0; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 1; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 2; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 3; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); } }




                { { const int p = 0;  {
                    const uint q = pc.e_off / 4u + uint( (g * ( ( (4 * 128) / 4) / 16) + h + p) / 2) * uint( (128 / 16)) * 128u
                        + uint(k) * 128u + lane * 4u;
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                    { { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 1;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 2;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 3;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); } }
                    { { const int m = 0;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 1;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 2;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 3;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); } }
                } }{ const int p = 2;  {
                    const uint q = pc.e_off / 4u + uint( (g * ( ( (4 * 128) / 4) / 16) + h + p) / 2) * uint( (128 / 16)) * 128u
                        + uint(k) * 128u + lane * 4u;
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                    { { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 1;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 2;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 3;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); } }
                    { { const int m = 0;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 1;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 2;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 3;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); } }
                } } }









                if (0 > 0 && (k + 1) % 0 == 0)
                    { { const int p = 0; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } }{ const int p = 1; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } }{ const int p = 2; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } }{ const int p = 3; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } } }
            } }{ const int k = 3;  {
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > xbk[ (64 / 16)];
                { { const int m = 0; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 1; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 2; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 3; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); } }




                { { const int p = 0;  {
                    const uint q = pc.e_off / 4u + uint( (g * ( ( (4 * 128) / 4) / 16) + h + p) / 2) * uint( (128 / 16)) * 128u
                        + uint(k) * 128u + lane * 4u;
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                    { { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 1;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 2;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 3;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); } }
                    { { const int m = 0;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 1;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 2;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 3;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); } }
                } }{ const int p = 2;  {
                    const uint q = pc.e_off / 4u + uint( (g * ( ( (4 * 128) / 4) / 16) + h + p) / 2) * uint( (128 / 16)) * 128u
                        + uint(k) * 128u + lane * 4u;
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                    { { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 1;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 2;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 3;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); } }
                    { { const int m = 0;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 1;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 2;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 3;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); } }
                } } }









                if (0 > 0 && (k + 1) % 0 == 0)
                    { { const int p = 0; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } }{ const int p = 1; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } }{ const int p = 2; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } }{ const int p = 3; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } } }
            } }{ const int k = 4;  {
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > xbk[ (64 / 16)];
                { { const int m = 0; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 1; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 2; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 3; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); } }




                { { const int p = 0;  {
                    const uint q = pc.e_off / 4u + uint( (g * ( ( (4 * 128) / 4) / 16) + h + p) / 2) * uint( (128 / 16)) * 128u
                        + uint(k) * 128u + lane * 4u;
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                    { { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 1;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 2;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 3;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); } }
                    { { const int m = 0;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 1;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 2;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 3;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); } }
                } }{ const int p = 2;  {
                    const uint q = pc.e_off / 4u + uint( (g * ( ( (4 * 128) / 4) / 16) + h + p) / 2) * uint( (128 / 16)) * 128u
                        + uint(k) * 128u + lane * 4u;
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                    { { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 1;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 2;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 3;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); } }
                    { { const int m = 0;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 1;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 2;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 3;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); } }
                } } }









                if (0 > 0 && (k + 1) % 0 == 0)
                    { { const int p = 0; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } }{ const int p = 1; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } }{ const int p = 2; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } }{ const int p = 3; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } } }
            } }{ const int k = 5;  {
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > xbk[ (64 / 16)];
                { { const int m = 0; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 1; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 2; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 3; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); } }




                { { const int p = 0;  {
                    const uint q = pc.e_off / 4u + uint( (g * ( ( (4 * 128) / 4) / 16) + h + p) / 2) * uint( (128 / 16)) * 128u
                        + uint(k) * 128u + lane * 4u;
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                    { { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 1;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 2;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 3;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); } }
                    { { const int m = 0;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 1;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 2;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 3;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); } }
                } }{ const int p = 2;  {
                    const uint q = pc.e_off / 4u + uint( (g * ( ( (4 * 128) / 4) / 16) + h + p) / 2) * uint( (128 / 16)) * 128u
                        + uint(k) * 128u + lane * 4u;
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                    { { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 1;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 2;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 3;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); } }
                    { { const int m = 0;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 1;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 2;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 3;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); } }
                } } }









                if (0 > 0 && (k + 1) % 0 == 0)
                    { { const int p = 0; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } }{ const int p = 1; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } }{ const int p = 2; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } }{ const int p = 3; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } } }
            } }{ const int k = 6;  {
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > xbk[ (64 / 16)];
                { { const int m = 0; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 1; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 2; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 3; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); } }




                { { const int p = 0;  {
                    const uint q = pc.e_off / 4u + uint( (g * ( ( (4 * 128) / 4) / 16) + h + p) / 2) * uint( (128 / 16)) * 128u
                        + uint(k) * 128u + lane * 4u;
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                    { { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 1;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 2;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 3;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); } }
                    { { const int m = 0;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 1;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 2;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 3;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); } }
                } }{ const int p = 2;  {
                    const uint q = pc.e_off / 4u + uint( (g * ( ( (4 * 128) / 4) / 16) + h + p) / 2) * uint( (128 / 16)) * 128u
                        + uint(k) * 128u + lane * 4u;
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                    { { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 1;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 2;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 3;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); } }
                    { { const int m = 0;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 1;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 2;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 3;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); } }
                } } }









                if (0 > 0 && (k + 1) % 0 == 0)
                    { { const int p = 0; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } }{ const int p = 1; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } }{ const int p = 2; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } }{ const int p = 3; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } } }
            } }{ const int k = 7;  {
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > xbk[ (64 / 16)];
                { { const int m = 0; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 1; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 2; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 3; 

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); } }




                { { const int p = 0;  {
                    const uint q = pc.e_off / 4u + uint( (g * ( ( (4 * 128) / 4) / 16) + h + p) / 2) * uint( (128 / 16)) * 128u
                        + uint(k) * 128u + lane * 4u;
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                    { { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 1;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 2;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 3;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); } }
                    { { const int m = 0;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 1;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 2;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 3;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); } }
                } }{ const int p = 2;  {
                    const uint q = pc.e_off / 4u + uint( (g * ( ( (4 * 128) / 4) / 16) + h + p) / 2) * uint( (128 / 16)) * 128u
                        + uint(k) * 128u + lane * 4u;
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                    { { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 1;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 2;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); }{ const int m = 3;  a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]); } }
                    { { const int m = 0;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 1;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 2;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); }{ const int m = 3;  a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]); } }
                } } }









                if (0 > 0 && (k + 1) % 0 == 0)
                    { { const int p = 0; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } }{ const int p = 1; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } }{ const int p = 2; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } }{ const int p = 3; 
                        { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } } } }
            } } }
            { { const int p = 0; 
            { { const int m = 0; 






                { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} } } }{ const int m = 1; 






                { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} } } }{ const int m = 2; 






                { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} } } }{ const int m = 3; 






                { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} } } } } }{ const int p = 1; 
            { { const int m = 0; 






                { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} } } }{ const int m = 1; 






                { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} } } }{ const int m = 2; 






                { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} } } }{ const int m = 3; 






                { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} } } } } }{ const int p = 2; 
            { { const int m = 0; 






                { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} } } }{ const int m = 1; 






                { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} } } }{ const int m = 2; 






                { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} } } }{ const int m = 3; 






                { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} } } } } }{ const int p = 3; 
            { { const int m = 0; 






                { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} } } }{ const int m = 1; 






                { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} } } }{ const int m = 2; 






                { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} } } }{ const int m = 3; 






                { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(
                                             nr_act_horner(a[p][m][c]), nr_act_horner_b(a[p][m][c + 1])), vec2(
                                             nr_act_horner(a[p][m][(c + 2)]), nr_act_horner_b(a[p][m][(c + 2) + 1])));
eqg[m][h + p][c] = qp.x;
eqg[m][h + p][c + 1] = qp.y;
eqg[m][h + p][(c + 2)] = qp.z;
eqg[m][h + p][(c + 2) + 1] = qp.w;
} } } } } } }































        } } }





































































              coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > nr_mid_acc[ ( (128 / 4) / 16)][ (64 / 16)];
        { { const int n = 0;  { { const int m = 0;  nr_mid_acc[n][m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int m = 1;  nr_mid_acc[n][m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int m = 2;  nr_mid_acc[n][m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int m = 3;  nr_mid_acc[n][m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); } } }{ const int n = 1;  { { const int m = 0;  nr_mid_acc[n][m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int m = 1;  nr_mid_acc[n][m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int m = 2;  nr_mid_acc[n][m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int m = 3;  nr_mid_acc[n][m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); } } } }
        { { const int k = 0;  {
                 coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                    { const uint q = (pc.mid_off) / 4u + ( (uint(g * ( (128 / 4) / 16))) / 2u) * (uint( ( ( (4 * 128) / 4) / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
            { { const int m = 0;  nr_mid_acc[0][m] = coopMatMulAdd(wf0, eqg[m][k], nr_mid_acc[0][m]); }{ const int m = 1;  nr_mid_acc[0][m] = coopMatMulAdd(wf0, eqg[m][k], nr_mid_acc[0][m]); }{ const int m = 2;  nr_mid_acc[0][m] = coopMatMulAdd(wf0, eqg[m][k], nr_mid_acc[0][m]); }{ const int m = 3;  nr_mid_acc[0][m] = coopMatMulAdd(wf0, eqg[m][k], nr_mid_acc[0][m]); } }
            { { const int m = 0;  nr_mid_acc[1][m] = coopMatMulAdd(wf1, eqg[m][k], nr_mid_acc[1][m]); }{ const int m = 1;  nr_mid_acc[1][m] = coopMatMulAdd(wf1, eqg[m][k], nr_mid_acc[1][m]); }{ const int m = 2;  nr_mid_acc[1][m] = coopMatMulAdd(wf1, eqg[m][k], nr_mid_acc[1][m]); }{ const int m = 3;  nr_mid_acc[1][m] = coopMatMulAdd(wf1, eqg[m][k], nr_mid_acc[1][m]); } }
        } }{ const int k = 1;  {
                 coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                    { const uint q = (pc.mid_off) / 4u + ( (uint(g * ( (128 / 4) / 16))) / 2u) * (uint( ( ( (4 * 128) / 4) / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
            { { const int m = 0;  nr_mid_acc[0][m] = coopMatMulAdd(wf0, eqg[m][k], nr_mid_acc[0][m]); }{ const int m = 1;  nr_mid_acc[0][m] = coopMatMulAdd(wf0, eqg[m][k], nr_mid_acc[0][m]); }{ const int m = 2;  nr_mid_acc[0][m] = coopMatMulAdd(wf0, eqg[m][k], nr_mid_acc[0][m]); }{ const int m = 3;  nr_mid_acc[0][m] = coopMatMulAdd(wf0, eqg[m][k], nr_mid_acc[0][m]); } }
            { { const int m = 0;  nr_mid_acc[1][m] = coopMatMulAdd(wf1, eqg[m][k], nr_mid_acc[1][m]); }{ const int m = 1;  nr_mid_acc[1][m] = coopMatMulAdd(wf1, eqg[m][k], nr_mid_acc[1][m]); }{ const int m = 2;  nr_mid_acc[1][m] = coopMatMulAdd(wf1, eqg[m][k], nr_mid_acc[1][m]); }{ const int m = 3;  nr_mid_acc[1][m] = coopMatMulAdd(wf1, eqg[m][k], nr_mid_acc[1][m]); } }
        } }{ const int k = 2;  {
                 coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                    { const uint q = (pc.mid_off) / 4u + ( (uint(g * ( (128 / 4) / 16))) / 2u) * (uint( ( ( (4 * 128) / 4) / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
            { { const int m = 0;  nr_mid_acc[0][m] = coopMatMulAdd(wf0, eqg[m][k], nr_mid_acc[0][m]); }{ const int m = 1;  nr_mid_acc[0][m] = coopMatMulAdd(wf0, eqg[m][k], nr_mid_acc[0][m]); }{ const int m = 2;  nr_mid_acc[0][m] = coopMatMulAdd(wf0, eqg[m][k], nr_mid_acc[0][m]); }{ const int m = 3;  nr_mid_acc[0][m] = coopMatMulAdd(wf0, eqg[m][k], nr_mid_acc[0][m]); } }
            { { const int m = 0;  nr_mid_acc[1][m] = coopMatMulAdd(wf1, eqg[m][k], nr_mid_acc[1][m]); }{ const int m = 1;  nr_mid_acc[1][m] = coopMatMulAdd(wf1, eqg[m][k], nr_mid_acc[1][m]); }{ const int m = 2;  nr_mid_acc[1][m] = coopMatMulAdd(wf1, eqg[m][k], nr_mid_acc[1][m]); }{ const int m = 3;  nr_mid_acc[1][m] = coopMatMulAdd(wf1, eqg[m][k], nr_mid_acc[1][m]); } }
        } }{ const int k = 3;  {
                 coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                    { const uint q = (pc.mid_off) / 4u + ( (uint(g * ( (128 / 4) / 16))) / 2u) * (uint( ( ( (4 * 128) / 4) / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
            { { const int m = 0;  nr_mid_acc[0][m] = coopMatMulAdd(wf0, eqg[m][k], nr_mid_acc[0][m]); }{ const int m = 1;  nr_mid_acc[0][m] = coopMatMulAdd(wf0, eqg[m][k], nr_mid_acc[0][m]); }{ const int m = 2;  nr_mid_acc[0][m] = coopMatMulAdd(wf0, eqg[m][k], nr_mid_acc[0][m]); }{ const int m = 3;  nr_mid_acc[0][m] = coopMatMulAdd(wf0, eqg[m][k], nr_mid_acc[0][m]); } }
            { { const int m = 0;  nr_mid_acc[1][m] = coopMatMulAdd(wf1, eqg[m][k], nr_mid_acc[1][m]); }{ const int m = 1;  nr_mid_acc[1][m] = coopMatMulAdd(wf1, eqg[m][k], nr_mid_acc[1][m]); }{ const int m = 2;  nr_mid_acc[1][m] = coopMatMulAdd(wf1, eqg[m][k], nr_mid_acc[1][m]); }{ const int m = 3;  nr_mid_acc[1][m] = coopMatMulAdd(wf1, eqg[m][k], nr_mid_acc[1][m]); } }
        } }{ const int k = 4;  {
                 coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                    { const uint q = (pc.mid_off) / 4u + ( (uint(g * ( (128 / 4) / 16))) / 2u) * (uint( ( ( (4 * 128) / 4) / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
            { { const int m = 0;  nr_mid_acc[0][m] = coopMatMulAdd(wf0, eqg[m][k], nr_mid_acc[0][m]); }{ const int m = 1;  nr_mid_acc[0][m] = coopMatMulAdd(wf0, eqg[m][k], nr_mid_acc[0][m]); }{ const int m = 2;  nr_mid_acc[0][m] = coopMatMulAdd(wf0, eqg[m][k], nr_mid_acc[0][m]); }{ const int m = 3;  nr_mid_acc[0][m] = coopMatMulAdd(wf0, eqg[m][k], nr_mid_acc[0][m]); } }
            { { const int m = 0;  nr_mid_acc[1][m] = coopMatMulAdd(wf1, eqg[m][k], nr_mid_acc[1][m]); }{ const int m = 1;  nr_mid_acc[1][m] = coopMatMulAdd(wf1, eqg[m][k], nr_mid_acc[1][m]); }{ const int m = 2;  nr_mid_acc[1][m] = coopMatMulAdd(wf1, eqg[m][k], nr_mid_acc[1][m]); }{ const int m = 3;  nr_mid_acc[1][m] = coopMatMulAdd(wf1, eqg[m][k], nr_mid_acc[1][m]); } }
        } }{ const int k = 5;  {
                 coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                    { const uint q = (pc.mid_off) / 4u + ( (uint(g * ( (128 / 4) / 16))) / 2u) * (uint( ( ( (4 * 128) / 4) / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
            { { const int m = 0;  nr_mid_acc[0][m] = coopMatMulAdd(wf0, eqg[m][k], nr_mid_acc[0][m]); }{ const int m = 1;  nr_mid_acc[0][m] = coopMatMulAdd(wf0, eqg[m][k], nr_mid_acc[0][m]); }{ const int m = 2;  nr_mid_acc[0][m] = coopMatMulAdd(wf0, eqg[m][k], nr_mid_acc[0][m]); }{ const int m = 3;  nr_mid_acc[0][m] = coopMatMulAdd(wf0, eqg[m][k], nr_mid_acc[0][m]); } }
            { { const int m = 0;  nr_mid_acc[1][m] = coopMatMulAdd(wf1, eqg[m][k], nr_mid_acc[1][m]); }{ const int m = 1;  nr_mid_acc[1][m] = coopMatMulAdd(wf1, eqg[m][k], nr_mid_acc[1][m]); }{ const int m = 2;  nr_mid_acc[1][m] = coopMatMulAdd(wf1, eqg[m][k], nr_mid_acc[1][m]); }{ const int m = 3;  nr_mid_acc[1][m] = coopMatMulAdd(wf1, eqg[m][k], nr_mid_acc[1][m]); } }
        } }{ const int k = 6;  {
                 coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                    { const uint q = (pc.mid_off) / 4u + ( (uint(g * ( (128 / 4) / 16))) / 2u) * (uint( ( ( (4 * 128) / 4) / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
            { { const int m = 0;  nr_mid_acc[0][m] = coopMatMulAdd(wf0, eqg[m][k], nr_mid_acc[0][m]); }{ const int m = 1;  nr_mid_acc[0][m] = coopMatMulAdd(wf0, eqg[m][k], nr_mid_acc[0][m]); }{ const int m = 2;  nr_mid_acc[0][m] = coopMatMulAdd(wf0, eqg[m][k], nr_mid_acc[0][m]); }{ const int m = 3;  nr_mid_acc[0][m] = coopMatMulAdd(wf0, eqg[m][k], nr_mid_acc[0][m]); } }
            { { const int m = 0;  nr_mid_acc[1][m] = coopMatMulAdd(wf1, eqg[m][k], nr_mid_acc[1][m]); }{ const int m = 1;  nr_mid_acc[1][m] = coopMatMulAdd(wf1, eqg[m][k], nr_mid_acc[1][m]); }{ const int m = 2;  nr_mid_acc[1][m] = coopMatMulAdd(wf1, eqg[m][k], nr_mid_acc[1][m]); }{ const int m = 3;  nr_mid_acc[1][m] = coopMatMulAdd(wf1, eqg[m][k], nr_mid_acc[1][m]); } }
        } }{ const int k = 7;  {
                 coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                    { const uint q = (pc.mid_off) / 4u + ( (uint(g * ( (128 / 4) / 16))) / 2u) * (uint( ( ( (4 * 128) / 4) / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
            { { const int m = 0;  nr_mid_acc[0][m] = coopMatMulAdd(wf0, eqg[m][k], nr_mid_acc[0][m]); }{ const int m = 1;  nr_mid_acc[0][m] = coopMatMulAdd(wf0, eqg[m][k], nr_mid_acc[0][m]); }{ const int m = 2;  nr_mid_acc[0][m] = coopMatMulAdd(wf0, eqg[m][k], nr_mid_acc[0][m]); }{ const int m = 3;  nr_mid_acc[0][m] = coopMatMulAdd(wf0, eqg[m][k], nr_mid_acc[0][m]); } }
            { { const int m = 0;  nr_mid_acc[1][m] = coopMatMulAdd(wf1, eqg[m][k], nr_mid_acc[1][m]); }{ const int m = 1;  nr_mid_acc[1][m] = coopMatMulAdd(wf1, eqg[m][k], nr_mid_acc[1][m]); }{ const int m = 2;  nr_mid_acc[1][m] = coopMatMulAdd(wf1, eqg[m][k], nr_mid_acc[1][m]); }{ const int m = 3;  nr_mid_acc[1][m] = coopMatMulAdd(wf1, eqg[m][k], nr_mid_acc[1][m]); } }
        } } }




        { { const int n = 0;  {
            const int nf = g * ( (128 / 4) / 16) + n;

                       coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > mqf[ (64 / 16)];





                  coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > a[ (64 / 16)];
            { { const int m = 0;  a[m] = nr_mid_acc[n][m]; }{ const int m = 1;  a[m] = nr_mid_acc[n][m]; }{ const int m = 2;  a[m] = nr_mid_acc[n][m]; }{ const int m = 3;  a[m] = nr_mid_acc[n][m]; } }













            { { const int m = 0; 







                { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(a[m][c], a[m][c + 1]), vec2(a[m][(c + 2)], a[m][(c + 2) + 1]));
mqf[m][c] = qp.x;
mqf[m][c + 1] = qp.y;
mqf[m][(c + 2)] = qp.z;
mqf[m][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(a[m][c], a[m][c + 1]), vec2(a[m][(c + 2)], a[m][(c + 2) + 1]));
mqf[m][c] = qp.x;
mqf[m][c + 1] = qp.y;
mqf[m][(c + 2)] = qp.z;
mqf[m][(c + 2) + 1] = qp.w;
} } } }{ const int m = 1; 







                { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(a[m][c], a[m][c + 1]), vec2(a[m][(c + 2)], a[m][(c + 2) + 1]));
mqf[m][c] = qp.x;
mqf[m][c + 1] = qp.y;
mqf[m][(c + 2)] = qp.z;
mqf[m][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(a[m][c], a[m][c + 1]), vec2(a[m][(c + 2)], a[m][(c + 2) + 1]));
mqf[m][c] = qp.x;
mqf[m][c + 1] = qp.y;
mqf[m][(c + 2)] = qp.z;
mqf[m][(c + 2) + 1] = qp.w;
} } } }{ const int m = 2; 







                { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(a[m][c], a[m][c + 1]), vec2(a[m][(c + 2)], a[m][(c + 2) + 1]));
mqf[m][c] = qp.x;
mqf[m][c + 1] = qp.y;
mqf[m][(c + 2)] = qp.z;
mqf[m][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(a[m][c], a[m][c + 1]), vec2(a[m][(c + 2)], a[m][(c + 2) + 1]));
mqf[m][c] = qp.x;
mqf[m][c + 1] = qp.y;
mqf[m][(c + 2)] = qp.z;
mqf[m][(c + 2) + 1] = qp.w;
} } } }{ const int m = 3; 







                { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(a[m][c], a[m][c + 1]), vec2(a[m][(c + 2)], a[m][(c + 2) + 1]));
mqf[m][c] = qp.x;
mqf[m][c + 1] = qp.y;
mqf[m][(c + 2)] = qp.z;
mqf[m][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(a[m][c], a[m][c + 1]), vec2(a[m][(c + 2)], a[m][(c + 2) + 1]));
mqf[m][c] = qp.x;
mqf[m][c + 1] = qp.y;
mqf[m][(c + 2)] = qp.z;
mqf[m][(c + 2) + 1] = qp.w;
} } } } }




            { { const int m = 0; 
                                                                                        coopMatStore(mqf[m], lds_y, (uint(m * (128 / 16) + nf) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 1; 
                                                                                        coopMatStore(mqf[m], lds_y, (uint(m * (128 / 16) + nf) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 2; 
                                                                                        coopMatStore(mqf[m], lds_y, (uint(m * (128 / 16) + nf) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 3; 
                                                                                        coopMatStore(mqf[m], lds_y, (uint(m * (128 / 16) + nf) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor); } }

        } }{ const int n = 1;  {
            const int nf = g * ( (128 / 4) / 16) + n;

                       coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > mqf[ (64 / 16)];





                  coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > a[ (64 / 16)];
            { { const int m = 0;  a[m] = nr_mid_acc[n][m]; }{ const int m = 1;  a[m] = nr_mid_acc[n][m]; }{ const int m = 2;  a[m] = nr_mid_acc[n][m]; }{ const int m = 3;  a[m] = nr_mid_acc[n][m]; } }













            { { const int m = 0; 







                { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(a[m][c], a[m][c + 1]), vec2(a[m][(c + 2)], a[m][(c + 2) + 1]));
mqf[m][c] = qp.x;
mqf[m][c + 1] = qp.y;
mqf[m][(c + 2)] = qp.z;
mqf[m][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(a[m][c], a[m][c + 1]), vec2(a[m][(c + 2)], a[m][(c + 2) + 1]));
mqf[m][c] = qp.x;
mqf[m][c + 1] = qp.y;
mqf[m][(c + 2)] = qp.z;
mqf[m][(c + 2) + 1] = qp.w;
} } } }{ const int m = 1; 







                { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(a[m][c], a[m][c + 1]), vec2(a[m][(c + 2)], a[m][(c + 2) + 1]));
mqf[m][c] = qp.x;
mqf[m][c + 1] = qp.y;
mqf[m][(c + 2)] = qp.z;
mqf[m][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(a[m][c], a[m][c + 1]), vec2(a[m][(c + 2)], a[m][(c + 2) + 1]));
mqf[m][c] = qp.x;
mqf[m][c + 1] = qp.y;
mqf[m][(c + 2)] = qp.z;
mqf[m][(c + 2) + 1] = qp.w;
} } } }{ const int m = 2; 







                { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(a[m][c], a[m][c + 1]), vec2(a[m][(c + 2)], a[m][(c + 2) + 1]));
mqf[m][c] = qp.x;
mqf[m][c + 1] = qp.y;
mqf[m][(c + 2)] = qp.z;
mqf[m][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(a[m][c], a[m][c + 1]), vec2(a[m][(c + 2)], a[m][(c + 2) + 1]));
mqf[m][c] = qp.x;
mqf[m][c + 1] = qp.y;
mqf[m][(c + 2)] = qp.z;
mqf[m][(c + 2) + 1] = qp.w;
} } } }{ const int m = 3; 







                { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(a[m][c], a[m][c + 1]), vec2(a[m][(c + 2)], a[m][(c + 2) + 1]));
mqf[m][c] = qp.x;
mqf[m][c + 1] = qp.y;
mqf[m][(c + 2)] = qp.z;
mqf[m][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(a[m][c], a[m][c + 1]), vec2(a[m][(c + 2)], a[m][(c + 2) + 1]));
mqf[m][c] = qp.x;
mqf[m][c + 1] = qp.y;
mqf[m][(c + 2)] = qp.z;
mqf[m][(c + 2) + 1] = qp.w;
} } } } }




            { { const int m = 0; 
                                                                                        coopMatStore(mqf[m], lds_y, (uint(m * (128 / 16) + nf) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 1; 
                                                                                        coopMatStore(mqf[m], lds_y, (uint(m * (128 / 16) + nf) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 2; 
                                                                                        coopMatStore(mqf[m], lds_y, (uint(m * (128 / 16) + nf) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 3; 
                                                                                        coopMatStore(mqf[m], lds_y, (uint(m * (128 / 16) + nf) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor); } }

        } } }
    }

    barrier();


















































































































































































          coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > nr_contract_acc[ ( (128 / 4) / 16)][ (64 / 16)];
    { { const int p = 0;  {
        const int n = nrhw_h * ( (128 / 4) / 16) + p;
        { { const int m = 0;  {
                    coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yr;
                                                                            coopMatLoad(yr, lds_x, (uint(m * (128 / 16) + n) * 256u + (nr_opaque * ( (80u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);
            { { const int c = 0;  {
                const uint off = pc.rs_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_contract_acc[p][m][c] = float(residual.x);
                nr_contract_acc[p][m][c + 1] = float(residual.y);
            } }{ const int c = 2;  {
                const uint off = pc.rs_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_contract_acc[p][m][c] = float(residual.x);
                nr_contract_acc[p][m][c + 1] = float(residual.y);
            } }{ const int c = 4;  {
                const uint off = pc.rs_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_contract_acc[p][m][c] = float(residual.x);
                nr_contract_acc[p][m][c + 1] = float(residual.y);
            } }{ const int c = 6;  {
                const uint off = pc.rs_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_contract_acc[p][m][c] = float(residual.x);
                nr_contract_acc[p][m][c + 1] = float(residual.y);
            } } }
        } }{ const int m = 1;  {
                    coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yr;
                                                                            coopMatLoad(yr, lds_x, (uint(m * (128 / 16) + n) * 256u + (nr_opaque * ( (80u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);
            { { const int c = 0;  {
                const uint off = pc.rs_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_contract_acc[p][m][c] = float(residual.x);
                nr_contract_acc[p][m][c + 1] = float(residual.y);
            } }{ const int c = 2;  {
                const uint off = pc.rs_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_contract_acc[p][m][c] = float(residual.x);
                nr_contract_acc[p][m][c + 1] = float(residual.y);
            } }{ const int c = 4;  {
                const uint off = pc.rs_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_contract_acc[p][m][c] = float(residual.x);
                nr_contract_acc[p][m][c + 1] = float(residual.y);
            } }{ const int c = 6;  {
                const uint off = pc.rs_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_contract_acc[p][m][c] = float(residual.x);
                nr_contract_acc[p][m][c + 1] = float(residual.y);
            } } }
        } }{ const int m = 2;  {
                    coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yr;
                                                                            coopMatLoad(yr, lds_x, (uint(m * (128 / 16) + n) * 256u + (nr_opaque * ( (80u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);
            { { const int c = 0;  {
                const uint off = pc.rs_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_contract_acc[p][m][c] = float(residual.x);
                nr_contract_acc[p][m][c + 1] = float(residual.y);
            } }{ const int c = 2;  {
                const uint off = pc.rs_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_contract_acc[p][m][c] = float(residual.x);
                nr_contract_acc[p][m][c + 1] = float(residual.y);
            } }{ const int c = 4;  {
                const uint off = pc.rs_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_contract_acc[p][m][c] = float(residual.x);
                nr_contract_acc[p][m][c + 1] = float(residual.y);
            } }{ const int c = 6;  {
                const uint off = pc.rs_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_contract_acc[p][m][c] = float(residual.x);
                nr_contract_acc[p][m][c + 1] = float(residual.y);
            } } }
        } }{ const int m = 3;  {
                    coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yr;
                                                                            coopMatLoad(yr, lds_x, (uint(m * (128 / 16) + n) * 256u + (nr_opaque * ( (80u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);
            { { const int c = 0;  {
                const uint off = pc.rs_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_contract_acc[p][m][c] = float(residual.x);
                nr_contract_acc[p][m][c + 1] = float(residual.y);
            } }{ const int c = 2;  {
                const uint off = pc.rs_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_contract_acc[p][m][c] = float(residual.x);
                nr_contract_acc[p][m][c + 1] = float(residual.y);
            } }{ const int c = 4;  {
                const uint off = pc.rs_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_contract_acc[p][m][c] = float(residual.x);
                nr_contract_acc[p][m][c + 1] = float(residual.y);
            } }{ const int c = 6;  {
                const uint off = pc.rs_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_contract_acc[p][m][c] = float(residual.x);
                nr_contract_acc[p][m][c + 1] = float(residual.y);
            } } }
        } } }
    } }{ const int p = 1;  {
        const int n = nrhw_h * ( (128 / 4) / 16) + p;
        { { const int m = 0;  {
                    coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yr;
                                                                            coopMatLoad(yr, lds_x, (uint(m * (128 / 16) + n) * 256u + (nr_opaque * ( (80u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);
            { { const int c = 0;  {
                const uint off = pc.rs_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_contract_acc[p][m][c] = float(residual.x);
                nr_contract_acc[p][m][c + 1] = float(residual.y);
            } }{ const int c = 2;  {
                const uint off = pc.rs_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_contract_acc[p][m][c] = float(residual.x);
                nr_contract_acc[p][m][c + 1] = float(residual.y);
            } }{ const int c = 4;  {
                const uint off = pc.rs_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_contract_acc[p][m][c] = float(residual.x);
                nr_contract_acc[p][m][c + 1] = float(residual.y);
            } }{ const int c = 6;  {
                const uint off = pc.rs_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_contract_acc[p][m][c] = float(residual.x);
                nr_contract_acc[p][m][c + 1] = float(residual.y);
            } } }
        } }{ const int m = 1;  {
                    coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yr;
                                                                            coopMatLoad(yr, lds_x, (uint(m * (128 / 16) + n) * 256u + (nr_opaque * ( (80u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);
            { { const int c = 0;  {
                const uint off = pc.rs_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_contract_acc[p][m][c] = float(residual.x);
                nr_contract_acc[p][m][c + 1] = float(residual.y);
            } }{ const int c = 2;  {
                const uint off = pc.rs_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_contract_acc[p][m][c] = float(residual.x);
                nr_contract_acc[p][m][c + 1] = float(residual.y);
            } }{ const int c = 4;  {
                const uint off = pc.rs_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_contract_acc[p][m][c] = float(residual.x);
                nr_contract_acc[p][m][c + 1] = float(residual.y);
            } }{ const int c = 6;  {
                const uint off = pc.rs_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_contract_acc[p][m][c] = float(residual.x);
                nr_contract_acc[p][m][c + 1] = float(residual.y);
            } } }
        } }{ const int m = 2;  {
                    coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yr;
                                                                            coopMatLoad(yr, lds_x, (uint(m * (128 / 16) + n) * 256u + (nr_opaque * ( (80u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);
            { { const int c = 0;  {
                const uint off = pc.rs_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_contract_acc[p][m][c] = float(residual.x);
                nr_contract_acc[p][m][c + 1] = float(residual.y);
            } }{ const int c = 2;  {
                const uint off = pc.rs_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_contract_acc[p][m][c] = float(residual.x);
                nr_contract_acc[p][m][c + 1] = float(residual.y);
            } }{ const int c = 4;  {
                const uint off = pc.rs_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_contract_acc[p][m][c] = float(residual.x);
                nr_contract_acc[p][m][c + 1] = float(residual.y);
            } }{ const int c = 6;  {
                const uint off = pc.rs_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_contract_acc[p][m][c] = float(residual.x);
                nr_contract_acc[p][m][c + 1] = float(residual.y);
            } } }
        } }{ const int m = 3;  {
                    coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yr;
                                                                            coopMatLoad(yr, lds_x, (uint(m * (128 / 16) + n) * 256u + (nr_opaque * ( (80u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);
            { { const int c = 0;  {
                const uint off = pc.rs_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_contract_acc[p][m][c] = float(residual.x);
                nr_contract_acc[p][m][c + 1] = float(residual.y);
            } }{ const int c = 2;  {
                const uint off = pc.rs_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_contract_acc[p][m][c] = float(residual.x);
                nr_contract_acc[p][m][c + 1] = float(residual.y);
            } }{ const int c = 4;  {
                const uint off = pc.rs_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_contract_acc[p][m][c] = float(residual.x);
                nr_contract_acc[p][m][c + 1] = float(residual.y);
            } }{ const int c = 6;  {
                const uint off = pc.rs_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_contract_acc[p][m][c] = float(residual.x);
                nr_contract_acc[p][m][c + 1] = float(residual.y);
            } } }
        } } }
    } } }
    { { const int k = 0;  {
                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > ctx[ (64 / 16)];
        { { const int m = 0; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 1; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 2; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 3; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); } }
             coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                    { const uint q = (pc.ct_off) / 4u + ( (uint(nrhw_h * ( (128 / 4) / 16))) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
        { { const int m = 0;  nr_contract_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_contract_acc[0][m]); }{ const int m = 1;  nr_contract_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_contract_acc[0][m]); }{ const int m = 2;  nr_contract_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_contract_acc[0][m]); }{ const int m = 3;  nr_contract_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_contract_acc[0][m]); } }
        { { const int m = 0;  nr_contract_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_contract_acc[1][m]); }{ const int m = 1;  nr_contract_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_contract_acc[1][m]); }{ const int m = 2;  nr_contract_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_contract_acc[1][m]); }{ const int m = 3;  nr_contract_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_contract_acc[1][m]); } }
    } }{ const int k = 1;  {
                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > ctx[ (64 / 16)];
        { { const int m = 0; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 1; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 2; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 3; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); } }
             coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                    { const uint q = (pc.ct_off) / 4u + ( (uint(nrhw_h * ( (128 / 4) / 16))) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
        { { const int m = 0;  nr_contract_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_contract_acc[0][m]); }{ const int m = 1;  nr_contract_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_contract_acc[0][m]); }{ const int m = 2;  nr_contract_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_contract_acc[0][m]); }{ const int m = 3;  nr_contract_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_contract_acc[0][m]); } }
        { { const int m = 0;  nr_contract_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_contract_acc[1][m]); }{ const int m = 1;  nr_contract_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_contract_acc[1][m]); }{ const int m = 2;  nr_contract_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_contract_acc[1][m]); }{ const int m = 3;  nr_contract_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_contract_acc[1][m]); } }
    } }{ const int k = 2;  {
                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > ctx[ (64 / 16)];
        { { const int m = 0; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 1; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 2; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 3; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); } }
             coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                    { const uint q = (pc.ct_off) / 4u + ( (uint(nrhw_h * ( (128 / 4) / 16))) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
        { { const int m = 0;  nr_contract_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_contract_acc[0][m]); }{ const int m = 1;  nr_contract_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_contract_acc[0][m]); }{ const int m = 2;  nr_contract_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_contract_acc[0][m]); }{ const int m = 3;  nr_contract_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_contract_acc[0][m]); } }
        { { const int m = 0;  nr_contract_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_contract_acc[1][m]); }{ const int m = 1;  nr_contract_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_contract_acc[1][m]); }{ const int m = 2;  nr_contract_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_contract_acc[1][m]); }{ const int m = 3;  nr_contract_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_contract_acc[1][m]); } }
    } }{ const int k = 3;  {
                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > ctx[ (64 / 16)];
        { { const int m = 0; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 1; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 2; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 3; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); } }
             coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                    { const uint q = (pc.ct_off) / 4u + ( (uint(nrhw_h * ( (128 / 4) / 16))) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
        { { const int m = 0;  nr_contract_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_contract_acc[0][m]); }{ const int m = 1;  nr_contract_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_contract_acc[0][m]); }{ const int m = 2;  nr_contract_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_contract_acc[0][m]); }{ const int m = 3;  nr_contract_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_contract_acc[0][m]); } }
        { { const int m = 0;  nr_contract_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_contract_acc[1][m]); }{ const int m = 1;  nr_contract_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_contract_acc[1][m]); }{ const int m = 2;  nr_contract_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_contract_acc[1][m]); }{ const int m = 3;  nr_contract_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_contract_acc[1][m]); } }
    } }{ const int k = 4;  {
                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > ctx[ (64 / 16)];
        { { const int m = 0; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 1; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 2; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 3; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); } }
             coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                    { const uint q = (pc.ct_off) / 4u + ( (uint(nrhw_h * ( (128 / 4) / 16))) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
        { { const int m = 0;  nr_contract_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_contract_acc[0][m]); }{ const int m = 1;  nr_contract_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_contract_acc[0][m]); }{ const int m = 2;  nr_contract_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_contract_acc[0][m]); }{ const int m = 3;  nr_contract_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_contract_acc[0][m]); } }
        { { const int m = 0;  nr_contract_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_contract_acc[1][m]); }{ const int m = 1;  nr_contract_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_contract_acc[1][m]); }{ const int m = 2;  nr_contract_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_contract_acc[1][m]); }{ const int m = 3;  nr_contract_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_contract_acc[1][m]); } }
    } }{ const int k = 5;  {
                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > ctx[ (64 / 16)];
        { { const int m = 0; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 1; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 2; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 3; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); } }
             coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                    { const uint q = (pc.ct_off) / 4u + ( (uint(nrhw_h * ( (128 / 4) / 16))) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
        { { const int m = 0;  nr_contract_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_contract_acc[0][m]); }{ const int m = 1;  nr_contract_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_contract_acc[0][m]); }{ const int m = 2;  nr_contract_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_contract_acc[0][m]); }{ const int m = 3;  nr_contract_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_contract_acc[0][m]); } }
        { { const int m = 0;  nr_contract_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_contract_acc[1][m]); }{ const int m = 1;  nr_contract_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_contract_acc[1][m]); }{ const int m = 2;  nr_contract_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_contract_acc[1][m]); }{ const int m = 3;  nr_contract_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_contract_acc[1][m]); } }
    } }{ const int k = 6;  {
                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > ctx[ (64 / 16)];
        { { const int m = 0; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 1; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 2; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 3; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); } }
             coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                    { const uint q = (pc.ct_off) / 4u + ( (uint(nrhw_h * ( (128 / 4) / 16))) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
        { { const int m = 0;  nr_contract_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_contract_acc[0][m]); }{ const int m = 1;  nr_contract_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_contract_acc[0][m]); }{ const int m = 2;  nr_contract_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_contract_acc[0][m]); }{ const int m = 3;  nr_contract_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_contract_acc[0][m]); } }
        { { const int m = 0;  nr_contract_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_contract_acc[1][m]); }{ const int m = 1;  nr_contract_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_contract_acc[1][m]); }{ const int m = 2;  nr_contract_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_contract_acc[1][m]); }{ const int m = 3;  nr_contract_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_contract_acc[1][m]); } }
    } }{ const int k = 7;  {
                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > ctx[ (64 / 16)];
        { { const int m = 0; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 1; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 2; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 3; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); } }
             coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                    { const uint q = (pc.ct_off) / 4u + ( (uint(nrhw_h * ( (128 / 4) / 16))) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
        { { const int m = 0;  nr_contract_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_contract_acc[0][m]); }{ const int m = 1;  nr_contract_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_contract_acc[0][m]); }{ const int m = 2;  nr_contract_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_contract_acc[0][m]); }{ const int m = 3;  nr_contract_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_contract_acc[0][m]); } }
        { { const int m = 0;  nr_contract_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_contract_acc[1][m]); }{ const int m = 1;  nr_contract_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_contract_acc[1][m]); }{ const int m = 2;  nr_contract_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_contract_acc[1][m]); }{ const int m = 3;  nr_contract_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_contract_acc[1][m]); } }
    } } }


    { { const int nn = 0;  {
        const int n = nrhw_h * ( (128 / 4) / 16) + nn;


                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > xbk[ (64 / 16)];
        { { const int m = 0; 

                                                                   coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + n) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 1; 

                                                                   coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + n) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 2; 

                                                                   coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + n) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 3; 

                                                                   coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + n) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); } }



                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yqw[ (64 / 16)];







              coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > a[ (64 / 16)];
        { { const int m = 0;  a[m] = nr_contract_acc[nn][m]; }{ const int m = 1;  a[m] = nr_contract_acc[nn][m]; }{ const int m = 2;  a[m] = nr_contract_acc[nn][m]; }{ const int m = 3;  a[m] = nr_contract_acc[nn][m]; } }







































































        { { const int m = 0;  {

            float requantized[8];






















            { { const int c = 0;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 1;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 2;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 3;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 4;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 5;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 6;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 7;  {

                const float v = a[m][c];












                requantized[c] = v;










            } } }


            { { const int c = 0;  {
const fe4m3vec4 q = nr_quant_quad32(vec2(requantized[c], requantized[c + 1]), vec2(requantized[(c + 2)], requantized[(c + 2) + 1]));
yqw[m][c] = q.x;
yqw[m][c + 1] = q.y;
yqw[m][(c + 2)] = q.z;
yqw[m][(c + 2) + 1] = q.w;
} }{ const int c = 4;  {
const fe4m3vec4 q = nr_quant_quad32(vec2(requantized[c], requantized[c + 1]), vec2(requantized[(c + 2)], requantized[(c + 2) + 1]));
yqw[m][c] = q.x;
yqw[m][c + 1] = q.y;
yqw[m][(c + 2)] = q.z;
yqw[m][(c + 2) + 1] = q.w;
} } }
        } }{ const int m = 1;  {

            float requantized[8];






















            { { const int c = 0;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 1;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 2;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 3;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 4;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 5;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 6;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 7;  {

                const float v = a[m][c];












                requantized[c] = v;










            } } }


            { { const int c = 0;  {
const fe4m3vec4 q = nr_quant_quad32(vec2(requantized[c], requantized[c + 1]), vec2(requantized[(c + 2)], requantized[(c + 2) + 1]));
yqw[m][c] = q.x;
yqw[m][c + 1] = q.y;
yqw[m][(c + 2)] = q.z;
yqw[m][(c + 2) + 1] = q.w;
} }{ const int c = 4;  {
const fe4m3vec4 q = nr_quant_quad32(vec2(requantized[c], requantized[c + 1]), vec2(requantized[(c + 2)], requantized[(c + 2) + 1]));
yqw[m][c] = q.x;
yqw[m][c + 1] = q.y;
yqw[m][(c + 2)] = q.z;
yqw[m][(c + 2) + 1] = q.w;
} } }
        } }{ const int m = 2;  {

            float requantized[8];






















            { { const int c = 0;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 1;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 2;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 3;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 4;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 5;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 6;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 7;  {

                const float v = a[m][c];












                requantized[c] = v;










            } } }


            { { const int c = 0;  {
const fe4m3vec4 q = nr_quant_quad32(vec2(requantized[c], requantized[c + 1]), vec2(requantized[(c + 2)], requantized[(c + 2) + 1]));
yqw[m][c] = q.x;
yqw[m][c + 1] = q.y;
yqw[m][(c + 2)] = q.z;
yqw[m][(c + 2) + 1] = q.w;
} }{ const int c = 4;  {
const fe4m3vec4 q = nr_quant_quad32(vec2(requantized[c], requantized[c + 1]), vec2(requantized[(c + 2)], requantized[(c + 2) + 1]));
yqw[m][c] = q.x;
yqw[m][c + 1] = q.y;
yqw[m][(c + 2)] = q.z;
yqw[m][(c + 2) + 1] = q.w;
} } }
        } }{ const int m = 3;  {

            float requantized[8];






















            { { const int c = 0;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 1;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 2;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 3;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 4;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 5;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 6;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 7;  {

                const float v = a[m][c];












                requantized[c] = v;










            } } }


            { { const int c = 0;  {
const fe4m3vec4 q = nr_quant_quad32(vec2(requantized[c], requantized[c + 1]), vec2(requantized[(c + 2)], requantized[(c + 2) + 1]));
yqw[m][c] = q.x;
yqw[m][c + 1] = q.y;
yqw[m][(c + 2)] = q.z;
yqw[m][(c + 2) + 1] = q.w;
} }{ const int c = 4;  {
const fe4m3vec4 q = nr_quant_quad32(vec2(requantized[c], requantized[c + 1]), vec2(requantized[(c + 2)], requantized[(c + 2) + 1]));
yqw[m][c] = q.x;
yqw[m][c + 1] = q.y;
yqw[m][(c + 2)] = q.z;
yqw[m][(c + 2) + 1] = q.w;
} } }
        } } }





        { { const int m = 0;  {
                       coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > yf;
            { { const int c = 0;  yf[c] = yqw[m][c]; }{ const int c = 1;  yf[c] = yqw[m][c]; }{ const int c = 2;  yf[c] = yqw[m][c]; }{ const int c = 3;  yf[c] = yqw[m][c]; }{ const int c = 4;  yf[c] = yqw[m][c]; }{ const int c = 5;  yf[c] = yqw[m][c]; }{ const int c = 6;  yf[c] = yqw[m][c]; }{ const int c = 7;  yf[c] = yqw[m][c]; } }
                                                                               coopMatStore(yf, lds_x, (uint(m * (128 / 16) + n) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);
        } }{ const int m = 1;  {
                       coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > yf;
            { { const int c = 0;  yf[c] = yqw[m][c]; }{ const int c = 1;  yf[c] = yqw[m][c]; }{ const int c = 2;  yf[c] = yqw[m][c]; }{ const int c = 3;  yf[c] = yqw[m][c]; }{ const int c = 4;  yf[c] = yqw[m][c]; }{ const int c = 5;  yf[c] = yqw[m][c]; }{ const int c = 6;  yf[c] = yqw[m][c]; }{ const int c = 7;  yf[c] = yqw[m][c]; } }
                                                                               coopMatStore(yf, lds_x, (uint(m * (128 / 16) + n) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);
        } }{ const int m = 2;  {
                       coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > yf;
            { { const int c = 0;  yf[c] = yqw[m][c]; }{ const int c = 1;  yf[c] = yqw[m][c]; }{ const int c = 2;  yf[c] = yqw[m][c]; }{ const int c = 3;  yf[c] = yqw[m][c]; }{ const int c = 4;  yf[c] = yqw[m][c]; }{ const int c = 5;  yf[c] = yqw[m][c]; }{ const int c = 6;  yf[c] = yqw[m][c]; }{ const int c = 7;  yf[c] = yqw[m][c]; } }
                                                                               coopMatStore(yf, lds_x, (uint(m * (128 / 16) + n) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);
        } }{ const int m = 3;  {
                       coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > yf;
            { { const int c = 0;  yf[c] = yqw[m][c]; }{ const int c = 1;  yf[c] = yqw[m][c]; }{ const int c = 2;  yf[c] = yqw[m][c]; }{ const int c = 3;  yf[c] = yqw[m][c]; }{ const int c = 4;  yf[c] = yqw[m][c]; }{ const int c = 5;  yf[c] = yqw[m][c]; }{ const int c = 6;  yf[c] = yqw[m][c]; }{ const int c = 7;  yf[c] = yqw[m][c]; } }
                                                                               coopMatStore(yf, lds_x, (uint(m * (128 / 16) + n) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);
        } } }

    } }{ const int nn = 1;  {
        const int n = nrhw_h * ( (128 / 4) / 16) + nn;


                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > xbk[ (64 / 16)];
        { { const int m = 0; 

                                                                   coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + n) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 1; 

                                                                   coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + n) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 2; 

                                                                   coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + n) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 3; 

                                                                   coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + n) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); } }



                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yqw[ (64 / 16)];







              coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > a[ (64 / 16)];
        { { const int m = 0;  a[m] = nr_contract_acc[nn][m]; }{ const int m = 1;  a[m] = nr_contract_acc[nn][m]; }{ const int m = 2;  a[m] = nr_contract_acc[nn][m]; }{ const int m = 3;  a[m] = nr_contract_acc[nn][m]; } }







































































        { { const int m = 0;  {

            float requantized[8];






















            { { const int c = 0;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 1;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 2;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 3;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 4;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 5;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 6;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 7;  {

                const float v = a[m][c];












                requantized[c] = v;










            } } }


            { { const int c = 0;  {
const fe4m3vec4 q = nr_quant_quad32(vec2(requantized[c], requantized[c + 1]), vec2(requantized[(c + 2)], requantized[(c + 2) + 1]));
yqw[m][c] = q.x;
yqw[m][c + 1] = q.y;
yqw[m][(c + 2)] = q.z;
yqw[m][(c + 2) + 1] = q.w;
} }{ const int c = 4;  {
const fe4m3vec4 q = nr_quant_quad32(vec2(requantized[c], requantized[c + 1]), vec2(requantized[(c + 2)], requantized[(c + 2) + 1]));
yqw[m][c] = q.x;
yqw[m][c + 1] = q.y;
yqw[m][(c + 2)] = q.z;
yqw[m][(c + 2) + 1] = q.w;
} } }
        } }{ const int m = 1;  {

            float requantized[8];






















            { { const int c = 0;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 1;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 2;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 3;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 4;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 5;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 6;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 7;  {

                const float v = a[m][c];












                requantized[c] = v;










            } } }


            { { const int c = 0;  {
const fe4m3vec4 q = nr_quant_quad32(vec2(requantized[c], requantized[c + 1]), vec2(requantized[(c + 2)], requantized[(c + 2) + 1]));
yqw[m][c] = q.x;
yqw[m][c + 1] = q.y;
yqw[m][(c + 2)] = q.z;
yqw[m][(c + 2) + 1] = q.w;
} }{ const int c = 4;  {
const fe4m3vec4 q = nr_quant_quad32(vec2(requantized[c], requantized[c + 1]), vec2(requantized[(c + 2)], requantized[(c + 2) + 1]));
yqw[m][c] = q.x;
yqw[m][c + 1] = q.y;
yqw[m][(c + 2)] = q.z;
yqw[m][(c + 2) + 1] = q.w;
} } }
        } }{ const int m = 2;  {

            float requantized[8];






















            { { const int c = 0;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 1;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 2;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 3;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 4;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 5;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 6;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 7;  {

                const float v = a[m][c];












                requantized[c] = v;










            } } }


            { { const int c = 0;  {
const fe4m3vec4 q = nr_quant_quad32(vec2(requantized[c], requantized[c + 1]), vec2(requantized[(c + 2)], requantized[(c + 2) + 1]));
yqw[m][c] = q.x;
yqw[m][c + 1] = q.y;
yqw[m][(c + 2)] = q.z;
yqw[m][(c + 2) + 1] = q.w;
} }{ const int c = 4;  {
const fe4m3vec4 q = nr_quant_quad32(vec2(requantized[c], requantized[c + 1]), vec2(requantized[(c + 2)], requantized[(c + 2) + 1]));
yqw[m][c] = q.x;
yqw[m][c + 1] = q.y;
yqw[m][(c + 2)] = q.z;
yqw[m][(c + 2) + 1] = q.w;
} } }
        } }{ const int m = 3;  {

            float requantized[8];






















            { { const int c = 0;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 1;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 2;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 3;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 4;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 5;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 6;  {

                const float v = a[m][c];












                requantized[c] = v;










            } }{ const int c = 7;  {

                const float v = a[m][c];












                requantized[c] = v;










            } } }


            { { const int c = 0;  {
const fe4m3vec4 q = nr_quant_quad32(vec2(requantized[c], requantized[c + 1]), vec2(requantized[(c + 2)], requantized[(c + 2) + 1]));
yqw[m][c] = q.x;
yqw[m][c + 1] = q.y;
yqw[m][(c + 2)] = q.z;
yqw[m][(c + 2) + 1] = q.w;
} }{ const int c = 4;  {
const fe4m3vec4 q = nr_quant_quad32(vec2(requantized[c], requantized[c + 1]), vec2(requantized[(c + 2)], requantized[(c + 2) + 1]));
yqw[m][c] = q.x;
yqw[m][c + 1] = q.y;
yqw[m][(c + 2)] = q.z;
yqw[m][(c + 2) + 1] = q.w;
} } }
        } } }





        { { const int m = 0;  {
                       coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > yf;
            { { const int c = 0;  yf[c] = yqw[m][c]; }{ const int c = 1;  yf[c] = yqw[m][c]; }{ const int c = 2;  yf[c] = yqw[m][c]; }{ const int c = 3;  yf[c] = yqw[m][c]; }{ const int c = 4;  yf[c] = yqw[m][c]; }{ const int c = 5;  yf[c] = yqw[m][c]; }{ const int c = 6;  yf[c] = yqw[m][c]; }{ const int c = 7;  yf[c] = yqw[m][c]; } }
                                                                               coopMatStore(yf, lds_x, (uint(m * (128 / 16) + n) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);
        } }{ const int m = 1;  {
                       coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > yf;
            { { const int c = 0;  yf[c] = yqw[m][c]; }{ const int c = 1;  yf[c] = yqw[m][c]; }{ const int c = 2;  yf[c] = yqw[m][c]; }{ const int c = 3;  yf[c] = yqw[m][c]; }{ const int c = 4;  yf[c] = yqw[m][c]; }{ const int c = 5;  yf[c] = yqw[m][c]; }{ const int c = 6;  yf[c] = yqw[m][c]; }{ const int c = 7;  yf[c] = yqw[m][c]; } }
                                                                               coopMatStore(yf, lds_x, (uint(m * (128 / 16) + n) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);
        } }{ const int m = 2;  {
                       coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > yf;
            { { const int c = 0;  yf[c] = yqw[m][c]; }{ const int c = 1;  yf[c] = yqw[m][c]; }{ const int c = 2;  yf[c] = yqw[m][c]; }{ const int c = 3;  yf[c] = yqw[m][c]; }{ const int c = 4;  yf[c] = yqw[m][c]; }{ const int c = 5;  yf[c] = yqw[m][c]; }{ const int c = 6;  yf[c] = yqw[m][c]; }{ const int c = 7;  yf[c] = yqw[m][c]; } }
                                                                               coopMatStore(yf, lds_x, (uint(m * (128 / 16) + n) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);
        } }{ const int m = 3;  {
                       coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > yf;
            { { const int c = 0;  yf[c] = yqw[m][c]; }{ const int c = 1;  yf[c] = yqw[m][c]; }{ const int c = 2;  yf[c] = yqw[m][c]; }{ const int c = 3;  yf[c] = yqw[m][c]; }{ const int c = 4;  yf[c] = yqw[m][c]; }{ const int c = 5;  yf[c] = yqw[m][c]; }{ const int c = 6;  yf[c] = yqw[m][c]; }{ const int c = 7;  yf[c] = yqw[m][c]; } }
                                                                               coopMatStore(yf, lds_x, (uint(m * (128 / 16) + n) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);
        } } }

    } } }

    barrier();































    {
        const int hh = nrhw_h;





                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > kreg[ (64 / 16)][ ( (128 / 4) / 16)];


                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > vreg[ ( (128 / 4) / 16)][ (64 / 16)];

        const float16_t hscale = float16_t(wgt_f32[pc.s_off + uint(hh)]);
                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > qb[ (64 / 16)][ ( (128 / 4) / 16)];
























        {










                  coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > acc[ (64 / 16)][ ( (1 + 1) * ( (128 / 4) / 16))];

            { { const int m = 0; 
                { { const int d = 0;  acc[m][d] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int d = 1;  acc[m][d] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int d = 2;  acc[m][d] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int d = 3;  acc[m][d] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); } } }{ const int m = 1; 
                { { const int d = 0;  acc[m][d] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int d = 1;  acc[m][d] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int d = 2;  acc[m][d] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int d = 3;  acc[m][d] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); } } }{ const int m = 2; 
                { { const int d = 0;  acc[m][d] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int d = 1;  acc[m][d] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int d = 2;  acc[m][d] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int d = 3;  acc[m][d] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); } } }{ const int m = 3; 
                { { const int d = 0;  acc[m][d] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int d = 1;  acc[m][d] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int d = 2;  acc[m][d] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int d = 3;  acc[m][d] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); } } } }
            { { const int k = 0;  {
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yk[ (64 / 16)];
                { { const int m = 0; 

                                                                            coopMatLoad(yk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (128u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 1; 

                                                                            coopMatLoad(yk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (128u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 2; 

                                                                            coopMatLoad(yk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (128u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 3; 

                                                                            coopMatLoad(yk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (128u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); } }




                { { const int r = 0;  {
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                                  { const uint q = (pc.qkv_off) / 4u + ( (uint(hh * 3 * ( (128 / 4) / 16) + 0 + r)) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); }{ const int m = 1;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); }{ const int m = 2;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); }{ const int m = 3;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); } }
                    { { const int m = 0;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); }{ const int m = 1;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); }{ const int m = 2;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); }{ const int m = 3;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); } }
                } }{ const int r = 2;  {
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                                  { const uint q = (pc.qkv_off) / 4u + ( (uint(hh * 3 * ( (128 / 4) / 16) + 0 + r)) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); }{ const int m = 1;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); }{ const int m = 2;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); }{ const int m = 3;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); } }
                    { { const int m = 0;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); }{ const int m = 1;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); }{ const int m = 2;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); }{ const int m = 3;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); } }
                } } }







                if (0 > 0 && (k + 1) % 0 == 0)
                    { { const int m = 0; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } }{ const int r = 2;  { } }{ const int r = 3;  { } } } }{ const int m = 1; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } }{ const int r = 2;  { } }{ const int r = 3;  { } } } }{ const int m = 2; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } }{ const int r = 2;  { } }{ const int r = 3;  { } } } }{ const int m = 3; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } }{ const int r = 2;  { } }{ const int r = 3;  { } } } } }

            } }{ const int k = 1;  {
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yk[ (64 / 16)];
                { { const int m = 0; 

                                                                            coopMatLoad(yk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (128u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 1; 

                                                                            coopMatLoad(yk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (128u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 2; 

                                                                            coopMatLoad(yk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (128u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 3; 

                                                                            coopMatLoad(yk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (128u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); } }




                { { const int r = 0;  {
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                                  { const uint q = (pc.qkv_off) / 4u + ( (uint(hh * 3 * ( (128 / 4) / 16) + 0 + r)) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); }{ const int m = 1;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); }{ const int m = 2;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); }{ const int m = 3;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); } }
                    { { const int m = 0;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); }{ const int m = 1;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); }{ const int m = 2;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); }{ const int m = 3;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); } }
                } }{ const int r = 2;  {
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                                  { const uint q = (pc.qkv_off) / 4u + ( (uint(hh * 3 * ( (128 / 4) / 16) + 0 + r)) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); }{ const int m = 1;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); }{ const int m = 2;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); }{ const int m = 3;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); } }
                    { { const int m = 0;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); }{ const int m = 1;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); }{ const int m = 2;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); }{ const int m = 3;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); } }
                } } }







                if (0 > 0 && (k + 1) % 0 == 0)
                    { { const int m = 0; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } }{ const int r = 2;  { } }{ const int r = 3;  { } } } }{ const int m = 1; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } }{ const int r = 2;  { } }{ const int r = 3;  { } } } }{ const int m = 2; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } }{ const int r = 2;  { } }{ const int r = 3;  { } } } }{ const int m = 3; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } }{ const int r = 2;  { } }{ const int r = 3;  { } } } } }

            } }{ const int k = 2;  {
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yk[ (64 / 16)];
                { { const int m = 0; 

                                                                            coopMatLoad(yk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (128u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 1; 

                                                                            coopMatLoad(yk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (128u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 2; 

                                                                            coopMatLoad(yk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (128u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 3; 

                                                                            coopMatLoad(yk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (128u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); } }




                { { const int r = 0;  {
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                                  { const uint q = (pc.qkv_off) / 4u + ( (uint(hh * 3 * ( (128 / 4) / 16) + 0 + r)) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); }{ const int m = 1;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); }{ const int m = 2;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); }{ const int m = 3;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); } }
                    { { const int m = 0;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); }{ const int m = 1;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); }{ const int m = 2;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); }{ const int m = 3;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); } }
                } }{ const int r = 2;  {
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                                  { const uint q = (pc.qkv_off) / 4u + ( (uint(hh * 3 * ( (128 / 4) / 16) + 0 + r)) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); }{ const int m = 1;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); }{ const int m = 2;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); }{ const int m = 3;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); } }
                    { { const int m = 0;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); }{ const int m = 1;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); }{ const int m = 2;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); }{ const int m = 3;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); } }
                } } }







                if (0 > 0 && (k + 1) % 0 == 0)
                    { { const int m = 0; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } }{ const int r = 2;  { } }{ const int r = 3;  { } } } }{ const int m = 1; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } }{ const int r = 2;  { } }{ const int r = 3;  { } } } }{ const int m = 2; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } }{ const int r = 2;  { } }{ const int r = 3;  { } } } }{ const int m = 3; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } }{ const int r = 2;  { } }{ const int r = 3;  { } } } } }

            } }{ const int k = 3;  {
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yk[ (64 / 16)];
                { { const int m = 0; 

                                                                            coopMatLoad(yk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (128u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 1; 

                                                                            coopMatLoad(yk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (128u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 2; 

                                                                            coopMatLoad(yk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (128u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 3; 

                                                                            coopMatLoad(yk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (128u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); } }




                { { const int r = 0;  {
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                                  { const uint q = (pc.qkv_off) / 4u + ( (uint(hh * 3 * ( (128 / 4) / 16) + 0 + r)) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); }{ const int m = 1;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); }{ const int m = 2;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); }{ const int m = 3;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); } }
                    { { const int m = 0;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); }{ const int m = 1;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); }{ const int m = 2;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); }{ const int m = 3;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); } }
                } }{ const int r = 2;  {
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                                  { const uint q = (pc.qkv_off) / 4u + ( (uint(hh * 3 * ( (128 / 4) / 16) + 0 + r)) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); }{ const int m = 1;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); }{ const int m = 2;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); }{ const int m = 3;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); } }
                    { { const int m = 0;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); }{ const int m = 1;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); }{ const int m = 2;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); }{ const int m = 3;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); } }
                } } }







                if (0 > 0 && (k + 1) % 0 == 0)
                    { { const int m = 0; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } }{ const int r = 2;  { } }{ const int r = 3;  { } } } }{ const int m = 1; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } }{ const int r = 2;  { } }{ const int r = 3;  { } } } }{ const int m = 2; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } }{ const int r = 2;  { } }{ const int r = 3;  { } } } }{ const int m = 3; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } }{ const int r = 2;  { } }{ const int r = 3;  { } } } } }

            } }{ const int k = 4;  {
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yk[ (64 / 16)];
                { { const int m = 0; 

                                                                            coopMatLoad(yk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (128u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 1; 

                                                                            coopMatLoad(yk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (128u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 2; 

                                                                            coopMatLoad(yk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (128u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 3; 

                                                                            coopMatLoad(yk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (128u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); } }




                { { const int r = 0;  {
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                                  { const uint q = (pc.qkv_off) / 4u + ( (uint(hh * 3 * ( (128 / 4) / 16) + 0 + r)) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); }{ const int m = 1;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); }{ const int m = 2;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); }{ const int m = 3;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); } }
                    { { const int m = 0;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); }{ const int m = 1;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); }{ const int m = 2;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); }{ const int m = 3;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); } }
                } }{ const int r = 2;  {
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                                  { const uint q = (pc.qkv_off) / 4u + ( (uint(hh * 3 * ( (128 / 4) / 16) + 0 + r)) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); }{ const int m = 1;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); }{ const int m = 2;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); }{ const int m = 3;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); } }
                    { { const int m = 0;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); }{ const int m = 1;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); }{ const int m = 2;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); }{ const int m = 3;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); } }
                } } }







                if (0 > 0 && (k + 1) % 0 == 0)
                    { { const int m = 0; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } }{ const int r = 2;  { } }{ const int r = 3;  { } } } }{ const int m = 1; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } }{ const int r = 2;  { } }{ const int r = 3;  { } } } }{ const int m = 2; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } }{ const int r = 2;  { } }{ const int r = 3;  { } } } }{ const int m = 3; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } }{ const int r = 2;  { } }{ const int r = 3;  { } } } } }

            } }{ const int k = 5;  {
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yk[ (64 / 16)];
                { { const int m = 0; 

                                                                            coopMatLoad(yk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (128u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 1; 

                                                                            coopMatLoad(yk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (128u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 2; 

                                                                            coopMatLoad(yk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (128u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 3; 

                                                                            coopMatLoad(yk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (128u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); } }




                { { const int r = 0;  {
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                                  { const uint q = (pc.qkv_off) / 4u + ( (uint(hh * 3 * ( (128 / 4) / 16) + 0 + r)) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); }{ const int m = 1;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); }{ const int m = 2;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); }{ const int m = 3;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); } }
                    { { const int m = 0;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); }{ const int m = 1;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); }{ const int m = 2;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); }{ const int m = 3;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); } }
                } }{ const int r = 2;  {
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                                  { const uint q = (pc.qkv_off) / 4u + ( (uint(hh * 3 * ( (128 / 4) / 16) + 0 + r)) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); }{ const int m = 1;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); }{ const int m = 2;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); }{ const int m = 3;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); } }
                    { { const int m = 0;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); }{ const int m = 1;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); }{ const int m = 2;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); }{ const int m = 3;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); } }
                } } }







                if (0 > 0 && (k + 1) % 0 == 0)
                    { { const int m = 0; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } }{ const int r = 2;  { } }{ const int r = 3;  { } } } }{ const int m = 1; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } }{ const int r = 2;  { } }{ const int r = 3;  { } } } }{ const int m = 2; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } }{ const int r = 2;  { } }{ const int r = 3;  { } } } }{ const int m = 3; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } }{ const int r = 2;  { } }{ const int r = 3;  { } } } } }

            } }{ const int k = 6;  {
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yk[ (64 / 16)];
                { { const int m = 0; 

                                                                            coopMatLoad(yk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (128u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 1; 

                                                                            coopMatLoad(yk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (128u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 2; 

                                                                            coopMatLoad(yk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (128u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 3; 

                                                                            coopMatLoad(yk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (128u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); } }




                { { const int r = 0;  {
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                                  { const uint q = (pc.qkv_off) / 4u + ( (uint(hh * 3 * ( (128 / 4) / 16) + 0 + r)) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); }{ const int m = 1;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); }{ const int m = 2;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); }{ const int m = 3;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); } }
                    { { const int m = 0;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); }{ const int m = 1;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); }{ const int m = 2;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); }{ const int m = 3;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); } }
                } }{ const int r = 2;  {
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                                  { const uint q = (pc.qkv_off) / 4u + ( (uint(hh * 3 * ( (128 / 4) / 16) + 0 + r)) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); }{ const int m = 1;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); }{ const int m = 2;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); }{ const int m = 3;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); } }
                    { { const int m = 0;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); }{ const int m = 1;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); }{ const int m = 2;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); }{ const int m = 3;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); } }
                } } }







                if (0 > 0 && (k + 1) % 0 == 0)
                    { { const int m = 0; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } }{ const int r = 2;  { } }{ const int r = 3;  { } } } }{ const int m = 1; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } }{ const int r = 2;  { } }{ const int r = 3;  { } } } }{ const int m = 2; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } }{ const int r = 2;  { } }{ const int r = 3;  { } } } }{ const int m = 3; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } }{ const int r = 2;  { } }{ const int r = 3;  { } } } } }

            } }{ const int k = 7;  {
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yk[ (64 / 16)];
                { { const int m = 0; 

                                                                            coopMatLoad(yk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (128u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 1; 

                                                                            coopMatLoad(yk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (128u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 2; 

                                                                            coopMatLoad(yk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (128u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 3; 

                                                                            coopMatLoad(yk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (128u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); } }




                { { const int r = 0;  {
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                                  { const uint q = (pc.qkv_off) / 4u + ( (uint(hh * 3 * ( (128 / 4) / 16) + 0 + r)) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); }{ const int m = 1;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); }{ const int m = 2;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); }{ const int m = 3;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); } }
                    { { const int m = 0;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); }{ const int m = 1;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); }{ const int m = 2;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); }{ const int m = 3;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); } }
                } }{ const int r = 2;  {
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                                  { const uint q = (pc.qkv_off) / 4u + ( (uint(hh * 3 * ( (128 / 4) / 16) + 0 + r)) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); }{ const int m = 1;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); }{ const int m = 2;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); }{ const int m = 3;  acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]); } }
                    { { const int m = 0;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); }{ const int m = 1;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); }{ const int m = 2;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); }{ const int m = 3;  acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]); } }
                } } }







                if (0 > 0 && (k + 1) % 0 == 0)
                    { { const int m = 0; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } }{ const int r = 2;  { } }{ const int r = 3;  { } } } }{ const int m = 1; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } }{ const int r = 2;  { } }{ const int r = 3;  { } } } }{ const int m = 2; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } }{ const int r = 2;  { } }{ const int r = 3;  { } } } }{ const int m = 3; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } }{ const int r = 2;  { } }{ const int r = 3;  { } } } } }

            } } }
            { { const int m = 0;  {

                float sqp[4];
                { { const int i = 0;  sqp[i] = 0.0; }{ const int i = 1;  sqp[i] = 0.0; }{ const int i = 2;  sqp[i] = 0.0; }{ const int i = 3;  sqp[i] = 0.0; } }
                { { const int c = 0; 
                    { { const int d = 0;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } }{ const int d = 1;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } } } }{ const int c = 1; 
                    { { const int d = 0;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } }{ const int d = 1;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } } } }{ const int c = 2; 
                    { { const int d = 0;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } }{ const int d = 1;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } } } }{ const int c = 3; 
                    { { const int d = 0;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } }{ const int d = 1;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } } } }{ const int c = 4; 
                    { { const int d = 0;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } }{ const int d = 1;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } } } }{ const int c = 5; 
                    { { const int d = 0;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } }{ const int d = 1;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } } } }{ const int c = 6; 
                    { { const int d = 0;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } }{ const int d = 1;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } } } }{ const int c = 7; 
                    { { const int d = 0;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } }{ const int d = 1;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } } } } }








                f16vec2 sq = f16vec2(vec2( (sqp[0] + sqp[1]) + (sqp[2] + sqp[3]), 0.0));
                sq = sq + unpackFloat2x16(subgroupShuffleXor(packFloat2x16(sq), 16u));
                const float16_t nq =
                                    float16_t(inversesqrt(float(max( (sq.x), float16_t(0.000062)))));





































                { { const int d = 0; 
                    { { const int c = 0;  {
const fe4m3vec4 qp = nr_qscale_fast4(vec2(acc[m][d][c], acc[m][d][c + 1]), nq, hscale, vec2(acc[m][d][(c + 2)], acc[m][d][(c + 2) + 1]), nq, hscale);
qb[m][d][c] = qp.x;
qb[m][d][c + 1] = qp.y;
qb[m][d][(c + 2)] = qp.z;
qb[m][d][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_qscale_fast4(vec2(acc[m][d][c], acc[m][d][c + 1]), nq, hscale, vec2(acc[m][d][(c + 2)], acc[m][d][(c + 2) + 1]), nq, hscale);
qb[m][d][c] = qp.x;
qb[m][d][c + 1] = qp.y;
qb[m][d][(c + 2)] = qp.z;
qb[m][d][(c + 2) + 1] = qp.w;
} } } }{ const int d = 1; 
                    { { const int c = 0;  {
const fe4m3vec4 qp = nr_qscale_fast4(vec2(acc[m][d][c], acc[m][d][c + 1]), nq, hscale, vec2(acc[m][d][(c + 2)], acc[m][d][(c + 2) + 1]), nq, hscale);
qb[m][d][c] = qp.x;
qb[m][d][c + 1] = qp.y;
qb[m][d][(c + 2)] = qp.z;
qb[m][d][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_qscale_fast4(vec2(acc[m][d][c], acc[m][d][c + 1]), nq, hscale, vec2(acc[m][d][(c + 2)], acc[m][d][(c + 2) + 1]), nq, hscale);
qb[m][d][c] = qp.x;
qb[m][d][c + 1] = qp.y;
qb[m][d][(c + 2)] = qp.z;
qb[m][d][(c + 2) + 1] = qp.w;
} } } } }
            } }{ const int m = 1;  {

                float sqp[4];
                { { const int i = 0;  sqp[i] = 0.0; }{ const int i = 1;  sqp[i] = 0.0; }{ const int i = 2;  sqp[i] = 0.0; }{ const int i = 3;  sqp[i] = 0.0; } }
                { { const int c = 0; 
                    { { const int d = 0;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } }{ const int d = 1;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } } } }{ const int c = 1; 
                    { { const int d = 0;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } }{ const int d = 1;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } } } }{ const int c = 2; 
                    { { const int d = 0;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } }{ const int d = 1;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } } } }{ const int c = 3; 
                    { { const int d = 0;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } }{ const int d = 1;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } } } }{ const int c = 4; 
                    { { const int d = 0;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } }{ const int d = 1;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } } } }{ const int c = 5; 
                    { { const int d = 0;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } }{ const int d = 1;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } } } }{ const int c = 6; 
                    { { const int d = 0;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } }{ const int d = 1;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } } } }{ const int c = 7; 
                    { { const int d = 0;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } }{ const int d = 1;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } } } } }








                f16vec2 sq = f16vec2(vec2( (sqp[0] + sqp[1]) + (sqp[2] + sqp[3]), 0.0));
                sq = sq + unpackFloat2x16(subgroupShuffleXor(packFloat2x16(sq), 16u));
                const float16_t nq =
                                    float16_t(inversesqrt(float(max( (sq.x), float16_t(0.000062)))));





































                { { const int d = 0; 
                    { { const int c = 0;  {
const fe4m3vec4 qp = nr_qscale_fast4(vec2(acc[m][d][c], acc[m][d][c + 1]), nq, hscale, vec2(acc[m][d][(c + 2)], acc[m][d][(c + 2) + 1]), nq, hscale);
qb[m][d][c] = qp.x;
qb[m][d][c + 1] = qp.y;
qb[m][d][(c + 2)] = qp.z;
qb[m][d][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_qscale_fast4(vec2(acc[m][d][c], acc[m][d][c + 1]), nq, hscale, vec2(acc[m][d][(c + 2)], acc[m][d][(c + 2) + 1]), nq, hscale);
qb[m][d][c] = qp.x;
qb[m][d][c + 1] = qp.y;
qb[m][d][(c + 2)] = qp.z;
qb[m][d][(c + 2) + 1] = qp.w;
} } } }{ const int d = 1; 
                    { { const int c = 0;  {
const fe4m3vec4 qp = nr_qscale_fast4(vec2(acc[m][d][c], acc[m][d][c + 1]), nq, hscale, vec2(acc[m][d][(c + 2)], acc[m][d][(c + 2) + 1]), nq, hscale);
qb[m][d][c] = qp.x;
qb[m][d][c + 1] = qp.y;
qb[m][d][(c + 2)] = qp.z;
qb[m][d][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_qscale_fast4(vec2(acc[m][d][c], acc[m][d][c + 1]), nq, hscale, vec2(acc[m][d][(c + 2)], acc[m][d][(c + 2) + 1]), nq, hscale);
qb[m][d][c] = qp.x;
qb[m][d][c + 1] = qp.y;
qb[m][d][(c + 2)] = qp.z;
qb[m][d][(c + 2) + 1] = qp.w;
} } } } }
            } }{ const int m = 2;  {

                float sqp[4];
                { { const int i = 0;  sqp[i] = 0.0; }{ const int i = 1;  sqp[i] = 0.0; }{ const int i = 2;  sqp[i] = 0.0; }{ const int i = 3;  sqp[i] = 0.0; } }
                { { const int c = 0; 
                    { { const int d = 0;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } }{ const int d = 1;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } } } }{ const int c = 1; 
                    { { const int d = 0;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } }{ const int d = 1;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } } } }{ const int c = 2; 
                    { { const int d = 0;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } }{ const int d = 1;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } } } }{ const int c = 3; 
                    { { const int d = 0;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } }{ const int d = 1;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } } } }{ const int c = 4; 
                    { { const int d = 0;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } }{ const int d = 1;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } } } }{ const int c = 5; 
                    { { const int d = 0;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } }{ const int d = 1;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } } } }{ const int c = 6; 
                    { { const int d = 0;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } }{ const int d = 1;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } } } }{ const int c = 7; 
                    { { const int d = 0;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } }{ const int d = 1;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } } } } }








                f16vec2 sq = f16vec2(vec2( (sqp[0] + sqp[1]) + (sqp[2] + sqp[3]), 0.0));
                sq = sq + unpackFloat2x16(subgroupShuffleXor(packFloat2x16(sq), 16u));
                const float16_t nq =
                                    float16_t(inversesqrt(float(max( (sq.x), float16_t(0.000062)))));





































                { { const int d = 0; 
                    { { const int c = 0;  {
const fe4m3vec4 qp = nr_qscale_fast4(vec2(acc[m][d][c], acc[m][d][c + 1]), nq, hscale, vec2(acc[m][d][(c + 2)], acc[m][d][(c + 2) + 1]), nq, hscale);
qb[m][d][c] = qp.x;
qb[m][d][c + 1] = qp.y;
qb[m][d][(c + 2)] = qp.z;
qb[m][d][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_qscale_fast4(vec2(acc[m][d][c], acc[m][d][c + 1]), nq, hscale, vec2(acc[m][d][(c + 2)], acc[m][d][(c + 2) + 1]), nq, hscale);
qb[m][d][c] = qp.x;
qb[m][d][c + 1] = qp.y;
qb[m][d][(c + 2)] = qp.z;
qb[m][d][(c + 2) + 1] = qp.w;
} } } }{ const int d = 1; 
                    { { const int c = 0;  {
const fe4m3vec4 qp = nr_qscale_fast4(vec2(acc[m][d][c], acc[m][d][c + 1]), nq, hscale, vec2(acc[m][d][(c + 2)], acc[m][d][(c + 2) + 1]), nq, hscale);
qb[m][d][c] = qp.x;
qb[m][d][c + 1] = qp.y;
qb[m][d][(c + 2)] = qp.z;
qb[m][d][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_qscale_fast4(vec2(acc[m][d][c], acc[m][d][c + 1]), nq, hscale, vec2(acc[m][d][(c + 2)], acc[m][d][(c + 2) + 1]), nq, hscale);
qb[m][d][c] = qp.x;
qb[m][d][c + 1] = qp.y;
qb[m][d][(c + 2)] = qp.z;
qb[m][d][(c + 2) + 1] = qp.w;
} } } } }
            } }{ const int m = 3;  {

                float sqp[4];
                { { const int i = 0;  sqp[i] = 0.0; }{ const int i = 1;  sqp[i] = 0.0; }{ const int i = 2;  sqp[i] = 0.0; }{ const int i = 3;  sqp[i] = 0.0; } }
                { { const int c = 0; 
                    { { const int d = 0;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } }{ const int d = 1;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } } } }{ const int c = 1; 
                    { { const int d = 0;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } }{ const int d = 1;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } } } }{ const int c = 2; 
                    { { const int d = 0;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } }{ const int d = 1;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } } } }{ const int c = 3; 
                    { { const int d = 0;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } }{ const int d = 1;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } } } }{ const int c = 4; 
                    { { const int d = 0;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } }{ const int d = 1;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } } } }{ const int c = 5; 
                    { { const int d = 0;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } }{ const int d = 1;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } } } }{ const int c = 6; 
                    { { const int d = 0;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } }{ const int d = 1;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } } } }{ const int c = 7; 
                    { { const int d = 0;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } }{ const int d = 1;  {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    } } } } }








                f16vec2 sq = f16vec2(vec2( (sqp[0] + sqp[1]) + (sqp[2] + sqp[3]), 0.0));
                sq = sq + unpackFloat2x16(subgroupShuffleXor(packFloat2x16(sq), 16u));
                const float16_t nq =
                                    float16_t(inversesqrt(float(max( (sq.x), float16_t(0.000062)))));





































                { { const int d = 0; 
                    { { const int c = 0;  {
const fe4m3vec4 qp = nr_qscale_fast4(vec2(acc[m][d][c], acc[m][d][c + 1]), nq, hscale, vec2(acc[m][d][(c + 2)], acc[m][d][(c + 2) + 1]), nq, hscale);
qb[m][d][c] = qp.x;
qb[m][d][c + 1] = qp.y;
qb[m][d][(c + 2)] = qp.z;
qb[m][d][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_qscale_fast4(vec2(acc[m][d][c], acc[m][d][c + 1]), nq, hscale, vec2(acc[m][d][(c + 2)], acc[m][d][(c + 2) + 1]), nq, hscale);
qb[m][d][c] = qp.x;
qb[m][d][c + 1] = qp.y;
qb[m][d][(c + 2)] = qp.z;
qb[m][d][(c + 2) + 1] = qp.w;
} } } }{ const int d = 1; 
                    { { const int c = 0;  {
const fe4m3vec4 qp = nr_qscale_fast4(vec2(acc[m][d][c], acc[m][d][c + 1]), nq, hscale, vec2(acc[m][d][(c + 2)], acc[m][d][(c + 2) + 1]), nq, hscale);
qb[m][d][c] = qp.x;
qb[m][d][c + 1] = qp.y;
qb[m][d][(c + 2)] = qp.z;
qb[m][d][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_qscale_fast4(vec2(acc[m][d][c], acc[m][d][c + 1]), nq, hscale, vec2(acc[m][d][(c + 2)], acc[m][d][(c + 2) + 1]), nq, hscale);
qb[m][d][c] = qp.x;
qb[m][d][c + 1] = qp.y;
qb[m][d][(c + 2)] = qp.z;
qb[m][d][(c + 2) + 1] = qp.w;
} } } } }
            } } }






















            { { const int m = 0;  {

                float skp[4];
                { { const int i = 0;  skp[i] = 0.0; }{ const int i = 1;  skp[i] = 0.0; }{ const int i = 2;  skp[i] = 0.0; }{ const int i = 3;  skp[i] = 0.0; } }
                { { const int c = 0; 
                    { { const int d = 0;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } }{ const int d = 1;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } } } }{ const int c = 1; 
                    { { const int d = 0;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } }{ const int d = 1;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } } } }{ const int c = 2; 
                    { { const int d = 0;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } }{ const int d = 1;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } } } }{ const int c = 3; 
                    { { const int d = 0;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } }{ const int d = 1;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } } } }{ const int c = 4; 
                    { { const int d = 0;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } }{ const int d = 1;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } } } }{ const int c = 5; 
                    { { const int d = 0;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } }{ const int d = 1;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } } } }{ const int c = 6; 
                    { { const int d = 0;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } }{ const int d = 1;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } } } }{ const int c = 7; 
                    { { const int d = 0;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } }{ const int d = 1;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } } } } }





                f16vec2 sk = f16vec2(vec2( (skp[0] + skp[1]) + (skp[2] + skp[3]), 0.0));
                sk = sk + unpackFloat2x16(subgroupShuffleXor(packFloat2x16(sk), 16u));
                const float16_t nk =
                                    float16_t(inversesqrt(float(max( (sk.x), float16_t(0.000062)))));























                { { const int d = 0;  {
                               coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > kf;
                    { { const int c = 0;  {
const fe4m3vec4 qp = nr_kscale_fast4(vec2(acc[m][d + 1 * ( (128 / 4) / 16)][c],
                            acc[m][d + 1 * ( (128 / 4) / 16)][c + 1]), nk, vec2(acc[m][d + 1 * ( (128 / 4) / 16)][(c + 2)],
                            acc[m][d + 1 * ( (128 / 4) / 16)][(c + 2) + 1]), nk);
kf[c] = qp.x;
kf[c + 1] = qp.y;
kf[(c + 2)] = qp.z;
kf[(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_kscale_fast4(vec2(acc[m][d + 1 * ( (128 / 4) / 16)][c],
                            acc[m][d + 1 * ( (128 / 4) / 16)][c + 1]), nk, vec2(acc[m][d + 1 * ( (128 / 4) / 16)][(c + 2)],
                            acc[m][d + 1 * ( (128 / 4) / 16)][(c + 2) + 1]), nk);
kf[c] = qp.x;
kf[c + 1] = qp.y;
kf[(c + 2)] = qp.z;
kf[(c + 2) + 1] = qp.w;
} } }


                    { { const int c = 0;  kreg[m][d][c] = kf[c]; }{ const int c = 1;  kreg[m][d][c] = kf[c]; }{ const int c = 2;  kreg[m][d][c] = kf[c]; }{ const int c = 3;  kreg[m][d][c] = kf[c]; }{ const int c = 4;  kreg[m][d][c] = kf[c]; }{ const int c = 5;  kreg[m][d][c] = kf[c]; }{ const int c = 6;  kreg[m][d][c] = kf[c]; }{ const int c = 7;  kreg[m][d][c] = kf[c]; } }
                } }{ const int d = 1;  {
                               coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > kf;
                    { { const int c = 0;  {
const fe4m3vec4 qp = nr_kscale_fast4(vec2(acc[m][d + 1 * ( (128 / 4) / 16)][c],
                            acc[m][d + 1 * ( (128 / 4) / 16)][c + 1]), nk, vec2(acc[m][d + 1 * ( (128 / 4) / 16)][(c + 2)],
                            acc[m][d + 1 * ( (128 / 4) / 16)][(c + 2) + 1]), nk);
kf[c] = qp.x;
kf[c + 1] = qp.y;
kf[(c + 2)] = qp.z;
kf[(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_kscale_fast4(vec2(acc[m][d + 1 * ( (128 / 4) / 16)][c],
                            acc[m][d + 1 * ( (128 / 4) / 16)][c + 1]), nk, vec2(acc[m][d + 1 * ( (128 / 4) / 16)][(c + 2)],
                            acc[m][d + 1 * ( (128 / 4) / 16)][(c + 2) + 1]), nk);
kf[c] = qp.x;
kf[c + 1] = qp.y;
kf[(c + 2)] = qp.z;
kf[(c + 2) + 1] = qp.w;
} } }


                    { { const int c = 0;  kreg[m][d][c] = kf[c]; }{ const int c = 1;  kreg[m][d][c] = kf[c]; }{ const int c = 2;  kreg[m][d][c] = kf[c]; }{ const int c = 3;  kreg[m][d][c] = kf[c]; }{ const int c = 4;  kreg[m][d][c] = kf[c]; }{ const int c = 5;  kreg[m][d][c] = kf[c]; }{ const int c = 6;  kreg[m][d][c] = kf[c]; }{ const int c = 7;  kreg[m][d][c] = kf[c]; } }
                } } }
            } }{ const int m = 1;  {

                float skp[4];
                { { const int i = 0;  skp[i] = 0.0; }{ const int i = 1;  skp[i] = 0.0; }{ const int i = 2;  skp[i] = 0.0; }{ const int i = 3;  skp[i] = 0.0; } }
                { { const int c = 0; 
                    { { const int d = 0;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } }{ const int d = 1;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } } } }{ const int c = 1; 
                    { { const int d = 0;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } }{ const int d = 1;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } } } }{ const int c = 2; 
                    { { const int d = 0;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } }{ const int d = 1;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } } } }{ const int c = 3; 
                    { { const int d = 0;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } }{ const int d = 1;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } } } }{ const int c = 4; 
                    { { const int d = 0;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } }{ const int d = 1;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } } } }{ const int c = 5; 
                    { { const int d = 0;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } }{ const int d = 1;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } } } }{ const int c = 6; 
                    { { const int d = 0;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } }{ const int d = 1;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } } } }{ const int c = 7; 
                    { { const int d = 0;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } }{ const int d = 1;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } } } } }





                f16vec2 sk = f16vec2(vec2( (skp[0] + skp[1]) + (skp[2] + skp[3]), 0.0));
                sk = sk + unpackFloat2x16(subgroupShuffleXor(packFloat2x16(sk), 16u));
                const float16_t nk =
                                    float16_t(inversesqrt(float(max( (sk.x), float16_t(0.000062)))));























                { { const int d = 0;  {
                               coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > kf;
                    { { const int c = 0;  {
const fe4m3vec4 qp = nr_kscale_fast4(vec2(acc[m][d + 1 * ( (128 / 4) / 16)][c],
                            acc[m][d + 1 * ( (128 / 4) / 16)][c + 1]), nk, vec2(acc[m][d + 1 * ( (128 / 4) / 16)][(c + 2)],
                            acc[m][d + 1 * ( (128 / 4) / 16)][(c + 2) + 1]), nk);
kf[c] = qp.x;
kf[c + 1] = qp.y;
kf[(c + 2)] = qp.z;
kf[(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_kscale_fast4(vec2(acc[m][d + 1 * ( (128 / 4) / 16)][c],
                            acc[m][d + 1 * ( (128 / 4) / 16)][c + 1]), nk, vec2(acc[m][d + 1 * ( (128 / 4) / 16)][(c + 2)],
                            acc[m][d + 1 * ( (128 / 4) / 16)][(c + 2) + 1]), nk);
kf[c] = qp.x;
kf[c + 1] = qp.y;
kf[(c + 2)] = qp.z;
kf[(c + 2) + 1] = qp.w;
} } }


                    { { const int c = 0;  kreg[m][d][c] = kf[c]; }{ const int c = 1;  kreg[m][d][c] = kf[c]; }{ const int c = 2;  kreg[m][d][c] = kf[c]; }{ const int c = 3;  kreg[m][d][c] = kf[c]; }{ const int c = 4;  kreg[m][d][c] = kf[c]; }{ const int c = 5;  kreg[m][d][c] = kf[c]; }{ const int c = 6;  kreg[m][d][c] = kf[c]; }{ const int c = 7;  kreg[m][d][c] = kf[c]; } }
                } }{ const int d = 1;  {
                               coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > kf;
                    { { const int c = 0;  {
const fe4m3vec4 qp = nr_kscale_fast4(vec2(acc[m][d + 1 * ( (128 / 4) / 16)][c],
                            acc[m][d + 1 * ( (128 / 4) / 16)][c + 1]), nk, vec2(acc[m][d + 1 * ( (128 / 4) / 16)][(c + 2)],
                            acc[m][d + 1 * ( (128 / 4) / 16)][(c + 2) + 1]), nk);
kf[c] = qp.x;
kf[c + 1] = qp.y;
kf[(c + 2)] = qp.z;
kf[(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_kscale_fast4(vec2(acc[m][d + 1 * ( (128 / 4) / 16)][c],
                            acc[m][d + 1 * ( (128 / 4) / 16)][c + 1]), nk, vec2(acc[m][d + 1 * ( (128 / 4) / 16)][(c + 2)],
                            acc[m][d + 1 * ( (128 / 4) / 16)][(c + 2) + 1]), nk);
kf[c] = qp.x;
kf[c + 1] = qp.y;
kf[(c + 2)] = qp.z;
kf[(c + 2) + 1] = qp.w;
} } }


                    { { const int c = 0;  kreg[m][d][c] = kf[c]; }{ const int c = 1;  kreg[m][d][c] = kf[c]; }{ const int c = 2;  kreg[m][d][c] = kf[c]; }{ const int c = 3;  kreg[m][d][c] = kf[c]; }{ const int c = 4;  kreg[m][d][c] = kf[c]; }{ const int c = 5;  kreg[m][d][c] = kf[c]; }{ const int c = 6;  kreg[m][d][c] = kf[c]; }{ const int c = 7;  kreg[m][d][c] = kf[c]; } }
                } } }
            } }{ const int m = 2;  {

                float skp[4];
                { { const int i = 0;  skp[i] = 0.0; }{ const int i = 1;  skp[i] = 0.0; }{ const int i = 2;  skp[i] = 0.0; }{ const int i = 3;  skp[i] = 0.0; } }
                { { const int c = 0; 
                    { { const int d = 0;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } }{ const int d = 1;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } } } }{ const int c = 1; 
                    { { const int d = 0;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } }{ const int d = 1;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } } } }{ const int c = 2; 
                    { { const int d = 0;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } }{ const int d = 1;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } } } }{ const int c = 3; 
                    { { const int d = 0;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } }{ const int d = 1;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } } } }{ const int c = 4; 
                    { { const int d = 0;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } }{ const int d = 1;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } } } }{ const int c = 5; 
                    { { const int d = 0;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } }{ const int d = 1;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } } } }{ const int c = 6; 
                    { { const int d = 0;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } }{ const int d = 1;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } } } }{ const int c = 7; 
                    { { const int d = 0;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } }{ const int d = 1;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } } } } }





                f16vec2 sk = f16vec2(vec2( (skp[0] + skp[1]) + (skp[2] + skp[3]), 0.0));
                sk = sk + unpackFloat2x16(subgroupShuffleXor(packFloat2x16(sk), 16u));
                const float16_t nk =
                                    float16_t(inversesqrt(float(max( (sk.x), float16_t(0.000062)))));























                { { const int d = 0;  {
                               coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > kf;
                    { { const int c = 0;  {
const fe4m3vec4 qp = nr_kscale_fast4(vec2(acc[m][d + 1 * ( (128 / 4) / 16)][c],
                            acc[m][d + 1 * ( (128 / 4) / 16)][c + 1]), nk, vec2(acc[m][d + 1 * ( (128 / 4) / 16)][(c + 2)],
                            acc[m][d + 1 * ( (128 / 4) / 16)][(c + 2) + 1]), nk);
kf[c] = qp.x;
kf[c + 1] = qp.y;
kf[(c + 2)] = qp.z;
kf[(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_kscale_fast4(vec2(acc[m][d + 1 * ( (128 / 4) / 16)][c],
                            acc[m][d + 1 * ( (128 / 4) / 16)][c + 1]), nk, vec2(acc[m][d + 1 * ( (128 / 4) / 16)][(c + 2)],
                            acc[m][d + 1 * ( (128 / 4) / 16)][(c + 2) + 1]), nk);
kf[c] = qp.x;
kf[c + 1] = qp.y;
kf[(c + 2)] = qp.z;
kf[(c + 2) + 1] = qp.w;
} } }


                    { { const int c = 0;  kreg[m][d][c] = kf[c]; }{ const int c = 1;  kreg[m][d][c] = kf[c]; }{ const int c = 2;  kreg[m][d][c] = kf[c]; }{ const int c = 3;  kreg[m][d][c] = kf[c]; }{ const int c = 4;  kreg[m][d][c] = kf[c]; }{ const int c = 5;  kreg[m][d][c] = kf[c]; }{ const int c = 6;  kreg[m][d][c] = kf[c]; }{ const int c = 7;  kreg[m][d][c] = kf[c]; } }
                } }{ const int d = 1;  {
                               coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > kf;
                    { { const int c = 0;  {
const fe4m3vec4 qp = nr_kscale_fast4(vec2(acc[m][d + 1 * ( (128 / 4) / 16)][c],
                            acc[m][d + 1 * ( (128 / 4) / 16)][c + 1]), nk, vec2(acc[m][d + 1 * ( (128 / 4) / 16)][(c + 2)],
                            acc[m][d + 1 * ( (128 / 4) / 16)][(c + 2) + 1]), nk);
kf[c] = qp.x;
kf[c + 1] = qp.y;
kf[(c + 2)] = qp.z;
kf[(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_kscale_fast4(vec2(acc[m][d + 1 * ( (128 / 4) / 16)][c],
                            acc[m][d + 1 * ( (128 / 4) / 16)][c + 1]), nk, vec2(acc[m][d + 1 * ( (128 / 4) / 16)][(c + 2)],
                            acc[m][d + 1 * ( (128 / 4) / 16)][(c + 2) + 1]), nk);
kf[c] = qp.x;
kf[c + 1] = qp.y;
kf[(c + 2)] = qp.z;
kf[(c + 2) + 1] = qp.w;
} } }


                    { { const int c = 0;  kreg[m][d][c] = kf[c]; }{ const int c = 1;  kreg[m][d][c] = kf[c]; }{ const int c = 2;  kreg[m][d][c] = kf[c]; }{ const int c = 3;  kreg[m][d][c] = kf[c]; }{ const int c = 4;  kreg[m][d][c] = kf[c]; }{ const int c = 5;  kreg[m][d][c] = kf[c]; }{ const int c = 6;  kreg[m][d][c] = kf[c]; }{ const int c = 7;  kreg[m][d][c] = kf[c]; } }
                } } }
            } }{ const int m = 3;  {

                float skp[4];
                { { const int i = 0;  skp[i] = 0.0; }{ const int i = 1;  skp[i] = 0.0; }{ const int i = 2;  skp[i] = 0.0; }{ const int i = 3;  skp[i] = 0.0; } }
                { { const int c = 0; 
                    { { const int d = 0;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } }{ const int d = 1;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } } } }{ const int c = 1; 
                    { { const int d = 0;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } }{ const int d = 1;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } } } }{ const int c = 2; 
                    { { const int d = 0;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } }{ const int d = 1;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } } } }{ const int c = 3; 
                    { { const int d = 0;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } }{ const int d = 1;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } } } }{ const int c = 4; 
                    { { const int d = 0;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } }{ const int d = 1;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } } } }{ const int c = 5; 
                    { { const int d = 0;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } }{ const int d = 1;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } } } }{ const int c = 6; 
                    { { const int d = 0;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } }{ const int d = 1;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } } } }{ const int c = 7; 
                    { { const int d = 0;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } }{ const int d = 1;  {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    } } } } }





                f16vec2 sk = f16vec2(vec2( (skp[0] + skp[1]) + (skp[2] + skp[3]), 0.0));
                sk = sk + unpackFloat2x16(subgroupShuffleXor(packFloat2x16(sk), 16u));
                const float16_t nk =
                                    float16_t(inversesqrt(float(max( (sk.x), float16_t(0.000062)))));























                { { const int d = 0;  {
                               coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > kf;
                    { { const int c = 0;  {
const fe4m3vec4 qp = nr_kscale_fast4(vec2(acc[m][d + 1 * ( (128 / 4) / 16)][c],
                            acc[m][d + 1 * ( (128 / 4) / 16)][c + 1]), nk, vec2(acc[m][d + 1 * ( (128 / 4) / 16)][(c + 2)],
                            acc[m][d + 1 * ( (128 / 4) / 16)][(c + 2) + 1]), nk);
kf[c] = qp.x;
kf[c + 1] = qp.y;
kf[(c + 2)] = qp.z;
kf[(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_kscale_fast4(vec2(acc[m][d + 1 * ( (128 / 4) / 16)][c],
                            acc[m][d + 1 * ( (128 / 4) / 16)][c + 1]), nk, vec2(acc[m][d + 1 * ( (128 / 4) / 16)][(c + 2)],
                            acc[m][d + 1 * ( (128 / 4) / 16)][(c + 2) + 1]), nk);
kf[c] = qp.x;
kf[c + 1] = qp.y;
kf[(c + 2)] = qp.z;
kf[(c + 2) + 1] = qp.w;
} } }


                    { { const int c = 0;  kreg[m][d][c] = kf[c]; }{ const int c = 1;  kreg[m][d][c] = kf[c]; }{ const int c = 2;  kreg[m][d][c] = kf[c]; }{ const int c = 3;  kreg[m][d][c] = kf[c]; }{ const int c = 4;  kreg[m][d][c] = kf[c]; }{ const int c = 5;  kreg[m][d][c] = kf[c]; }{ const int c = 6;  kreg[m][d][c] = kf[c]; }{ const int c = 7;  kreg[m][d][c] = kf[c]; } }
                } }{ const int d = 1;  {
                               coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > kf;
                    { { const int c = 0;  {
const fe4m3vec4 qp = nr_kscale_fast4(vec2(acc[m][d + 1 * ( (128 / 4) / 16)][c],
                            acc[m][d + 1 * ( (128 / 4) / 16)][c + 1]), nk, vec2(acc[m][d + 1 * ( (128 / 4) / 16)][(c + 2)],
                            acc[m][d + 1 * ( (128 / 4) / 16)][(c + 2) + 1]), nk);
kf[c] = qp.x;
kf[c + 1] = qp.y;
kf[(c + 2)] = qp.z;
kf[(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_kscale_fast4(vec2(acc[m][d + 1 * ( (128 / 4) / 16)][c],
                            acc[m][d + 1 * ( (128 / 4) / 16)][c + 1]), nk, vec2(acc[m][d + 1 * ( (128 / 4) / 16)][(c + 2)],
                            acc[m][d + 1 * ( (128 / 4) / 16)][(c + 2) + 1]), nk);
kf[c] = qp.x;
kf[c + 1] = qp.y;
kf[(c + 2)] = qp.z;
kf[(c + 2) + 1] = qp.w;
} } }


                    { { const int c = 0;  kreg[m][d][c] = kf[c]; }{ const int c = 1;  kreg[m][d][c] = kf[c]; }{ const int c = 2;  kreg[m][d][c] = kf[c]; }{ const int c = 3;  kreg[m][d][c] = kf[c]; }{ const int c = 4;  kreg[m][d][c] = kf[c]; }{ const int c = 5;  kreg[m][d][c] = kf[c]; }{ const int c = 6;  kreg[m][d][c] = kf[c]; }{ const int c = 7;  kreg[m][d][c] = kf[c]; } }
                } } }
            } } }
































            { { const int m = 0; 
                { { const int d = 0;  acc[m][d] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int d = 1;  acc[m][d] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); } } }{ const int m = 1; 
                { { const int d = 0;  acc[m][d] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int d = 1;  acc[m][d] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); } } }{ const int m = 2; 
                { { const int d = 0;  acc[m][d] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int d = 1;  acc[m][d] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); } } }{ const int m = 3; 
                { { const int d = 0;  acc[m][d] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int d = 1;  acc[m][d] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); } } } }
            { { const int k = 0;  {








                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > yka[ (64 / 16)];
                { { const int m = 0; 

                                                                            coopMatLoad(yka[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (130u) * 16u))), (16u), gl_CooperativeMatrixLayoutRowMajor); }{ const int m = 1; 

                                                                            coopMatLoad(yka[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (130u) * 16u))), (16u), gl_CooperativeMatrixLayoutRowMajor); }{ const int m = 2; 

                                                                            coopMatLoad(yka[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (130u) * 16u))), (16u), gl_CooperativeMatrixLayoutRowMajor); }{ const int m = 3; 

                                                                            coopMatLoad(yka[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (130u) * 16u))), (16u), gl_CooperativeMatrixLayoutRowMajor); } }
                { { const int r = 0;  {
                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > wb0, wb1;
                                                                                                         { const uint q = (pc.qkv_off) / 4u + ( (uint(hh * 3 * ( (128 / 4) / 16) + 2 * ( (128 / 4) / 16) + r)) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wb0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wb0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wb0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wb0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wb1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wb1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wb1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wb1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  acc[m][r] = coopMatMulAdd(yka[m], wb0, acc[m][r]); }{ const int m = 1;  acc[m][r] = coopMatMulAdd(yka[m], wb0, acc[m][r]); }{ const int m = 2;  acc[m][r] = coopMatMulAdd(yka[m], wb0, acc[m][r]); }{ const int m = 3;  acc[m][r] = coopMatMulAdd(yka[m], wb0, acc[m][r]); } }
                    { { const int m = 0;  acc[m][r + 1] = coopMatMulAdd(yka[m], wb1, acc[m][r + 1]); }{ const int m = 1;  acc[m][r + 1] = coopMatMulAdd(yka[m], wb1, acc[m][r + 1]); }{ const int m = 2;  acc[m][r + 1] = coopMatMulAdd(yka[m], wb1, acc[m][r + 1]); }{ const int m = 3;  acc[m][r + 1] = coopMatMulAdd(yka[m], wb1, acc[m][r + 1]); } }
                } } }


























                if (0 > 0 && (k + 1) % 0 == 0)
                    { { const int m = 0; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } } } }{ const int m = 1; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } } } }{ const int m = 2; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } } } }{ const int m = 3; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } } } } }

            } }{ const int k = 1;  {








                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > yka[ (64 / 16)];
                { { const int m = 0; 

                                                                            coopMatLoad(yka[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (130u) * 16u))), (16u), gl_CooperativeMatrixLayoutRowMajor); }{ const int m = 1; 

                                                                            coopMatLoad(yka[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (130u) * 16u))), (16u), gl_CooperativeMatrixLayoutRowMajor); }{ const int m = 2; 

                                                                            coopMatLoad(yka[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (130u) * 16u))), (16u), gl_CooperativeMatrixLayoutRowMajor); }{ const int m = 3; 

                                                                            coopMatLoad(yka[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (130u) * 16u))), (16u), gl_CooperativeMatrixLayoutRowMajor); } }
                { { const int r = 0;  {
                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > wb0, wb1;
                                                                                                         { const uint q = (pc.qkv_off) / 4u + ( (uint(hh * 3 * ( (128 / 4) / 16) + 2 * ( (128 / 4) / 16) + r)) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wb0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wb0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wb0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wb0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wb1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wb1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wb1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wb1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  acc[m][r] = coopMatMulAdd(yka[m], wb0, acc[m][r]); }{ const int m = 1;  acc[m][r] = coopMatMulAdd(yka[m], wb0, acc[m][r]); }{ const int m = 2;  acc[m][r] = coopMatMulAdd(yka[m], wb0, acc[m][r]); }{ const int m = 3;  acc[m][r] = coopMatMulAdd(yka[m], wb0, acc[m][r]); } }
                    { { const int m = 0;  acc[m][r + 1] = coopMatMulAdd(yka[m], wb1, acc[m][r + 1]); }{ const int m = 1;  acc[m][r + 1] = coopMatMulAdd(yka[m], wb1, acc[m][r + 1]); }{ const int m = 2;  acc[m][r + 1] = coopMatMulAdd(yka[m], wb1, acc[m][r + 1]); }{ const int m = 3;  acc[m][r + 1] = coopMatMulAdd(yka[m], wb1, acc[m][r + 1]); } }
                } } }


























                if (0 > 0 && (k + 1) % 0 == 0)
                    { { const int m = 0; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } } } }{ const int m = 1; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } } } }{ const int m = 2; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } } } }{ const int m = 3; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } } } } }

            } }{ const int k = 2;  {








                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > yka[ (64 / 16)];
                { { const int m = 0; 

                                                                            coopMatLoad(yka[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (130u) * 16u))), (16u), gl_CooperativeMatrixLayoutRowMajor); }{ const int m = 1; 

                                                                            coopMatLoad(yka[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (130u) * 16u))), (16u), gl_CooperativeMatrixLayoutRowMajor); }{ const int m = 2; 

                                                                            coopMatLoad(yka[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (130u) * 16u))), (16u), gl_CooperativeMatrixLayoutRowMajor); }{ const int m = 3; 

                                                                            coopMatLoad(yka[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (130u) * 16u))), (16u), gl_CooperativeMatrixLayoutRowMajor); } }
                { { const int r = 0;  {
                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > wb0, wb1;
                                                                                                         { const uint q = (pc.qkv_off) / 4u + ( (uint(hh * 3 * ( (128 / 4) / 16) + 2 * ( (128 / 4) / 16) + r)) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wb0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wb0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wb0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wb0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wb1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wb1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wb1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wb1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  acc[m][r] = coopMatMulAdd(yka[m], wb0, acc[m][r]); }{ const int m = 1;  acc[m][r] = coopMatMulAdd(yka[m], wb0, acc[m][r]); }{ const int m = 2;  acc[m][r] = coopMatMulAdd(yka[m], wb0, acc[m][r]); }{ const int m = 3;  acc[m][r] = coopMatMulAdd(yka[m], wb0, acc[m][r]); } }
                    { { const int m = 0;  acc[m][r + 1] = coopMatMulAdd(yka[m], wb1, acc[m][r + 1]); }{ const int m = 1;  acc[m][r + 1] = coopMatMulAdd(yka[m], wb1, acc[m][r + 1]); }{ const int m = 2;  acc[m][r + 1] = coopMatMulAdd(yka[m], wb1, acc[m][r + 1]); }{ const int m = 3;  acc[m][r + 1] = coopMatMulAdd(yka[m], wb1, acc[m][r + 1]); } }
                } } }


























                if (0 > 0 && (k + 1) % 0 == 0)
                    { { const int m = 0; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } } } }{ const int m = 1; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } } } }{ const int m = 2; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } } } }{ const int m = 3; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } } } } }

            } }{ const int k = 3;  {








                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > yka[ (64 / 16)];
                { { const int m = 0; 

                                                                            coopMatLoad(yka[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (130u) * 16u))), (16u), gl_CooperativeMatrixLayoutRowMajor); }{ const int m = 1; 

                                                                            coopMatLoad(yka[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (130u) * 16u))), (16u), gl_CooperativeMatrixLayoutRowMajor); }{ const int m = 2; 

                                                                            coopMatLoad(yka[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (130u) * 16u))), (16u), gl_CooperativeMatrixLayoutRowMajor); }{ const int m = 3; 

                                                                            coopMatLoad(yka[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (130u) * 16u))), (16u), gl_CooperativeMatrixLayoutRowMajor); } }
                { { const int r = 0;  {
                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > wb0, wb1;
                                                                                                         { const uint q = (pc.qkv_off) / 4u + ( (uint(hh * 3 * ( (128 / 4) / 16) + 2 * ( (128 / 4) / 16) + r)) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wb0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wb0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wb0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wb0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wb1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wb1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wb1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wb1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  acc[m][r] = coopMatMulAdd(yka[m], wb0, acc[m][r]); }{ const int m = 1;  acc[m][r] = coopMatMulAdd(yka[m], wb0, acc[m][r]); }{ const int m = 2;  acc[m][r] = coopMatMulAdd(yka[m], wb0, acc[m][r]); }{ const int m = 3;  acc[m][r] = coopMatMulAdd(yka[m], wb0, acc[m][r]); } }
                    { { const int m = 0;  acc[m][r + 1] = coopMatMulAdd(yka[m], wb1, acc[m][r + 1]); }{ const int m = 1;  acc[m][r + 1] = coopMatMulAdd(yka[m], wb1, acc[m][r + 1]); }{ const int m = 2;  acc[m][r + 1] = coopMatMulAdd(yka[m], wb1, acc[m][r + 1]); }{ const int m = 3;  acc[m][r + 1] = coopMatMulAdd(yka[m], wb1, acc[m][r + 1]); } }
                } } }


























                if (0 > 0 && (k + 1) % 0 == 0)
                    { { const int m = 0; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } } } }{ const int m = 1; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } } } }{ const int m = 2; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } } } }{ const int m = 3; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } } } } }

            } }{ const int k = 4;  {








                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > yka[ (64 / 16)];
                { { const int m = 0; 

                                                                            coopMatLoad(yka[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (130u) * 16u))), (16u), gl_CooperativeMatrixLayoutRowMajor); }{ const int m = 1; 

                                                                            coopMatLoad(yka[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (130u) * 16u))), (16u), gl_CooperativeMatrixLayoutRowMajor); }{ const int m = 2; 

                                                                            coopMatLoad(yka[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (130u) * 16u))), (16u), gl_CooperativeMatrixLayoutRowMajor); }{ const int m = 3; 

                                                                            coopMatLoad(yka[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (130u) * 16u))), (16u), gl_CooperativeMatrixLayoutRowMajor); } }
                { { const int r = 0;  {
                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > wb0, wb1;
                                                                                                         { const uint q = (pc.qkv_off) / 4u + ( (uint(hh * 3 * ( (128 / 4) / 16) + 2 * ( (128 / 4) / 16) + r)) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wb0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wb0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wb0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wb0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wb1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wb1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wb1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wb1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  acc[m][r] = coopMatMulAdd(yka[m], wb0, acc[m][r]); }{ const int m = 1;  acc[m][r] = coopMatMulAdd(yka[m], wb0, acc[m][r]); }{ const int m = 2;  acc[m][r] = coopMatMulAdd(yka[m], wb0, acc[m][r]); }{ const int m = 3;  acc[m][r] = coopMatMulAdd(yka[m], wb0, acc[m][r]); } }
                    { { const int m = 0;  acc[m][r + 1] = coopMatMulAdd(yka[m], wb1, acc[m][r + 1]); }{ const int m = 1;  acc[m][r + 1] = coopMatMulAdd(yka[m], wb1, acc[m][r + 1]); }{ const int m = 2;  acc[m][r + 1] = coopMatMulAdd(yka[m], wb1, acc[m][r + 1]); }{ const int m = 3;  acc[m][r + 1] = coopMatMulAdd(yka[m], wb1, acc[m][r + 1]); } }
                } } }


























                if (0 > 0 && (k + 1) % 0 == 0)
                    { { const int m = 0; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } } } }{ const int m = 1; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } } } }{ const int m = 2; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } } } }{ const int m = 3; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } } } } }

            } }{ const int k = 5;  {








                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > yka[ (64 / 16)];
                { { const int m = 0; 

                                                                            coopMatLoad(yka[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (130u) * 16u))), (16u), gl_CooperativeMatrixLayoutRowMajor); }{ const int m = 1; 

                                                                            coopMatLoad(yka[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (130u) * 16u))), (16u), gl_CooperativeMatrixLayoutRowMajor); }{ const int m = 2; 

                                                                            coopMatLoad(yka[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (130u) * 16u))), (16u), gl_CooperativeMatrixLayoutRowMajor); }{ const int m = 3; 

                                                                            coopMatLoad(yka[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (130u) * 16u))), (16u), gl_CooperativeMatrixLayoutRowMajor); } }
                { { const int r = 0;  {
                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > wb0, wb1;
                                                                                                         { const uint q = (pc.qkv_off) / 4u + ( (uint(hh * 3 * ( (128 / 4) / 16) + 2 * ( (128 / 4) / 16) + r)) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wb0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wb0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wb0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wb0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wb1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wb1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wb1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wb1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  acc[m][r] = coopMatMulAdd(yka[m], wb0, acc[m][r]); }{ const int m = 1;  acc[m][r] = coopMatMulAdd(yka[m], wb0, acc[m][r]); }{ const int m = 2;  acc[m][r] = coopMatMulAdd(yka[m], wb0, acc[m][r]); }{ const int m = 3;  acc[m][r] = coopMatMulAdd(yka[m], wb0, acc[m][r]); } }
                    { { const int m = 0;  acc[m][r + 1] = coopMatMulAdd(yka[m], wb1, acc[m][r + 1]); }{ const int m = 1;  acc[m][r + 1] = coopMatMulAdd(yka[m], wb1, acc[m][r + 1]); }{ const int m = 2;  acc[m][r + 1] = coopMatMulAdd(yka[m], wb1, acc[m][r + 1]); }{ const int m = 3;  acc[m][r + 1] = coopMatMulAdd(yka[m], wb1, acc[m][r + 1]); } }
                } } }


























                if (0 > 0 && (k + 1) % 0 == 0)
                    { { const int m = 0; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } } } }{ const int m = 1; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } } } }{ const int m = 2; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } } } }{ const int m = 3; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } } } } }

            } }{ const int k = 6;  {








                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > yka[ (64 / 16)];
                { { const int m = 0; 

                                                                            coopMatLoad(yka[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (130u) * 16u))), (16u), gl_CooperativeMatrixLayoutRowMajor); }{ const int m = 1; 

                                                                            coopMatLoad(yka[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (130u) * 16u))), (16u), gl_CooperativeMatrixLayoutRowMajor); }{ const int m = 2; 

                                                                            coopMatLoad(yka[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (130u) * 16u))), (16u), gl_CooperativeMatrixLayoutRowMajor); }{ const int m = 3; 

                                                                            coopMatLoad(yka[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (130u) * 16u))), (16u), gl_CooperativeMatrixLayoutRowMajor); } }
                { { const int r = 0;  {
                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > wb0, wb1;
                                                                                                         { const uint q = (pc.qkv_off) / 4u + ( (uint(hh * 3 * ( (128 / 4) / 16) + 2 * ( (128 / 4) / 16) + r)) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wb0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wb0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wb0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wb0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wb1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wb1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wb1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wb1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  acc[m][r] = coopMatMulAdd(yka[m], wb0, acc[m][r]); }{ const int m = 1;  acc[m][r] = coopMatMulAdd(yka[m], wb0, acc[m][r]); }{ const int m = 2;  acc[m][r] = coopMatMulAdd(yka[m], wb0, acc[m][r]); }{ const int m = 3;  acc[m][r] = coopMatMulAdd(yka[m], wb0, acc[m][r]); } }
                    { { const int m = 0;  acc[m][r + 1] = coopMatMulAdd(yka[m], wb1, acc[m][r + 1]); }{ const int m = 1;  acc[m][r + 1] = coopMatMulAdd(yka[m], wb1, acc[m][r + 1]); }{ const int m = 2;  acc[m][r + 1] = coopMatMulAdd(yka[m], wb1, acc[m][r + 1]); }{ const int m = 3;  acc[m][r + 1] = coopMatMulAdd(yka[m], wb1, acc[m][r + 1]); } }
                } } }


























                if (0 > 0 && (k + 1) % 0 == 0)
                    { { const int m = 0; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } } } }{ const int m = 1; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } } } }{ const int m = 2; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } } } }{ const int m = 3; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } } } } }

            } }{ const int k = 7;  {








                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > yka[ (64 / 16)];
                { { const int m = 0; 

                                                                            coopMatLoad(yka[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (130u) * 16u))), (16u), gl_CooperativeMatrixLayoutRowMajor); }{ const int m = 1; 

                                                                            coopMatLoad(yka[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (130u) * 16u))), (16u), gl_CooperativeMatrixLayoutRowMajor); }{ const int m = 2; 

                                                                            coopMatLoad(yka[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (130u) * 16u))), (16u), gl_CooperativeMatrixLayoutRowMajor); }{ const int m = 3; 

                                                                            coopMatLoad(yka[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (130u) * 16u))), (16u), gl_CooperativeMatrixLayoutRowMajor); } }
                { { const int r = 0;  {
                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > wb0, wb1;
                                                                                                         { const uint q = (pc.qkv_off) / 4u + ( (uint(hh * 3 * ( (128 / 4) / 16) + 2 * ( (128 / 4) / 16) + r)) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wb0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wb0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wb0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wb0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wb1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wb1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wb1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wb1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wb1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
                    { { const int m = 0;  acc[m][r] = coopMatMulAdd(yka[m], wb0, acc[m][r]); }{ const int m = 1;  acc[m][r] = coopMatMulAdd(yka[m], wb0, acc[m][r]); }{ const int m = 2;  acc[m][r] = coopMatMulAdd(yka[m], wb0, acc[m][r]); }{ const int m = 3;  acc[m][r] = coopMatMulAdd(yka[m], wb0, acc[m][r]); } }
                    { { const int m = 0;  acc[m][r + 1] = coopMatMulAdd(yka[m], wb1, acc[m][r + 1]); }{ const int m = 1;  acc[m][r + 1] = coopMatMulAdd(yka[m], wb1, acc[m][r + 1]); }{ const int m = 2;  acc[m][r + 1] = coopMatMulAdd(yka[m], wb1, acc[m][r + 1]); }{ const int m = 3;  acc[m][r + 1] = coopMatMulAdd(yka[m], wb1, acc[m][r + 1]); } }
                } } }


























                if (0 > 0 && (k + 1) % 0 == 0)
                    { { const int m = 0; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } } } }{ const int m = 1; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } } } }{ const int m = 2; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } } } }{ const int m = 3; 
                        { { const int r = 0;  { } }{ const int r = 1;  { } } } } }

            } } }

            { { const int m = 0; 
                { { const int d = 0; 
                    { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(acc[m][d][c], acc[m][d][c + 1]), vec2(acc[m][d][(c + 2)], acc[m][d][(c + 2) + 1]));
vreg[d][m][c] = qp.x;
vreg[d][m][c + 1] = qp.y;
vreg[d][m][(c + 2)] = qp.z;
vreg[d][m][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(acc[m][d][c], acc[m][d][c + 1]), vec2(acc[m][d][(c + 2)], acc[m][d][(c + 2) + 1]));
vreg[d][m][c] = qp.x;
vreg[d][m][c + 1] = qp.y;
vreg[d][m][(c + 2)] = qp.z;
vreg[d][m][(c + 2) + 1] = qp.w;
} } } }{ const int d = 1; 
                    { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(acc[m][d][c], acc[m][d][c + 1]), vec2(acc[m][d][(c + 2)], acc[m][d][(c + 2) + 1]));
vreg[d][m][c] = qp.x;
vreg[d][m][c + 1] = qp.y;
vreg[d][m][(c + 2)] = qp.z;
vreg[d][m][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(acc[m][d][c], acc[m][d][c + 1]), vec2(acc[m][d][(c + 2)], acc[m][d][(c + 2) + 1]));
vreg[d][m][c] = qp.x;
vreg[d][m][c + 1] = qp.y;
vreg[d][m][(c + 2)] = qp.z;
vreg[d][m][(c + 2) + 1] = qp.w;
} } } } } }{ const int m = 1; 
                { { const int d = 0; 
                    { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(acc[m][d][c], acc[m][d][c + 1]), vec2(acc[m][d][(c + 2)], acc[m][d][(c + 2) + 1]));
vreg[d][m][c] = qp.x;
vreg[d][m][c + 1] = qp.y;
vreg[d][m][(c + 2)] = qp.z;
vreg[d][m][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(acc[m][d][c], acc[m][d][c + 1]), vec2(acc[m][d][(c + 2)], acc[m][d][(c + 2) + 1]));
vreg[d][m][c] = qp.x;
vreg[d][m][c + 1] = qp.y;
vreg[d][m][(c + 2)] = qp.z;
vreg[d][m][(c + 2) + 1] = qp.w;
} } } }{ const int d = 1; 
                    { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(acc[m][d][c], acc[m][d][c + 1]), vec2(acc[m][d][(c + 2)], acc[m][d][(c + 2) + 1]));
vreg[d][m][c] = qp.x;
vreg[d][m][c + 1] = qp.y;
vreg[d][m][(c + 2)] = qp.z;
vreg[d][m][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(acc[m][d][c], acc[m][d][c + 1]), vec2(acc[m][d][(c + 2)], acc[m][d][(c + 2) + 1]));
vreg[d][m][c] = qp.x;
vreg[d][m][c + 1] = qp.y;
vreg[d][m][(c + 2)] = qp.z;
vreg[d][m][(c + 2) + 1] = qp.w;
} } } } } }{ const int m = 2; 
                { { const int d = 0; 
                    { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(acc[m][d][c], acc[m][d][c + 1]), vec2(acc[m][d][(c + 2)], acc[m][d][(c + 2) + 1]));
vreg[d][m][c] = qp.x;
vreg[d][m][c + 1] = qp.y;
vreg[d][m][(c + 2)] = qp.z;
vreg[d][m][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(acc[m][d][c], acc[m][d][c + 1]), vec2(acc[m][d][(c + 2)], acc[m][d][(c + 2) + 1]));
vreg[d][m][c] = qp.x;
vreg[d][m][c + 1] = qp.y;
vreg[d][m][(c + 2)] = qp.z;
vreg[d][m][(c + 2) + 1] = qp.w;
} } } }{ const int d = 1; 
                    { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(acc[m][d][c], acc[m][d][c + 1]), vec2(acc[m][d][(c + 2)], acc[m][d][(c + 2) + 1]));
vreg[d][m][c] = qp.x;
vreg[d][m][c + 1] = qp.y;
vreg[d][m][(c + 2)] = qp.z;
vreg[d][m][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(acc[m][d][c], acc[m][d][c + 1]), vec2(acc[m][d][(c + 2)], acc[m][d][(c + 2) + 1]));
vreg[d][m][c] = qp.x;
vreg[d][m][c + 1] = qp.y;
vreg[d][m][(c + 2)] = qp.z;
vreg[d][m][(c + 2) + 1] = qp.w;
} } } } } }{ const int m = 3; 
                { { const int d = 0; 
                    { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(acc[m][d][c], acc[m][d][c + 1]), vec2(acc[m][d][(c + 2)], acc[m][d][(c + 2) + 1]));
vreg[d][m][c] = qp.x;
vreg[d][m][c + 1] = qp.y;
vreg[d][m][(c + 2)] = qp.z;
vreg[d][m][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(acc[m][d][c], acc[m][d][c + 1]), vec2(acc[m][d][(c + 2)], acc[m][d][(c + 2) + 1]));
vreg[d][m][c] = qp.x;
vreg[d][m][c + 1] = qp.y;
vreg[d][m][(c + 2)] = qp.z;
vreg[d][m][(c + 2) + 1] = qp.w;
} } } }{ const int d = 1; 
                    { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(acc[m][d][c], acc[m][d][c + 1]), vec2(acc[m][d][(c + 2)], acc[m][d][(c + 2) + 1]));
vreg[d][m][c] = qp.x;
vreg[d][m][c + 1] = qp.y;
vreg[d][m][(c + 2)] = qp.z;
vreg[d][m][(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(acc[m][d][c], acc[m][d][c + 1]), vec2(acc[m][d][(c + 2)], acc[m][d][(c + 2) + 1]));
vreg[d][m][c] = qp.x;
vreg[d][m][c + 1] = qp.y;
vreg[d][m][(c + 2)] = qp.z;
vreg[d][m][(c + 2) + 1] = qp.w;
} } } } } } }




















        }













































































































































































































































































































             coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > pb[ (64 / 16)][ (64 / 16)];
        { { const int m = 0;  {
            f16vec2 pq2[ (64 / 16)][4];
                  coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > lg[ (64 / 16)];



            { { const int j = 0;  lg[j] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int j = 1;  lg[j] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int j = 2;  lg[j] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int j = 3;  lg[j] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); } }


            { { const int d = 0; 
                { { const int j = 0;  {
                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > kf = kreg[j][d];
                                              lg[j] = coopMatMulAdd(kf, qb[m][d], lg[j]);
                } }{ const int j = 1;  {
                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > kf = kreg[j][d];
                                              lg[j] = coopMatMulAdd(kf, qb[m][d], lg[j]);
                } }{ const int j = 2;  {
                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > kf = kreg[j][d];
                                              lg[j] = coopMatMulAdd(kf, qb[m][d], lg[j]);
                } }{ const int j = 3;  {
                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > kf = kreg[j][d];
                                              lg[j] = coopMatMulAdd(kf, qb[m][d], lg[j]);
                } } } }{ const int d = 1; 
                { { const int j = 0;  {
                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > kf = kreg[j][d];
                                              lg[j] = coopMatMulAdd(kf, qb[m][d], lg[j]);
                } }{ const int j = 1;  {
                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > kf = kreg[j][d];
                                              lg[j] = coopMatMulAdd(kf, qb[m][d], lg[j]);
                } }{ const int j = 2;  {
                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > kf = kreg[j][d];
                                              lg[j] = coopMatMulAdd(kf, qb[m][d], lg[j]);
                } }{ const int j = 3;  {
                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > kf = kreg[j][d];
                                              lg[j] = coopMatMulAdd(kf, qb[m][d], lg[j]);
                } } } } }
            { { const int j = 0;  {
















                          coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > bf;



                                            coopMatLoad(bf, wgt_f32, (pc.b_off + uint(hh) * uint(64 * 64) + (tok0 + uint(m) * 16u) * uint(64) + uint(j) * 16u), (uint(64)), gl_CooperativeMatrixLayoutColumnMajor);


                { { const int c = 0; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); }{ const int c = 2; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); }{ const int c = 4; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); }{ const int c = 6; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); } }



            } }{ const int j = 1;  {
















                          coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > bf;



                                            coopMatLoad(bf, wgt_f32, (pc.b_off + uint(hh) * uint(64 * 64) + (tok0 + uint(m) * 16u) * uint(64) + uint(j) * 16u), (uint(64)), gl_CooperativeMatrixLayoutColumnMajor);


                { { const int c = 0; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); }{ const int c = 2; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); }{ const int c = 4; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); }{ const int c = 6; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); } }



            } }{ const int j = 2;  {
















                          coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > bf;



                                            coopMatLoad(bf, wgt_f32, (pc.b_off + uint(hh) * uint(64 * 64) + (tok0 + uint(m) * 16u) * uint(64) + uint(j) * 16u), (uint(64)), gl_CooperativeMatrixLayoutColumnMajor);


                { { const int c = 0; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); }{ const int c = 2; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); }{ const int c = 4; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); }{ const int c = 6; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); } }



            } }{ const int j = 3;  {
















                          coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > bf;



                                            coopMatLoad(bf, wgt_f32, (pc.b_off + uint(hh) * uint(64 * 64) + (tok0 + uint(m) * 16u) * uint(64) + uint(j) * 16u), (uint(64)), gl_CooperativeMatrixLayoutColumnMajor);


                { { const int c = 0; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); }{ const int c = 2; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); }{ const int c = 4; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); }{ const int c = 6; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); } }



            } } }
                 float16_t sum = nr_swin_probability_sum(pq2);


            float inv = float(float16_t(1.0 / float(max(sum, float16_t(6.103515625e-05)))));
            { { const int j = 0; 
                { { const int c = 0;  {
float x_qa = float(pq2[j][c].x) * inv;
float y_qa = float(pq2[j][c].y) * inv;
float x_qb = float(pq2[j][(c + 1)].x) * inv;
float y_qb = float(pq2[j][(c + 1)].y) * inv;
const fe4m3vec4 q = nr_convert_quad(pq2[j][c] * f16vec2(float16_t(inv)), pq2[j][(c + 1)] * f16vec2(float16_t(inv)));
pb[m][j][2 * c] = q.x;
pb[m][j][2 * c + 1] = q.y;
pb[m][j][2 * (c + 1)] = q.z;
pb[m][j][2 * (c + 1) + 1] = q.w;
} }{ const int c = 2;  {
float x_qa = float(pq2[j][c].x) * inv;
float y_qa = float(pq2[j][c].y) * inv;
float x_qb = float(pq2[j][(c + 1)].x) * inv;
float y_qb = float(pq2[j][(c + 1)].y) * inv;
const fe4m3vec4 q = nr_convert_quad(pq2[j][c] * f16vec2(float16_t(inv)), pq2[j][(c + 1)] * f16vec2(float16_t(inv)));
pb[m][j][2 * c] = q.x;
pb[m][j][2 * c + 1] = q.y;
pb[m][j][2 * (c + 1)] = q.z;
pb[m][j][2 * (c + 1) + 1] = q.w;
} } } }{ const int j = 1; 
                { { const int c = 0;  {
float x_qa = float(pq2[j][c].x) * inv;
float y_qa = float(pq2[j][c].y) * inv;
float x_qb = float(pq2[j][(c + 1)].x) * inv;
float y_qb = float(pq2[j][(c + 1)].y) * inv;
const fe4m3vec4 q = nr_convert_quad(pq2[j][c] * f16vec2(float16_t(inv)), pq2[j][(c + 1)] * f16vec2(float16_t(inv)));
pb[m][j][2 * c] = q.x;
pb[m][j][2 * c + 1] = q.y;
pb[m][j][2 * (c + 1)] = q.z;
pb[m][j][2 * (c + 1) + 1] = q.w;
} }{ const int c = 2;  {
float x_qa = float(pq2[j][c].x) * inv;
float y_qa = float(pq2[j][c].y) * inv;
float x_qb = float(pq2[j][(c + 1)].x) * inv;
float y_qb = float(pq2[j][(c + 1)].y) * inv;
const fe4m3vec4 q = nr_convert_quad(pq2[j][c] * f16vec2(float16_t(inv)), pq2[j][(c + 1)] * f16vec2(float16_t(inv)));
pb[m][j][2 * c] = q.x;
pb[m][j][2 * c + 1] = q.y;
pb[m][j][2 * (c + 1)] = q.z;
pb[m][j][2 * (c + 1) + 1] = q.w;
} } } }{ const int j = 2; 
                { { const int c = 0;  {
float x_qa = float(pq2[j][c].x) * inv;
float y_qa = float(pq2[j][c].y) * inv;
float x_qb = float(pq2[j][(c + 1)].x) * inv;
float y_qb = float(pq2[j][(c + 1)].y) * inv;
const fe4m3vec4 q = nr_convert_quad(pq2[j][c] * f16vec2(float16_t(inv)), pq2[j][(c + 1)] * f16vec2(float16_t(inv)));
pb[m][j][2 * c] = q.x;
pb[m][j][2 * c + 1] = q.y;
pb[m][j][2 * (c + 1)] = q.z;
pb[m][j][2 * (c + 1) + 1] = q.w;
} }{ const int c = 2;  {
float x_qa = float(pq2[j][c].x) * inv;
float y_qa = float(pq2[j][c].y) * inv;
float x_qb = float(pq2[j][(c + 1)].x) * inv;
float y_qb = float(pq2[j][(c + 1)].y) * inv;
const fe4m3vec4 q = nr_convert_quad(pq2[j][c] * f16vec2(float16_t(inv)), pq2[j][(c + 1)] * f16vec2(float16_t(inv)));
pb[m][j][2 * c] = q.x;
pb[m][j][2 * c + 1] = q.y;
pb[m][j][2 * (c + 1)] = q.z;
pb[m][j][2 * (c + 1) + 1] = q.w;
} } } }{ const int j = 3; 
                { { const int c = 0;  {
float x_qa = float(pq2[j][c].x) * inv;
float y_qa = float(pq2[j][c].y) * inv;
float x_qb = float(pq2[j][(c + 1)].x) * inv;
float y_qb = float(pq2[j][(c + 1)].y) * inv;
const fe4m3vec4 q = nr_convert_quad(pq2[j][c] * f16vec2(float16_t(inv)), pq2[j][(c + 1)] * f16vec2(float16_t(inv)));
pb[m][j][2 * c] = q.x;
pb[m][j][2 * c + 1] = q.y;
pb[m][j][2 * (c + 1)] = q.z;
pb[m][j][2 * (c + 1) + 1] = q.w;
} }{ const int c = 2;  {
float x_qa = float(pq2[j][c].x) * inv;
float y_qa = float(pq2[j][c].y) * inv;
float x_qb = float(pq2[j][(c + 1)].x) * inv;
float y_qb = float(pq2[j][(c + 1)].y) * inv;
const fe4m3vec4 q = nr_convert_quad(pq2[j][c] * f16vec2(float16_t(inv)), pq2[j][(c + 1)] * f16vec2(float16_t(inv)));
pb[m][j][2 * c] = q.x;
pb[m][j][2 * c + 1] = q.y;
pb[m][j][2 * (c + 1)] = q.z;
pb[m][j][2 * (c + 1) + 1] = q.w;
} } } } }
        } }{ const int m = 1;  {
            f16vec2 pq2[ (64 / 16)][4];
                  coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > lg[ (64 / 16)];



            { { const int j = 0;  lg[j] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int j = 1;  lg[j] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int j = 2;  lg[j] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int j = 3;  lg[j] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); } }


            { { const int d = 0; 
                { { const int j = 0;  {
                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > kf = kreg[j][d];
                                              lg[j] = coopMatMulAdd(kf, qb[m][d], lg[j]);
                } }{ const int j = 1;  {
                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > kf = kreg[j][d];
                                              lg[j] = coopMatMulAdd(kf, qb[m][d], lg[j]);
                } }{ const int j = 2;  {
                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > kf = kreg[j][d];
                                              lg[j] = coopMatMulAdd(kf, qb[m][d], lg[j]);
                } }{ const int j = 3;  {
                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > kf = kreg[j][d];
                                              lg[j] = coopMatMulAdd(kf, qb[m][d], lg[j]);
                } } } }{ const int d = 1; 
                { { const int j = 0;  {
                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > kf = kreg[j][d];
                                              lg[j] = coopMatMulAdd(kf, qb[m][d], lg[j]);
                } }{ const int j = 1;  {
                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > kf = kreg[j][d];
                                              lg[j] = coopMatMulAdd(kf, qb[m][d], lg[j]);
                } }{ const int j = 2;  {
                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > kf = kreg[j][d];
                                              lg[j] = coopMatMulAdd(kf, qb[m][d], lg[j]);
                } }{ const int j = 3;  {
                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > kf = kreg[j][d];
                                              lg[j] = coopMatMulAdd(kf, qb[m][d], lg[j]);
                } } } } }
            { { const int j = 0;  {
















                          coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > bf;



                                            coopMatLoad(bf, wgt_f32, (pc.b_off + uint(hh) * uint(64 * 64) + (tok0 + uint(m) * 16u) * uint(64) + uint(j) * 16u), (uint(64)), gl_CooperativeMatrixLayoutColumnMajor);


                { { const int c = 0; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); }{ const int c = 2; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); }{ const int c = 4; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); }{ const int c = 6; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); } }



            } }{ const int j = 1;  {
















                          coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > bf;



                                            coopMatLoad(bf, wgt_f32, (pc.b_off + uint(hh) * uint(64 * 64) + (tok0 + uint(m) * 16u) * uint(64) + uint(j) * 16u), (uint(64)), gl_CooperativeMatrixLayoutColumnMajor);


                { { const int c = 0; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); }{ const int c = 2; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); }{ const int c = 4; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); }{ const int c = 6; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); } }



            } }{ const int j = 2;  {
















                          coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > bf;



                                            coopMatLoad(bf, wgt_f32, (pc.b_off + uint(hh) * uint(64 * 64) + (tok0 + uint(m) * 16u) * uint(64) + uint(j) * 16u), (uint(64)), gl_CooperativeMatrixLayoutColumnMajor);


                { { const int c = 0; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); }{ const int c = 2; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); }{ const int c = 4; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); }{ const int c = 6; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); } }



            } }{ const int j = 3;  {
















                          coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > bf;



                                            coopMatLoad(bf, wgt_f32, (pc.b_off + uint(hh) * uint(64 * 64) + (tok0 + uint(m) * 16u) * uint(64) + uint(j) * 16u), (uint(64)), gl_CooperativeMatrixLayoutColumnMajor);


                { { const int c = 0; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); }{ const int c = 2; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); }{ const int c = 4; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); }{ const int c = 6; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); } }



            } } }
                 float16_t sum = nr_swin_probability_sum(pq2);


            float inv = float(float16_t(1.0 / float(max(sum, float16_t(6.103515625e-05)))));
            { { const int j = 0; 
                { { const int c = 0;  {
float x_qa = float(pq2[j][c].x) * inv;
float y_qa = float(pq2[j][c].y) * inv;
float x_qb = float(pq2[j][(c + 1)].x) * inv;
float y_qb = float(pq2[j][(c + 1)].y) * inv;
const fe4m3vec4 q = nr_convert_quad(pq2[j][c] * f16vec2(float16_t(inv)), pq2[j][(c + 1)] * f16vec2(float16_t(inv)));
pb[m][j][2 * c] = q.x;
pb[m][j][2 * c + 1] = q.y;
pb[m][j][2 * (c + 1)] = q.z;
pb[m][j][2 * (c + 1) + 1] = q.w;
} }{ const int c = 2;  {
float x_qa = float(pq2[j][c].x) * inv;
float y_qa = float(pq2[j][c].y) * inv;
float x_qb = float(pq2[j][(c + 1)].x) * inv;
float y_qb = float(pq2[j][(c + 1)].y) * inv;
const fe4m3vec4 q = nr_convert_quad(pq2[j][c] * f16vec2(float16_t(inv)), pq2[j][(c + 1)] * f16vec2(float16_t(inv)));
pb[m][j][2 * c] = q.x;
pb[m][j][2 * c + 1] = q.y;
pb[m][j][2 * (c + 1)] = q.z;
pb[m][j][2 * (c + 1) + 1] = q.w;
} } } }{ const int j = 1; 
                { { const int c = 0;  {
float x_qa = float(pq2[j][c].x) * inv;
float y_qa = float(pq2[j][c].y) * inv;
float x_qb = float(pq2[j][(c + 1)].x) * inv;
float y_qb = float(pq2[j][(c + 1)].y) * inv;
const fe4m3vec4 q = nr_convert_quad(pq2[j][c] * f16vec2(float16_t(inv)), pq2[j][(c + 1)] * f16vec2(float16_t(inv)));
pb[m][j][2 * c] = q.x;
pb[m][j][2 * c + 1] = q.y;
pb[m][j][2 * (c + 1)] = q.z;
pb[m][j][2 * (c + 1) + 1] = q.w;
} }{ const int c = 2;  {
float x_qa = float(pq2[j][c].x) * inv;
float y_qa = float(pq2[j][c].y) * inv;
float x_qb = float(pq2[j][(c + 1)].x) * inv;
float y_qb = float(pq2[j][(c + 1)].y) * inv;
const fe4m3vec4 q = nr_convert_quad(pq2[j][c] * f16vec2(float16_t(inv)), pq2[j][(c + 1)] * f16vec2(float16_t(inv)));
pb[m][j][2 * c] = q.x;
pb[m][j][2 * c + 1] = q.y;
pb[m][j][2 * (c + 1)] = q.z;
pb[m][j][2 * (c + 1) + 1] = q.w;
} } } }{ const int j = 2; 
                { { const int c = 0;  {
float x_qa = float(pq2[j][c].x) * inv;
float y_qa = float(pq2[j][c].y) * inv;
float x_qb = float(pq2[j][(c + 1)].x) * inv;
float y_qb = float(pq2[j][(c + 1)].y) * inv;
const fe4m3vec4 q = nr_convert_quad(pq2[j][c] * f16vec2(float16_t(inv)), pq2[j][(c + 1)] * f16vec2(float16_t(inv)));
pb[m][j][2 * c] = q.x;
pb[m][j][2 * c + 1] = q.y;
pb[m][j][2 * (c + 1)] = q.z;
pb[m][j][2 * (c + 1) + 1] = q.w;
} }{ const int c = 2;  {
float x_qa = float(pq2[j][c].x) * inv;
float y_qa = float(pq2[j][c].y) * inv;
float x_qb = float(pq2[j][(c + 1)].x) * inv;
float y_qb = float(pq2[j][(c + 1)].y) * inv;
const fe4m3vec4 q = nr_convert_quad(pq2[j][c] * f16vec2(float16_t(inv)), pq2[j][(c + 1)] * f16vec2(float16_t(inv)));
pb[m][j][2 * c] = q.x;
pb[m][j][2 * c + 1] = q.y;
pb[m][j][2 * (c + 1)] = q.z;
pb[m][j][2 * (c + 1) + 1] = q.w;
} } } }{ const int j = 3; 
                { { const int c = 0;  {
float x_qa = float(pq2[j][c].x) * inv;
float y_qa = float(pq2[j][c].y) * inv;
float x_qb = float(pq2[j][(c + 1)].x) * inv;
float y_qb = float(pq2[j][(c + 1)].y) * inv;
const fe4m3vec4 q = nr_convert_quad(pq2[j][c] * f16vec2(float16_t(inv)), pq2[j][(c + 1)] * f16vec2(float16_t(inv)));
pb[m][j][2 * c] = q.x;
pb[m][j][2 * c + 1] = q.y;
pb[m][j][2 * (c + 1)] = q.z;
pb[m][j][2 * (c + 1) + 1] = q.w;
} }{ const int c = 2;  {
float x_qa = float(pq2[j][c].x) * inv;
float y_qa = float(pq2[j][c].y) * inv;
float x_qb = float(pq2[j][(c + 1)].x) * inv;
float y_qb = float(pq2[j][(c + 1)].y) * inv;
const fe4m3vec4 q = nr_convert_quad(pq2[j][c] * f16vec2(float16_t(inv)), pq2[j][(c + 1)] * f16vec2(float16_t(inv)));
pb[m][j][2 * c] = q.x;
pb[m][j][2 * c + 1] = q.y;
pb[m][j][2 * (c + 1)] = q.z;
pb[m][j][2 * (c + 1) + 1] = q.w;
} } } } }
        } }{ const int m = 2;  {
            f16vec2 pq2[ (64 / 16)][4];
                  coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > lg[ (64 / 16)];



            { { const int j = 0;  lg[j] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int j = 1;  lg[j] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int j = 2;  lg[j] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int j = 3;  lg[j] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); } }


            { { const int d = 0; 
                { { const int j = 0;  {
                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > kf = kreg[j][d];
                                              lg[j] = coopMatMulAdd(kf, qb[m][d], lg[j]);
                } }{ const int j = 1;  {
                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > kf = kreg[j][d];
                                              lg[j] = coopMatMulAdd(kf, qb[m][d], lg[j]);
                } }{ const int j = 2;  {
                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > kf = kreg[j][d];
                                              lg[j] = coopMatMulAdd(kf, qb[m][d], lg[j]);
                } }{ const int j = 3;  {
                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > kf = kreg[j][d];
                                              lg[j] = coopMatMulAdd(kf, qb[m][d], lg[j]);
                } } } }{ const int d = 1; 
                { { const int j = 0;  {
                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > kf = kreg[j][d];
                                              lg[j] = coopMatMulAdd(kf, qb[m][d], lg[j]);
                } }{ const int j = 1;  {
                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > kf = kreg[j][d];
                                              lg[j] = coopMatMulAdd(kf, qb[m][d], lg[j]);
                } }{ const int j = 2;  {
                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > kf = kreg[j][d];
                                              lg[j] = coopMatMulAdd(kf, qb[m][d], lg[j]);
                } }{ const int j = 3;  {
                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > kf = kreg[j][d];
                                              lg[j] = coopMatMulAdd(kf, qb[m][d], lg[j]);
                } } } } }
            { { const int j = 0;  {
















                          coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > bf;



                                            coopMatLoad(bf, wgt_f32, (pc.b_off + uint(hh) * uint(64 * 64) + (tok0 + uint(m) * 16u) * uint(64) + uint(j) * 16u), (uint(64)), gl_CooperativeMatrixLayoutColumnMajor);


                { { const int c = 0; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); }{ const int c = 2; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); }{ const int c = 4; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); }{ const int c = 6; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); } }



            } }{ const int j = 1;  {
















                          coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > bf;



                                            coopMatLoad(bf, wgt_f32, (pc.b_off + uint(hh) * uint(64 * 64) + (tok0 + uint(m) * 16u) * uint(64) + uint(j) * 16u), (uint(64)), gl_CooperativeMatrixLayoutColumnMajor);


                { { const int c = 0; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); }{ const int c = 2; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); }{ const int c = 4; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); }{ const int c = 6; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); } }



            } }{ const int j = 2;  {
















                          coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > bf;



                                            coopMatLoad(bf, wgt_f32, (pc.b_off + uint(hh) * uint(64 * 64) + (tok0 + uint(m) * 16u) * uint(64) + uint(j) * 16u), (uint(64)), gl_CooperativeMatrixLayoutColumnMajor);


                { { const int c = 0; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); }{ const int c = 2; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); }{ const int c = 4; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); }{ const int c = 6; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); } }



            } }{ const int j = 3;  {
















                          coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > bf;



                                            coopMatLoad(bf, wgt_f32, (pc.b_off + uint(hh) * uint(64 * 64) + (tok0 + uint(m) * 16u) * uint(64) + uint(j) * 16u), (uint(64)), gl_CooperativeMatrixLayoutColumnMajor);


                { { const int c = 0; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); }{ const int c = 2; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); }{ const int c = 4; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); }{ const int c = 6; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); } }



            } } }
                 float16_t sum = nr_swin_probability_sum(pq2);


            float inv = float(float16_t(1.0 / float(max(sum, float16_t(6.103515625e-05)))));
            { { const int j = 0; 
                { { const int c = 0;  {
float x_qa = float(pq2[j][c].x) * inv;
float y_qa = float(pq2[j][c].y) * inv;
float x_qb = float(pq2[j][(c + 1)].x) * inv;
float y_qb = float(pq2[j][(c + 1)].y) * inv;
const fe4m3vec4 q = nr_convert_quad(pq2[j][c] * f16vec2(float16_t(inv)), pq2[j][(c + 1)] * f16vec2(float16_t(inv)));
pb[m][j][2 * c] = q.x;
pb[m][j][2 * c + 1] = q.y;
pb[m][j][2 * (c + 1)] = q.z;
pb[m][j][2 * (c + 1) + 1] = q.w;
} }{ const int c = 2;  {
float x_qa = float(pq2[j][c].x) * inv;
float y_qa = float(pq2[j][c].y) * inv;
float x_qb = float(pq2[j][(c + 1)].x) * inv;
float y_qb = float(pq2[j][(c + 1)].y) * inv;
const fe4m3vec4 q = nr_convert_quad(pq2[j][c] * f16vec2(float16_t(inv)), pq2[j][(c + 1)] * f16vec2(float16_t(inv)));
pb[m][j][2 * c] = q.x;
pb[m][j][2 * c + 1] = q.y;
pb[m][j][2 * (c + 1)] = q.z;
pb[m][j][2 * (c + 1) + 1] = q.w;
} } } }{ const int j = 1; 
                { { const int c = 0;  {
float x_qa = float(pq2[j][c].x) * inv;
float y_qa = float(pq2[j][c].y) * inv;
float x_qb = float(pq2[j][(c + 1)].x) * inv;
float y_qb = float(pq2[j][(c + 1)].y) * inv;
const fe4m3vec4 q = nr_convert_quad(pq2[j][c] * f16vec2(float16_t(inv)), pq2[j][(c + 1)] * f16vec2(float16_t(inv)));
pb[m][j][2 * c] = q.x;
pb[m][j][2 * c + 1] = q.y;
pb[m][j][2 * (c + 1)] = q.z;
pb[m][j][2 * (c + 1) + 1] = q.w;
} }{ const int c = 2;  {
float x_qa = float(pq2[j][c].x) * inv;
float y_qa = float(pq2[j][c].y) * inv;
float x_qb = float(pq2[j][(c + 1)].x) * inv;
float y_qb = float(pq2[j][(c + 1)].y) * inv;
const fe4m3vec4 q = nr_convert_quad(pq2[j][c] * f16vec2(float16_t(inv)), pq2[j][(c + 1)] * f16vec2(float16_t(inv)));
pb[m][j][2 * c] = q.x;
pb[m][j][2 * c + 1] = q.y;
pb[m][j][2 * (c + 1)] = q.z;
pb[m][j][2 * (c + 1) + 1] = q.w;
} } } }{ const int j = 2; 
                { { const int c = 0;  {
float x_qa = float(pq2[j][c].x) * inv;
float y_qa = float(pq2[j][c].y) * inv;
float x_qb = float(pq2[j][(c + 1)].x) * inv;
float y_qb = float(pq2[j][(c + 1)].y) * inv;
const fe4m3vec4 q = nr_convert_quad(pq2[j][c] * f16vec2(float16_t(inv)), pq2[j][(c + 1)] * f16vec2(float16_t(inv)));
pb[m][j][2 * c] = q.x;
pb[m][j][2 * c + 1] = q.y;
pb[m][j][2 * (c + 1)] = q.z;
pb[m][j][2 * (c + 1) + 1] = q.w;
} }{ const int c = 2;  {
float x_qa = float(pq2[j][c].x) * inv;
float y_qa = float(pq2[j][c].y) * inv;
float x_qb = float(pq2[j][(c + 1)].x) * inv;
float y_qb = float(pq2[j][(c + 1)].y) * inv;
const fe4m3vec4 q = nr_convert_quad(pq2[j][c] * f16vec2(float16_t(inv)), pq2[j][(c + 1)] * f16vec2(float16_t(inv)));
pb[m][j][2 * c] = q.x;
pb[m][j][2 * c + 1] = q.y;
pb[m][j][2 * (c + 1)] = q.z;
pb[m][j][2 * (c + 1) + 1] = q.w;
} } } }{ const int j = 3; 
                { { const int c = 0;  {
float x_qa = float(pq2[j][c].x) * inv;
float y_qa = float(pq2[j][c].y) * inv;
float x_qb = float(pq2[j][(c + 1)].x) * inv;
float y_qb = float(pq2[j][(c + 1)].y) * inv;
const fe4m3vec4 q = nr_convert_quad(pq2[j][c] * f16vec2(float16_t(inv)), pq2[j][(c + 1)] * f16vec2(float16_t(inv)));
pb[m][j][2 * c] = q.x;
pb[m][j][2 * c + 1] = q.y;
pb[m][j][2 * (c + 1)] = q.z;
pb[m][j][2 * (c + 1) + 1] = q.w;
} }{ const int c = 2;  {
float x_qa = float(pq2[j][c].x) * inv;
float y_qa = float(pq2[j][c].y) * inv;
float x_qb = float(pq2[j][(c + 1)].x) * inv;
float y_qb = float(pq2[j][(c + 1)].y) * inv;
const fe4m3vec4 q = nr_convert_quad(pq2[j][c] * f16vec2(float16_t(inv)), pq2[j][(c + 1)] * f16vec2(float16_t(inv)));
pb[m][j][2 * c] = q.x;
pb[m][j][2 * c + 1] = q.y;
pb[m][j][2 * (c + 1)] = q.z;
pb[m][j][2 * (c + 1) + 1] = q.w;
} } } } }
        } }{ const int m = 3;  {
            f16vec2 pq2[ (64 / 16)][4];
                  coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > lg[ (64 / 16)];



            { { const int j = 0;  lg[j] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int j = 1;  lg[j] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int j = 2;  lg[j] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int j = 3;  lg[j] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); } }


            { { const int d = 0; 
                { { const int j = 0;  {
                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > kf = kreg[j][d];
                                              lg[j] = coopMatMulAdd(kf, qb[m][d], lg[j]);
                } }{ const int j = 1;  {
                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > kf = kreg[j][d];
                                              lg[j] = coopMatMulAdd(kf, qb[m][d], lg[j]);
                } }{ const int j = 2;  {
                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > kf = kreg[j][d];
                                              lg[j] = coopMatMulAdd(kf, qb[m][d], lg[j]);
                } }{ const int j = 3;  {
                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > kf = kreg[j][d];
                                              lg[j] = coopMatMulAdd(kf, qb[m][d], lg[j]);
                } } } }{ const int d = 1; 
                { { const int j = 0;  {
                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > kf = kreg[j][d];
                                              lg[j] = coopMatMulAdd(kf, qb[m][d], lg[j]);
                } }{ const int j = 1;  {
                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > kf = kreg[j][d];
                                              lg[j] = coopMatMulAdd(kf, qb[m][d], lg[j]);
                } }{ const int j = 2;  {
                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > kf = kreg[j][d];
                                              lg[j] = coopMatMulAdd(kf, qb[m][d], lg[j]);
                } }{ const int j = 3;  {
                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > kf = kreg[j][d];
                                              lg[j] = coopMatMulAdd(kf, qb[m][d], lg[j]);
                } } } } }
            { { const int j = 0;  {
















                          coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > bf;



                                            coopMatLoad(bf, wgt_f32, (pc.b_off + uint(hh) * uint(64 * 64) + (tok0 + uint(m) * 16u) * uint(64) + uint(j) * 16u), (uint(64)), gl_CooperativeMatrixLayoutColumnMajor);


                { { const int c = 0; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); }{ const int c = 2; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); }{ const int c = 4; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); }{ const int c = 6; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); } }



            } }{ const int j = 1;  {
















                          coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > bf;



                                            coopMatLoad(bf, wgt_f32, (pc.b_off + uint(hh) * uint(64 * 64) + (tok0 + uint(m) * 16u) * uint(64) + uint(j) * 16u), (uint(64)), gl_CooperativeMatrixLayoutColumnMajor);


                { { const int c = 0; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); }{ const int c = 2; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); }{ const int c = 4; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); }{ const int c = 6; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); } }



            } }{ const int j = 2;  {
















                          coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > bf;



                                            coopMatLoad(bf, wgt_f32, (pc.b_off + uint(hh) * uint(64 * 64) + (tok0 + uint(m) * 16u) * uint(64) + uint(j) * 16u), (uint(64)), gl_CooperativeMatrixLayoutColumnMajor);


                { { const int c = 0; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); }{ const int c = 2; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); }{ const int c = 4; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); }{ const int c = 6; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); } }



            } }{ const int j = 3;  {
















                          coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > bf;



                                            coopMatLoad(bf, wgt_f32, (pc.b_off + uint(hh) * uint(64 * 64) + (tok0 + uint(m) * 16u) * uint(64) + uint(j) * 16u), (uint(64)), gl_CooperativeMatrixLayoutColumnMajor);


                { { const int c = 0; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); }{ const int c = 2; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); }{ const int c = 4; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); }{ const int c = 6; 
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1])); } }



            } } }
                 float16_t sum = nr_swin_probability_sum(pq2);


            float inv = float(float16_t(1.0 / float(max(sum, float16_t(6.103515625e-05)))));
            { { const int j = 0; 
                { { const int c = 0;  {
float x_qa = float(pq2[j][c].x) * inv;
float y_qa = float(pq2[j][c].y) * inv;
float x_qb = float(pq2[j][(c + 1)].x) * inv;
float y_qb = float(pq2[j][(c + 1)].y) * inv;
const fe4m3vec4 q = nr_convert_quad(pq2[j][c] * f16vec2(float16_t(inv)), pq2[j][(c + 1)] * f16vec2(float16_t(inv)));
pb[m][j][2 * c] = q.x;
pb[m][j][2 * c + 1] = q.y;
pb[m][j][2 * (c + 1)] = q.z;
pb[m][j][2 * (c + 1) + 1] = q.w;
} }{ const int c = 2;  {
float x_qa = float(pq2[j][c].x) * inv;
float y_qa = float(pq2[j][c].y) * inv;
float x_qb = float(pq2[j][(c + 1)].x) * inv;
float y_qb = float(pq2[j][(c + 1)].y) * inv;
const fe4m3vec4 q = nr_convert_quad(pq2[j][c] * f16vec2(float16_t(inv)), pq2[j][(c + 1)] * f16vec2(float16_t(inv)));
pb[m][j][2 * c] = q.x;
pb[m][j][2 * c + 1] = q.y;
pb[m][j][2 * (c + 1)] = q.z;
pb[m][j][2 * (c + 1) + 1] = q.w;
} } } }{ const int j = 1; 
                { { const int c = 0;  {
float x_qa = float(pq2[j][c].x) * inv;
float y_qa = float(pq2[j][c].y) * inv;
float x_qb = float(pq2[j][(c + 1)].x) * inv;
float y_qb = float(pq2[j][(c + 1)].y) * inv;
const fe4m3vec4 q = nr_convert_quad(pq2[j][c] * f16vec2(float16_t(inv)), pq2[j][(c + 1)] * f16vec2(float16_t(inv)));
pb[m][j][2 * c] = q.x;
pb[m][j][2 * c + 1] = q.y;
pb[m][j][2 * (c + 1)] = q.z;
pb[m][j][2 * (c + 1) + 1] = q.w;
} }{ const int c = 2;  {
float x_qa = float(pq2[j][c].x) * inv;
float y_qa = float(pq2[j][c].y) * inv;
float x_qb = float(pq2[j][(c + 1)].x) * inv;
float y_qb = float(pq2[j][(c + 1)].y) * inv;
const fe4m3vec4 q = nr_convert_quad(pq2[j][c] * f16vec2(float16_t(inv)), pq2[j][(c + 1)] * f16vec2(float16_t(inv)));
pb[m][j][2 * c] = q.x;
pb[m][j][2 * c + 1] = q.y;
pb[m][j][2 * (c + 1)] = q.z;
pb[m][j][2 * (c + 1) + 1] = q.w;
} } } }{ const int j = 2; 
                { { const int c = 0;  {
float x_qa = float(pq2[j][c].x) * inv;
float y_qa = float(pq2[j][c].y) * inv;
float x_qb = float(pq2[j][(c + 1)].x) * inv;
float y_qb = float(pq2[j][(c + 1)].y) * inv;
const fe4m3vec4 q = nr_convert_quad(pq2[j][c] * f16vec2(float16_t(inv)), pq2[j][(c + 1)] * f16vec2(float16_t(inv)));
pb[m][j][2 * c] = q.x;
pb[m][j][2 * c + 1] = q.y;
pb[m][j][2 * (c + 1)] = q.z;
pb[m][j][2 * (c + 1) + 1] = q.w;
} }{ const int c = 2;  {
float x_qa = float(pq2[j][c].x) * inv;
float y_qa = float(pq2[j][c].y) * inv;
float x_qb = float(pq2[j][(c + 1)].x) * inv;
float y_qb = float(pq2[j][(c + 1)].y) * inv;
const fe4m3vec4 q = nr_convert_quad(pq2[j][c] * f16vec2(float16_t(inv)), pq2[j][(c + 1)] * f16vec2(float16_t(inv)));
pb[m][j][2 * c] = q.x;
pb[m][j][2 * c + 1] = q.y;
pb[m][j][2 * (c + 1)] = q.z;
pb[m][j][2 * (c + 1) + 1] = q.w;
} } } }{ const int j = 3; 
                { { const int c = 0;  {
float x_qa = float(pq2[j][c].x) * inv;
float y_qa = float(pq2[j][c].y) * inv;
float x_qb = float(pq2[j][(c + 1)].x) * inv;
float y_qb = float(pq2[j][(c + 1)].y) * inv;
const fe4m3vec4 q = nr_convert_quad(pq2[j][c] * f16vec2(float16_t(inv)), pq2[j][(c + 1)] * f16vec2(float16_t(inv)));
pb[m][j][2 * c] = q.x;
pb[m][j][2 * c + 1] = q.y;
pb[m][j][2 * (c + 1)] = q.z;
pb[m][j][2 * (c + 1) + 1] = q.w;
} }{ const int c = 2;  {
float x_qa = float(pq2[j][c].x) * inv;
float y_qa = float(pq2[j][c].y) * inv;
float x_qb = float(pq2[j][(c + 1)].x) * inv;
float y_qb = float(pq2[j][(c + 1)].y) * inv;
const fe4m3vec4 q = nr_convert_quad(pq2[j][c] * f16vec2(float16_t(inv)), pq2[j][(c + 1)] * f16vec2(float16_t(inv)));
pb[m][j][2 * c] = q.x;
pb[m][j][2 * c + 1] = q.y;
pb[m][j][2 * (c + 1)] = q.z;
pb[m][j][2 * (c + 1) + 1] = q.w;
} } } } }
        } } }
























































































































































































        { { const int e = 0;  {
                  coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > a[ (64 / 16)];
            { { const int m = 0;  a[m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int m = 1;  a[m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int m = 2;  a[m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int m = 3;  a[m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); } }
            { { const int j = 0;  {
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > vf;

                vf = vreg[e][j];








                { { const int m = 0;  a[m] = coopMatMulAdd(vf, pb[m][j], a[m]); }{ const int m = 1;  a[m] = coopMatMulAdd(vf, pb[m][j], a[m]); }{ const int m = 2;  a[m] = coopMatMulAdd(vf, pb[m][j], a[m]); }{ const int m = 3;  a[m] = coopMatMulAdd(vf, pb[m][j], a[m]); } }
                if (0 > 0 && (j + 1) % 0 == 0)
                    { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } }
            } }{ const int j = 1;  {
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > vf;

                vf = vreg[e][j];








                { { const int m = 0;  a[m] = coopMatMulAdd(vf, pb[m][j], a[m]); }{ const int m = 1;  a[m] = coopMatMulAdd(vf, pb[m][j], a[m]); }{ const int m = 2;  a[m] = coopMatMulAdd(vf, pb[m][j], a[m]); }{ const int m = 3;  a[m] = coopMatMulAdd(vf, pb[m][j], a[m]); } }
                if (0 > 0 && (j + 1) % 0 == 0)
                    { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } }
            } }{ const int j = 2;  {
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > vf;

                vf = vreg[e][j];








                { { const int m = 0;  a[m] = coopMatMulAdd(vf, pb[m][j], a[m]); }{ const int m = 1;  a[m] = coopMatMulAdd(vf, pb[m][j], a[m]); }{ const int m = 2;  a[m] = coopMatMulAdd(vf, pb[m][j], a[m]); }{ const int m = 3;  a[m] = coopMatMulAdd(vf, pb[m][j], a[m]); } }
                if (0 > 0 && (j + 1) % 0 == 0)
                    { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } }
            } }{ const int j = 3;  {
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > vf;

                vf = vreg[e][j];








                { { const int m = 0;  a[m] = coopMatMulAdd(vf, pb[m][j], a[m]); }{ const int m = 1;  a[m] = coopMatMulAdd(vf, pb[m][j], a[m]); }{ const int m = 2;  a[m] = coopMatMulAdd(vf, pb[m][j], a[m]); }{ const int m = 3;  a[m] = coopMatMulAdd(vf, pb[m][j], a[m]); } }
                if (0 > 0 && (j + 1) % 0 == 0)
                    { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } }
            } } }
            { { const int m = 0;  {

                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > out_context;





                { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(a[m][c], a[m][c + 1]), vec2(a[m][(c + 2)], a[m][(c + 2) + 1]));
out_context[c] = qp.x;
out_context[c + 1] = qp.y;
out_context[(c + 2)] = qp.z;
out_context[(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(a[m][c], a[m][c + 1]), vec2(a[m][(c + 2)], a[m][(c + 2) + 1]));
out_context[c] = qp.x;
out_context[c + 1] = qp.y;
out_context[(c + 2)] = qp.z;
out_context[(c + 2) + 1] = qp.w;
} } }








                                                                             coopMatStore(out_context, lds_y, (uint(m * (128 / 16) + hh * ( (128 / 4) / 16) + e) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);




















            } }{ const int m = 1;  {

                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > out_context;





                { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(a[m][c], a[m][c + 1]), vec2(a[m][(c + 2)], a[m][(c + 2) + 1]));
out_context[c] = qp.x;
out_context[c + 1] = qp.y;
out_context[(c + 2)] = qp.z;
out_context[(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(a[m][c], a[m][c + 1]), vec2(a[m][(c + 2)], a[m][(c + 2) + 1]));
out_context[c] = qp.x;
out_context[c + 1] = qp.y;
out_context[(c + 2)] = qp.z;
out_context[(c + 2) + 1] = qp.w;
} } }








                                                                             coopMatStore(out_context, lds_y, (uint(m * (128 / 16) + hh * ( (128 / 4) / 16) + e) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);




















            } }{ const int m = 2;  {

                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > out_context;





                { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(a[m][c], a[m][c + 1]), vec2(a[m][(c + 2)], a[m][(c + 2) + 1]));
out_context[c] = qp.x;
out_context[c + 1] = qp.y;
out_context[(c + 2)] = qp.z;
out_context[(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(a[m][c], a[m][c + 1]), vec2(a[m][(c + 2)], a[m][(c + 2) + 1]));
out_context[c] = qp.x;
out_context[c + 1] = qp.y;
out_context[(c + 2)] = qp.z;
out_context[(c + 2) + 1] = qp.w;
} } }








                                                                             coopMatStore(out_context, lds_y, (uint(m * (128 / 16) + hh * ( (128 / 4) / 16) + e) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);




















            } }{ const int m = 3;  {

                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > out_context;





                { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(a[m][c], a[m][c + 1]), vec2(a[m][(c + 2)], a[m][(c + 2) + 1]));
out_context[c] = qp.x;
out_context[c + 1] = qp.y;
out_context[(c + 2)] = qp.z;
out_context[(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(a[m][c], a[m][c + 1]), vec2(a[m][(c + 2)], a[m][(c + 2) + 1]));
out_context[c] = qp.x;
out_context[c + 1] = qp.y;
out_context[(c + 2)] = qp.z;
out_context[(c + 2) + 1] = qp.w;
} } }








                                                                             coopMatStore(out_context, lds_y, (uint(m * (128 / 16) + hh * ( (128 / 4) / 16) + e) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);




















            } } }
        } }{ const int e = 1;  {
                  coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > a[ (64 / 16)];
            { { const int m = 0;  a[m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int m = 1;  a[m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int m = 2;  a[m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); }{ const int m = 3;  a[m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0); } }
            { { const int j = 0;  {
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > vf;

                vf = vreg[e][j];








                { { const int m = 0;  a[m] = coopMatMulAdd(vf, pb[m][j], a[m]); }{ const int m = 1;  a[m] = coopMatMulAdd(vf, pb[m][j], a[m]); }{ const int m = 2;  a[m] = coopMatMulAdd(vf, pb[m][j], a[m]); }{ const int m = 3;  a[m] = coopMatMulAdd(vf, pb[m][j], a[m]); } }
                if (0 > 0 && (j + 1) % 0 == 0)
                    { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } }
            } }{ const int j = 1;  {
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > vf;

                vf = vreg[e][j];








                { { const int m = 0;  a[m] = coopMatMulAdd(vf, pb[m][j], a[m]); }{ const int m = 1;  a[m] = coopMatMulAdd(vf, pb[m][j], a[m]); }{ const int m = 2;  a[m] = coopMatMulAdd(vf, pb[m][j], a[m]); }{ const int m = 3;  a[m] = coopMatMulAdd(vf, pb[m][j], a[m]); } }
                if (0 > 0 && (j + 1) % 0 == 0)
                    { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } }
            } }{ const int j = 2;  {
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > vf;

                vf = vreg[e][j];








                { { const int m = 0;  a[m] = coopMatMulAdd(vf, pb[m][j], a[m]); }{ const int m = 1;  a[m] = coopMatMulAdd(vf, pb[m][j], a[m]); }{ const int m = 2;  a[m] = coopMatMulAdd(vf, pb[m][j], a[m]); }{ const int m = 3;  a[m] = coopMatMulAdd(vf, pb[m][j], a[m]); } }
                if (0 > 0 && (j + 1) % 0 == 0)
                    { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } }
            } }{ const int j = 3;  {
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > vf;

                vf = vreg[e][j];








                { { const int m = 0;  a[m] = coopMatMulAdd(vf, pb[m][j], a[m]); }{ const int m = 1;  a[m] = coopMatMulAdd(vf, pb[m][j], a[m]); }{ const int m = 2;  a[m] = coopMatMulAdd(vf, pb[m][j], a[m]); }{ const int m = 3;  a[m] = coopMatMulAdd(vf, pb[m][j], a[m]); } }
                if (0 > 0 && (j + 1) % 0 == 0)
                    { { const int m = 0;  { } }{ const int m = 1;  { } }{ const int m = 2;  { } }{ const int m = 3;  { } } }
            } } }
            { { const int m = 0;  {

                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > out_context;





                { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(a[m][c], a[m][c + 1]), vec2(a[m][(c + 2)], a[m][(c + 2) + 1]));
out_context[c] = qp.x;
out_context[c + 1] = qp.y;
out_context[(c + 2)] = qp.z;
out_context[(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(a[m][c], a[m][c + 1]), vec2(a[m][(c + 2)], a[m][(c + 2) + 1]));
out_context[c] = qp.x;
out_context[c + 1] = qp.y;
out_context[(c + 2)] = qp.z;
out_context[(c + 2) + 1] = qp.w;
} } }








                                                                             coopMatStore(out_context, lds_y, (uint(m * (128 / 16) + hh * ( (128 / 4) / 16) + e) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);




















            } }{ const int m = 1;  {

                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > out_context;





                { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(a[m][c], a[m][c + 1]), vec2(a[m][(c + 2)], a[m][(c + 2) + 1]));
out_context[c] = qp.x;
out_context[c + 1] = qp.y;
out_context[(c + 2)] = qp.z;
out_context[(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(a[m][c], a[m][c + 1]), vec2(a[m][(c + 2)], a[m][(c + 2) + 1]));
out_context[c] = qp.x;
out_context[c + 1] = qp.y;
out_context[(c + 2)] = qp.z;
out_context[(c + 2) + 1] = qp.w;
} } }








                                                                             coopMatStore(out_context, lds_y, (uint(m * (128 / 16) + hh * ( (128 / 4) / 16) + e) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);




















            } }{ const int m = 2;  {

                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > out_context;





                { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(a[m][c], a[m][c + 1]), vec2(a[m][(c + 2)], a[m][(c + 2) + 1]));
out_context[c] = qp.x;
out_context[c + 1] = qp.y;
out_context[(c + 2)] = qp.z;
out_context[(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(a[m][c], a[m][c + 1]), vec2(a[m][(c + 2)], a[m][(c + 2) + 1]));
out_context[c] = qp.x;
out_context[c + 1] = qp.y;
out_context[(c + 2)] = qp.z;
out_context[(c + 2) + 1] = qp.w;
} } }








                                                                             coopMatStore(out_context, lds_y, (uint(m * (128 / 16) + hh * ( (128 / 4) / 16) + e) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);




















            } }{ const int m = 3;  {

                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > out_context;





                { { const int c = 0;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(a[m][c], a[m][c + 1]), vec2(a[m][(c + 2)], a[m][(c + 2) + 1]));
out_context[c] = qp.x;
out_context[c + 1] = qp.y;
out_context[(c + 2)] = qp.z;
out_context[(c + 2) + 1] = qp.w;
} }{ const int c = 4;  {
const fe4m3vec4 qp = nr_quant_quad32(vec2(a[m][c], a[m][c + 1]), vec2(a[m][(c + 2)], a[m][(c + 2) + 1]));
out_context[c] = qp.x;
out_context[c + 1] = qp.y;
out_context[(c + 2)] = qp.z;
out_context[(c + 2) + 1] = qp.w;
} } }








                                                                             coopMatStore(out_context, lds_y, (uint(m * (128 / 16) + hh * ( (128 / 4) / 16) + e) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);




















            } } }
        } } }


        barrier();

    }













































































          coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > nr_project_acc[ ( (128 / 4) / 16)][ (64 / 16)];
    { { const int p = 0;  {
        const int n = nrhw_h * ( (128 / 4) / 16) + p;
        { { const int m = 0;  {
                    coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yr;
                                                                            coopMatLoad(yr, lds_x, (uint(m * (128 / 16) + n) * 256u + (nr_opaque * ( (80u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);
            { { const int c = 0;  {
                const uint off = pc.ars_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_project_acc[p][m][c] = float(residual.x);
                nr_project_acc[p][m][c + 1] = float(residual.y);
            } }{ const int c = 2;  {
                const uint off = pc.ars_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_project_acc[p][m][c] = float(residual.x);
                nr_project_acc[p][m][c + 1] = float(residual.y);
            } }{ const int c = 4;  {
                const uint off = pc.ars_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_project_acc[p][m][c] = float(residual.x);
                nr_project_acc[p][m][c + 1] = float(residual.y);
            } }{ const int c = 6;  {
                const uint off = pc.ars_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_project_acc[p][m][c] = float(residual.x);
                nr_project_acc[p][m][c + 1] = float(residual.y);
            } } }
        } }{ const int m = 1;  {
                    coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yr;
                                                                            coopMatLoad(yr, lds_x, (uint(m * (128 / 16) + n) * 256u + (nr_opaque * ( (80u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);
            { { const int c = 0;  {
                const uint off = pc.ars_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_project_acc[p][m][c] = float(residual.x);
                nr_project_acc[p][m][c + 1] = float(residual.y);
            } }{ const int c = 2;  {
                const uint off = pc.ars_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_project_acc[p][m][c] = float(residual.x);
                nr_project_acc[p][m][c + 1] = float(residual.y);
            } }{ const int c = 4;  {
                const uint off = pc.ars_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_project_acc[p][m][c] = float(residual.x);
                nr_project_acc[p][m][c + 1] = float(residual.y);
            } }{ const int c = 6;  {
                const uint off = pc.ars_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_project_acc[p][m][c] = float(residual.x);
                nr_project_acc[p][m][c + 1] = float(residual.y);
            } } }
        } }{ const int m = 2;  {
                    coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yr;
                                                                            coopMatLoad(yr, lds_x, (uint(m * (128 / 16) + n) * 256u + (nr_opaque * ( (80u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);
            { { const int c = 0;  {
                const uint off = pc.ars_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_project_acc[p][m][c] = float(residual.x);
                nr_project_acc[p][m][c + 1] = float(residual.y);
            } }{ const int c = 2;  {
                const uint off = pc.ars_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_project_acc[p][m][c] = float(residual.x);
                nr_project_acc[p][m][c + 1] = float(residual.y);
            } }{ const int c = 4;  {
                const uint off = pc.ars_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_project_acc[p][m][c] = float(residual.x);
                nr_project_acc[p][m][c + 1] = float(residual.y);
            } }{ const int c = 6;  {
                const uint off = pc.ars_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_project_acc[p][m][c] = float(residual.x);
                nr_project_acc[p][m][c + 1] = float(residual.y);
            } } }
        } }{ const int m = 3;  {
                    coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yr;
                                                                            coopMatLoad(yr, lds_x, (uint(m * (128 / 16) + n) * 256u + (nr_opaque * ( (80u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);
            { { const int c = 0;  {
                const uint off = pc.ars_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_project_acc[p][m][c] = float(residual.x);
                nr_project_acc[p][m][c + 1] = float(residual.y);
            } }{ const int c = 2;  {
                const uint off = pc.ars_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_project_acc[p][m][c] = float(residual.x);
                nr_project_acc[p][m][c + 1] = float(residual.y);
            } }{ const int c = 4;  {
                const uint off = pc.ars_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_project_acc[p][m][c] = float(residual.x);
                nr_project_acc[p][m][c + 1] = float(residual.y);
            } }{ const int c = 6;  {
                const uint off = pc.ars_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_project_acc[p][m][c] = float(residual.x);
                nr_project_acc[p][m][c + 1] = float(residual.y);
            } } }
        } } }
    } }{ const int p = 1;  {
        const int n = nrhw_h * ( (128 / 4) / 16) + p;
        { { const int m = 0;  {
                    coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yr;
                                                                            coopMatLoad(yr, lds_x, (uint(m * (128 / 16) + n) * 256u + (nr_opaque * ( (80u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);
            { { const int c = 0;  {
                const uint off = pc.ars_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_project_acc[p][m][c] = float(residual.x);
                nr_project_acc[p][m][c + 1] = float(residual.y);
            } }{ const int c = 2;  {
                const uint off = pc.ars_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_project_acc[p][m][c] = float(residual.x);
                nr_project_acc[p][m][c + 1] = float(residual.y);
            } }{ const int c = 4;  {
                const uint off = pc.ars_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_project_acc[p][m][c] = float(residual.x);
                nr_project_acc[p][m][c + 1] = float(residual.y);
            } }{ const int c = 6;  {
                const uint off = pc.ars_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_project_acc[p][m][c] = float(residual.x);
                nr_project_acc[p][m][c + 1] = float(residual.y);
            } } }
        } }{ const int m = 1;  {
                    coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yr;
                                                                            coopMatLoad(yr, lds_x, (uint(m * (128 / 16) + n) * 256u + (nr_opaque * ( (80u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);
            { { const int c = 0;  {
                const uint off = pc.ars_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_project_acc[p][m][c] = float(residual.x);
                nr_project_acc[p][m][c + 1] = float(residual.y);
            } }{ const int c = 2;  {
                const uint off = pc.ars_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_project_acc[p][m][c] = float(residual.x);
                nr_project_acc[p][m][c + 1] = float(residual.y);
            } }{ const int c = 4;  {
                const uint off = pc.ars_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_project_acc[p][m][c] = float(residual.x);
                nr_project_acc[p][m][c + 1] = float(residual.y);
            } }{ const int c = 6;  {
                const uint off = pc.ars_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_project_acc[p][m][c] = float(residual.x);
                nr_project_acc[p][m][c + 1] = float(residual.y);
            } } }
        } }{ const int m = 2;  {
                    coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yr;
                                                                            coopMatLoad(yr, lds_x, (uint(m * (128 / 16) + n) * 256u + (nr_opaque * ( (80u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);
            { { const int c = 0;  {
                const uint off = pc.ars_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_project_acc[p][m][c] = float(residual.x);
                nr_project_acc[p][m][c + 1] = float(residual.y);
            } }{ const int c = 2;  {
                const uint off = pc.ars_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_project_acc[p][m][c] = float(residual.x);
                nr_project_acc[p][m][c + 1] = float(residual.y);
            } }{ const int c = 4;  {
                const uint off = pc.ars_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_project_acc[p][m][c] = float(residual.x);
                nr_project_acc[p][m][c + 1] = float(residual.y);
            } }{ const int c = 6;  {
                const uint off = pc.ars_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_project_acc[p][m][c] = float(residual.x);
                nr_project_acc[p][m][c + 1] = float(residual.y);
            } } }
        } }{ const int m = 3;  {
                    coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yr;
                                                                            coopMatLoad(yr, lds_x, (uint(m * (128 / 16) + n) * 256u + (nr_opaque * ( (80u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);
            { { const int c = 0;  {
                const uint off = pc.ars_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_project_acc[p][m][c] = float(residual.x);
                nr_project_acc[p][m][c + 1] = float(residual.y);
            } }{ const int c = 2;  {
                const uint off = pc.ars_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_project_acc[p][m][c] = float(residual.x);
                nr_project_acc[p][m][c + 1] = float(residual.y);
            } }{ const int c = 4;  {
                const uint off = pc.ars_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_project_acc[p][m][c] = float(residual.x);
                nr_project_acc[p][m][c + 1] = float(residual.y);
            } }{ const int c = 6;  {
                const uint off = pc.ars_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_project_acc[p][m][c] = float(residual.x);
                nr_project_acc[p][m][c + 1] = float(residual.y);
            } } }
        } } }
    } } }
    { { const int k = 0;  {
                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > ctx[ (64 / 16)];
        { { const int m = 0; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 1; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 2; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 3; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); } }
             coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                    { const uint q = (pc.op_off) / 4u + ( (uint(nrhw_h * ( (128 / 4) / 16))) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
        { { const int m = 0;  nr_project_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_project_acc[0][m]); }{ const int m = 1;  nr_project_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_project_acc[0][m]); }{ const int m = 2;  nr_project_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_project_acc[0][m]); }{ const int m = 3;  nr_project_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_project_acc[0][m]); } }
        { { const int m = 0;  nr_project_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_project_acc[1][m]); }{ const int m = 1;  nr_project_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_project_acc[1][m]); }{ const int m = 2;  nr_project_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_project_acc[1][m]); }{ const int m = 3;  nr_project_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_project_acc[1][m]); } }
    } }{ const int k = 1;  {
                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > ctx[ (64 / 16)];
        { { const int m = 0; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 1; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 2; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 3; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); } }
             coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                    { const uint q = (pc.op_off) / 4u + ( (uint(nrhw_h * ( (128 / 4) / 16))) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
        { { const int m = 0;  nr_project_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_project_acc[0][m]); }{ const int m = 1;  nr_project_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_project_acc[0][m]); }{ const int m = 2;  nr_project_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_project_acc[0][m]); }{ const int m = 3;  nr_project_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_project_acc[0][m]); } }
        { { const int m = 0;  nr_project_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_project_acc[1][m]); }{ const int m = 1;  nr_project_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_project_acc[1][m]); }{ const int m = 2;  nr_project_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_project_acc[1][m]); }{ const int m = 3;  nr_project_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_project_acc[1][m]); } }
    } }{ const int k = 2;  {
                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > ctx[ (64 / 16)];
        { { const int m = 0; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 1; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 2; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 3; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); } }
             coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                    { const uint q = (pc.op_off) / 4u + ( (uint(nrhw_h * ( (128 / 4) / 16))) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
        { { const int m = 0;  nr_project_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_project_acc[0][m]); }{ const int m = 1;  nr_project_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_project_acc[0][m]); }{ const int m = 2;  nr_project_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_project_acc[0][m]); }{ const int m = 3;  nr_project_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_project_acc[0][m]); } }
        { { const int m = 0;  nr_project_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_project_acc[1][m]); }{ const int m = 1;  nr_project_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_project_acc[1][m]); }{ const int m = 2;  nr_project_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_project_acc[1][m]); }{ const int m = 3;  nr_project_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_project_acc[1][m]); } }
    } }{ const int k = 3;  {
                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > ctx[ (64 / 16)];
        { { const int m = 0; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 1; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 2; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 3; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); } }
             coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                    { const uint q = (pc.op_off) / 4u + ( (uint(nrhw_h * ( (128 / 4) / 16))) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
        { { const int m = 0;  nr_project_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_project_acc[0][m]); }{ const int m = 1;  nr_project_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_project_acc[0][m]); }{ const int m = 2;  nr_project_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_project_acc[0][m]); }{ const int m = 3;  nr_project_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_project_acc[0][m]); } }
        { { const int m = 0;  nr_project_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_project_acc[1][m]); }{ const int m = 1;  nr_project_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_project_acc[1][m]); }{ const int m = 2;  nr_project_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_project_acc[1][m]); }{ const int m = 3;  nr_project_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_project_acc[1][m]); } }
    } }{ const int k = 4;  {
                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > ctx[ (64 / 16)];
        { { const int m = 0; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 1; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 2; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 3; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); } }
             coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                    { const uint q = (pc.op_off) / 4u + ( (uint(nrhw_h * ( (128 / 4) / 16))) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
        { { const int m = 0;  nr_project_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_project_acc[0][m]); }{ const int m = 1;  nr_project_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_project_acc[0][m]); }{ const int m = 2;  nr_project_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_project_acc[0][m]); }{ const int m = 3;  nr_project_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_project_acc[0][m]); } }
        { { const int m = 0;  nr_project_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_project_acc[1][m]); }{ const int m = 1;  nr_project_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_project_acc[1][m]); }{ const int m = 2;  nr_project_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_project_acc[1][m]); }{ const int m = 3;  nr_project_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_project_acc[1][m]); } }
    } }{ const int k = 5;  {
                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > ctx[ (64 / 16)];
        { { const int m = 0; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 1; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 2; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 3; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); } }
             coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                    { const uint q = (pc.op_off) / 4u + ( (uint(nrhw_h * ( (128 / 4) / 16))) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
        { { const int m = 0;  nr_project_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_project_acc[0][m]); }{ const int m = 1;  nr_project_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_project_acc[0][m]); }{ const int m = 2;  nr_project_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_project_acc[0][m]); }{ const int m = 3;  nr_project_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_project_acc[0][m]); } }
        { { const int m = 0;  nr_project_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_project_acc[1][m]); }{ const int m = 1;  nr_project_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_project_acc[1][m]); }{ const int m = 2;  nr_project_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_project_acc[1][m]); }{ const int m = 3;  nr_project_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_project_acc[1][m]); } }
    } }{ const int k = 6;  {
                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > ctx[ (64 / 16)];
        { { const int m = 0; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 1; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 2; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 3; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); } }
             coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                    { const uint q = (pc.op_off) / 4u + ( (uint(nrhw_h * ( (128 / 4) / 16))) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
        { { const int m = 0;  nr_project_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_project_acc[0][m]); }{ const int m = 1;  nr_project_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_project_acc[0][m]); }{ const int m = 2;  nr_project_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_project_acc[0][m]); }{ const int m = 3;  nr_project_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_project_acc[0][m]); } }
        { { const int m = 0;  nr_project_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_project_acc[1][m]); }{ const int m = 1;  nr_project_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_project_acc[1][m]); }{ const int m = 2;  nr_project_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_project_acc[1][m]); }{ const int m = 3;  nr_project_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_project_acc[1][m]); } }
    } }{ const int k = 7;  {
                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > ctx[ (64 / 16)];
        { { const int m = 0; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 1; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 2; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 3; 
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); } }
             coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                    { const uint q = (pc.op_off) / 4u + ( (uint(nrhw_h * ( (128 / 4) / 16))) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const uvec2 nr_fv = (wexpand_u2[ (q) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf0)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf0)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } { const uvec2 nr_fv = (wexpand_u2[ ( (q) + 2u) / 2u]); const u8vec4 nr_f0 = unpack8(nr_fv.x), nr_f1 = unpack8(nr_fv.y); { { const int nr_z = 0;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 1;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 2;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } }{ const int nr_z = 3;  { (wf1)[nr_z] = uintBitsToFloate4m3EXT(nr_f0[nr_z]); (wf1)[nr_z + 4] = uintBitsToFloate4m3EXT(nr_f1[nr_z]); } } } } }
        { { const int m = 0;  nr_project_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_project_acc[0][m]); }{ const int m = 1;  nr_project_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_project_acc[0][m]); }{ const int m = 2;  nr_project_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_project_acc[0][m]); }{ const int m = 3;  nr_project_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_project_acc[0][m]); } }
        { { const int m = 0;  nr_project_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_project_acc[1][m]); }{ const int m = 1;  nr_project_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_project_acc[1][m]); }{ const int m = 2;  nr_project_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_project_acc[1][m]); }{ const int m = 3;  nr_project_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_project_acc[1][m]); } }
    } } }


    { { const int nn = 0;  {
        const int n = nrhw_h * ( (128 / 4) / 16) + nn;






                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yqr[ (64 / 16)];
        { { const int m = 0; 

                                                                   coopMatLoad(yqr[m], lds_x, (uint(m * (128 / 16) + n) * 256u + (nr_opaque * ( (80u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 1; 

                                                                   coopMatLoad(yqr[m], lds_x, (uint(m * (128 / 16) + n) * 256u + (nr_opaque * ( (80u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 2; 

                                                                   coopMatLoad(yqr[m], lds_x, (uint(m * (128 / 16) + n) * 256u + (nr_opaque * ( (80u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 3; 

                                                                   coopMatLoad(yqr[m], lds_x, (uint(m * (128 / 16) + n) * 256u + (nr_opaque * ( (80u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); } }




              coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > a[ (64 / 16)];
        { { const int m = 0;  a[m] = nr_project_acc[nn][m]; }{ const int m = 1;  a[m] = nr_project_acc[nn][m]; }{ const int m = 2;  a[m] = nr_project_acc[nn][m]; }{ const int m = 3;  a[m] = nr_project_acc[nn][m]; } }
























































        { { const int m = 0;  {




















































                       coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > of;
                 float16_t wide[8];

            float widef[8];













            { { const int c = 0;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 1;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 2;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 3;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 4;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 5;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 6;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 7;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } } }
            { { const int c = 0;  {
const fe4m3vec4 q = nr_quant_quad32(vec2(widef[c], widef[c + 1]), vec2(widef[(c + 2)], widef[(c + 2) + 1]));
of[c] = q.x;
of[c + 1] = q.y;
of[(c + 2)] = q.z;
of[(c + 2) + 1] = q.w;
} }{ const int c = 4;  {
const fe4m3vec4 q = nr_quant_quad32(vec2(widef[c], widef[c + 1]), vec2(widef[(c + 2)], widef[(c + 2) + 1]));
of[c] = q.x;
of[c + 1] = q.y;
of[(c + 2)] = q.z;
of[(c + 2) + 1] = q.w;
} } }






































































































































































































































































































            if (! nr_tile_oob( (tok0 + uint(m) * 16u) / 16u))


                                                  coopMatStore(of, act_e4m3, (pc.o_off + nr_tile_base( (tok0 + uint(m) * 16u) / 16u) + uint(n) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);






        } }{ const int m = 1;  {




















































                       coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > of;
                 float16_t wide[8];

            float widef[8];













            { { const int c = 0;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 1;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 2;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 3;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 4;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 5;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 6;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 7;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } } }
            { { const int c = 0;  {
const fe4m3vec4 q = nr_quant_quad32(vec2(widef[c], widef[c + 1]), vec2(widef[(c + 2)], widef[(c + 2) + 1]));
of[c] = q.x;
of[c + 1] = q.y;
of[(c + 2)] = q.z;
of[(c + 2) + 1] = q.w;
} }{ const int c = 4;  {
const fe4m3vec4 q = nr_quant_quad32(vec2(widef[c], widef[c + 1]), vec2(widef[(c + 2)], widef[(c + 2) + 1]));
of[c] = q.x;
of[c + 1] = q.y;
of[(c + 2)] = q.z;
of[(c + 2) + 1] = q.w;
} } }






































































































































































































































































































            if (! nr_tile_oob( (tok0 + uint(m) * 16u) / 16u))


                                                  coopMatStore(of, act_e4m3, (pc.o_off + nr_tile_base( (tok0 + uint(m) * 16u) / 16u) + uint(n) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);






        } }{ const int m = 2;  {




















































                       coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > of;
                 float16_t wide[8];

            float widef[8];













            { { const int c = 0;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 1;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 2;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 3;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 4;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 5;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 6;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 7;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } } }
            { { const int c = 0;  {
const fe4m3vec4 q = nr_quant_quad32(vec2(widef[c], widef[c + 1]), vec2(widef[(c + 2)], widef[(c + 2) + 1]));
of[c] = q.x;
of[c + 1] = q.y;
of[(c + 2)] = q.z;
of[(c + 2) + 1] = q.w;
} }{ const int c = 4;  {
const fe4m3vec4 q = nr_quant_quad32(vec2(widef[c], widef[c + 1]), vec2(widef[(c + 2)], widef[(c + 2) + 1]));
of[c] = q.x;
of[c + 1] = q.y;
of[(c + 2)] = q.z;
of[(c + 2) + 1] = q.w;
} } }






































































































































































































































































































            if (! nr_tile_oob( (tok0 + uint(m) * 16u) / 16u))


                                                  coopMatStore(of, act_e4m3, (pc.o_off + nr_tile_base( (tok0 + uint(m) * 16u) / 16u) + uint(n) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);






        } }{ const int m = 3;  {




















































                       coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > of;
                 float16_t wide[8];

            float widef[8];













            { { const int c = 0;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 1;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 2;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 3;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 4;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 5;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 6;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 7;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } } }
            { { const int c = 0;  {
const fe4m3vec4 q = nr_quant_quad32(vec2(widef[c], widef[c + 1]), vec2(widef[(c + 2)], widef[(c + 2) + 1]));
of[c] = q.x;
of[c + 1] = q.y;
of[(c + 2)] = q.z;
of[(c + 2) + 1] = q.w;
} }{ const int c = 4;  {
const fe4m3vec4 q = nr_quant_quad32(vec2(widef[c], widef[c + 1]), vec2(widef[(c + 2)], widef[(c + 2) + 1]));
of[c] = q.x;
of[c + 1] = q.y;
of[(c + 2)] = q.z;
of[(c + 2) + 1] = q.w;
} } }






































































































































































































































































































            if (! nr_tile_oob( (tok0 + uint(m) * 16u) / 16u))


                                                  coopMatStore(of, act_e4m3, (pc.o_off + nr_tile_base( (tok0 + uint(m) * 16u) / 16u) + uint(n) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);






        } } }
    } }{ const int nn = 1;  {
        const int n = nrhw_h * ( (128 / 4) / 16) + nn;






                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yqr[ (64 / 16)];
        { { const int m = 0; 

                                                                   coopMatLoad(yqr[m], lds_x, (uint(m * (128 / 16) + n) * 256u + (nr_opaque * ( (80u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 1; 

                                                                   coopMatLoad(yqr[m], lds_x, (uint(m * (128 / 16) + n) * 256u + (nr_opaque * ( (80u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 2; 

                                                                   coopMatLoad(yqr[m], lds_x, (uint(m * (128 / 16) + n) * 256u + (nr_opaque * ( (80u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); }{ const int m = 3; 

                                                                   coopMatLoad(yqr[m], lds_x, (uint(m * (128 / 16) + n) * 256u + (nr_opaque * ( (80u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor); } }




              coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > a[ (64 / 16)];
        { { const int m = 0;  a[m] = nr_project_acc[nn][m]; }{ const int m = 1;  a[m] = nr_project_acc[nn][m]; }{ const int m = 2;  a[m] = nr_project_acc[nn][m]; }{ const int m = 3;  a[m] = nr_project_acc[nn][m]; } }
























































        { { const int m = 0;  {




















































                       coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > of;
                 float16_t wide[8];

            float widef[8];













            { { const int c = 0;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 1;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 2;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 3;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 4;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 5;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 6;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 7;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } } }
            { { const int c = 0;  {
const fe4m3vec4 q = nr_quant_quad32(vec2(widef[c], widef[c + 1]), vec2(widef[(c + 2)], widef[(c + 2) + 1]));
of[c] = q.x;
of[c + 1] = q.y;
of[(c + 2)] = q.z;
of[(c + 2) + 1] = q.w;
} }{ const int c = 4;  {
const fe4m3vec4 q = nr_quant_quad32(vec2(widef[c], widef[c + 1]), vec2(widef[(c + 2)], widef[(c + 2) + 1]));
of[c] = q.x;
of[c + 1] = q.y;
of[(c + 2)] = q.z;
of[(c + 2) + 1] = q.w;
} } }






































































































































































































































































































            if (! nr_tile_oob( (tok0 + uint(m) * 16u) / 16u))


                                                  coopMatStore(of, act_e4m3, (pc.o_off + nr_tile_base( (tok0 + uint(m) * 16u) / 16u) + uint(n) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);






        } }{ const int m = 1;  {




















































                       coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > of;
                 float16_t wide[8];

            float widef[8];













            { { const int c = 0;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 1;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 2;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 3;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 4;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 5;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 6;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 7;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } } }
            { { const int c = 0;  {
const fe4m3vec4 q = nr_quant_quad32(vec2(widef[c], widef[c + 1]), vec2(widef[(c + 2)], widef[(c + 2) + 1]));
of[c] = q.x;
of[c + 1] = q.y;
of[(c + 2)] = q.z;
of[(c + 2) + 1] = q.w;
} }{ const int c = 4;  {
const fe4m3vec4 q = nr_quant_quad32(vec2(widef[c], widef[c + 1]), vec2(widef[(c + 2)], widef[(c + 2) + 1]));
of[c] = q.x;
of[c + 1] = q.y;
of[(c + 2)] = q.z;
of[(c + 2) + 1] = q.w;
} } }






































































































































































































































































































            if (! nr_tile_oob( (tok0 + uint(m) * 16u) / 16u))


                                                  coopMatStore(of, act_e4m3, (pc.o_off + nr_tile_base( (tok0 + uint(m) * 16u) / 16u) + uint(n) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);






        } }{ const int m = 2;  {




















































                       coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > of;
                 float16_t wide[8];

            float widef[8];













            { { const int c = 0;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 1;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 2;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 3;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 4;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 5;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 6;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 7;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } } }
            { { const int c = 0;  {
const fe4m3vec4 q = nr_quant_quad32(vec2(widef[c], widef[c + 1]), vec2(widef[(c + 2)], widef[(c + 2) + 1]));
of[c] = q.x;
of[c + 1] = q.y;
of[(c + 2)] = q.z;
of[(c + 2) + 1] = q.w;
} }{ const int c = 4;  {
const fe4m3vec4 q = nr_quant_quad32(vec2(widef[c], widef[c + 1]), vec2(widef[(c + 2)], widef[(c + 2) + 1]));
of[c] = q.x;
of[c + 1] = q.y;
of[(c + 2)] = q.z;
of[(c + 2) + 1] = q.w;
} } }






































































































































































































































































































            if (! nr_tile_oob( (tok0 + uint(m) * 16u) / 16u))


                                                  coopMatStore(of, act_e4m3, (pc.o_off + nr_tile_base( (tok0 + uint(m) * 16u) / 16u) + uint(n) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);






        } }{ const int m = 3;  {




















































                       coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > of;
                 float16_t wide[8];

            float widef[8];













            { { const int c = 0;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 1;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 2;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 3;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 4;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 5;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 6;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } }{ const int c = 7;  {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            } } }
            { { const int c = 0;  {
const fe4m3vec4 q = nr_quant_quad32(vec2(widef[c], widef[c + 1]), vec2(widef[(c + 2)], widef[(c + 2) + 1]));
of[c] = q.x;
of[c + 1] = q.y;
of[(c + 2)] = q.z;
of[(c + 2) + 1] = q.w;
} }{ const int c = 4;  {
const fe4m3vec4 q = nr_quant_quad32(vec2(widef[c], widef[c + 1]), vec2(widef[(c + 2)], widef[(c + 2) + 1]));
of[c] = q.x;
of[c + 1] = q.y;
of[(c + 2)] = q.z;
of[(c + 2) + 1] = q.w;
} } }






































































































































































































































































































            if (! nr_tile_oob( (tok0 + uint(m) * 16u) / 16u))


                                                  coopMatStore(of, act_e4m3, (pc.o_off + nr_tile_base( (tok0 + uint(m) * 16u) / 16u) + uint(n) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);






        } } }
    } } }










































































































#line 3322 "D:\nr-work-20261011\_mochi\DLSSNR-AMD-main\windows\shaders\rdna4\fswin_t.comp"
































































































































































































































































































































}

