#version 460
#extension GL_GOOGLE_include_directive : require
#extension GL_KHR_shader_subgroup_shuffle : require
#extension GL_EXT_shader_explicit_arithmetic_types_int8 : require























































































#extension GL_KHR_shader_subgroup_basic : require
#extension GL_KHR_shader_subgroup_ballot : require









#extension GL_KHR_shader_subgroup_ballot : require



























































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
    for (int c = 0; c < 4; ++ c) {
        part[c] = f16vec2(0.0hf);
        for (int j = 0; j < 4; ++ j) {
            f16vec2 x = probability[j][c];

            part[c] = part[c] + x;





        }
    }
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



















layout(set = 0, binding = 0, std430) coherent buffer ActE4M3 { floate4m3_t act_e4m3[]; };








layout(set = 0, binding = 0, std430) coherent buffer ActE4M3v { uint act_v4[]; };




































vec2 nr_e4f2_pick(vec4 v, int c) { return(c & 2) != 0 ? v.zw : v.xy; }


uint nr_e4m3x4_bits(fe4m3vec4 v) {
    return pack32(u8vec4(floate4m3BitsToUintEXT(v.x), floate4m3BitsToUintEXT(v.y),
                         floate4m3BitsToUintEXT(v.z), floate4m3BitsToUintEXT(v.w)));
}

layout(set = 0, binding = 0, std430) coherent buffer ActE4M3v8 { uvec2 act_v8[]; };







layout(set = 0, binding = 1, std430) coherent buffer ActF16 { float16_t act_f16[]; };
layout(set = 0, binding = 2, std430) readonly buffer WgtE4M3 { floate4m3_t wgt_e4m3[]; };
layout(set = 0, binding = 3, std430) readonly buffer WgtF32 { float wgt_f32[]; };






















layout(set = 0, binding = 2, std430) readonly buffer WgtE4M3w { uvec2 wgt_w8[]; };





layout(set = 0, binding = 4, std430) readonly buffer WgtF16 { float16_t wgt_f16[]; };






layout(set = 0, binding = 4, std430) readonly buffer WgtU32 { uint wgt_u32[]; };






















f16vec2 nr_residual_scale(uint off) {



    return f16vec2(wgt_f32[off], wgt_f32[off + 1u]);

}




layout(set = 0, binding = 4, std430) readonly buffer WExpandPair4 { fe4m3vec4 wexpand_pair4[]; };
























































































































layout(set = 0, binding = 0, std430) coherent readonly buffer BlendE4M3x4 {
    fe4m3vec4 blend_e4m3x4[];
};




layout(set = 0, binding = 0, std430) coherent readonly buffer BlendU32 { uint blend_u32[]; };
fe4m3vec4 nr_blend_x4(uint i) {
    const u8vec4 b = unpack8(blend_u32[i]);
    return fe4m3vec4(uintBitsToFloate4m3EXT(b.x), uintBitsToFloate4m3EXT(b.y),
                     uintBitsToFloate4m3EXT(b.z), uintBitsToFloate4m3EXT(b.w));
}







































































































































































































































struct FSwinParams {
    uint x_off, o_off, e_off, ct_off, qkv_off, op_off, b_off,
         rs_off, ars_off, s_off, rsd_off, ard_off, mid_off;
    uint tiles_x, tiles_y;
    int shift, shift_y;
    uint pool_off, pool_tiles_x, pool_tiles_y;








    uint blend_p_off, blend_s_off, blend_o_off, blend_g_off;
    uint blend_tiles_x, blend_tiles_y, blend_itiles_x, blend_itiles_y;
    uint blend_mode, blend_stiles_x;
    uint ups_weight_off;

};





FSwinParams pc;
layout(push_constant) uniform PushPersist {
    uint layers_off;
    uint sync_off;
    uint n_layers, spin_limit;
    uint total_windows;
    uint df_off, df_n0;

    uint ds_off;




} pcp;





layout(set = 0, binding = 5, std430) coherent buffer Sync { uint nr_sync[]; };
uint nr_wx, nr_wy;



































































uint nr_tile_base(uint q) {




    int tx = 2 * int(nr_wx) + pc.shift + int(q & 1u);
    int ty = 2 * int(nr_wy) + pc.shift_y + int(q >> 1);
    tx = clamp(tx, 0, int(pc.tiles_x) - 1); ty = clamp(ty, 0, int(pc.tiles_y) - 1);
    return(uint(ty) * pc.tiles_x + uint(tx)) * uint(128 / 16) * 256u;

}
bool nr_tile_oob(uint q) {








    int tx = 2 * int(nr_wx) + pc.shift + int(q & 1u);
    int ty = 2 * int(nr_wy) + pc.shift_y + int(q >> 1);
    return tx < 0 || ty < 0 || tx >= int(pc.tiles_x) || ty >= int(pc.tiles_y);

}








































































































































#extension GL_EXT_shared_memory_block : require
shared NrLdsYX { floate4m3_t lds_y[64 * 128]; floate4m3_t lds_x[64 * 128]; };
shared NrUpsProj { float16_t ups_projected[128 * 16]; };

shared NrUpsProjU { uint ups_u32[128 * 8]; };



















































































































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
    return(bitCount(uint(c) & uint(3)) & 1) != 0 ? nr_act_horner_b(x) : nr_act_horner(x);
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













    if ( (gl_NumWorkGroups.x == 0xffffffffu)) {
        act_e4m3[0] = act_e4m3[1];
        act_f16[0] = act_f16[1];



    }






























    const uint tid = gl_LocalInvocationID.x, wave = subgroupBroadcastFirst( (tid) / 32u), lane = tid % 32u;


    uint nr_budget = pcp.spin_limit;



    const uint nr_epoch = nr_sync[pcp.sync_off + 2u] + 1u;










    const uint nr_slot = pcp.sync_off + 4u + pcp.total_windows + gl_WorkGroupID.x;



    uint nr_layer = 0u;







    const uint nr_qbase = pcp.sync_off + 4u + pcp.total_windows + gl_NumWorkGroups.x;
    const uint nr_tail = nr_qbase + pcp.total_windows;
    const uint nr_tag = (nr_epoch & 0xFFFFu) << 16u;

































































    uint nr_held = 0xFFFFFFFFu;

    while (true) {








        if (tid == 0u) {




































































































































            const uint h = atomicAdd(nr_sync[pcp.sync_off + 0u], 1u);
            uint it = pcp.total_windows;
            if (h < pcp.df_n0) {
                it = wgt_u32[pcp.df_off + 5u * pcp.total_windows + h];
            } else if (h < pcp.total_windows) {
                const uint qa = nr_qbase + (h - pcp.df_n0);
                uint e = atomicAdd(nr_sync[qa], 0u);
                while ( (e & 0xFFFF0000u) != nr_tag) {
                    if (nr_budget == 0u) {
                        atomicMax(nr_sync[pcp.sync_off + 3u], 1u);
                        break;
                    }
                    -- nr_budget;
                    e = atomicAdd(nr_sync[qa], 0u);
                }
                if ( (e & 0xFFFF0000u) == nr_tag) it = e & 0xFFFFu;
            }
































            atomicExchange(nr_sync[nr_slot], it);
        }









        memoryBarrierBuffer();
        barrier();
        uint nr_claim = 0u;
        if (subgroupElect()) nr_claim = atomicAdd(nr_sync[nr_slot], 0u);







        const uint nr_item = subgroupBroadcastFirst(nr_claim);
        barrier();
        if (nr_item >= pcp.total_windows) break;



        nr_layer = 0u;

        while (nr_layer + 1u < pcp.n_layers &&
               wgt_u32[pcp.layers_off + (nr_layer + 1u) * 24u + 23u]
                   <= nr_item)
            ++ nr_layer;
        const uint pb = pcp.layers_off + nr_layer * 24u;
        pc.x_off = wgt_u32[pb + 0u]; pc.o_off = wgt_u32[pb + 1u];
        pc.e_off = wgt_u32[pb + 2u]; pc.ct_off = wgt_u32[pb + 3u];
        pc.qkv_off = wgt_u32[pb + 4u]; pc.op_off = wgt_u32[pb + 5u];
        pc.b_off = wgt_u32[pb + 6u]; pc.rs_off = wgt_u32[pb + 7u];
        pc.ars_off = wgt_u32[pb + 8u]; pc.s_off = wgt_u32[pb + 9u];
        pc.rsd_off = wgt_u32[pb + 10u]; pc.ard_off = wgt_u32[pb + 11u];
        pc.mid_off = wgt_u32[pb + 12u];
        pc.tiles_x = wgt_u32[pb + 13u]; pc.tiles_y = wgt_u32[pb + 14u];
        pc.shift = int(wgt_u32[pb + 15u]); pc.shift_y = int(wgt_u32[pb + 16u]);
        pc.pool_off = wgt_u32[pb + 17u];
        pc.pool_tiles_x = wgt_u32[pb + 18u]; pc.pool_tiles_y = wgt_u32[pb + 19u];
        const uint nr_gx = wgt_u32[pb + 20u];
        const uint nr_flag = pcp.sync_off + 4u + wgt_u32[pb + 23u];
        const uint nr_w = nr_item - wgt_u32[pb + 23u];
        nr_wx = nr_w % nr_gx;
        nr_wy = nr_w / nr_gx;












        const bool nr_ups_layer = pcp.ds_off != 0u && nr_layer == 0u;
        if (nr_ups_layer) {
            pc.blend_p_off = wgt_u32[pcp.ds_off + 0u]; pc.blend_s_off = wgt_u32[pcp.ds_off + 1u];
            pc.blend_o_off = wgt_u32[pcp.ds_off + 2u]; pc.blend_g_off = wgt_u32[pcp.ds_off + 3u];
            pc.blend_tiles_x = wgt_u32[pcp.ds_off + 4u]; pc.blend_tiles_y = wgt_u32[pcp.ds_off + 5u];
            pc.blend_itiles_x = wgt_u32[pcp.ds_off + 6u]; pc.blend_itiles_y = wgt_u32[pcp.ds_off + 7u];
            pc.blend_mode = wgt_u32[pcp.ds_off + 8u]; pc.blend_stiles_x = wgt_u32[pcp.ds_off + 9u];
            pc.ups_weight_off = wgt_u32[pcp.ds_off + 10u];
        }




































        if (1 == 0 && nr_layer > 0u) {





            if (tid < 4u) {
                const int tx = 2 * int(nr_wx) + pc.shift + int(tid & 1u);
                const int ty = 2 * int(nr_wy) + pc.shift_y + int(tid >> 1u);
                if (tx >= 0 && ty >= 0 && tx < int(pc.tiles_x) && ty < int(pc.tiles_y)) {
                    const uint qb = pb - 24u;
                    const int ax = tx - int(wgt_u32[qb + 15u]);
                    const int ay = ty - int(wgt_u32[qb + 16u]);


                    const int px = ax >= 0 ? ax / 2 : - ( (1 - ax) / 2);
                    const int py = ay >= 0 ? ay / 2 : - ( (1 - ay) / 2);
                    if (px >= 0 && py >= 0 && px < int(wgt_u32[qb + 20u])
                                           && py < int(wgt_u32[qb + 21u])) {
                        const uint idx = pcp.sync_off + 4u + wgt_u32[qb + 23u]
                                       + uint(py) * wgt_u32[qb + 20u] + uint(px);

                        while (atomicAdd(nr_sync[idx], 0u) != nr_epoch) {
                            if (nr_budget == 0u) {
                                atomicMax(nr_sync[pcp.sync_off + 3u], 1u + nr_layer);
                                break;
                            }
                            -- nr_budget;
                        }
                    }
                }
            }






            barrier();

        }




































    {
    uint nr_live = 0u;
    for (uint q = 0u; q < 4u; ++ q) if (! nr_tile_oob(q)) nr_live |= 1u << q;
    const uint nr_body = nr_live == 15u ? 15u
        : ( (nr_live & 3u) == 0u ? 12u : (nr_live & 12u) == 0u ? 3u
        : (nr_live & 5u) == 0u ? 10u : (nr_live & 10u) == 0u ? 5u : 15u);






































    [[dont_flatten]] if (nr_body == 15u) {

#line 1 "D:/nr-work-20261011/_mochi/DLSSNR-AMD-main/windows/shaders/rdna4/include/fswin_body.glsl"





    const uint wbase = nr_wx * uint(64 * 128);

    const uint tok0 = 0u;
    const int nrhw_h = int(wave);









    const uint nr_opaque = gl_WorkGroupID.z;








    const uint rbase = 8u * (lane / 16u);































































    [[dont_flatten]] if (nr_ups_layer) {






            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > upsrc[2 * (128 / 16)];
    const uint ups_slot = lane % 16u;
    const uint ups_px = uint(clamp(4 * int(nr_wx) + 2 * pc.shift + int(ups_slot % 4u), 0, int(pc.blend_itiles_x * 4u) - 1));
    const uint ups_py = uint(clamp(4 * int(nr_wy) + 2 * pc.shift_y + int(ups_slot / 4u), 0, int(pc.blend_itiles_y * 4u) - 1));
    const uint ups_tile = (ups_py / 4u) * pc.blend_itiles_x + ups_px / 4u;
    const uint ups_in_slot = (ups_py % 4u) * 4u + ups_px % 4u;
























    for (int k = 0; k < 2 * (128 / 16); ++ k)
        for (int j = 0; j < 8; ++ j)






















            upsrc[k][j] = uintBitsToFloate4m3EXT(unpack8(act_v4[ (pc.blend_p_off + (ups_tile * uint(2 * (128 / 16)) + uint(k)) * 256u + ups_in_slot * 16u + rbase) / 4u + uint(j) / 4u])[ (j) % 4]);

    for (int n = 0; n < ( (128 / 4) / 16); ++ n) {
        const uint nf = uint(nrhw_h * ( (128 / 4) / 16) + n);
                  coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > acc = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0);
        for (int k = 0; k < 2 * (128 / 16); ++ k) {
                    coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > w;
                                                                                      coopMatLoad(w, wgt_e4m3, (pc.ups_weight_off + (nf * uint(2 * (128 / 16)) + uint(k)) * 256u), (16u), gl_CooperativeMatrixLayoutRowMajor);
                                 acc = coopMatMulAdd(w, upsrc[k], acc);
        }
                    coopmat < float16_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > half_result;
        for (int j = 0; j < 8; ++ j) half_result[j] = float16_t(acc[j]);
                                        coopMatStore(half_result, ups_projected, (nf * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);
    }

    barrier();

    }










    uint tbase[ (64 / 16)];
    for (int m = 0; m < (64 / 16); ++ m)

        tbase[m] = pc.x_off + nr_tile_base( (tok0 + uint(m) * 16u) / 16u);































    [[dont_flatten]] if (! nr_ups_layer) {
        for (int m = 0; m < (64 / 16); ++ m)
            for (int d = 0; d < ( (128 / 4) / 16); ++ d) {
                const uint k = uint(nrhw_h * ( (128 / 4) / 16) + d);
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > src;
                                                           do { const uint nr_la = ( (tbase[m] + k * 256u) + (gl_SubgroupInvocationID % 16u) * (16u) + (gl_SubgroupInvocationID / 16u) * 8u) / 4u; const u8vec4 nr_b0 = unpack8(act_v4[nr_la]), nr_b1 = unpack8(act_v4[nr_la + 1u]); for (int nr_i = 0; nr_i < 4; ++ nr_i) { src[nr_i] = uintBitsToFloate4m3EXT(nr_b0[nr_i]); src[nr_i + 4] = uintBitsToFloate4m3EXT(nr_b1[nr_i]); } } while (false);
                           coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > dst;
                for (int j = 0; j < 8; ++ j) dst[j] = src[j];
                if (nr_tile_oob(uint(m)))
                    for (int j = 0; j < 8; ++ j) dst[j] = floate4m3_t(0.0);
                                                                                            coopMatStore(dst, lds_x, ( (uint(m) * uint( (128 / 16)) + k) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);
            }
    } else

    for (int m = 0; m < (64 / 16); ++ m)
        for (int d = 0; d < ( (128 / 4) / 16); ++ d) {
            const uint k = uint(nrhw_h * ( (128 / 4) / 16) + d);
                    coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > src;

            const uint q = uint(m);
            const uint tx = uint(clamp(2 * int(nr_wx) + pc.shift + int(q & 1u), 0, int(pc.tiles_x) - 1));
            const uint ty = uint(clamp(2 * int(nr_wy) + pc.shift_y + int(q >> 1u), 0, int(pc.tiles_y) - 1));
            const uint slot = lane % 16u, dx = slot % 4u, dy = slot / 4u;
            const uint ipx = min( (4u * tx + dx) / 2u, pc.blend_itiles_x * 4u - 1u);
            const uint ipy = min( (4u * ty + dy) / 2u, pc.blend_itiles_y * 4u - 1u);
            const uint itile = (ipy / 4u) * pc.blend_itiles_x + ipx / 4u;
            const uint islot = (ipy % 4u) * 4u + ipx % 4u;
            const uint stw = pc.blend_stiles_x != 0u ? pc.blend_stiles_x : pc.blend_tiles_x;
            const uint stile = ty * stw + tx;




            {
                const uint saddr = pc.blend_s_off + (stile * uint( (128 / 16)) + k) * 256u + slot * 16u + rbase;
                const fe4m3vec4 sv4[2] = { nr_blend_x4(saddr / 4u), nr_blend_x4(saddr / 4u + 1u) };
                const uint local_slot = ( (q >> 1u) * 2u + dy / 2u) * 4u + (q & 1u) * 2u + dx / 2u;
                for (int j = 0; j < 8; j += 2) {
                    const uint ch = k * 16u + rbase + uint(j);
                    const uint pb = k * 256u + local_slot * 16u + rbase + uint(j);
                    const f16vec2 pv2 = unpackFloat2x16(ups_u32[ (pb) >> 1u]);
                    const f16vec2 sv2 = unpackFloat2x16(packHalf2x16(nr_e4f2_pick(vec4(sv4[j / 4]), j % 4)));

                    const f16vec2 g2 = unpackFloat2x16(wgt_u32[ (pc.blend_g_off + ch) >> 1u]);



                    const fe4m3vec2 qv = nr_quant_pair(fma(sv2, g2, pv2));
                    src[j] = qv.x; src[j + 1] = qv.y;
                }
            }
            if (false)

            {
                 float16_t blend_h[8];
            for (int j = 0; j < 8; ++ j) {
                const uint ch = k * 16u + rbase + uint(j);

                const uint local_slot = ( (q >> 1u) * 2u + dy / 2u) * 4u + (q & 1u) * 2u + dx / 2u;
                     float16_t pv = unpackFloat2x16(ups_u32[ (k * 256u + local_slot * 16u + rbase + uint(j)) >> 1u])[ (k * 256u + local_slot * 16u + rbase + uint(j)) & 1u];



                     float16_t sv = float16_t(uintBitsToFloate4m3EXT(unpack8(act_v4[ (pc.blend_s_off + (stile * uint( (128 / 16)) + k) * 256u + slot * 16u + rbase) / 4u + uint(j) / 4u])[ (j) % 4]));
                     float16_t sp = float16_t(sv * wgt_f16[pc.blend_g_off + ch]);

                blend_h[j] = float16_t(pv + sp);
            }

            for (int j = 0; j < 8; j += 4) {
                const fe4m3vec4 q4 = nr_quant4_h(f16vec4(blend_h[j], blend_h[j + 1], blend_h[j + 2], blend_h[j + 3]));
                src[j] = q4.x; src[j + 1] = q4.y; src[j + 2] = q4.z; src[j + 3] = q4.w;
            }
            }



                       coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > dst;
            for (int j = 0; j < 8; ++ j) dst[j] = src[j];


            if (nr_tile_oob(uint(m)))
                for (int j = 0; j < 8; ++ j) dst[j] = floate4m3_t(0.0);

                                                                                        coopMatStore(dst, lds_x, ( (uint(m) * uint( (128 / 16)) + k) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);
        }
    barrier();
































































































































































































    {
        const int g = nrhw_h;




                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > eqg[ (64 / 16)][ ( ( (4 * 128) / 4) / 16)];













































































































        for (int h = 0; h < ( ( (4 * 128) / 4) / 16); h += 2) {
                  coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > a[2][ (64 / 16)];
            for (int p = 0; p < 2; ++ p)
                for (int m = 0; m < (64 / 16); ++ m) a[p][m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0);
            for (int k = 0; k < (128 / 16); ++ k) {
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > xbk[ (64 / 16)];
                for (int m = 0; m < (64 / 16); ++ m)

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);




                for (int p = 0; p < 2; p += 2) {
                    const uint q = pc.e_off / 4u + uint( (g * ( ( (4 * 128) / 4) / 16) + h + p) / 2) * uint( (128 / 16)) * 128u
                        + uint(k) * 128u + lane * 4u;
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                    { { const fe4m3vec4 w0 = wexpand_pair4[q], w1 = wexpand_pair4[ (q) + 1u]; const fe4m3vec4 w2 = wexpand_pair4[ (q) + 2u], w3 = wexpand_pair4[ (q) + 3u]; for (int v = 0; v < 4; ++ v) { wf0[v] = w0[v]; wf0[v + 4] = w1[v]; wf1[v] = w2[v]; wf1[v + 4] = w3[v]; } } }
                    for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (15) >> (m)) & 1) != 0) a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]);
                    for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (15) >> (m)) & 1) != 0) a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]);
                }









                if (0 > 0 && (k + 1) % 0 == 0)
                    for (int p = 0; p < 2; ++ p)
                        for (int m = 0; m < (64 / 16); ++ m) { }
            }
            for (int p = 0; p < 2; ++ p)
            for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (15) >> (m)) & 1) != 0)






                for (int c = 0; c < 8; c += 2) {
                    const fe4m3vec2 qp = nr_quant_pair32(vec2(
                                             nr_act_pick(a[p][m][c], c), nr_act_pick(a[p][m][c + 1], c + 1)));
                    eqg[m][h + p][c] = qp.x;
                    eqg[m][h + p][c + 1] = qp.y;
                }































        }





































































              coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > nr_mid_acc[ ( (128 / 4) / 16)][ (64 / 16)];
        for (int n = 0; n < ( (128 / 4) / 16); ++ n) for (int m = 0; m < (64 / 16); ++ m) nr_mid_acc[n][m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0);
        for (int k = 0; k < ( ( (4 * 128) / 4) / 16); ++ k) {
                 coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                    { const uint q = (pc.mid_off) / 4u + ( (uint(g * ( (128 / 4) / 16))) / 2u) * (uint( ( ( (4 * 128) / 4) / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const fe4m3vec4 w0 = wexpand_pair4[q], w1 = wexpand_pair4[ (q) + 1u]; const fe4m3vec4 w2 = wexpand_pair4[ (q) + 2u], w3 = wexpand_pair4[ (q) + 3u]; for (int v = 0; v < 4; ++ v) { wf0[v] = w0[v]; wf0[v + 4] = w1[v]; wf1[v] = w2[v]; wf1[v + 4] = w3[v]; } } }
            for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (15) >> (m)) & 1) != 0) nr_mid_acc[0][m] = coopMatMulAdd(wf0, eqg[m][k], nr_mid_acc[0][m]);
            for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (15) >> (m)) & 1) != 0) nr_mid_acc[1][m] = coopMatMulAdd(wf1, eqg[m][k], nr_mid_acc[1][m]);
        }




        for (int n = 0; n < ( (128 / 4) / 16); ++ n) {
            const int nf = g * ( (128 / 4) / 16) + n;

                       coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > mqf[ (64 / 16)];





                  coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > a[ (64 / 16)];
            for (int m = 0; m < (64 / 16); ++ m) a[m] = nr_mid_acc[n][m];













            for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (15) >> (m)) & 1) != 0)







                for (int c = 0; c < 8; c += 2) {
                    fe4m3vec2 qp = nr_quant_pair(f16vec2(
                             float16_t(a[m][c]),
                             float16_t(a[m][c + 1])));
                               mqf[m][c] = qp.x;
                               mqf[m][c + 1] = qp.y;
                }




            for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (15) >> (m)) & 1) != 0)
                                                                                        coopMatStore(mqf[m], lds_y, (uint(m * (128 / 16) + nf) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);

        }
    }

    barrier();


















































































































































































          coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > nr_contract_acc[ ( (128 / 4) / 16)][ (64 / 16)];
    for (int p = 0; p < ( (128 / 4) / 16); ++ p) {
        const int n = nrhw_h * ( (128 / 4) / 16) + p;
        for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (15) >> (m)) & 1) != 0) {
                    coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yr;
                                                                            coopMatLoad(yr, lds_x, (uint(m * (128 / 16) + n) * 256u + (nr_opaque * ( (80u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);
            for (int c = 0; c < 8; c += 2) {
                const uint off = pc.rs_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_contract_acc[p][m][c] = float(residual.x);
                nr_contract_acc[p][m][c + 1] = float(residual.y);
            }
        }
    }
    for (int k = 0; k < (128 / 16); ++ k) {
                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > ctx[ (64 / 16)];
        for (int m = 0; m < (64 / 16); ++ m)
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);
             coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                    { const uint q = (pc.ct_off) / 4u + ( (uint(nrhw_h * ( (128 / 4) / 16))) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const fe4m3vec4 w0 = wexpand_pair4[q], w1 = wexpand_pair4[ (q) + 1u]; const fe4m3vec4 w2 = wexpand_pair4[ (q) + 2u], w3 = wexpand_pair4[ (q) + 3u]; for (int v = 0; v < 4; ++ v) { wf0[v] = w0[v]; wf0[v + 4] = w1[v]; wf1[v] = w2[v]; wf1[v + 4] = w3[v]; } } }
        for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (15) >> (m)) & 1) != 0) nr_contract_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_contract_acc[0][m]);
        for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (15) >> (m)) & 1) != 0) nr_contract_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_contract_acc[1][m]);
    }


    for (int nn = 0; nn < ( (128 / 4) / 16); ++ nn) {
        const int n = nrhw_h * ( (128 / 4) / 16) + nn;


                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > xbk[ (64 / 16)];
        for (int m = 0; m < (64 / 16); ++ m)

                                                                   coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + n) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);



                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yqw[ (64 / 16)];







              coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > a[ (64 / 16)];
        for (int m = 0; m < (64 / 16); ++ m) a[m] = nr_contract_acc[nn][m];







































































        for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (15) >> (m)) & 1) != 0) {

            float requantized[8];






















            for (int c = 0; c < 8; ++ c) {

                const float v = a[m][c];












                requantized[c] = v;










            }


            for (int c = 0; c < 8; c += 2) {

                         fe4m3vec2 q = nr_quant_pair32(vec2(requantized[c], requantized[c + 1]));



                          yqw[m][c] = q.x; yqw[m][c + 1] = q.y;



            }
        }





        for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (15) >> (m)) & 1) != 0) {
                       coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > yf;
            for (int c = 0; c < 8; ++ c) yf[c] = yqw[m][c];
                                                                               coopMatStore(yf, lds_x, (uint(m * (128 / 16) + n) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);
        }

    }

    barrier();































    {
        const int hh = nrhw_h;





                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > kreg[ (64 / 16)][ ( (128 / 4) / 16)];




        const float16_t hscale = float16_t(wgt_f32[pc.s_off + uint(hh)]);
                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > qb[ (64 / 16)][ ( (128 / 4) / 16)];
























        {










                  coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > acc[ (64 / 16)][ ( (1 + 1) * ( (128 / 4) / 16))];

            for (int m = 0; m < (64 / 16); ++ m)
                for (int d = 0; d < ( (1 + 1) * ( (128 / 4) / 16)); ++ d) acc[m][d] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0);
            for (int k = 0; k < (128 / 16); ++ k) {
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yk[ (64 / 16)];
                for (int m = 0; m < (64 / 16); ++ m)

                                                                            coopMatLoad(yk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (128u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);




                for (int r = 0; r < ( (1 + 1) * ( (128 / 4) / 16)); r += 2) {
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                                  { const uint q = (pc.qkv_off) / 4u + ( (uint(hh * 3 * ( (128 / 4) / 16) + 0 + r)) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const fe4m3vec4 w0 = wexpand_pair4[q], w1 = wexpand_pair4[ (q) + 1u]; const fe4m3vec4 w2 = wexpand_pair4[ (q) + 2u], w3 = wexpand_pair4[ (q) + 3u]; for (int v = 0; v < 4; ++ v) { wf0[v] = w0[v]; wf0[v + 4] = w1[v]; wf1[v] = w2[v]; wf1[v + 4] = w3[v]; } } }
                    for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (15) >> (m)) & 1) != 0) acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]);
                    for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (15) >> (m)) & 1) != 0) acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]);
                }







                if (0 > 0 && (k + 1) % 0 == 0)
                    for (int m = 0; m < (64 / 16); ++ m)
                        for (int r = 0; r < ( (1 + 1) * ( (128 / 4) / 16)); ++ r) { }

            }
            for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (15) >> (m)) & 1) != 0) {

                float sqp[4];
                for (int i = 0; i < 4; ++ i) sqp[i] = 0.0;
                for (int c = 0; c < 8; ++ c)
                    for (int d = 0; d < ( (128 / 4) / 16); ++ d) {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    }








                f16vec2 sq = f16vec2(vec2( (sqp[0] + sqp[1]) + (sqp[2] + sqp[3]), 0.0));
                sq = sq + unpackFloat2x16(subgroupShuffleXor(packFloat2x16(sq), 16u));
                const float16_t nq =
                                    float16_t(inversesqrt(float(max( (sq.x), float16_t(0.000062)))));





































                for (int d = 0; d < ( (128 / 4) / 16); ++ d)
                    for (int c = 0; c < 8; c += 2) {

                        fe4m3vec2 qp = nr_qscale_fast(vec2(acc[m][d][c], acc[m][d][c + 1]), nq, hscale);





                        qb[m][d][c] = qp.x;
                        qb[m][d][c + 1] = qp.y;
                    }
            }






















            for (int m = 0; m < (64 / 16); ++ m) {

                float skp[4];
                for (int i = 0; i < 4; ++ i) skp[i] = 0.0;
                for (int c = 0; c < 8; ++ c)
                    for (int d = 0; d < ( (128 / 4) / 16); ++ d) {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    }





                f16vec2 sk = f16vec2(vec2( (skp[0] + skp[1]) + (skp[2] + skp[3]), 0.0));
                sk = sk + unpackFloat2x16(subgroupShuffleXor(packFloat2x16(sk), 16u));
                const float16_t nk =
                                    float16_t(inversesqrt(float(max( (sk.x), float16_t(0.000062)))));























                for (int d = 0; d < ( (128 / 4) / 16); ++ d) {
                               coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > kf;
                    for (int c = 0; c < 8; c += 2) {

                        fe4m3vec2 qp = nr_kscale_fast(vec2(acc[m][d + 1 * ( (128 / 4) / 16)][c],
                            acc[m][d + 1 * ( (128 / 4) / 16)][c + 1]), nk);





                        kf[c] = qp.x;
                        kf[c + 1] = qp.y;
                    }


                    for (int c = 0; c < 8; ++ c) kreg[m][d][c] = kf[c];
                }
            }
































            for (int m = 0; m < (64 / 16); ++ m)
                for (int d = 0; d < ( (128 / 4) / 16); ++ d) acc[m][d] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0);
            for (int k = 0; k < (128 / 16); ++ k) {



















                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yk[ (64 / 16)];
                for (int m = 0; m < (64 / 16); ++ m)

                                                                            coopMatLoad(yk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (130u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);




                for (int r = 0; r < ( (128 / 4) / 16); r += 2) {
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                                         { const uint q = (pc.qkv_off) / 4u + ( (uint(hh * 3 * ( (128 / 4) / 16) + 2 * ( (128 / 4) / 16) + r)) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const fe4m3vec4 w0 = wexpand_pair4[q], w1 = wexpand_pair4[ (q) + 1u]; const fe4m3vec4 w2 = wexpand_pair4[ (q) + 2u], w3 = wexpand_pair4[ (q) + 3u]; for (int v = 0; v < 4; ++ v) { wf0[v] = w0[v]; wf0[v + 4] = w1[v]; wf1[v] = w2[v]; wf1[v + 4] = w3[v]; } } }
                    for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (15) >> (m)) & 1) != 0) acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]);
                    for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (15) >> (m)) & 1) != 0) acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]);
                }











                if (0 > 0 && (k + 1) % 0 == 0)
                    for (int m = 0; m < (64 / 16); ++ m)
                        for (int r = 0; r < ( (128 / 4) / 16); ++ r) { }

            }











            for (int m = 0; m < (64 / 16); ++ m)
                for (int d = 0; d < ( (128 / 4) / 16); ++ d) {
                               coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > vf;
                    for (int c = 0; c < 8; c += 2) {
                        fe4m3vec2 qp = nr_quant_pair(

                                            f16vec2(float16_t(acc[m][d][c]), float16_t(acc[m][d][c + 1])));
                        vf[c] = qp.x;
                        vf[c + 1] = qp.y;
                    }





                                                                                 coopMatStore(vf, lds_y, (uint(m * (128 / 16) + hh * ( (128 / 4) / 16) + d) * 256u), (16u), gl_CooperativeMatrixLayoutRowMajor);
                }


        }













































































































































































































































































































             coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > pb[ (64 / 16)][ (64 / 16)];
        for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (15) >> (m)) & 1) != 0) {
            f16vec2 pq2[ (64 / 16)][4];
                  coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > lg[ (64 / 16)];



            for (int j = 0; j < (64 / 16); ++ j) lg[j] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0);


            for (int d = 0; d < ( (128 / 4) / 16); ++ d)
                for (int j = 0; j < (64 / 16); ++ j) {
                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > kf = kreg[j][d];
                                              lg[j] = coopMatMulAdd(kf, qb[m][d], lg[j]);
                }
            for (int j = 0; j < (64 / 16); ++ j) {
















                          coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > bf;



                                            coopMatLoad(bf, wgt_f32, (pc.b_off + uint(hh) * uint(64 * 64) + (tok0 + uint(m) * 16u) * uint(64) + uint(j) * 16u), (uint(64)), gl_CooperativeMatrixLayoutColumnMajor);


                for (int c = 0; c < 8; c += 2)
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1]));



            }
                 float16_t sum = nr_swin_probability_sum(pq2);


            float inv = float(float16_t(1.0 / float(max(sum, float16_t(6.103515625e-05)))));
            for (int j = 0; j < (64 / 16); ++ j)
                for (int c = 0; c < 4; ++ c) {
                    float x = float(pq2[j][c].x) * inv;
                    float y = float(pq2[j][c].y) * inv;










                    fe4m3vec2 q = fe4m3vec2(pq2[j][c] * f16vec2(float16_t(inv)));





                    pb[m][j][2 * c] = q.x;
                    pb[m][j][2 * c + 1] = q.y;
                }
        }
























































































































































































        for (int e = 0; e < ( (128 / 4) / 16); ++ e) {
                  coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > a[ (64 / 16)];
            for (int m = 0; m < (64 / 16); ++ m) a[m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0);
            for (int j = 0; j < (64 / 16); ++ j) {
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > vf;





                                                 coopMatLoad(vf, lds_y, (uint(j * (128 / 16) + hh * ( (128 / 4) / 16) + e) * 256u + (nr_opaque * ( (192u) * 16u))), (16u), gl_CooperativeMatrixLayoutRowMajor);




                for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (15) >> (m)) & 1) != 0) a[m] = coopMatMulAdd(vf, pb[m][j], a[m]);
                if (0 > 0 && (j + 1) % 0 == 0)
                    for (int m = 0; m < (64 / 16); ++ m) { }
            }
            for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (15) >> (m)) & 1) != 0) {

                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > out_context;





                for (int c = 0; c < 8; c += 2) {
                             fe4m3vec2 qp = nr_quant_pair(f16vec2(float16_t(a[m][c]), float16_t(a[m][c + 1])));
                    out_context[c] = qp.x;
                    out_context[c + 1] = qp.y;
                }








                                                                             coopMatStore(out_context, lds_y, (uint(m * (128 / 16) + hh * ( (128 / 4) / 16) + e) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);




















            }
        }


        barrier();

    }













































































          coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > nr_project_acc[ ( (128 / 4) / 16)][ (64 / 16)];
    for (int p = 0; p < ( (128 / 4) / 16); ++ p) {
        const int n = nrhw_h * ( (128 / 4) / 16) + p;
        for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (15) >> (m)) & 1) != 0) {
                    coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yr;
                                                                            coopMatLoad(yr, lds_x, (uint(m * (128 / 16) + n) * 256u + (nr_opaque * ( (80u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);
            for (int c = 0; c < 8; c += 2) {
                const uint off = pc.ars_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_project_acc[p][m][c] = float(residual.x);
                nr_project_acc[p][m][c + 1] = float(residual.y);
            }
        }
    }
    for (int k = 0; k < (128 / 16); ++ k) {
                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > ctx[ (64 / 16)];
        for (int m = 0; m < (64 / 16); ++ m)
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);
             coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                    { const uint q = (pc.op_off) / 4u + ( (uint(nrhw_h * ( (128 / 4) / 16))) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const fe4m3vec4 w0 = wexpand_pair4[q], w1 = wexpand_pair4[ (q) + 1u]; const fe4m3vec4 w2 = wexpand_pair4[ (q) + 2u], w3 = wexpand_pair4[ (q) + 3u]; for (int v = 0; v < 4; ++ v) { wf0[v] = w0[v]; wf0[v + 4] = w1[v]; wf1[v] = w2[v]; wf1[v + 4] = w3[v]; } } }
        for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (15) >> (m)) & 1) != 0) nr_project_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_project_acc[0][m]);
        for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (15) >> (m)) & 1) != 0) nr_project_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_project_acc[1][m]);
    }


    for (int nn = 0; nn < ( (128 / 4) / 16); ++ nn) {
        const int n = nrhw_h * ( (128 / 4) / 16) + nn;






                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yqr[ (64 / 16)];
        for (int m = 0; m < (64 / 16); ++ m)

                                                                   coopMatLoad(yqr[m], lds_x, (uint(m * (128 / 16) + n) * 256u + (nr_opaque * ( (80u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);




              coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > a[ (64 / 16)];
        for (int m = 0; m < (64 / 16); ++ m) a[m] = nr_project_acc[nn][m];
























































        for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (15) >> (m)) & 1) != 0) {




















































                       coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > of;
                 float16_t wide[8];

            float widef[8];













            for (int c = 0; c < 8; ++ c) {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            }
            for (int c = 0; c < 8; c += 2) {

                fe4m3vec2 q = nr_quant_pair32(vec2(widef[c], widef[c + 1]));



                of[c] = q.x; of[c + 1] = q.y;



            }






































































































































































































































































































            if (! nr_tile_oob( (tok0 + uint(m) * 16u) / 16u))


                                                  do { const uint nr_sa = ( (pc.o_off + nr_tile_base( (tok0 + uint(m) * 16u) / 16u) + uint(n) * 256u) + (gl_SubgroupInvocationID % 16u) * (16u) + (gl_SubgroupInvocationID / 16u) * 8u) / 8u; act_v8[nr_sa] = uvec2(nr_e4m3x4_bits(fe4m3vec4(of[0], of[1], of[2], of[3])), nr_e4m3x4_bits(fe4m3vec4(of[4], of[5], of[6], of[7]))); } while (false);






        }
    }










































































































#line 3270 "D:\nr-work-20261011\_mochi\DLSSNR-AMD-main\windows\shaders\rdna4\fswin_t.comp"

    }
    [[dont_flatten]] if (nr_body != 15u) {

    [[dont_flatten]] if (nr_body == 12u) {

#line 1 "D:/nr-work-20261011/_mochi/DLSSNR-AMD-main/windows/shaders/rdna4/include/fswin_body.glsl"





    const uint wbase = nr_wx * uint(64 * 128);

    const uint tok0 = 0u;
    const int nrhw_h = int(wave);









    const uint nr_opaque = gl_WorkGroupID.z;








    const uint rbase = 8u * (lane / 16u);































































    [[dont_flatten]] if (nr_ups_layer) {






            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > upsrc[2 * (128 / 16)];
    const uint ups_slot = lane % 16u;
    const uint ups_px = uint(clamp(4 * int(nr_wx) + 2 * pc.shift + int(ups_slot % 4u), 0, int(pc.blend_itiles_x * 4u) - 1));
    const uint ups_py = uint(clamp(4 * int(nr_wy) + 2 * pc.shift_y + int(ups_slot / 4u), 0, int(pc.blend_itiles_y * 4u) - 1));
    const uint ups_tile = (ups_py / 4u) * pc.blend_itiles_x + ups_px / 4u;
    const uint ups_in_slot = (ups_py % 4u) * 4u + ups_px % 4u;
























    for (int k = 0; k < 2 * (128 / 16); ++ k)
        for (int j = 0; j < 8; ++ j)






















            upsrc[k][j] = uintBitsToFloate4m3EXT(unpack8(act_v4[ (pc.blend_p_off + (ups_tile * uint(2 * (128 / 16)) + uint(k)) * 256u + ups_in_slot * 16u + rbase) / 4u + uint(j) / 4u])[ (j) % 4]);

    for (int n = 0; n < ( (128 / 4) / 16); ++ n) {
        const uint nf = uint(nrhw_h * ( (128 / 4) / 16) + n);
                  coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > acc = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0);
        for (int k = 0; k < 2 * (128 / 16); ++ k) {
                    coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > w;
                                                                                      coopMatLoad(w, wgt_e4m3, (pc.ups_weight_off + (nf * uint(2 * (128 / 16)) + uint(k)) * 256u), (16u), gl_CooperativeMatrixLayoutRowMajor);
                                 acc = coopMatMulAdd(w, upsrc[k], acc);
        }
                    coopmat < float16_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > half_result;
        for (int j = 0; j < 8; ++ j) half_result[j] = float16_t(acc[j]);
                                        coopMatStore(half_result, ups_projected, (nf * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);
    }

    barrier();

    }










    uint tbase[ (64 / 16)];
    for (int m = 0; m < (64 / 16); ++ m)

        tbase[m] = pc.x_off + nr_tile_base( (tok0 + uint(m) * 16u) / 16u);































    [[dont_flatten]] if (! nr_ups_layer) {
        for (int m = 0; m < (64 / 16); ++ m)
            for (int d = 0; d < ( (128 / 4) / 16); ++ d) {
                const uint k = uint(nrhw_h * ( (128 / 4) / 16) + d);
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > src;
                                                           do { const uint nr_la = ( (tbase[m] + k * 256u) + (gl_SubgroupInvocationID % 16u) * (16u) + (gl_SubgroupInvocationID / 16u) * 8u) / 4u; const u8vec4 nr_b0 = unpack8(act_v4[nr_la]), nr_b1 = unpack8(act_v4[nr_la + 1u]); for (int nr_i = 0; nr_i < 4; ++ nr_i) { src[nr_i] = uintBitsToFloate4m3EXT(nr_b0[nr_i]); src[nr_i + 4] = uintBitsToFloate4m3EXT(nr_b1[nr_i]); } } while (false);
                           coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > dst;
                for (int j = 0; j < 8; ++ j) dst[j] = src[j];
                if (nr_tile_oob(uint(m)))
                    for (int j = 0; j < 8; ++ j) dst[j] = floate4m3_t(0.0);
                                                                                            coopMatStore(dst, lds_x, ( (uint(m) * uint( (128 / 16)) + k) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);
            }
    } else

    for (int m = 0; m < (64 / 16); ++ m)
        for (int d = 0; d < ( (128 / 4) / 16); ++ d) {
            const uint k = uint(nrhw_h * ( (128 / 4) / 16) + d);
                    coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > src;

            const uint q = uint(m);
            const uint tx = uint(clamp(2 * int(nr_wx) + pc.shift + int(q & 1u), 0, int(pc.tiles_x) - 1));
            const uint ty = uint(clamp(2 * int(nr_wy) + pc.shift_y + int(q >> 1u), 0, int(pc.tiles_y) - 1));
            const uint slot = lane % 16u, dx = slot % 4u, dy = slot / 4u;
            const uint ipx = min( (4u * tx + dx) / 2u, pc.blend_itiles_x * 4u - 1u);
            const uint ipy = min( (4u * ty + dy) / 2u, pc.blend_itiles_y * 4u - 1u);
            const uint itile = (ipy / 4u) * pc.blend_itiles_x + ipx / 4u;
            const uint islot = (ipy % 4u) * 4u + ipx % 4u;
            const uint stw = pc.blend_stiles_x != 0u ? pc.blend_stiles_x : pc.blend_tiles_x;
            const uint stile = ty * stw + tx;




            {
                const uint saddr = pc.blend_s_off + (stile * uint( (128 / 16)) + k) * 256u + slot * 16u + rbase;
                const fe4m3vec4 sv4[2] = { nr_blend_x4(saddr / 4u), nr_blend_x4(saddr / 4u + 1u) };
                const uint local_slot = ( (q >> 1u) * 2u + dy / 2u) * 4u + (q & 1u) * 2u + dx / 2u;
                for (int j = 0; j < 8; j += 2) {
                    const uint ch = k * 16u + rbase + uint(j);
                    const uint pb = k * 256u + local_slot * 16u + rbase + uint(j);
                    const f16vec2 pv2 = unpackFloat2x16(ups_u32[ (pb) >> 1u]);
                    const f16vec2 sv2 = unpackFloat2x16(packHalf2x16(nr_e4f2_pick(vec4(sv4[j / 4]), j % 4)));

                    const f16vec2 g2 = unpackFloat2x16(wgt_u32[ (pc.blend_g_off + ch) >> 1u]);



                    const fe4m3vec2 qv = nr_quant_pair(fma(sv2, g2, pv2));
                    src[j] = qv.x; src[j + 1] = qv.y;
                }
            }
            if (false)

            {
                 float16_t blend_h[8];
            for (int j = 0; j < 8; ++ j) {
                const uint ch = k * 16u + rbase + uint(j);

                const uint local_slot = ( (q >> 1u) * 2u + dy / 2u) * 4u + (q & 1u) * 2u + dx / 2u;
                     float16_t pv = unpackFloat2x16(ups_u32[ (k * 256u + local_slot * 16u + rbase + uint(j)) >> 1u])[ (k * 256u + local_slot * 16u + rbase + uint(j)) & 1u];



                     float16_t sv = float16_t(uintBitsToFloate4m3EXT(unpack8(act_v4[ (pc.blend_s_off + (stile * uint( (128 / 16)) + k) * 256u + slot * 16u + rbase) / 4u + uint(j) / 4u])[ (j) % 4]));
                     float16_t sp = float16_t(sv * wgt_f16[pc.blend_g_off + ch]);

                blend_h[j] = float16_t(pv + sp);
            }

            for (int j = 0; j < 8; j += 4) {
                const fe4m3vec4 q4 = nr_quant4_h(f16vec4(blend_h[j], blend_h[j + 1], blend_h[j + 2], blend_h[j + 3]));
                src[j] = q4.x; src[j + 1] = q4.y; src[j + 2] = q4.z; src[j + 3] = q4.w;
            }
            }



                       coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > dst;
            for (int j = 0; j < 8; ++ j) dst[j] = src[j];


            if (nr_tile_oob(uint(m)))
                for (int j = 0; j < 8; ++ j) dst[j] = floate4m3_t(0.0);

                                                                                        coopMatStore(dst, lds_x, ( (uint(m) * uint( (128 / 16)) + k) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);
        }
    barrier();
































































































































































































    {
        const int g = nrhw_h;




                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > eqg[ (64 / 16)][ ( ( (4 * 128) / 4) / 16)];













































































































        for (int h = 0; h < ( ( (4 * 128) / 4) / 16); h += 2) {
                  coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > a[2][ (64 / 16)];
            for (int p = 0; p < 2; ++ p)
                for (int m = 0; m < (64 / 16); ++ m) a[p][m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0);
            for (int k = 0; k < (128 / 16); ++ k) {
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > xbk[ (64 / 16)];
                for (int m = 0; m < (64 / 16); ++ m)

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);




                for (int p = 0; p < 2; p += 2) {
                    const uint q = pc.e_off / 4u + uint( (g * ( ( (4 * 128) / 4) / 16) + h + p) / 2) * uint( (128 / 16)) * 128u
                        + uint(k) * 128u + lane * 4u;
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                    { { const fe4m3vec4 w0 = wexpand_pair4[q], w1 = wexpand_pair4[ (q) + 1u]; const fe4m3vec4 w2 = wexpand_pair4[ (q) + 2u], w3 = wexpand_pair4[ (q) + 3u]; for (int v = 0; v < 4; ++ v) { wf0[v] = w0[v]; wf0[v + 4] = w1[v]; wf1[v] = w2[v]; wf1[v + 4] = w3[v]; } } }
                    for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (12) >> (m)) & 1) != 0) a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]);
                    for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (12) >> (m)) & 1) != 0) a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]);
                }









                if (0 > 0 && (k + 1) % 0 == 0)
                    for (int p = 0; p < 2; ++ p)
                        for (int m = 0; m < (64 / 16); ++ m) { }
            }
            for (int p = 0; p < 2; ++ p)
            for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (12) >> (m)) & 1) != 0)






                for (int c = 0; c < 8; c += 2) {
                    const fe4m3vec2 qp = nr_quant_pair32(vec2(
                                             nr_act_pick(a[p][m][c], c), nr_act_pick(a[p][m][c + 1], c + 1)));
                    eqg[m][h + p][c] = qp.x;
                    eqg[m][h + p][c + 1] = qp.y;
                }































        }





































































              coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > nr_mid_acc[ ( (128 / 4) / 16)][ (64 / 16)];
        for (int n = 0; n < ( (128 / 4) / 16); ++ n) for (int m = 0; m < (64 / 16); ++ m) nr_mid_acc[n][m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0);
        for (int k = 0; k < ( ( (4 * 128) / 4) / 16); ++ k) {
                 coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                    { const uint q = (pc.mid_off) / 4u + ( (uint(g * ( (128 / 4) / 16))) / 2u) * (uint( ( ( (4 * 128) / 4) / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const fe4m3vec4 w0 = wexpand_pair4[q], w1 = wexpand_pair4[ (q) + 1u]; const fe4m3vec4 w2 = wexpand_pair4[ (q) + 2u], w3 = wexpand_pair4[ (q) + 3u]; for (int v = 0; v < 4; ++ v) { wf0[v] = w0[v]; wf0[v + 4] = w1[v]; wf1[v] = w2[v]; wf1[v + 4] = w3[v]; } } }
            for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (12) >> (m)) & 1) != 0) nr_mid_acc[0][m] = coopMatMulAdd(wf0, eqg[m][k], nr_mid_acc[0][m]);
            for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (12) >> (m)) & 1) != 0) nr_mid_acc[1][m] = coopMatMulAdd(wf1, eqg[m][k], nr_mid_acc[1][m]);
        }




        for (int n = 0; n < ( (128 / 4) / 16); ++ n) {
            const int nf = g * ( (128 / 4) / 16) + n;

                       coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > mqf[ (64 / 16)];





                  coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > a[ (64 / 16)];
            for (int m = 0; m < (64 / 16); ++ m) a[m] = nr_mid_acc[n][m];













            for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (12) >> (m)) & 1) != 0)







                for (int c = 0; c < 8; c += 2) {
                    fe4m3vec2 qp = nr_quant_pair(f16vec2(
                             float16_t(a[m][c]),
                             float16_t(a[m][c + 1])));
                               mqf[m][c] = qp.x;
                               mqf[m][c + 1] = qp.y;
                }




            for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (12) >> (m)) & 1) != 0)
                                                                                        coopMatStore(mqf[m], lds_y, (uint(m * (128 / 16) + nf) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);

        }
    }

    barrier();


















































































































































































          coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > nr_contract_acc[ ( (128 / 4) / 16)][ (64 / 16)];
    for (int p = 0; p < ( (128 / 4) / 16); ++ p) {
        const int n = nrhw_h * ( (128 / 4) / 16) + p;
        for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (12) >> (m)) & 1) != 0) {
                    coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yr;
                                                                            coopMatLoad(yr, lds_x, (uint(m * (128 / 16) + n) * 256u + (nr_opaque * ( (80u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);
            for (int c = 0; c < 8; c += 2) {
                const uint off = pc.rs_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_contract_acc[p][m][c] = float(residual.x);
                nr_contract_acc[p][m][c + 1] = float(residual.y);
            }
        }
    }
    for (int k = 0; k < (128 / 16); ++ k) {
                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > ctx[ (64 / 16)];
        for (int m = 0; m < (64 / 16); ++ m)
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);
             coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                    { const uint q = (pc.ct_off) / 4u + ( (uint(nrhw_h * ( (128 / 4) / 16))) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const fe4m3vec4 w0 = wexpand_pair4[q], w1 = wexpand_pair4[ (q) + 1u]; const fe4m3vec4 w2 = wexpand_pair4[ (q) + 2u], w3 = wexpand_pair4[ (q) + 3u]; for (int v = 0; v < 4; ++ v) { wf0[v] = w0[v]; wf0[v + 4] = w1[v]; wf1[v] = w2[v]; wf1[v + 4] = w3[v]; } } }
        for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (12) >> (m)) & 1) != 0) nr_contract_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_contract_acc[0][m]);
        for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (12) >> (m)) & 1) != 0) nr_contract_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_contract_acc[1][m]);
    }


    for (int nn = 0; nn < ( (128 / 4) / 16); ++ nn) {
        const int n = nrhw_h * ( (128 / 4) / 16) + nn;


                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > xbk[ (64 / 16)];
        for (int m = 0; m < (64 / 16); ++ m)

                                                                   coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + n) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);



                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yqw[ (64 / 16)];







              coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > a[ (64 / 16)];
        for (int m = 0; m < (64 / 16); ++ m) a[m] = nr_contract_acc[nn][m];







































































        for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (12) >> (m)) & 1) != 0) {

            float requantized[8];






















            for (int c = 0; c < 8; ++ c) {

                const float v = a[m][c];












                requantized[c] = v;










            }


            for (int c = 0; c < 8; c += 2) {

                         fe4m3vec2 q = nr_quant_pair32(vec2(requantized[c], requantized[c + 1]));



                          yqw[m][c] = q.x; yqw[m][c + 1] = q.y;



            }
        }





        for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (12) >> (m)) & 1) != 0) {
                       coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > yf;
            for (int c = 0; c < 8; ++ c) yf[c] = yqw[m][c];
                                                                               coopMatStore(yf, lds_x, (uint(m * (128 / 16) + n) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);
        }

    }

    barrier();































    {
        const int hh = nrhw_h;





                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > kreg[ (64 / 16)][ ( (128 / 4) / 16)];




        const float16_t hscale = float16_t(wgt_f32[pc.s_off + uint(hh)]);
                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > qb[ (64 / 16)][ ( (128 / 4) / 16)];
























        {










                  coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > acc[ (64 / 16)][ ( (1 + 1) * ( (128 / 4) / 16))];

            for (int m = 0; m < (64 / 16); ++ m)
                for (int d = 0; d < ( (1 + 1) * ( (128 / 4) / 16)); ++ d) acc[m][d] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0);
            for (int k = 0; k < (128 / 16); ++ k) {
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yk[ (64 / 16)];
                for (int m = 0; m < (64 / 16); ++ m)

                                                                            coopMatLoad(yk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (128u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);




                for (int r = 0; r < ( (1 + 1) * ( (128 / 4) / 16)); r += 2) {
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                                  { const uint q = (pc.qkv_off) / 4u + ( (uint(hh * 3 * ( (128 / 4) / 16) + 0 + r)) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const fe4m3vec4 w0 = wexpand_pair4[q], w1 = wexpand_pair4[ (q) + 1u]; const fe4m3vec4 w2 = wexpand_pair4[ (q) + 2u], w3 = wexpand_pair4[ (q) + 3u]; for (int v = 0; v < 4; ++ v) { wf0[v] = w0[v]; wf0[v + 4] = w1[v]; wf1[v] = w2[v]; wf1[v + 4] = w3[v]; } } }
                    for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (12) >> (m)) & 1) != 0) acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]);
                    for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (12) >> (m)) & 1) != 0) acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]);
                }







                if (0 > 0 && (k + 1) % 0 == 0)
                    for (int m = 0; m < (64 / 16); ++ m)
                        for (int r = 0; r < ( (1 + 1) * ( (128 / 4) / 16)); ++ r) { }

            }
            for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (12) >> (m)) & 1) != 0) {

                float sqp[4];
                for (int i = 0; i < 4; ++ i) sqp[i] = 0.0;
                for (int c = 0; c < 8; ++ c)
                    for (int d = 0; d < ( (128 / 4) / 16); ++ d) {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    }








                f16vec2 sq = f16vec2(vec2( (sqp[0] + sqp[1]) + (sqp[2] + sqp[3]), 0.0));
                sq = sq + unpackFloat2x16(subgroupShuffleXor(packFloat2x16(sq), 16u));
                const float16_t nq =
                                    float16_t(inversesqrt(float(max( (sq.x), float16_t(0.000062)))));





































                for (int d = 0; d < ( (128 / 4) / 16); ++ d)
                    for (int c = 0; c < 8; c += 2) {

                        fe4m3vec2 qp = nr_qscale_fast(vec2(acc[m][d][c], acc[m][d][c + 1]), nq, hscale);





                        qb[m][d][c] = qp.x;
                        qb[m][d][c + 1] = qp.y;
                    }
            }






















            for (int m = 0; m < (64 / 16); ++ m) {

                float skp[4];
                for (int i = 0; i < 4; ++ i) skp[i] = 0.0;
                for (int c = 0; c < 8; ++ c)
                    for (int d = 0; d < ( (128 / 4) / 16); ++ d) {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    }





                f16vec2 sk = f16vec2(vec2( (skp[0] + skp[1]) + (skp[2] + skp[3]), 0.0));
                sk = sk + unpackFloat2x16(subgroupShuffleXor(packFloat2x16(sk), 16u));
                const float16_t nk =
                                    float16_t(inversesqrt(float(max( (sk.x), float16_t(0.000062)))));























                for (int d = 0; d < ( (128 / 4) / 16); ++ d) {
                               coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > kf;
                    for (int c = 0; c < 8; c += 2) {

                        fe4m3vec2 qp = nr_kscale_fast(vec2(acc[m][d + 1 * ( (128 / 4) / 16)][c],
                            acc[m][d + 1 * ( (128 / 4) / 16)][c + 1]), nk);





                        kf[c] = qp.x;
                        kf[c + 1] = qp.y;
                    }


                    for (int c = 0; c < 8; ++ c) kreg[m][d][c] = kf[c];
                }
            }
































            for (int m = 0; m < (64 / 16); ++ m)
                for (int d = 0; d < ( (128 / 4) / 16); ++ d) acc[m][d] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0);
            for (int k = 0; k < (128 / 16); ++ k) {



















                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yk[ (64 / 16)];
                for (int m = 0; m < (64 / 16); ++ m)

                                                                            coopMatLoad(yk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (130u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);




                for (int r = 0; r < ( (128 / 4) / 16); r += 2) {
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                                         { const uint q = (pc.qkv_off) / 4u + ( (uint(hh * 3 * ( (128 / 4) / 16) + 2 * ( (128 / 4) / 16) + r)) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const fe4m3vec4 w0 = wexpand_pair4[q], w1 = wexpand_pair4[ (q) + 1u]; const fe4m3vec4 w2 = wexpand_pair4[ (q) + 2u], w3 = wexpand_pair4[ (q) + 3u]; for (int v = 0; v < 4; ++ v) { wf0[v] = w0[v]; wf0[v + 4] = w1[v]; wf1[v] = w2[v]; wf1[v + 4] = w3[v]; } } }
                    for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (12) >> (m)) & 1) != 0) acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]);
                    for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (12) >> (m)) & 1) != 0) acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]);
                }











                if (0 > 0 && (k + 1) % 0 == 0)
                    for (int m = 0; m < (64 / 16); ++ m)
                        for (int r = 0; r < ( (128 / 4) / 16); ++ r) { }

            }











            for (int m = 0; m < (64 / 16); ++ m)
                for (int d = 0; d < ( (128 / 4) / 16); ++ d) {
                               coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > vf;
                    for (int c = 0; c < 8; c += 2) {
                        fe4m3vec2 qp = nr_quant_pair(

                                            f16vec2(float16_t(acc[m][d][c]), float16_t(acc[m][d][c + 1])));
                        vf[c] = qp.x;
                        vf[c + 1] = qp.y;
                    }





                                                                                 coopMatStore(vf, lds_y, (uint(m * (128 / 16) + hh * ( (128 / 4) / 16) + d) * 256u), (16u), gl_CooperativeMatrixLayoutRowMajor);
                }


        }













































































































































































































































































































             coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > pb[ (64 / 16)][ (64 / 16)];
        for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (12) >> (m)) & 1) != 0) {
            f16vec2 pq2[ (64 / 16)][4];
                  coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > lg[ (64 / 16)];



            for (int j = 0; j < (64 / 16); ++ j) lg[j] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0);


            for (int d = 0; d < ( (128 / 4) / 16); ++ d)
                for (int j = 0; j < (64 / 16); ++ j) {
                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > kf = kreg[j][d];
                                              lg[j] = coopMatMulAdd(kf, qb[m][d], lg[j]);
                }
            for (int j = 0; j < (64 / 16); ++ j) {
















                          coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > bf;



                                            coopMatLoad(bf, wgt_f32, (pc.b_off + uint(hh) * uint(64 * 64) + (tok0 + uint(m) * 16u) * uint(64) + uint(j) * 16u), (uint(64)), gl_CooperativeMatrixLayoutColumnMajor);


                for (int c = 0; c < 8; c += 2)
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1]));



            }
                 float16_t sum = nr_swin_probability_sum(pq2);


            float inv = float(float16_t(1.0 / float(max(sum, float16_t(6.103515625e-05)))));
            for (int j = 0; j < (64 / 16); ++ j)
                for (int c = 0; c < 4; ++ c) {
                    float x = float(pq2[j][c].x) * inv;
                    float y = float(pq2[j][c].y) * inv;










                    fe4m3vec2 q = fe4m3vec2(pq2[j][c] * f16vec2(float16_t(inv)));





                    pb[m][j][2 * c] = q.x;
                    pb[m][j][2 * c + 1] = q.y;
                }
        }
























































































































































































        for (int e = 0; e < ( (128 / 4) / 16); ++ e) {
                  coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > a[ (64 / 16)];
            for (int m = 0; m < (64 / 16); ++ m) a[m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0);
            for (int j = 0; j < (64 / 16); ++ j) {
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > vf;





                                                 coopMatLoad(vf, lds_y, (uint(j * (128 / 16) + hh * ( (128 / 4) / 16) + e) * 256u + (nr_opaque * ( (192u) * 16u))), (16u), gl_CooperativeMatrixLayoutRowMajor);




                for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (12) >> (m)) & 1) != 0) a[m] = coopMatMulAdd(vf, pb[m][j], a[m]);
                if (0 > 0 && (j + 1) % 0 == 0)
                    for (int m = 0; m < (64 / 16); ++ m) { }
            }
            for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (12) >> (m)) & 1) != 0) {

                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > out_context;





                for (int c = 0; c < 8; c += 2) {
                             fe4m3vec2 qp = nr_quant_pair(f16vec2(float16_t(a[m][c]), float16_t(a[m][c + 1])));
                    out_context[c] = qp.x;
                    out_context[c + 1] = qp.y;
                }








                                                                             coopMatStore(out_context, lds_y, (uint(m * (128 / 16) + hh * ( (128 / 4) / 16) + e) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);




















            }
        }


        barrier();

    }













































































          coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > nr_project_acc[ ( (128 / 4) / 16)][ (64 / 16)];
    for (int p = 0; p < ( (128 / 4) / 16); ++ p) {
        const int n = nrhw_h * ( (128 / 4) / 16) + p;
        for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (12) >> (m)) & 1) != 0) {
                    coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yr;
                                                                            coopMatLoad(yr, lds_x, (uint(m * (128 / 16) + n) * 256u + (nr_opaque * ( (80u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);
            for (int c = 0; c < 8; c += 2) {
                const uint off = pc.ars_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_project_acc[p][m][c] = float(residual.x);
                nr_project_acc[p][m][c + 1] = float(residual.y);
            }
        }
    }
    for (int k = 0; k < (128 / 16); ++ k) {
                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > ctx[ (64 / 16)];
        for (int m = 0; m < (64 / 16); ++ m)
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);
             coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                    { const uint q = (pc.op_off) / 4u + ( (uint(nrhw_h * ( (128 / 4) / 16))) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const fe4m3vec4 w0 = wexpand_pair4[q], w1 = wexpand_pair4[ (q) + 1u]; const fe4m3vec4 w2 = wexpand_pair4[ (q) + 2u], w3 = wexpand_pair4[ (q) + 3u]; for (int v = 0; v < 4; ++ v) { wf0[v] = w0[v]; wf0[v + 4] = w1[v]; wf1[v] = w2[v]; wf1[v + 4] = w3[v]; } } }
        for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (12) >> (m)) & 1) != 0) nr_project_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_project_acc[0][m]);
        for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (12) >> (m)) & 1) != 0) nr_project_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_project_acc[1][m]);
    }


    for (int nn = 0; nn < ( (128 / 4) / 16); ++ nn) {
        const int n = nrhw_h * ( (128 / 4) / 16) + nn;






                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yqr[ (64 / 16)];
        for (int m = 0; m < (64 / 16); ++ m)

                                                                   coopMatLoad(yqr[m], lds_x, (uint(m * (128 / 16) + n) * 256u + (nr_opaque * ( (80u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);




              coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > a[ (64 / 16)];
        for (int m = 0; m < (64 / 16); ++ m) a[m] = nr_project_acc[nn][m];
























































        for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (12) >> (m)) & 1) != 0) {




















































                       coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > of;
                 float16_t wide[8];

            float widef[8];













            for (int c = 0; c < 8; ++ c) {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            }
            for (int c = 0; c < 8; c += 2) {

                fe4m3vec2 q = nr_quant_pair32(vec2(widef[c], widef[c + 1]));



                of[c] = q.x; of[c + 1] = q.y;



            }






































































































































































































































































































            if (! nr_tile_oob( (tok0 + uint(m) * 16u) / 16u))


                                                  do { const uint nr_sa = ( (pc.o_off + nr_tile_base( (tok0 + uint(m) * 16u) / 16u) + uint(n) * 256u) + (gl_SubgroupInvocationID % 16u) * (16u) + (gl_SubgroupInvocationID / 16u) * 8u) / 8u; act_v8[nr_sa] = uvec2(nr_e4m3x4_bits(fe4m3vec4(of[0], of[1], of[2], of[3])), nr_e4m3x4_bits(fe4m3vec4(of[4], of[5], of[6], of[7]))); } while (false);






        }
    }










































































































#line 3277 "D:\nr-work-20261011\_mochi\DLSSNR-AMD-main\windows\shaders\rdna4\fswin_t.comp"

    }
    [[dont_flatten]] if (nr_body == 3u) {

#line 1 "D:/nr-work-20261011/_mochi/DLSSNR-AMD-main/windows/shaders/rdna4/include/fswin_body.glsl"





    const uint wbase = nr_wx * uint(64 * 128);

    const uint tok0 = 0u;
    const int nrhw_h = int(wave);









    const uint nr_opaque = gl_WorkGroupID.z;








    const uint rbase = 8u * (lane / 16u);































































    [[dont_flatten]] if (nr_ups_layer) {






            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > upsrc[2 * (128 / 16)];
    const uint ups_slot = lane % 16u;
    const uint ups_px = uint(clamp(4 * int(nr_wx) + 2 * pc.shift + int(ups_slot % 4u), 0, int(pc.blend_itiles_x * 4u) - 1));
    const uint ups_py = uint(clamp(4 * int(nr_wy) + 2 * pc.shift_y + int(ups_slot / 4u), 0, int(pc.blend_itiles_y * 4u) - 1));
    const uint ups_tile = (ups_py / 4u) * pc.blend_itiles_x + ups_px / 4u;
    const uint ups_in_slot = (ups_py % 4u) * 4u + ups_px % 4u;
























    for (int k = 0; k < 2 * (128 / 16); ++ k)
        for (int j = 0; j < 8; ++ j)






















            upsrc[k][j] = uintBitsToFloate4m3EXT(unpack8(act_v4[ (pc.blend_p_off + (ups_tile * uint(2 * (128 / 16)) + uint(k)) * 256u + ups_in_slot * 16u + rbase) / 4u + uint(j) / 4u])[ (j) % 4]);

    for (int n = 0; n < ( (128 / 4) / 16); ++ n) {
        const uint nf = uint(nrhw_h * ( (128 / 4) / 16) + n);
                  coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > acc = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0);
        for (int k = 0; k < 2 * (128 / 16); ++ k) {
                    coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > w;
                                                                                      coopMatLoad(w, wgt_e4m3, (pc.ups_weight_off + (nf * uint(2 * (128 / 16)) + uint(k)) * 256u), (16u), gl_CooperativeMatrixLayoutRowMajor);
                                 acc = coopMatMulAdd(w, upsrc[k], acc);
        }
                    coopmat < float16_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > half_result;
        for (int j = 0; j < 8; ++ j) half_result[j] = float16_t(acc[j]);
                                        coopMatStore(half_result, ups_projected, (nf * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);
    }

    barrier();

    }










    uint tbase[ (64 / 16)];
    for (int m = 0; m < (64 / 16); ++ m)

        tbase[m] = pc.x_off + nr_tile_base( (tok0 + uint(m) * 16u) / 16u);































    [[dont_flatten]] if (! nr_ups_layer) {
        for (int m = 0; m < (64 / 16); ++ m)
            for (int d = 0; d < ( (128 / 4) / 16); ++ d) {
                const uint k = uint(nrhw_h * ( (128 / 4) / 16) + d);
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > src;
                                                           do { const uint nr_la = ( (tbase[m] + k * 256u) + (gl_SubgroupInvocationID % 16u) * (16u) + (gl_SubgroupInvocationID / 16u) * 8u) / 4u; const u8vec4 nr_b0 = unpack8(act_v4[nr_la]), nr_b1 = unpack8(act_v4[nr_la + 1u]); for (int nr_i = 0; nr_i < 4; ++ nr_i) { src[nr_i] = uintBitsToFloate4m3EXT(nr_b0[nr_i]); src[nr_i + 4] = uintBitsToFloate4m3EXT(nr_b1[nr_i]); } } while (false);
                           coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > dst;
                for (int j = 0; j < 8; ++ j) dst[j] = src[j];
                if (nr_tile_oob(uint(m)))
                    for (int j = 0; j < 8; ++ j) dst[j] = floate4m3_t(0.0);
                                                                                            coopMatStore(dst, lds_x, ( (uint(m) * uint( (128 / 16)) + k) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);
            }
    } else

    for (int m = 0; m < (64 / 16); ++ m)
        for (int d = 0; d < ( (128 / 4) / 16); ++ d) {
            const uint k = uint(nrhw_h * ( (128 / 4) / 16) + d);
                    coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > src;

            const uint q = uint(m);
            const uint tx = uint(clamp(2 * int(nr_wx) + pc.shift + int(q & 1u), 0, int(pc.tiles_x) - 1));
            const uint ty = uint(clamp(2 * int(nr_wy) + pc.shift_y + int(q >> 1u), 0, int(pc.tiles_y) - 1));
            const uint slot = lane % 16u, dx = slot % 4u, dy = slot / 4u;
            const uint ipx = min( (4u * tx + dx) / 2u, pc.blend_itiles_x * 4u - 1u);
            const uint ipy = min( (4u * ty + dy) / 2u, pc.blend_itiles_y * 4u - 1u);
            const uint itile = (ipy / 4u) * pc.blend_itiles_x + ipx / 4u;
            const uint islot = (ipy % 4u) * 4u + ipx % 4u;
            const uint stw = pc.blend_stiles_x != 0u ? pc.blend_stiles_x : pc.blend_tiles_x;
            const uint stile = ty * stw + tx;




            {
                const uint saddr = pc.blend_s_off + (stile * uint( (128 / 16)) + k) * 256u + slot * 16u + rbase;
                const fe4m3vec4 sv4[2] = { nr_blend_x4(saddr / 4u), nr_blend_x4(saddr / 4u + 1u) };
                const uint local_slot = ( (q >> 1u) * 2u + dy / 2u) * 4u + (q & 1u) * 2u + dx / 2u;
                for (int j = 0; j < 8; j += 2) {
                    const uint ch = k * 16u + rbase + uint(j);
                    const uint pb = k * 256u + local_slot * 16u + rbase + uint(j);
                    const f16vec2 pv2 = unpackFloat2x16(ups_u32[ (pb) >> 1u]);
                    const f16vec2 sv2 = unpackFloat2x16(packHalf2x16(nr_e4f2_pick(vec4(sv4[j / 4]), j % 4)));

                    const f16vec2 g2 = unpackFloat2x16(wgt_u32[ (pc.blend_g_off + ch) >> 1u]);



                    const fe4m3vec2 qv = nr_quant_pair(fma(sv2, g2, pv2));
                    src[j] = qv.x; src[j + 1] = qv.y;
                }
            }
            if (false)

            {
                 float16_t blend_h[8];
            for (int j = 0; j < 8; ++ j) {
                const uint ch = k * 16u + rbase + uint(j);

                const uint local_slot = ( (q >> 1u) * 2u + dy / 2u) * 4u + (q & 1u) * 2u + dx / 2u;
                     float16_t pv = unpackFloat2x16(ups_u32[ (k * 256u + local_slot * 16u + rbase + uint(j)) >> 1u])[ (k * 256u + local_slot * 16u + rbase + uint(j)) & 1u];



                     float16_t sv = float16_t(uintBitsToFloate4m3EXT(unpack8(act_v4[ (pc.blend_s_off + (stile * uint( (128 / 16)) + k) * 256u + slot * 16u + rbase) / 4u + uint(j) / 4u])[ (j) % 4]));
                     float16_t sp = float16_t(sv * wgt_f16[pc.blend_g_off + ch]);

                blend_h[j] = float16_t(pv + sp);
            }

            for (int j = 0; j < 8; j += 4) {
                const fe4m3vec4 q4 = nr_quant4_h(f16vec4(blend_h[j], blend_h[j + 1], blend_h[j + 2], blend_h[j + 3]));
                src[j] = q4.x; src[j + 1] = q4.y; src[j + 2] = q4.z; src[j + 3] = q4.w;
            }
            }



                       coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > dst;
            for (int j = 0; j < 8; ++ j) dst[j] = src[j];


            if (nr_tile_oob(uint(m)))
                for (int j = 0; j < 8; ++ j) dst[j] = floate4m3_t(0.0);

                                                                                        coopMatStore(dst, lds_x, ( (uint(m) * uint( (128 / 16)) + k) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);
        }
    barrier();
































































































































































































    {
        const int g = nrhw_h;




                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > eqg[ (64 / 16)][ ( ( (4 * 128) / 4) / 16)];













































































































        for (int h = 0; h < ( ( (4 * 128) / 4) / 16); h += 2) {
                  coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > a[2][ (64 / 16)];
            for (int p = 0; p < 2; ++ p)
                for (int m = 0; m < (64 / 16); ++ m) a[p][m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0);
            for (int k = 0; k < (128 / 16); ++ k) {
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > xbk[ (64 / 16)];
                for (int m = 0; m < (64 / 16); ++ m)

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);




                for (int p = 0; p < 2; p += 2) {
                    const uint q = pc.e_off / 4u + uint( (g * ( ( (4 * 128) / 4) / 16) + h + p) / 2) * uint( (128 / 16)) * 128u
                        + uint(k) * 128u + lane * 4u;
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                    { { const fe4m3vec4 w0 = wexpand_pair4[q], w1 = wexpand_pair4[ (q) + 1u]; const fe4m3vec4 w2 = wexpand_pair4[ (q) + 2u], w3 = wexpand_pair4[ (q) + 3u]; for (int v = 0; v < 4; ++ v) { wf0[v] = w0[v]; wf0[v + 4] = w1[v]; wf1[v] = w2[v]; wf1[v + 4] = w3[v]; } } }
                    for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (3) >> (m)) & 1) != 0) a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]);
                    for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (3) >> (m)) & 1) != 0) a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]);
                }









                if (0 > 0 && (k + 1) % 0 == 0)
                    for (int p = 0; p < 2; ++ p)
                        for (int m = 0; m < (64 / 16); ++ m) { }
            }
            for (int p = 0; p < 2; ++ p)
            for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (3) >> (m)) & 1) != 0)






                for (int c = 0; c < 8; c += 2) {
                    const fe4m3vec2 qp = nr_quant_pair32(vec2(
                                             nr_act_pick(a[p][m][c], c), nr_act_pick(a[p][m][c + 1], c + 1)));
                    eqg[m][h + p][c] = qp.x;
                    eqg[m][h + p][c + 1] = qp.y;
                }































        }





































































              coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > nr_mid_acc[ ( (128 / 4) / 16)][ (64 / 16)];
        for (int n = 0; n < ( (128 / 4) / 16); ++ n) for (int m = 0; m < (64 / 16); ++ m) nr_mid_acc[n][m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0);
        for (int k = 0; k < ( ( (4 * 128) / 4) / 16); ++ k) {
                 coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                    { const uint q = (pc.mid_off) / 4u + ( (uint(g * ( (128 / 4) / 16))) / 2u) * (uint( ( ( (4 * 128) / 4) / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const fe4m3vec4 w0 = wexpand_pair4[q], w1 = wexpand_pair4[ (q) + 1u]; const fe4m3vec4 w2 = wexpand_pair4[ (q) + 2u], w3 = wexpand_pair4[ (q) + 3u]; for (int v = 0; v < 4; ++ v) { wf0[v] = w0[v]; wf0[v + 4] = w1[v]; wf1[v] = w2[v]; wf1[v + 4] = w3[v]; } } }
            for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (3) >> (m)) & 1) != 0) nr_mid_acc[0][m] = coopMatMulAdd(wf0, eqg[m][k], nr_mid_acc[0][m]);
            for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (3) >> (m)) & 1) != 0) nr_mid_acc[1][m] = coopMatMulAdd(wf1, eqg[m][k], nr_mid_acc[1][m]);
        }




        for (int n = 0; n < ( (128 / 4) / 16); ++ n) {
            const int nf = g * ( (128 / 4) / 16) + n;

                       coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > mqf[ (64 / 16)];





                  coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > a[ (64 / 16)];
            for (int m = 0; m < (64 / 16); ++ m) a[m] = nr_mid_acc[n][m];













            for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (3) >> (m)) & 1) != 0)







                for (int c = 0; c < 8; c += 2) {
                    fe4m3vec2 qp = nr_quant_pair(f16vec2(
                             float16_t(a[m][c]),
                             float16_t(a[m][c + 1])));
                               mqf[m][c] = qp.x;
                               mqf[m][c + 1] = qp.y;
                }




            for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (3) >> (m)) & 1) != 0)
                                                                                        coopMatStore(mqf[m], lds_y, (uint(m * (128 / 16) + nf) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);

        }
    }

    barrier();


















































































































































































          coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > nr_contract_acc[ ( (128 / 4) / 16)][ (64 / 16)];
    for (int p = 0; p < ( (128 / 4) / 16); ++ p) {
        const int n = nrhw_h * ( (128 / 4) / 16) + p;
        for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (3) >> (m)) & 1) != 0) {
                    coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yr;
                                                                            coopMatLoad(yr, lds_x, (uint(m * (128 / 16) + n) * 256u + (nr_opaque * ( (80u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);
            for (int c = 0; c < 8; c += 2) {
                const uint off = pc.rs_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_contract_acc[p][m][c] = float(residual.x);
                nr_contract_acc[p][m][c + 1] = float(residual.y);
            }
        }
    }
    for (int k = 0; k < (128 / 16); ++ k) {
                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > ctx[ (64 / 16)];
        for (int m = 0; m < (64 / 16); ++ m)
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);
             coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                    { const uint q = (pc.ct_off) / 4u + ( (uint(nrhw_h * ( (128 / 4) / 16))) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const fe4m3vec4 w0 = wexpand_pair4[q], w1 = wexpand_pair4[ (q) + 1u]; const fe4m3vec4 w2 = wexpand_pair4[ (q) + 2u], w3 = wexpand_pair4[ (q) + 3u]; for (int v = 0; v < 4; ++ v) { wf0[v] = w0[v]; wf0[v + 4] = w1[v]; wf1[v] = w2[v]; wf1[v + 4] = w3[v]; } } }
        for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (3) >> (m)) & 1) != 0) nr_contract_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_contract_acc[0][m]);
        for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (3) >> (m)) & 1) != 0) nr_contract_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_contract_acc[1][m]);
    }


    for (int nn = 0; nn < ( (128 / 4) / 16); ++ nn) {
        const int n = nrhw_h * ( (128 / 4) / 16) + nn;


                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > xbk[ (64 / 16)];
        for (int m = 0; m < (64 / 16); ++ m)

                                                                   coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + n) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);



                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yqw[ (64 / 16)];







              coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > a[ (64 / 16)];
        for (int m = 0; m < (64 / 16); ++ m) a[m] = nr_contract_acc[nn][m];







































































        for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (3) >> (m)) & 1) != 0) {

            float requantized[8];






















            for (int c = 0; c < 8; ++ c) {

                const float v = a[m][c];












                requantized[c] = v;










            }


            for (int c = 0; c < 8; c += 2) {

                         fe4m3vec2 q = nr_quant_pair32(vec2(requantized[c], requantized[c + 1]));



                          yqw[m][c] = q.x; yqw[m][c + 1] = q.y;



            }
        }





        for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (3) >> (m)) & 1) != 0) {
                       coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > yf;
            for (int c = 0; c < 8; ++ c) yf[c] = yqw[m][c];
                                                                               coopMatStore(yf, lds_x, (uint(m * (128 / 16) + n) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);
        }

    }

    barrier();































    {
        const int hh = nrhw_h;





                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > kreg[ (64 / 16)][ ( (128 / 4) / 16)];




        const float16_t hscale = float16_t(wgt_f32[pc.s_off + uint(hh)]);
                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > qb[ (64 / 16)][ ( (128 / 4) / 16)];
























        {










                  coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > acc[ (64 / 16)][ ( (1 + 1) * ( (128 / 4) / 16))];

            for (int m = 0; m < (64 / 16); ++ m)
                for (int d = 0; d < ( (1 + 1) * ( (128 / 4) / 16)); ++ d) acc[m][d] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0);
            for (int k = 0; k < (128 / 16); ++ k) {
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yk[ (64 / 16)];
                for (int m = 0; m < (64 / 16); ++ m)

                                                                            coopMatLoad(yk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (128u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);




                for (int r = 0; r < ( (1 + 1) * ( (128 / 4) / 16)); r += 2) {
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                                  { const uint q = (pc.qkv_off) / 4u + ( (uint(hh * 3 * ( (128 / 4) / 16) + 0 + r)) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const fe4m3vec4 w0 = wexpand_pair4[q], w1 = wexpand_pair4[ (q) + 1u]; const fe4m3vec4 w2 = wexpand_pair4[ (q) + 2u], w3 = wexpand_pair4[ (q) + 3u]; for (int v = 0; v < 4; ++ v) { wf0[v] = w0[v]; wf0[v + 4] = w1[v]; wf1[v] = w2[v]; wf1[v + 4] = w3[v]; } } }
                    for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (3) >> (m)) & 1) != 0) acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]);
                    for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (3) >> (m)) & 1) != 0) acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]);
                }







                if (0 > 0 && (k + 1) % 0 == 0)
                    for (int m = 0; m < (64 / 16); ++ m)
                        for (int r = 0; r < ( (1 + 1) * ( (128 / 4) / 16)); ++ r) { }

            }
            for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (3) >> (m)) & 1) != 0) {

                float sqp[4];
                for (int i = 0; i < 4; ++ i) sqp[i] = 0.0;
                for (int c = 0; c < 8; ++ c)
                    for (int d = 0; d < ( (128 / 4) / 16); ++ d) {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    }








                f16vec2 sq = f16vec2(vec2( (sqp[0] + sqp[1]) + (sqp[2] + sqp[3]), 0.0));
                sq = sq + unpackFloat2x16(subgroupShuffleXor(packFloat2x16(sq), 16u));
                const float16_t nq =
                                    float16_t(inversesqrt(float(max( (sq.x), float16_t(0.000062)))));





































                for (int d = 0; d < ( (128 / 4) / 16); ++ d)
                    for (int c = 0; c < 8; c += 2) {

                        fe4m3vec2 qp = nr_qscale_fast(vec2(acc[m][d][c], acc[m][d][c + 1]), nq, hscale);





                        qb[m][d][c] = qp.x;
                        qb[m][d][c + 1] = qp.y;
                    }
            }






















            for (int m = 0; m < (64 / 16); ++ m) {

                float skp[4];
                for (int i = 0; i < 4; ++ i) skp[i] = 0.0;
                for (int c = 0; c < 8; ++ c)
                    for (int d = 0; d < ( (128 / 4) / 16); ++ d) {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    }





                f16vec2 sk = f16vec2(vec2( (skp[0] + skp[1]) + (skp[2] + skp[3]), 0.0));
                sk = sk + unpackFloat2x16(subgroupShuffleXor(packFloat2x16(sk), 16u));
                const float16_t nk =
                                    float16_t(inversesqrt(float(max( (sk.x), float16_t(0.000062)))));























                for (int d = 0; d < ( (128 / 4) / 16); ++ d) {
                               coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > kf;
                    for (int c = 0; c < 8; c += 2) {

                        fe4m3vec2 qp = nr_kscale_fast(vec2(acc[m][d + 1 * ( (128 / 4) / 16)][c],
                            acc[m][d + 1 * ( (128 / 4) / 16)][c + 1]), nk);





                        kf[c] = qp.x;
                        kf[c + 1] = qp.y;
                    }


                    for (int c = 0; c < 8; ++ c) kreg[m][d][c] = kf[c];
                }
            }
































            for (int m = 0; m < (64 / 16); ++ m)
                for (int d = 0; d < ( (128 / 4) / 16); ++ d) acc[m][d] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0);
            for (int k = 0; k < (128 / 16); ++ k) {



















                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yk[ (64 / 16)];
                for (int m = 0; m < (64 / 16); ++ m)

                                                                            coopMatLoad(yk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (130u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);




                for (int r = 0; r < ( (128 / 4) / 16); r += 2) {
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                                         { const uint q = (pc.qkv_off) / 4u + ( (uint(hh * 3 * ( (128 / 4) / 16) + 2 * ( (128 / 4) / 16) + r)) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const fe4m3vec4 w0 = wexpand_pair4[q], w1 = wexpand_pair4[ (q) + 1u]; const fe4m3vec4 w2 = wexpand_pair4[ (q) + 2u], w3 = wexpand_pair4[ (q) + 3u]; for (int v = 0; v < 4; ++ v) { wf0[v] = w0[v]; wf0[v + 4] = w1[v]; wf1[v] = w2[v]; wf1[v + 4] = w3[v]; } } }
                    for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (3) >> (m)) & 1) != 0) acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]);
                    for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (3) >> (m)) & 1) != 0) acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]);
                }











                if (0 > 0 && (k + 1) % 0 == 0)
                    for (int m = 0; m < (64 / 16); ++ m)
                        for (int r = 0; r < ( (128 / 4) / 16); ++ r) { }

            }











            for (int m = 0; m < (64 / 16); ++ m)
                for (int d = 0; d < ( (128 / 4) / 16); ++ d) {
                               coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > vf;
                    for (int c = 0; c < 8; c += 2) {
                        fe4m3vec2 qp = nr_quant_pair(

                                            f16vec2(float16_t(acc[m][d][c]), float16_t(acc[m][d][c + 1])));
                        vf[c] = qp.x;
                        vf[c + 1] = qp.y;
                    }





                                                                                 coopMatStore(vf, lds_y, (uint(m * (128 / 16) + hh * ( (128 / 4) / 16) + d) * 256u), (16u), gl_CooperativeMatrixLayoutRowMajor);
                }


        }













































































































































































































































































































             coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > pb[ (64 / 16)][ (64 / 16)];
        for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (3) >> (m)) & 1) != 0) {
            f16vec2 pq2[ (64 / 16)][4];
                  coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > lg[ (64 / 16)];



            for (int j = 0; j < (64 / 16); ++ j) lg[j] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0);


            for (int d = 0; d < ( (128 / 4) / 16); ++ d)
                for (int j = 0; j < (64 / 16); ++ j) {
                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > kf = kreg[j][d];
                                              lg[j] = coopMatMulAdd(kf, qb[m][d], lg[j]);
                }
            for (int j = 0; j < (64 / 16); ++ j) {
















                          coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > bf;



                                            coopMatLoad(bf, wgt_f32, (pc.b_off + uint(hh) * uint(64 * 64) + (tok0 + uint(m) * 16u) * uint(64) + uint(j) * 16u), (uint(64)), gl_CooperativeMatrixLayoutColumnMajor);


                for (int c = 0; c < 8; c += 2)
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1]));



            }
                 float16_t sum = nr_swin_probability_sum(pq2);


            float inv = float(float16_t(1.0 / float(max(sum, float16_t(6.103515625e-05)))));
            for (int j = 0; j < (64 / 16); ++ j)
                for (int c = 0; c < 4; ++ c) {
                    float x = float(pq2[j][c].x) * inv;
                    float y = float(pq2[j][c].y) * inv;










                    fe4m3vec2 q = fe4m3vec2(pq2[j][c] * f16vec2(float16_t(inv)));





                    pb[m][j][2 * c] = q.x;
                    pb[m][j][2 * c + 1] = q.y;
                }
        }
























































































































































































        for (int e = 0; e < ( (128 / 4) / 16); ++ e) {
                  coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > a[ (64 / 16)];
            for (int m = 0; m < (64 / 16); ++ m) a[m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0);
            for (int j = 0; j < (64 / 16); ++ j) {
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > vf;





                                                 coopMatLoad(vf, lds_y, (uint(j * (128 / 16) + hh * ( (128 / 4) / 16) + e) * 256u + (nr_opaque * ( (192u) * 16u))), (16u), gl_CooperativeMatrixLayoutRowMajor);




                for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (3) >> (m)) & 1) != 0) a[m] = coopMatMulAdd(vf, pb[m][j], a[m]);
                if (0 > 0 && (j + 1) % 0 == 0)
                    for (int m = 0; m < (64 / 16); ++ m) { }
            }
            for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (3) >> (m)) & 1) != 0) {

                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > out_context;





                for (int c = 0; c < 8; c += 2) {
                             fe4m3vec2 qp = nr_quant_pair(f16vec2(float16_t(a[m][c]), float16_t(a[m][c + 1])));
                    out_context[c] = qp.x;
                    out_context[c + 1] = qp.y;
                }








                                                                             coopMatStore(out_context, lds_y, (uint(m * (128 / 16) + hh * ( (128 / 4) / 16) + e) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);




















            }
        }


        barrier();

    }













































































          coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > nr_project_acc[ ( (128 / 4) / 16)][ (64 / 16)];
    for (int p = 0; p < ( (128 / 4) / 16); ++ p) {
        const int n = nrhw_h * ( (128 / 4) / 16) + p;
        for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (3) >> (m)) & 1) != 0) {
                    coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yr;
                                                                            coopMatLoad(yr, lds_x, (uint(m * (128 / 16) + n) * 256u + (nr_opaque * ( (80u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);
            for (int c = 0; c < 8; c += 2) {
                const uint off = pc.ars_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_project_acc[p][m][c] = float(residual.x);
                nr_project_acc[p][m][c + 1] = float(residual.y);
            }
        }
    }
    for (int k = 0; k < (128 / 16); ++ k) {
                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > ctx[ (64 / 16)];
        for (int m = 0; m < (64 / 16); ++ m)
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);
             coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                    { const uint q = (pc.op_off) / 4u + ( (uint(nrhw_h * ( (128 / 4) / 16))) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const fe4m3vec4 w0 = wexpand_pair4[q], w1 = wexpand_pair4[ (q) + 1u]; const fe4m3vec4 w2 = wexpand_pair4[ (q) + 2u], w3 = wexpand_pair4[ (q) + 3u]; for (int v = 0; v < 4; ++ v) { wf0[v] = w0[v]; wf0[v + 4] = w1[v]; wf1[v] = w2[v]; wf1[v + 4] = w3[v]; } } }
        for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (3) >> (m)) & 1) != 0) nr_project_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_project_acc[0][m]);
        for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (3) >> (m)) & 1) != 0) nr_project_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_project_acc[1][m]);
    }


    for (int nn = 0; nn < ( (128 / 4) / 16); ++ nn) {
        const int n = nrhw_h * ( (128 / 4) / 16) + nn;






                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yqr[ (64 / 16)];
        for (int m = 0; m < (64 / 16); ++ m)

                                                                   coopMatLoad(yqr[m], lds_x, (uint(m * (128 / 16) + n) * 256u + (nr_opaque * ( (80u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);




              coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > a[ (64 / 16)];
        for (int m = 0; m < (64 / 16); ++ m) a[m] = nr_project_acc[nn][m];
























































        for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (3) >> (m)) & 1) != 0) {




















































                       coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > of;
                 float16_t wide[8];

            float widef[8];













            for (int c = 0; c < 8; ++ c) {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            }
            for (int c = 0; c < 8; c += 2) {

                fe4m3vec2 q = nr_quant_pair32(vec2(widef[c], widef[c + 1]));



                of[c] = q.x; of[c + 1] = q.y;



            }






































































































































































































































































































            if (! nr_tile_oob( (tok0 + uint(m) * 16u) / 16u))


                                                  do { const uint nr_sa = ( (pc.o_off + nr_tile_base( (tok0 + uint(m) * 16u) / 16u) + uint(n) * 256u) + (gl_SubgroupInvocationID % 16u) * (16u) + (gl_SubgroupInvocationID / 16u) * 8u) / 8u; act_v8[nr_sa] = uvec2(nr_e4m3x4_bits(fe4m3vec4(of[0], of[1], of[2], of[3])), nr_e4m3x4_bits(fe4m3vec4(of[4], of[5], of[6], of[7]))); } while (false);






        }
    }










































































































#line 3282 "D:\nr-work-20261011\_mochi\DLSSNR-AMD-main\windows\shaders\rdna4\fswin_t.comp"

    }
    [[dont_flatten]] if (nr_body == 10u) {

#line 1 "D:/nr-work-20261011/_mochi/DLSSNR-AMD-main/windows/shaders/rdna4/include/fswin_body.glsl"





    const uint wbase = nr_wx * uint(64 * 128);

    const uint tok0 = 0u;
    const int nrhw_h = int(wave);









    const uint nr_opaque = gl_WorkGroupID.z;








    const uint rbase = 8u * (lane / 16u);































































    [[dont_flatten]] if (nr_ups_layer) {






            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > upsrc[2 * (128 / 16)];
    const uint ups_slot = lane % 16u;
    const uint ups_px = uint(clamp(4 * int(nr_wx) + 2 * pc.shift + int(ups_slot % 4u), 0, int(pc.blend_itiles_x * 4u) - 1));
    const uint ups_py = uint(clamp(4 * int(nr_wy) + 2 * pc.shift_y + int(ups_slot / 4u), 0, int(pc.blend_itiles_y * 4u) - 1));
    const uint ups_tile = (ups_py / 4u) * pc.blend_itiles_x + ups_px / 4u;
    const uint ups_in_slot = (ups_py % 4u) * 4u + ups_px % 4u;
























    for (int k = 0; k < 2 * (128 / 16); ++ k)
        for (int j = 0; j < 8; ++ j)






















            upsrc[k][j] = uintBitsToFloate4m3EXT(unpack8(act_v4[ (pc.blend_p_off + (ups_tile * uint(2 * (128 / 16)) + uint(k)) * 256u + ups_in_slot * 16u + rbase) / 4u + uint(j) / 4u])[ (j) % 4]);

    for (int n = 0; n < ( (128 / 4) / 16); ++ n) {
        const uint nf = uint(nrhw_h * ( (128 / 4) / 16) + n);
                  coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > acc = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0);
        for (int k = 0; k < 2 * (128 / 16); ++ k) {
                    coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > w;
                                                                                      coopMatLoad(w, wgt_e4m3, (pc.ups_weight_off + (nf * uint(2 * (128 / 16)) + uint(k)) * 256u), (16u), gl_CooperativeMatrixLayoutRowMajor);
                                 acc = coopMatMulAdd(w, upsrc[k], acc);
        }
                    coopmat < float16_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > half_result;
        for (int j = 0; j < 8; ++ j) half_result[j] = float16_t(acc[j]);
                                        coopMatStore(half_result, ups_projected, (nf * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);
    }

    barrier();

    }










    uint tbase[ (64 / 16)];
    for (int m = 0; m < (64 / 16); ++ m)

        tbase[m] = pc.x_off + nr_tile_base( (tok0 + uint(m) * 16u) / 16u);































    [[dont_flatten]] if (! nr_ups_layer) {
        for (int m = 0; m < (64 / 16); ++ m)
            for (int d = 0; d < ( (128 / 4) / 16); ++ d) {
                const uint k = uint(nrhw_h * ( (128 / 4) / 16) + d);
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > src;
                                                           do { const uint nr_la = ( (tbase[m] + k * 256u) + (gl_SubgroupInvocationID % 16u) * (16u) + (gl_SubgroupInvocationID / 16u) * 8u) / 4u; const u8vec4 nr_b0 = unpack8(act_v4[nr_la]), nr_b1 = unpack8(act_v4[nr_la + 1u]); for (int nr_i = 0; nr_i < 4; ++ nr_i) { src[nr_i] = uintBitsToFloate4m3EXT(nr_b0[nr_i]); src[nr_i + 4] = uintBitsToFloate4m3EXT(nr_b1[nr_i]); } } while (false);
                           coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > dst;
                for (int j = 0; j < 8; ++ j) dst[j] = src[j];
                if (nr_tile_oob(uint(m)))
                    for (int j = 0; j < 8; ++ j) dst[j] = floate4m3_t(0.0);
                                                                                            coopMatStore(dst, lds_x, ( (uint(m) * uint( (128 / 16)) + k) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);
            }
    } else

    for (int m = 0; m < (64 / 16); ++ m)
        for (int d = 0; d < ( (128 / 4) / 16); ++ d) {
            const uint k = uint(nrhw_h * ( (128 / 4) / 16) + d);
                    coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > src;

            const uint q = uint(m);
            const uint tx = uint(clamp(2 * int(nr_wx) + pc.shift + int(q & 1u), 0, int(pc.tiles_x) - 1));
            const uint ty = uint(clamp(2 * int(nr_wy) + pc.shift_y + int(q >> 1u), 0, int(pc.tiles_y) - 1));
            const uint slot = lane % 16u, dx = slot % 4u, dy = slot / 4u;
            const uint ipx = min( (4u * tx + dx) / 2u, pc.blend_itiles_x * 4u - 1u);
            const uint ipy = min( (4u * ty + dy) / 2u, pc.blend_itiles_y * 4u - 1u);
            const uint itile = (ipy / 4u) * pc.blend_itiles_x + ipx / 4u;
            const uint islot = (ipy % 4u) * 4u + ipx % 4u;
            const uint stw = pc.blend_stiles_x != 0u ? pc.blend_stiles_x : pc.blend_tiles_x;
            const uint stile = ty * stw + tx;




            {
                const uint saddr = pc.blend_s_off + (stile * uint( (128 / 16)) + k) * 256u + slot * 16u + rbase;
                const fe4m3vec4 sv4[2] = { nr_blend_x4(saddr / 4u), nr_blend_x4(saddr / 4u + 1u) };
                const uint local_slot = ( (q >> 1u) * 2u + dy / 2u) * 4u + (q & 1u) * 2u + dx / 2u;
                for (int j = 0; j < 8; j += 2) {
                    const uint ch = k * 16u + rbase + uint(j);
                    const uint pb = k * 256u + local_slot * 16u + rbase + uint(j);
                    const f16vec2 pv2 = unpackFloat2x16(ups_u32[ (pb) >> 1u]);
                    const f16vec2 sv2 = unpackFloat2x16(packHalf2x16(nr_e4f2_pick(vec4(sv4[j / 4]), j % 4)));

                    const f16vec2 g2 = unpackFloat2x16(wgt_u32[ (pc.blend_g_off + ch) >> 1u]);



                    const fe4m3vec2 qv = nr_quant_pair(fma(sv2, g2, pv2));
                    src[j] = qv.x; src[j + 1] = qv.y;
                }
            }
            if (false)

            {
                 float16_t blend_h[8];
            for (int j = 0; j < 8; ++ j) {
                const uint ch = k * 16u + rbase + uint(j);

                const uint local_slot = ( (q >> 1u) * 2u + dy / 2u) * 4u + (q & 1u) * 2u + dx / 2u;
                     float16_t pv = unpackFloat2x16(ups_u32[ (k * 256u + local_slot * 16u + rbase + uint(j)) >> 1u])[ (k * 256u + local_slot * 16u + rbase + uint(j)) & 1u];



                     float16_t sv = float16_t(uintBitsToFloate4m3EXT(unpack8(act_v4[ (pc.blend_s_off + (stile * uint( (128 / 16)) + k) * 256u + slot * 16u + rbase) / 4u + uint(j) / 4u])[ (j) % 4]));
                     float16_t sp = float16_t(sv * wgt_f16[pc.blend_g_off + ch]);

                blend_h[j] = float16_t(pv + sp);
            }

            for (int j = 0; j < 8; j += 4) {
                const fe4m3vec4 q4 = nr_quant4_h(f16vec4(blend_h[j], blend_h[j + 1], blend_h[j + 2], blend_h[j + 3]));
                src[j] = q4.x; src[j + 1] = q4.y; src[j + 2] = q4.z; src[j + 3] = q4.w;
            }
            }



                       coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > dst;
            for (int j = 0; j < 8; ++ j) dst[j] = src[j];


            if (nr_tile_oob(uint(m)))
                for (int j = 0; j < 8; ++ j) dst[j] = floate4m3_t(0.0);

                                                                                        coopMatStore(dst, lds_x, ( (uint(m) * uint( (128 / 16)) + k) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);
        }
    barrier();
































































































































































































    {
        const int g = nrhw_h;




                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > eqg[ (64 / 16)][ ( ( (4 * 128) / 4) / 16)];













































































































        for (int h = 0; h < ( ( (4 * 128) / 4) / 16); h += 2) {
                  coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > a[2][ (64 / 16)];
            for (int p = 0; p < 2; ++ p)
                for (int m = 0; m < (64 / 16); ++ m) a[p][m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0);
            for (int k = 0; k < (128 / 16); ++ k) {
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > xbk[ (64 / 16)];
                for (int m = 0; m < (64 / 16); ++ m)

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);




                for (int p = 0; p < 2; p += 2) {
                    const uint q = pc.e_off / 4u + uint( (g * ( ( (4 * 128) / 4) / 16) + h + p) / 2) * uint( (128 / 16)) * 128u
                        + uint(k) * 128u + lane * 4u;
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                    { { const fe4m3vec4 w0 = wexpand_pair4[q], w1 = wexpand_pair4[ (q) + 1u]; const fe4m3vec4 w2 = wexpand_pair4[ (q) + 2u], w3 = wexpand_pair4[ (q) + 3u]; for (int v = 0; v < 4; ++ v) { wf0[v] = w0[v]; wf0[v + 4] = w1[v]; wf1[v] = w2[v]; wf1[v + 4] = w3[v]; } } }
                    for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (10) >> (m)) & 1) != 0) a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]);
                    for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (10) >> (m)) & 1) != 0) a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]);
                }









                if (0 > 0 && (k + 1) % 0 == 0)
                    for (int p = 0; p < 2; ++ p)
                        for (int m = 0; m < (64 / 16); ++ m) { }
            }
            for (int p = 0; p < 2; ++ p)
            for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (10) >> (m)) & 1) != 0)






                for (int c = 0; c < 8; c += 2) {
                    const fe4m3vec2 qp = nr_quant_pair32(vec2(
                                             nr_act_pick(a[p][m][c], c), nr_act_pick(a[p][m][c + 1], c + 1)));
                    eqg[m][h + p][c] = qp.x;
                    eqg[m][h + p][c + 1] = qp.y;
                }































        }





































































              coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > nr_mid_acc[ ( (128 / 4) / 16)][ (64 / 16)];
        for (int n = 0; n < ( (128 / 4) / 16); ++ n) for (int m = 0; m < (64 / 16); ++ m) nr_mid_acc[n][m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0);
        for (int k = 0; k < ( ( (4 * 128) / 4) / 16); ++ k) {
                 coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                    { const uint q = (pc.mid_off) / 4u + ( (uint(g * ( (128 / 4) / 16))) / 2u) * (uint( ( ( (4 * 128) / 4) / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const fe4m3vec4 w0 = wexpand_pair4[q], w1 = wexpand_pair4[ (q) + 1u]; const fe4m3vec4 w2 = wexpand_pair4[ (q) + 2u], w3 = wexpand_pair4[ (q) + 3u]; for (int v = 0; v < 4; ++ v) { wf0[v] = w0[v]; wf0[v + 4] = w1[v]; wf1[v] = w2[v]; wf1[v + 4] = w3[v]; } } }
            for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (10) >> (m)) & 1) != 0) nr_mid_acc[0][m] = coopMatMulAdd(wf0, eqg[m][k], nr_mid_acc[0][m]);
            for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (10) >> (m)) & 1) != 0) nr_mid_acc[1][m] = coopMatMulAdd(wf1, eqg[m][k], nr_mid_acc[1][m]);
        }




        for (int n = 0; n < ( (128 / 4) / 16); ++ n) {
            const int nf = g * ( (128 / 4) / 16) + n;

                       coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > mqf[ (64 / 16)];





                  coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > a[ (64 / 16)];
            for (int m = 0; m < (64 / 16); ++ m) a[m] = nr_mid_acc[n][m];













            for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (10) >> (m)) & 1) != 0)







                for (int c = 0; c < 8; c += 2) {
                    fe4m3vec2 qp = nr_quant_pair(f16vec2(
                             float16_t(a[m][c]),
                             float16_t(a[m][c + 1])));
                               mqf[m][c] = qp.x;
                               mqf[m][c + 1] = qp.y;
                }




            for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (10) >> (m)) & 1) != 0)
                                                                                        coopMatStore(mqf[m], lds_y, (uint(m * (128 / 16) + nf) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);

        }
    }

    barrier();


















































































































































































          coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > nr_contract_acc[ ( (128 / 4) / 16)][ (64 / 16)];
    for (int p = 0; p < ( (128 / 4) / 16); ++ p) {
        const int n = nrhw_h * ( (128 / 4) / 16) + p;
        for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (10) >> (m)) & 1) != 0) {
                    coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yr;
                                                                            coopMatLoad(yr, lds_x, (uint(m * (128 / 16) + n) * 256u + (nr_opaque * ( (80u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);
            for (int c = 0; c < 8; c += 2) {
                const uint off = pc.rs_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_contract_acc[p][m][c] = float(residual.x);
                nr_contract_acc[p][m][c + 1] = float(residual.y);
            }
        }
    }
    for (int k = 0; k < (128 / 16); ++ k) {
                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > ctx[ (64 / 16)];
        for (int m = 0; m < (64 / 16); ++ m)
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);
             coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                    { const uint q = (pc.ct_off) / 4u + ( (uint(nrhw_h * ( (128 / 4) / 16))) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const fe4m3vec4 w0 = wexpand_pair4[q], w1 = wexpand_pair4[ (q) + 1u]; const fe4m3vec4 w2 = wexpand_pair4[ (q) + 2u], w3 = wexpand_pair4[ (q) + 3u]; for (int v = 0; v < 4; ++ v) { wf0[v] = w0[v]; wf0[v + 4] = w1[v]; wf1[v] = w2[v]; wf1[v + 4] = w3[v]; } } }
        for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (10) >> (m)) & 1) != 0) nr_contract_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_contract_acc[0][m]);
        for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (10) >> (m)) & 1) != 0) nr_contract_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_contract_acc[1][m]);
    }


    for (int nn = 0; nn < ( (128 / 4) / 16); ++ nn) {
        const int n = nrhw_h * ( (128 / 4) / 16) + nn;


                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > xbk[ (64 / 16)];
        for (int m = 0; m < (64 / 16); ++ m)

                                                                   coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + n) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);



                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yqw[ (64 / 16)];







              coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > a[ (64 / 16)];
        for (int m = 0; m < (64 / 16); ++ m) a[m] = nr_contract_acc[nn][m];







































































        for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (10) >> (m)) & 1) != 0) {

            float requantized[8];






















            for (int c = 0; c < 8; ++ c) {

                const float v = a[m][c];












                requantized[c] = v;










            }


            for (int c = 0; c < 8; c += 2) {

                         fe4m3vec2 q = nr_quant_pair32(vec2(requantized[c], requantized[c + 1]));



                          yqw[m][c] = q.x; yqw[m][c + 1] = q.y;



            }
        }





        for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (10) >> (m)) & 1) != 0) {
                       coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > yf;
            for (int c = 0; c < 8; ++ c) yf[c] = yqw[m][c];
                                                                               coopMatStore(yf, lds_x, (uint(m * (128 / 16) + n) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);
        }

    }

    barrier();































    {
        const int hh = nrhw_h;





                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > kreg[ (64 / 16)][ ( (128 / 4) / 16)];




        const float16_t hscale = float16_t(wgt_f32[pc.s_off + uint(hh)]);
                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > qb[ (64 / 16)][ ( (128 / 4) / 16)];
























        {










                  coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > acc[ (64 / 16)][ ( (1 + 1) * ( (128 / 4) / 16))];

            for (int m = 0; m < (64 / 16); ++ m)
                for (int d = 0; d < ( (1 + 1) * ( (128 / 4) / 16)); ++ d) acc[m][d] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0);
            for (int k = 0; k < (128 / 16); ++ k) {
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yk[ (64 / 16)];
                for (int m = 0; m < (64 / 16); ++ m)

                                                                            coopMatLoad(yk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (128u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);




                for (int r = 0; r < ( (1 + 1) * ( (128 / 4) / 16)); r += 2) {
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                                  { const uint q = (pc.qkv_off) / 4u + ( (uint(hh * 3 * ( (128 / 4) / 16) + 0 + r)) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const fe4m3vec4 w0 = wexpand_pair4[q], w1 = wexpand_pair4[ (q) + 1u]; const fe4m3vec4 w2 = wexpand_pair4[ (q) + 2u], w3 = wexpand_pair4[ (q) + 3u]; for (int v = 0; v < 4; ++ v) { wf0[v] = w0[v]; wf0[v + 4] = w1[v]; wf1[v] = w2[v]; wf1[v + 4] = w3[v]; } } }
                    for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (10) >> (m)) & 1) != 0) acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]);
                    for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (10) >> (m)) & 1) != 0) acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]);
                }







                if (0 > 0 && (k + 1) % 0 == 0)
                    for (int m = 0; m < (64 / 16); ++ m)
                        for (int r = 0; r < ( (1 + 1) * ( (128 / 4) / 16)); ++ r) { }

            }
            for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (10) >> (m)) & 1) != 0) {

                float sqp[4];
                for (int i = 0; i < 4; ++ i) sqp[i] = 0.0;
                for (int c = 0; c < 8; ++ c)
                    for (int d = 0; d < ( (128 / 4) / 16); ++ d) {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    }








                f16vec2 sq = f16vec2(vec2( (sqp[0] + sqp[1]) + (sqp[2] + sqp[3]), 0.0));
                sq = sq + unpackFloat2x16(subgroupShuffleXor(packFloat2x16(sq), 16u));
                const float16_t nq =
                                    float16_t(inversesqrt(float(max( (sq.x), float16_t(0.000062)))));





































                for (int d = 0; d < ( (128 / 4) / 16); ++ d)
                    for (int c = 0; c < 8; c += 2) {

                        fe4m3vec2 qp = nr_qscale_fast(vec2(acc[m][d][c], acc[m][d][c + 1]), nq, hscale);





                        qb[m][d][c] = qp.x;
                        qb[m][d][c + 1] = qp.y;
                    }
            }






















            for (int m = 0; m < (64 / 16); ++ m) {

                float skp[4];
                for (int i = 0; i < 4; ++ i) skp[i] = 0.0;
                for (int c = 0; c < 8; ++ c)
                    for (int d = 0; d < ( (128 / 4) / 16); ++ d) {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    }





                f16vec2 sk = f16vec2(vec2( (skp[0] + skp[1]) + (skp[2] + skp[3]), 0.0));
                sk = sk + unpackFloat2x16(subgroupShuffleXor(packFloat2x16(sk), 16u));
                const float16_t nk =
                                    float16_t(inversesqrt(float(max( (sk.x), float16_t(0.000062)))));























                for (int d = 0; d < ( (128 / 4) / 16); ++ d) {
                               coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > kf;
                    for (int c = 0; c < 8; c += 2) {

                        fe4m3vec2 qp = nr_kscale_fast(vec2(acc[m][d + 1 * ( (128 / 4) / 16)][c],
                            acc[m][d + 1 * ( (128 / 4) / 16)][c + 1]), nk);





                        kf[c] = qp.x;
                        kf[c + 1] = qp.y;
                    }


                    for (int c = 0; c < 8; ++ c) kreg[m][d][c] = kf[c];
                }
            }
































            for (int m = 0; m < (64 / 16); ++ m)
                for (int d = 0; d < ( (128 / 4) / 16); ++ d) acc[m][d] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0);
            for (int k = 0; k < (128 / 16); ++ k) {



















                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yk[ (64 / 16)];
                for (int m = 0; m < (64 / 16); ++ m)

                                                                            coopMatLoad(yk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (130u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);




                for (int r = 0; r < ( (128 / 4) / 16); r += 2) {
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                                         { const uint q = (pc.qkv_off) / 4u + ( (uint(hh * 3 * ( (128 / 4) / 16) + 2 * ( (128 / 4) / 16) + r)) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const fe4m3vec4 w0 = wexpand_pair4[q], w1 = wexpand_pair4[ (q) + 1u]; const fe4m3vec4 w2 = wexpand_pair4[ (q) + 2u], w3 = wexpand_pair4[ (q) + 3u]; for (int v = 0; v < 4; ++ v) { wf0[v] = w0[v]; wf0[v + 4] = w1[v]; wf1[v] = w2[v]; wf1[v + 4] = w3[v]; } } }
                    for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (10) >> (m)) & 1) != 0) acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]);
                    for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (10) >> (m)) & 1) != 0) acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]);
                }











                if (0 > 0 && (k + 1) % 0 == 0)
                    for (int m = 0; m < (64 / 16); ++ m)
                        for (int r = 0; r < ( (128 / 4) / 16); ++ r) { }

            }











            for (int m = 0; m < (64 / 16); ++ m)
                for (int d = 0; d < ( (128 / 4) / 16); ++ d) {
                               coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > vf;
                    for (int c = 0; c < 8; c += 2) {
                        fe4m3vec2 qp = nr_quant_pair(

                                            f16vec2(float16_t(acc[m][d][c]), float16_t(acc[m][d][c + 1])));
                        vf[c] = qp.x;
                        vf[c + 1] = qp.y;
                    }





                                                                                 coopMatStore(vf, lds_y, (uint(m * (128 / 16) + hh * ( (128 / 4) / 16) + d) * 256u), (16u), gl_CooperativeMatrixLayoutRowMajor);
                }


        }













































































































































































































































































































             coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > pb[ (64 / 16)][ (64 / 16)];
        for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (10) >> (m)) & 1) != 0) {
            f16vec2 pq2[ (64 / 16)][4];
                  coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > lg[ (64 / 16)];



            for (int j = 0; j < (64 / 16); ++ j) lg[j] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0);


            for (int d = 0; d < ( (128 / 4) / 16); ++ d)
                for (int j = 0; j < (64 / 16); ++ j) {
                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > kf = kreg[j][d];
                                              lg[j] = coopMatMulAdd(kf, qb[m][d], lg[j]);
                }
            for (int j = 0; j < (64 / 16); ++ j) {
















                          coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > bf;



                                            coopMatLoad(bf, wgt_f32, (pc.b_off + uint(hh) * uint(64 * 64) + (tok0 + uint(m) * 16u) * uint(64) + uint(j) * 16u), (uint(64)), gl_CooperativeMatrixLayoutColumnMajor);


                for (int c = 0; c < 8; c += 2)
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1]));



            }
                 float16_t sum = nr_swin_probability_sum(pq2);


            float inv = float(float16_t(1.0 / float(max(sum, float16_t(6.103515625e-05)))));
            for (int j = 0; j < (64 / 16); ++ j)
                for (int c = 0; c < 4; ++ c) {
                    float x = float(pq2[j][c].x) * inv;
                    float y = float(pq2[j][c].y) * inv;










                    fe4m3vec2 q = fe4m3vec2(pq2[j][c] * f16vec2(float16_t(inv)));





                    pb[m][j][2 * c] = q.x;
                    pb[m][j][2 * c + 1] = q.y;
                }
        }
























































































































































































        for (int e = 0; e < ( (128 / 4) / 16); ++ e) {
                  coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > a[ (64 / 16)];
            for (int m = 0; m < (64 / 16); ++ m) a[m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0);
            for (int j = 0; j < (64 / 16); ++ j) {
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > vf;





                                                 coopMatLoad(vf, lds_y, (uint(j * (128 / 16) + hh * ( (128 / 4) / 16) + e) * 256u + (nr_opaque * ( (192u) * 16u))), (16u), gl_CooperativeMatrixLayoutRowMajor);




                for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (10) >> (m)) & 1) != 0) a[m] = coopMatMulAdd(vf, pb[m][j], a[m]);
                if (0 > 0 && (j + 1) % 0 == 0)
                    for (int m = 0; m < (64 / 16); ++ m) { }
            }
            for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (10) >> (m)) & 1) != 0) {

                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > out_context;





                for (int c = 0; c < 8; c += 2) {
                             fe4m3vec2 qp = nr_quant_pair(f16vec2(float16_t(a[m][c]), float16_t(a[m][c + 1])));
                    out_context[c] = qp.x;
                    out_context[c + 1] = qp.y;
                }








                                                                             coopMatStore(out_context, lds_y, (uint(m * (128 / 16) + hh * ( (128 / 4) / 16) + e) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);




















            }
        }


        barrier();

    }













































































          coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > nr_project_acc[ ( (128 / 4) / 16)][ (64 / 16)];
    for (int p = 0; p < ( (128 / 4) / 16); ++ p) {
        const int n = nrhw_h * ( (128 / 4) / 16) + p;
        for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (10) >> (m)) & 1) != 0) {
                    coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yr;
                                                                            coopMatLoad(yr, lds_x, (uint(m * (128 / 16) + n) * 256u + (nr_opaque * ( (80u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);
            for (int c = 0; c < 8; c += 2) {
                const uint off = pc.ars_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_project_acc[p][m][c] = float(residual.x);
                nr_project_acc[p][m][c + 1] = float(residual.y);
            }
        }
    }
    for (int k = 0; k < (128 / 16); ++ k) {
                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > ctx[ (64 / 16)];
        for (int m = 0; m < (64 / 16); ++ m)
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);
             coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                    { const uint q = (pc.op_off) / 4u + ( (uint(nrhw_h * ( (128 / 4) / 16))) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const fe4m3vec4 w0 = wexpand_pair4[q], w1 = wexpand_pair4[ (q) + 1u]; const fe4m3vec4 w2 = wexpand_pair4[ (q) + 2u], w3 = wexpand_pair4[ (q) + 3u]; for (int v = 0; v < 4; ++ v) { wf0[v] = w0[v]; wf0[v + 4] = w1[v]; wf1[v] = w2[v]; wf1[v + 4] = w3[v]; } } }
        for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (10) >> (m)) & 1) != 0) nr_project_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_project_acc[0][m]);
        for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (10) >> (m)) & 1) != 0) nr_project_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_project_acc[1][m]);
    }


    for (int nn = 0; nn < ( (128 / 4) / 16); ++ nn) {
        const int n = nrhw_h * ( (128 / 4) / 16) + nn;






                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yqr[ (64 / 16)];
        for (int m = 0; m < (64 / 16); ++ m)

                                                                   coopMatLoad(yqr[m], lds_x, (uint(m * (128 / 16) + n) * 256u + (nr_opaque * ( (80u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);




              coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > a[ (64 / 16)];
        for (int m = 0; m < (64 / 16); ++ m) a[m] = nr_project_acc[nn][m];
























































        for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (10) >> (m)) & 1) != 0) {




















































                       coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > of;
                 float16_t wide[8];

            float widef[8];













            for (int c = 0; c < 8; ++ c) {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            }
            for (int c = 0; c < 8; c += 2) {

                fe4m3vec2 q = nr_quant_pair32(vec2(widef[c], widef[c + 1]));



                of[c] = q.x; of[c + 1] = q.y;



            }






































































































































































































































































































            if (! nr_tile_oob( (tok0 + uint(m) * 16u) / 16u))


                                                  do { const uint nr_sa = ( (pc.o_off + nr_tile_base( (tok0 + uint(m) * 16u) / 16u) + uint(n) * 256u) + (gl_SubgroupInvocationID % 16u) * (16u) + (gl_SubgroupInvocationID / 16u) * 8u) / 8u; act_v8[nr_sa] = uvec2(nr_e4m3x4_bits(fe4m3vec4(of[0], of[1], of[2], of[3])), nr_e4m3x4_bits(fe4m3vec4(of[4], of[5], of[6], of[7]))); } while (false);






        }
    }










































































































#line 3287 "D:\nr-work-20261011\_mochi\DLSSNR-AMD-main\windows\shaders\rdna4\fswin_t.comp"

    }
    [[dont_flatten]] if (nr_body == 5u) {

#line 1 "D:/nr-work-20261011/_mochi/DLSSNR-AMD-main/windows/shaders/rdna4/include/fswin_body.glsl"





    const uint wbase = nr_wx * uint(64 * 128);

    const uint tok0 = 0u;
    const int nrhw_h = int(wave);









    const uint nr_opaque = gl_WorkGroupID.z;








    const uint rbase = 8u * (lane / 16u);































































    [[dont_flatten]] if (nr_ups_layer) {






            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > upsrc[2 * (128 / 16)];
    const uint ups_slot = lane % 16u;
    const uint ups_px = uint(clamp(4 * int(nr_wx) + 2 * pc.shift + int(ups_slot % 4u), 0, int(pc.blend_itiles_x * 4u) - 1));
    const uint ups_py = uint(clamp(4 * int(nr_wy) + 2 * pc.shift_y + int(ups_slot / 4u), 0, int(pc.blend_itiles_y * 4u) - 1));
    const uint ups_tile = (ups_py / 4u) * pc.blend_itiles_x + ups_px / 4u;
    const uint ups_in_slot = (ups_py % 4u) * 4u + ups_px % 4u;
























    for (int k = 0; k < 2 * (128 / 16); ++ k)
        for (int j = 0; j < 8; ++ j)






















            upsrc[k][j] = uintBitsToFloate4m3EXT(unpack8(act_v4[ (pc.blend_p_off + (ups_tile * uint(2 * (128 / 16)) + uint(k)) * 256u + ups_in_slot * 16u + rbase) / 4u + uint(j) / 4u])[ (j) % 4]);

    for (int n = 0; n < ( (128 / 4) / 16); ++ n) {
        const uint nf = uint(nrhw_h * ( (128 / 4) / 16) + n);
                  coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > acc = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0);
        for (int k = 0; k < 2 * (128 / 16); ++ k) {
                    coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > w;
                                                                                      coopMatLoad(w, wgt_e4m3, (pc.ups_weight_off + (nf * uint(2 * (128 / 16)) + uint(k)) * 256u), (16u), gl_CooperativeMatrixLayoutRowMajor);
                                 acc = coopMatMulAdd(w, upsrc[k], acc);
        }
                    coopmat < float16_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > half_result;
        for (int j = 0; j < 8; ++ j) half_result[j] = float16_t(acc[j]);
                                        coopMatStore(half_result, ups_projected, (nf * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);
    }

    barrier();

    }










    uint tbase[ (64 / 16)];
    for (int m = 0; m < (64 / 16); ++ m)

        tbase[m] = pc.x_off + nr_tile_base( (tok0 + uint(m) * 16u) / 16u);































    [[dont_flatten]] if (! nr_ups_layer) {
        for (int m = 0; m < (64 / 16); ++ m)
            for (int d = 0; d < ( (128 / 4) / 16); ++ d) {
                const uint k = uint(nrhw_h * ( (128 / 4) / 16) + d);
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > src;
                                                           do { const uint nr_la = ( (tbase[m] + k * 256u) + (gl_SubgroupInvocationID % 16u) * (16u) + (gl_SubgroupInvocationID / 16u) * 8u) / 4u; const u8vec4 nr_b0 = unpack8(act_v4[nr_la]), nr_b1 = unpack8(act_v4[nr_la + 1u]); for (int nr_i = 0; nr_i < 4; ++ nr_i) { src[nr_i] = uintBitsToFloate4m3EXT(nr_b0[nr_i]); src[nr_i + 4] = uintBitsToFloate4m3EXT(nr_b1[nr_i]); } } while (false);
                           coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > dst;
                for (int j = 0; j < 8; ++ j) dst[j] = src[j];
                if (nr_tile_oob(uint(m)))
                    for (int j = 0; j < 8; ++ j) dst[j] = floate4m3_t(0.0);
                                                                                            coopMatStore(dst, lds_x, ( (uint(m) * uint( (128 / 16)) + k) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);
            }
    } else

    for (int m = 0; m < (64 / 16); ++ m)
        for (int d = 0; d < ( (128 / 4) / 16); ++ d) {
            const uint k = uint(nrhw_h * ( (128 / 4) / 16) + d);
                    coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > src;

            const uint q = uint(m);
            const uint tx = uint(clamp(2 * int(nr_wx) + pc.shift + int(q & 1u), 0, int(pc.tiles_x) - 1));
            const uint ty = uint(clamp(2 * int(nr_wy) + pc.shift_y + int(q >> 1u), 0, int(pc.tiles_y) - 1));
            const uint slot = lane % 16u, dx = slot % 4u, dy = slot / 4u;
            const uint ipx = min( (4u * tx + dx) / 2u, pc.blend_itiles_x * 4u - 1u);
            const uint ipy = min( (4u * ty + dy) / 2u, pc.blend_itiles_y * 4u - 1u);
            const uint itile = (ipy / 4u) * pc.blend_itiles_x + ipx / 4u;
            const uint islot = (ipy % 4u) * 4u + ipx % 4u;
            const uint stw = pc.blend_stiles_x != 0u ? pc.blend_stiles_x : pc.blend_tiles_x;
            const uint stile = ty * stw + tx;




            {
                const uint saddr = pc.blend_s_off + (stile * uint( (128 / 16)) + k) * 256u + slot * 16u + rbase;
                const fe4m3vec4 sv4[2] = { nr_blend_x4(saddr / 4u), nr_blend_x4(saddr / 4u + 1u) };
                const uint local_slot = ( (q >> 1u) * 2u + dy / 2u) * 4u + (q & 1u) * 2u + dx / 2u;
                for (int j = 0; j < 8; j += 2) {
                    const uint ch = k * 16u + rbase + uint(j);
                    const uint pb = k * 256u + local_slot * 16u + rbase + uint(j);
                    const f16vec2 pv2 = unpackFloat2x16(ups_u32[ (pb) >> 1u]);
                    const f16vec2 sv2 = unpackFloat2x16(packHalf2x16(nr_e4f2_pick(vec4(sv4[j / 4]), j % 4)));

                    const f16vec2 g2 = unpackFloat2x16(wgt_u32[ (pc.blend_g_off + ch) >> 1u]);



                    const fe4m3vec2 qv = nr_quant_pair(fma(sv2, g2, pv2));
                    src[j] = qv.x; src[j + 1] = qv.y;
                }
            }
            if (false)

            {
                 float16_t blend_h[8];
            for (int j = 0; j < 8; ++ j) {
                const uint ch = k * 16u + rbase + uint(j);

                const uint local_slot = ( (q >> 1u) * 2u + dy / 2u) * 4u + (q & 1u) * 2u + dx / 2u;
                     float16_t pv = unpackFloat2x16(ups_u32[ (k * 256u + local_slot * 16u + rbase + uint(j)) >> 1u])[ (k * 256u + local_slot * 16u + rbase + uint(j)) & 1u];



                     float16_t sv = float16_t(uintBitsToFloate4m3EXT(unpack8(act_v4[ (pc.blend_s_off + (stile * uint( (128 / 16)) + k) * 256u + slot * 16u + rbase) / 4u + uint(j) / 4u])[ (j) % 4]));
                     float16_t sp = float16_t(sv * wgt_f16[pc.blend_g_off + ch]);

                blend_h[j] = float16_t(pv + sp);
            }

            for (int j = 0; j < 8; j += 4) {
                const fe4m3vec4 q4 = nr_quant4_h(f16vec4(blend_h[j], blend_h[j + 1], blend_h[j + 2], blend_h[j + 3]));
                src[j] = q4.x; src[j + 1] = q4.y; src[j + 2] = q4.z; src[j + 3] = q4.w;
            }
            }



                       coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > dst;
            for (int j = 0; j < 8; ++ j) dst[j] = src[j];


            if (nr_tile_oob(uint(m)))
                for (int j = 0; j < 8; ++ j) dst[j] = floate4m3_t(0.0);

                                                                                        coopMatStore(dst, lds_x, ( (uint(m) * uint( (128 / 16)) + k) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);
        }
    barrier();
































































































































































































    {
        const int g = nrhw_h;




                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > eqg[ (64 / 16)][ ( ( (4 * 128) / 4) / 16)];













































































































        for (int h = 0; h < ( ( (4 * 128) / 4) / 16); h += 2) {
                  coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > a[2][ (64 / 16)];
            for (int p = 0; p < 2; ++ p)
                for (int m = 0; m < (64 / 16); ++ m) a[p][m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0);
            for (int k = 0; k < (128 / 16); ++ k) {
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > xbk[ (64 / 16)];
                for (int m = 0; m < (64 / 16); ++ m)

                                                                                    coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (1u + uint(h)) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);




                for (int p = 0; p < 2; p += 2) {
                    const uint q = pc.e_off / 4u + uint( (g * ( ( (4 * 128) / 4) / 16) + h + p) / 2) * uint( (128 / 16)) * 128u
                        + uint(k) * 128u + lane * 4u;
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                    { { const fe4m3vec4 w0 = wexpand_pair4[q], w1 = wexpand_pair4[ (q) + 1u]; const fe4m3vec4 w2 = wexpand_pair4[ (q) + 2u], w3 = wexpand_pair4[ (q) + 3u]; for (int v = 0; v < 4; ++ v) { wf0[v] = w0[v]; wf0[v + 4] = w1[v]; wf1[v] = w2[v]; wf1[v + 4] = w3[v]; } } }
                    for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (5) >> (m)) & 1) != 0) a[p][m] = coopMatMulAdd(wf0, xbk[m], a[p][m]);
                    for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (5) >> (m)) & 1) != 0) a[p + 1][m] = coopMatMulAdd(wf1, xbk[m], a[p + 1][m]);
                }









                if (0 > 0 && (k + 1) % 0 == 0)
                    for (int p = 0; p < 2; ++ p)
                        for (int m = 0; m < (64 / 16); ++ m) { }
            }
            for (int p = 0; p < 2; ++ p)
            for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (5) >> (m)) & 1) != 0)






                for (int c = 0; c < 8; c += 2) {
                    const fe4m3vec2 qp = nr_quant_pair32(vec2(
                                             nr_act_pick(a[p][m][c], c), nr_act_pick(a[p][m][c + 1], c + 1)));
                    eqg[m][h + p][c] = qp.x;
                    eqg[m][h + p][c + 1] = qp.y;
                }































        }





































































              coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > nr_mid_acc[ ( (128 / 4) / 16)][ (64 / 16)];
        for (int n = 0; n < ( (128 / 4) / 16); ++ n) for (int m = 0; m < (64 / 16); ++ m) nr_mid_acc[n][m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0);
        for (int k = 0; k < ( ( (4 * 128) / 4) / 16); ++ k) {
                 coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                    { const uint q = (pc.mid_off) / 4u + ( (uint(g * ( (128 / 4) / 16))) / 2u) * (uint( ( ( (4 * 128) / 4) / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const fe4m3vec4 w0 = wexpand_pair4[q], w1 = wexpand_pair4[ (q) + 1u]; const fe4m3vec4 w2 = wexpand_pair4[ (q) + 2u], w3 = wexpand_pair4[ (q) + 3u]; for (int v = 0; v < 4; ++ v) { wf0[v] = w0[v]; wf0[v + 4] = w1[v]; wf1[v] = w2[v]; wf1[v + 4] = w3[v]; } } }
            for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (5) >> (m)) & 1) != 0) nr_mid_acc[0][m] = coopMatMulAdd(wf0, eqg[m][k], nr_mid_acc[0][m]);
            for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (5) >> (m)) & 1) != 0) nr_mid_acc[1][m] = coopMatMulAdd(wf1, eqg[m][k], nr_mid_acc[1][m]);
        }




        for (int n = 0; n < ( (128 / 4) / 16); ++ n) {
            const int nf = g * ( (128 / 4) / 16) + n;

                       coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > mqf[ (64 / 16)];





                  coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > a[ (64 / 16)];
            for (int m = 0; m < (64 / 16); ++ m) a[m] = nr_mid_acc[n][m];













            for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (5) >> (m)) & 1) != 0)







                for (int c = 0; c < 8; c += 2) {
                    fe4m3vec2 qp = nr_quant_pair(f16vec2(
                             float16_t(a[m][c]),
                             float16_t(a[m][c + 1])));
                               mqf[m][c] = qp.x;
                               mqf[m][c + 1] = qp.y;
                }




            for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (5) >> (m)) & 1) != 0)
                                                                                        coopMatStore(mqf[m], lds_y, (uint(m * (128 / 16) + nf) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);

        }
    }

    barrier();


















































































































































































          coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > nr_contract_acc[ ( (128 / 4) / 16)][ (64 / 16)];
    for (int p = 0; p < ( (128 / 4) / 16); ++ p) {
        const int n = nrhw_h * ( (128 / 4) / 16) + p;
        for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (5) >> (m)) & 1) != 0) {
                    coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yr;
                                                                            coopMatLoad(yr, lds_x, (uint(m * (128 / 16) + n) * 256u + (nr_opaque * ( (80u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);
            for (int c = 0; c < 8; c += 2) {
                const uint off = pc.rs_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_contract_acc[p][m][c] = float(residual.x);
                nr_contract_acc[p][m][c + 1] = float(residual.y);
            }
        }
    }
    for (int k = 0; k < (128 / 16); ++ k) {
                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > ctx[ (64 / 16)];
        for (int m = 0; m < (64 / 16); ++ m)
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);
             coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                    { const uint q = (pc.ct_off) / 4u + ( (uint(nrhw_h * ( (128 / 4) / 16))) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const fe4m3vec4 w0 = wexpand_pair4[q], w1 = wexpand_pair4[ (q) + 1u]; const fe4m3vec4 w2 = wexpand_pair4[ (q) + 2u], w3 = wexpand_pair4[ (q) + 3u]; for (int v = 0; v < 4; ++ v) { wf0[v] = w0[v]; wf0[v + 4] = w1[v]; wf1[v] = w2[v]; wf1[v + 4] = w3[v]; } } }
        for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (5) >> (m)) & 1) != 0) nr_contract_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_contract_acc[0][m]);
        for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (5) >> (m)) & 1) != 0) nr_contract_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_contract_acc[1][m]);
    }


    for (int nn = 0; nn < ( (128 / 4) / 16); ++ nn) {
        const int n = nrhw_h * ( (128 / 4) / 16) + nn;


                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > xbk[ (64 / 16)];
        for (int m = 0; m < (64 / 16); ++ m)

                                                                   coopMatLoad(xbk[m], lds_x, (uint(m * (128 / 16) + n) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);



                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yqw[ (64 / 16)];







              coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > a[ (64 / 16)];
        for (int m = 0; m < (64 / 16); ++ m) a[m] = nr_contract_acc[nn][m];







































































        for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (5) >> (m)) & 1) != 0) {

            float requantized[8];






















            for (int c = 0; c < 8; ++ c) {

                const float v = a[m][c];












                requantized[c] = v;










            }


            for (int c = 0; c < 8; c += 2) {

                         fe4m3vec2 q = nr_quant_pair32(vec2(requantized[c], requantized[c + 1]));



                          yqw[m][c] = q.x; yqw[m][c + 1] = q.y;



            }
        }





        for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (5) >> (m)) & 1) != 0) {
                       coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > yf;
            for (int c = 0; c < 8; ++ c) yf[c] = yqw[m][c];
                                                                               coopMatStore(yf, lds_x, (uint(m * (128 / 16) + n) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);
        }

    }

    barrier();































    {
        const int hh = nrhw_h;





                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > kreg[ (64 / 16)][ ( (128 / 4) / 16)];




        const float16_t hscale = float16_t(wgt_f32[pc.s_off + uint(hh)]);
                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > qb[ (64 / 16)][ ( (128 / 4) / 16)];
























        {










                  coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > acc[ (64 / 16)][ ( (1 + 1) * ( (128 / 4) / 16))];

            for (int m = 0; m < (64 / 16); ++ m)
                for (int d = 0; d < ( (1 + 1) * ( (128 / 4) / 16)); ++ d) acc[m][d] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0);
            for (int k = 0; k < (128 / 16); ++ k) {
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yk[ (64 / 16)];
                for (int m = 0; m < (64 / 16); ++ m)

                                                                            coopMatLoad(yk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (128u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);




                for (int r = 0; r < ( (1 + 1) * ( (128 / 4) / 16)); r += 2) {
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                                  { const uint q = (pc.qkv_off) / 4u + ( (uint(hh * 3 * ( (128 / 4) / 16) + 0 + r)) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const fe4m3vec4 w0 = wexpand_pair4[q], w1 = wexpand_pair4[ (q) + 1u]; const fe4m3vec4 w2 = wexpand_pair4[ (q) + 2u], w3 = wexpand_pair4[ (q) + 3u]; for (int v = 0; v < 4; ++ v) { wf0[v] = w0[v]; wf0[v + 4] = w1[v]; wf1[v] = w2[v]; wf1[v + 4] = w3[v]; } } }
                    for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (5) >> (m)) & 1) != 0) acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]);
                    for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (5) >> (m)) & 1) != 0) acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]);
                }







                if (0 > 0 && (k + 1) % 0 == 0)
                    for (int m = 0; m < (64 / 16); ++ m)
                        for (int r = 0; r < ( (1 + 1) * ( (128 / 4) / 16)); ++ r) { }

            }
            for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (5) >> (m)) & 1) != 0) {

                float sqp[4];
                for (int i = 0; i < 4; ++ i) sqp[i] = 0.0;
                for (int c = 0; c < 8; ++ c)
                    for (int d = 0; d < ( (128 / 4) / 16); ++ d) {
                        const float q = acc[m][d][c];
                        sqp[c & 3] = fma(q, q, sqp[c & 3]);
                    }








                f16vec2 sq = f16vec2(vec2( (sqp[0] + sqp[1]) + (sqp[2] + sqp[3]), 0.0));
                sq = sq + unpackFloat2x16(subgroupShuffleXor(packFloat2x16(sq), 16u));
                const float16_t nq =
                                    float16_t(inversesqrt(float(max( (sq.x), float16_t(0.000062)))));





































                for (int d = 0; d < ( (128 / 4) / 16); ++ d)
                    for (int c = 0; c < 8; c += 2) {

                        fe4m3vec2 qp = nr_qscale_fast(vec2(acc[m][d][c], acc[m][d][c + 1]), nq, hscale);





                        qb[m][d][c] = qp.x;
                        qb[m][d][c + 1] = qp.y;
                    }
            }






















            for (int m = 0; m < (64 / 16); ++ m) {

                float skp[4];
                for (int i = 0; i < 4; ++ i) skp[i] = 0.0;
                for (int c = 0; c < 8; ++ c)
                    for (int d = 0; d < ( (128 / 4) / 16); ++ d) {
                        const float kk = acc[m][d + 1 * ( (128 / 4) / 16)][c];
                        skp[c & 3] = fma(kk, kk, skp[c & 3]);
                    }





                f16vec2 sk = f16vec2(vec2( (skp[0] + skp[1]) + (skp[2] + skp[3]), 0.0));
                sk = sk + unpackFloat2x16(subgroupShuffleXor(packFloat2x16(sk), 16u));
                const float16_t nk =
                                    float16_t(inversesqrt(float(max( (sk.x), float16_t(0.000062)))));























                for (int d = 0; d < ( (128 / 4) / 16); ++ d) {
                               coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > kf;
                    for (int c = 0; c < 8; c += 2) {

                        fe4m3vec2 qp = nr_kscale_fast(vec2(acc[m][d + 1 * ( (128 / 4) / 16)][c],
                            acc[m][d + 1 * ( (128 / 4) / 16)][c + 1]), nk);





                        kf[c] = qp.x;
                        kf[c + 1] = qp.y;
                    }


                    for (int c = 0; c < 8; ++ c) kreg[m][d][c] = kf[c];
                }
            }
































            for (int m = 0; m < (64 / 16); ++ m)
                for (int d = 0; d < ( (128 / 4) / 16); ++ d) acc[m][d] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0);
            for (int k = 0; k < (128 / 16); ++ k) {



















                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yk[ (64 / 16)];
                for (int m = 0; m < (64 / 16); ++ m)

                                                                            coopMatLoad(yk[m], lds_x, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (130u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);




                for (int r = 0; r < ( (128 / 4) / 16); r += 2) {
                         coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                                         { const uint q = (pc.qkv_off) / 4u + ( (uint(hh * 3 * ( (128 / 4) / 16) + 2 * ( (128 / 4) / 16) + r)) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const fe4m3vec4 w0 = wexpand_pair4[q], w1 = wexpand_pair4[ (q) + 1u]; const fe4m3vec4 w2 = wexpand_pair4[ (q) + 2u], w3 = wexpand_pair4[ (q) + 3u]; for (int v = 0; v < 4; ++ v) { wf0[v] = w0[v]; wf0[v + 4] = w1[v]; wf1[v] = w2[v]; wf1[v + 4] = w3[v]; } } }
                    for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (5) >> (m)) & 1) != 0) acc[m][r] = coopMatMulAdd(wf0, yk[m], acc[m][r]);
                    for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (5) >> (m)) & 1) != 0) acc[m][r + 1] = coopMatMulAdd(wf1, yk[m], acc[m][r + 1]);
                }











                if (0 > 0 && (k + 1) % 0 == 0)
                    for (int m = 0; m < (64 / 16); ++ m)
                        for (int r = 0; r < ( (128 / 4) / 16); ++ r) { }

            }











            for (int m = 0; m < (64 / 16); ++ m)
                for (int d = 0; d < ( (128 / 4) / 16); ++ d) {
                               coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > vf;
                    for (int c = 0; c < 8; c += 2) {
                        fe4m3vec2 qp = nr_quant_pair(

                                            f16vec2(float16_t(acc[m][d][c]), float16_t(acc[m][d][c + 1])));
                        vf[c] = qp.x;
                        vf[c + 1] = qp.y;
                    }





                                                                                 coopMatStore(vf, lds_y, (uint(m * (128 / 16) + hh * ( (128 / 4) / 16) + d) * 256u), (16u), gl_CooperativeMatrixLayoutRowMajor);
                }


        }













































































































































































































































































































             coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > pb[ (64 / 16)][ (64 / 16)];
        for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (5) >> (m)) & 1) != 0) {
            f16vec2 pq2[ (64 / 16)][4];
                  coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > lg[ (64 / 16)];



            for (int j = 0; j < (64 / 16); ++ j) lg[j] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0);


            for (int d = 0; d < ( (128 / 4) / 16); ++ d)
                for (int j = 0; j < (64 / 16); ++ j) {
                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > kf = kreg[j][d];
                                              lg[j] = coopMatMulAdd(kf, qb[m][d], lg[j]);
                }
            for (int j = 0; j < (64 / 16); ++ j) {
















                          coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > bf;



                                            coopMatLoad(bf, wgt_f32, (pc.b_off + uint(hh) * uint(64 * 64) + (tok0 + uint(m) * 16u) * uint(64) + uint(j) * 16u), (uint(64)), gl_CooperativeMatrixLayoutColumnMajor);


                for (int c = 0; c < 8; c += 2)
                    pq2[j][c / 2] =



                        nr_swin_exp_baked(vec2(lg[j][c], lg[j][c + 1]), vec2(bf[c], bf[c + 1]));



            }
                 float16_t sum = nr_swin_probability_sum(pq2);


            float inv = float(float16_t(1.0 / float(max(sum, float16_t(6.103515625e-05)))));
            for (int j = 0; j < (64 / 16); ++ j)
                for (int c = 0; c < 4; ++ c) {
                    float x = float(pq2[j][c].x) * inv;
                    float y = float(pq2[j][c].y) * inv;










                    fe4m3vec2 q = fe4m3vec2(pq2[j][c] * f16vec2(float16_t(inv)));





                    pb[m][j][2 * c] = q.x;
                    pb[m][j][2 * c + 1] = q.y;
                }
        }
























































































































































































        for (int e = 0; e < ( (128 / 4) / 16); ++ e) {
                  coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > a[ (64 / 16)];
            for (int m = 0; m < (64 / 16); ++ m) a[m] = coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > (0.0);
            for (int j = 0; j < (64 / 16); ++ j) {
                        coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > vf;





                                                 coopMatLoad(vf, lds_y, (uint(j * (128 / 16) + hh * ( (128 / 4) / 16) + e) * 256u + (nr_opaque * ( (192u) * 16u))), (16u), gl_CooperativeMatrixLayoutRowMajor);




                for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (5) >> (m)) & 1) != 0) a[m] = coopMatMulAdd(vf, pb[m][j], a[m]);
                if (0 > 0 && (j + 1) % 0 == 0)
                    for (int m = 0; m < (64 / 16); ++ m) { }
            }
            for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (5) >> (m)) & 1) != 0) {

                            coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > out_context;





                for (int c = 0; c < 8; c += 2) {
                             fe4m3vec2 qp = nr_quant_pair(f16vec2(float16_t(a[m][c]), float16_t(a[m][c + 1])));
                    out_context[c] = qp.x;
                    out_context[c + 1] = qp.y;
                }








                                                                             coopMatStore(out_context, lds_y, (uint(m * (128 / 16) + hh * ( (128 / 4) / 16) + e) * 256u), (16u), gl_CooperativeMatrixLayoutColumnMajor);




















            }
        }


        barrier();

    }













































































          coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > nr_project_acc[ ( (128 / 4) / 16)][ (64 / 16)];
    for (int p = 0; p < ( (128 / 4) / 16); ++ p) {
        const int n = nrhw_h * ( (128 / 4) / 16) + p;
        for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (5) >> (m)) & 1) != 0) {
                    coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yr;
                                                                            coopMatLoad(yr, lds_x, (uint(m * (128 / 16) + n) * 256u + (nr_opaque * ( (80u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);
            for (int c = 0; c < 8; c += 2) {
                const uint off = pc.ars_off + uint(n) * 16u + rbase + uint(c);

                const vec2 residual = nr_e4f2_pick(vec4(fe4m3vec4( (yr)[ (c) & ~ 3], (yr)[ ( (c) & ~ 3) + 1], (yr)[ ( (c) & ~ 3) + 2], (yr)[ ( (c) & ~ 3) + 3])), (c)) * vec2(wgt_f32[off], wgt_f32[off + 1u]);




                nr_project_acc[p][m][c] = float(residual.x);
                nr_project_acc[p][m][c + 1] = float(residual.y);
            }
        }
    }
    for (int k = 0; k < (128 / 16); ++ k) {
                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > ctx[ (64 / 16)];
        for (int m = 0; m < (64 / 16); ++ m)
                                                                                coopMatLoad(ctx[m], lds_y, (uint(m * (128 / 16) + k) * 256u + (nr_opaque * ( (64u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);
             coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseA > wf0, wf1;
                                                                                    { const uint q = (pc.op_off) / 4u + ( (uint(nrhw_h * ( (128 / 4) / 16))) / 2u) * (uint( (128 / 16))) * 128u + (uint(k)) * 128u + lane * 4u; { const fe4m3vec4 w0 = wexpand_pair4[q], w1 = wexpand_pair4[ (q) + 1u]; const fe4m3vec4 w2 = wexpand_pair4[ (q) + 2u], w3 = wexpand_pair4[ (q) + 3u]; for (int v = 0; v < 4; ++ v) { wf0[v] = w0[v]; wf0[v + 4] = w1[v]; wf1[v] = w2[v]; wf1[v + 4] = w3[v]; } } }
        for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (5) >> (m)) & 1) != 0) nr_project_acc[0][m] = coopMatMulAdd(wf0, ctx[m], nr_project_acc[0][m]);
        for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (5) >> (m)) & 1) != 0) nr_project_acc[1][m] = coopMatMulAdd(wf1, ctx[m], nr_project_acc[1][m]);
    }


    for (int nn = 0; nn < ( (128 / 4) / 16); ++ nn) {
        const int n = nrhw_h * ( (128 / 4) / 16) + nn;






                coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB > yqr[ (64 / 16)];
        for (int m = 0; m < (64 / 16); ++ m)

                                                                   coopMatLoad(yqr[m], lds_x, (uint(m * (128 / 16) + n) * 256u + (nr_opaque * ( (80u) * 16u))), (16u), gl_CooperativeMatrixLayoutColumnMajor);




              coopmat < float, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > a[ (64 / 16)];
        for (int m = 0; m < (64 / 16); ++ m) a[m] = nr_project_acc[nn][m];
























































        for (int m = 0; m < (64 / 16); ++ m) if ( ( ( (5) >> (m)) & 1) != 0) {




















































                       coopmat < floate4m3_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseAccumulator > of;
                 float16_t wide[8];

            float widef[8];













            for (int c = 0; c < 8; ++ c) {













                widef[c] = a[m][c]




                    ;
                wide[c] = float16_t(widef[c]);










            }
            for (int c = 0; c < 8; c += 2) {

                fe4m3vec2 q = nr_quant_pair32(vec2(widef[c], widef[c + 1]));



                of[c] = q.x; of[c + 1] = q.y;



            }






































































































































































































































































































            if (! nr_tile_oob( (tok0 + uint(m) * 16u) / 16u))


                                                  do { const uint nr_sa = ( (pc.o_off + nr_tile_base( (tok0 + uint(m) * 16u) / 16u) + uint(n) * 256u) + (gl_SubgroupInvocationID % 16u) * (16u) + (gl_SubgroupInvocationID / 16u) * 8u) / 8u; act_v8[nr_sa] = uvec2(nr_e4m3x4_bits(fe4m3vec4(of[0], of[1], of[2], of[3])), nr_e4m3x4_bits(fe4m3vec4(of[4], of[5], of[6], of[7]))); } while (false);






        }
    }










































































































#line 3292 "D:\nr-work-20261011\_mochi\DLSSNR-AMD-main\windows\shaders\rdna4\fswin_t.comp"

    }






















    }

    }






        memoryBarrierBuffer();
        barrier();






















        if (tid < 4u) {

            const uint c = wgt_u32[pcp.df_off + pcp.total_windows + nr_item * 4u + tid];
            if (c != 0xFFFFFFFFu) {
                const uint need = wgt_u32[pcp.df_off + c];
                const uint old = atomicAdd(nr_sync[pcp.sync_off + 4u + c], 1u);
                if (old + 1u == need * nr_epoch) { const uint pos = atomicAdd(nr_sync[nr_tail], 1u); atomicExchange(nr_sync[nr_qbase + pos], nr_tag | (c)); }
            }
        }












        if (gl_NumWorkGroups.x >= pcp.total_windows) break;

        barrier();































    }







    if (tid == 0u) {

        const uint fin = atomicAdd(nr_sync[pcp.sync_off + 1u], 1u);
        if (fin + 1u == gl_NumWorkGroups.x) {
            atomicExchange(nr_sync[pcp.sync_off + 0u], 0u);
            atomicExchange(nr_sync[pcp.sync_off + 1u], 0u);

            atomicExchange(nr_sync[nr_tail], 0u);





            atomicExchange(nr_sync[pcp.sync_off + 2u], nr_epoch);
        }
    }






















































































































































































































}

