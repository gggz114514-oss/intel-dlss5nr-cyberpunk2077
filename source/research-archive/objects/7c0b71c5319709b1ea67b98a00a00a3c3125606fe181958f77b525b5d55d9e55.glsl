// NB04 INT8 variant (VK-INT8-008 / vit-v1, block32 template).
//
// DIFF vs candidates/amd-netorg-t2-20261018/vit-companion-direct-epilogue-v1/source/vit_nb04_mpair.glsl
//   * :57-62  K constants unchanged (1024 / 4096 / 1024); weight base is the INT8
//             segment constant (VIT_W8_WE / _WC / _WO) instead of pc.p1.x/y/w,
//             because the INT8 segments start at byte offsets that are not the old
//             half offsets. pc.p1 is left untouched and unused on this path.
//   * :63     accumulator type MC(float) -> AC8(int32)
//   * :64     K step 16 -> 32 (INT8 tuple)
//   * :66-67  B load: 32x16 int8, ColumnMajor stride 32 over the [N/32][K/32][32][32]
//             pack (vit_wbase8)
//   * :68-90  A load: int8 A fragment. Stage 0 goes through a map-free staging pass
//             (see below), stages 1/4 load qA/qT directly as int8.
//   * :96-106 stage 0 epilogue: after vit_cubic the fragment is requantised with sA
//             (vit_code) and stored as int8 (qA) instead of half.
//   * :28-51  stages 1/4 epilogue: acc int32 -> float -> one alpha multiply, residual
//             FMA unchanged (reads FP16 x / FP16 y), store stays FP16.
//
// Why stage 0 stages the A tile instead of converting the fragment in place:
// the spec's pseudocode converts "each (lane,comp) element of the 8x32 tile", which
// requires the measured B580 lane map for a coopmat<int8,8,32,A>. This workspace has
// no such measurement (only the 8x16 f16/acc CH map in register_handoff.glsl). A
// guessed map is exactly the C128 silent-error class, and it is invisible to any CPU
// oracle. So the quantisation is done with plain scalar addresses into a staging
// region and the fragment is produced by coopMatLoad, which is map-free.
// Staging region: binding 4 bytes [1179648, 2359296) - the second half of
// block32_A, which no plan row reads (qA occupies the first 1179648 bytes and
// contract reads 288*4096 int8 elements = 1179648 bytes). One workgroup barrier,
// no new binding, no shared memory (the PASS row reserves shared=0).
layout(local_size_x=256) in;
#include "vit_common.glsl"
#define MH coopmat<float16_t,gl_ScopeSubgroup,8,16,gl_MatrixUseAccumulator>
#define VIT_A_SCRATCH 1179648u
#define VIT_QY_OFF 1474560u
#ifndef VIT_QY
#define VIT_QY 0
#endif

#if VIT_STAGE == 1
void vit_direct_epilogue(AC8 acc,uint m,uint side,uint n0,uint lane) {
    MH res;
    uint col=n0+side*16u+(lane&15u);
    uint row0=m+(lane>>4u);
    float alpha=ac[col];              // resident sA*sWC[col], one multiply per component
#if VIT_QY
    float invY=ws[12];                // 127/absmax(Y), Y edge of the next qkv GEMM
#endif
    MF8 f=MF8(acc);
    for(uint ci=0u;ci<f.length();++ci) {
        uint t=row0+2u*ci;
        precise float accf=f[ci]*alpha;
        res[ci]=float16_t(fma(VIT_GAIN_C(col),
                              float(x[pc.p5.x+t*1024u+col]),accf));
#if VIT_QY
        // producer-side single quantisation of the Y edge: the qkv INT8 GEMM reads these
        // codes from the same buffer (no second pass, no re-read of Y, no double write of
        // the FP16 value that the projection residual still needs).
        aHidden[VIT_QY_OFF+t*1024u+col]=int8_t(vit_code(float(res[ci]),invY));
#endif
    }
    coopMatStore(res,y,pc.p5.w+m*1024u+n0+side*16u,1024u,RM);
}
#else
void vit_direct_epilogue(AC8 acc,uint m,uint side,uint n0,uint lane) {
    MH res;
    uint col=n0+side*16u+(lane&15u);
    uint row0=m+(lane>>4u);
    float alpha=ap[col];              // resident sT*sWO[col]
    MF8 f=MF8(acc);
    for(uint ci=0u;ci<f.length();++ci) {
        uint t=row0+2u*ci;
        precise float accf=f[ci]*alpha;
        res[ci]=float16_t(fma(VIT_GAIN_P(col),
                              float(y[pc.p5.w+t*1024u+col]),accf));
    }
    coopMatStore(res,o,pc.p5.y+m*1024u+n0+side*16u,1024u,RM);
}
#endif

void main() {
    uint sg=gl_SubgroupID,lane=gl_SubgroupInvocationID;
    uint mA=gl_WorkGroupID.x*128u+sg*8u,mB=mA+64u,n0=gl_WorkGroupID.y*32u;
#if VIT_STAGE == 0
    const uint K=1024u; uint wb=VIT_W8_WE;
#elif VIT_STAGE == 1
    const uint K=4096u; uint wb=VIT_W8_WC;
#else
    const uint K=1024u; uint wb=VIT_W8_WO;
#endif
// v2: the qX producer (vit_nb04_qx_producer.comp) now writes this staging region
// ONCE per frame as its own dispatch.  v1 staged qX inside this kernel, which
// re-quantised the whole A tile in every gy workgroup (128x duplicated) and measured
// +1.19 ms / +5.7M SEND on pass 116; the producer removes the duplication and the
// barrier.  Same codes, same addresses, identical downstream bytes.
    AC8 accA0=AC8(0),accA1=AC8(0),accB0=AC8(0),accB1=AC8(0);
    for(uint k0=0u;k0<K;k0+=32u) {
        MB8 b0,b1;
        coopMatLoad(b0,w8,vit_wbase8(wb,n0,k0,K),32u,CM);
        coopMatLoad(b1,w8,vit_wbase8(wb,n0+16u,k0,K),32u,CM);
        MA8 af;
        if(mA<pc.p0.x) {
#if VIT_STAGE == 0
            coopMatLoad(af,aHidden,VIT_A_SCRATCH+mA*K+k0,K,RM);
#elif VIT_STAGE == 1
            coopMatLoad(af,aHidden,pc.p5.z+mA*K+k0,K,RM);
#else
            coopMatLoad(af,context,pc.p6.y+mA*K+k0,K,RM);
#endif
            accA0=coopMatMulAdd(af,b0,accA0);
            accA1=coopMatMulAdd(af,b1,accA1);
        }
        if(mB<pc.p0.x) {
#if VIT_STAGE == 0
            coopMatLoad(af,aHidden,VIT_A_SCRATCH+mB*K+k0,K,RM);
#elif VIT_STAGE == 1
            coopMatLoad(af,aHidden,pc.p5.z+mB*K+k0,K,RM);
#else
            coopMatLoad(af,context,pc.p6.y+mB*K+k0,K,RM);
#endif
            accB0=coopMatMulAdd(af,b0,accB0);
            accB1=coopMatMulAdd(af,b1,accB1);
        }
    }
    for(uint group=0u;group<2u;++group) {
        uint m=group==0u?mA:mB;
        if(m>=pc.p0.x)continue; // uniform within this SG; no WG barriers here.
        for(uint side=0u;side<2u;++side) {
#if VIT_STAGE == 0
            AC8 acc;
            if(group==0u) {
                if(side==0u)acc=accA0;else acc=accA1;
            } else {
                if(side==0u)acc=accB0;else acc=accB1;
            }
            // dequant: one multiply by the resident per-channel factor sX*sWE[col];
            // narrow to half BEFORE vit_cubic, exactly like the FP16 parent (which
            // narrowed the fp32 accumulator to half first).
            uint col=n0+side*16u+(lane&15u);
            float ew_c=ew[col];
            MH result;
            {
                MF8 f=MF8(acc);
                for(uint c=0u;c<f.length();++c)result[c]=float16_t(f[c]*ew_c);
            }
            if(pc.p0.w!=0u)
                coopMatStore(result,dbg,pc.p6.z+pc.p3.x+m*4096u+n0+side*16u,4096u,RM);
            for(uint c=0u;c<result.length();++c)result[c]=vit_cubic(result[c]);
            // producer requant: qA = int8(clamp(RNE(float(GELU) * invA), -127, 127))
            float invA=ws[9];
            MF8 qf=MF8(result);
            for(uint c=0u;c<qf.length();++c)qf[c]=vit_code(qf[c],invA);
            MQ8 qa=MQ8(qf);
            coopMatStore(qa,aHidden,pc.p5.z+m*4096u+n0+side*16u,4096u,RM);
#else
            if(group==0u) {
                if(side==0u)vit_direct_epilogue(accA0,m,side,n0,lane);
                else vit_direct_epilogue(accA1,m,side,n0,lane);
            } else {
                if(side==0u)vit_direct_epilogue(accB0,m,side,n0,lane);
                else vit_direct_epilogue(accB1,m,side,n0,lane);
            }
#endif
        }
    }
}
