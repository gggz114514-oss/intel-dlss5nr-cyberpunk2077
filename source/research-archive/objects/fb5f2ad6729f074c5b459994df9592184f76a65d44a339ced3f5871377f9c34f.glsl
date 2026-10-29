// C128 block11 FFN. Direct M8 column-major qX/qM/sa, stride8; no repack. Native operands remain signed INT8.
// B carries identical integers in half; B is diagnostic only.
#extension GL_EXT_shader_explicit_arithmetic_types_int8 : require
#extension GL_EXT_shader_8bit_storage : require
#if NATIVE
#define QT int8_t
#define KS 32u
#define MA coopmat<int8_t, gl_ScopeSubgroup, 8, 32, gl_MatrixUseA>
#define MB coopmat<int8_t, gl_ScopeSubgroup, 32, 16, gl_MatrixUseB>
#define ACC coopmat<int, gl_ScopeSubgroup, 8, 16, gl_MatrixUseAccumulator>
#define ZERO 0
#else
#define QT float16_t
#define KS 16u
#define MA coopmat<float16_t, gl_ScopeSubgroup, 8, 16, gl_MatrixUseA>
#define MB coopmat<float16_t, gl_ScopeSubgroup, 16, 16, gl_MatrixUseB>
#define ACC coopmat<float, gl_ScopeSubgroup, 8, 16, gl_MatrixUseAccumulator>
#define ZERO 0.0
#endif
#define MF coopmat<float, gl_ScopeSubgroup, 8, 16, gl_MatrixUseAccumulator>
#define MH coopmat<float16_t, gl_ScopeSubgroup, 8, 16, gl_MatrixUseAccumulator>
#define MQ coopmat<QT, gl_ScopeSubgroup, 8, 16, gl_MatrixUseAccumulator>
#define ROW gl_CooperativeMatrixLayoutRowMajor
#define COL gl_CooperativeMatrixLayoutColumnMajor

layout(set=0,binding=0) readonly buffer Weights { QT qw[]; };
// 0:sX, 1:invSX, 2:invSA, 3:invSM; 16:expand sX*sWe[512],
// 528:mid sA*sWm[128], 656:contract sM*sWc[128], 784:sX*residual_scale[128]; 912:sP*sWds/sX[128].
layout(set=0,binding=1) readonly buffer Scales { float sc[]; };
layout(set=0,binding=2) readonly buffer PackedEntry { QT gx[]; };
layout(set=0,binding=4) buffer DotDump { float dd[]; };
layout(set=0,binding=5) buffer Mid { QT gm[]; };
layout(set=0,binding=6) buffer Output { float16_t gy[]; };
layout(push_constant) uniform PC { ivec4 p0; ivec4 p1; ivec4 p2; ivec4 p3;
    ivec4 p4; ivec4 p5; ivec4 p6; ivec4 p7; } pc;

// One signed tile/OOB decision per M8, outside K and shared by both N halves.
uint input_addr(uint m,uint c,uint wx,uint wy,out bool oob) {
    uint tile=m>>4u,slot=m&15u;
    int tx=2*int(wx)+pc.p0.z+int(tile&1u),ty=2*int(wy)+pc.p0.w+int(tile>>1u);
    oob=tx<0||ty<0||tx>=pc.p0.x||ty>=pc.p0.y;
    if(oob)return 0u;
    return (((uint(ty)*uint(pc.p0.x)+uint(tx))*2u+(slot>>3u))*128u+c)*8u+(slot&7u);
}
float rounded_code(float x,float invs) {
    precise float scaled=x*invs;
    return clamp(roundEven(scaled),-127.0,127.0);
}
float16_t act(float16_t x) {
    float16_t t=clamp(x,float16_t(-4.0),float16_t(4.0));
    float16_t u=fma(float16_t(-0.055908203125),abs(t),float16_t(0.447265625));
    return x*fma(t,u,float16_t(0.89453125));
}
// B580, subgroup32, FP32 accumulator M8N16 only. Native r5 ISA proves
// component i has (row,col)=(2*i+lane/16,lane%16). Every component in
// one lane therefore uses the same channel scale. This is not a portable
// cooperative-matrix lane-layout assertion and requires bound numeric/ISA gates.
// One ordinary scalar load per lane, reused by its four elementwise products;
// no cooperative-matrix multiply by a scope-nonuniform scalar is performed.
float nr_scale_column(uint offset) {
    return sc[offset+(gl_SubgroupInvocationID&15u)];
}

// Column factors and reciprocal scalars are loaded once outside K and r.
MQ requant_act(ACC a,float multiplier,float invs) {
    MF f=MF(a);
    for(int i=0;i<f.length();++i) {
        precise float realv=f[i]*multiplier;
        // Original nonlinear arithmetic uses half; this is a necessary model
        // arithmetic boundary, not a tensor dequantization transport.
        float16_t h=act(float16_t(realv));
        f[i]=rounded_code(float(h),invs);
    }
    return MQ(f);
}
MQ requant_linear(ACC a,float multiplier,float invs) {
    MF f=MF(a);
    for(int i=0;i<f.length();++i) {
        precise float realv=f[i]*multiplier;
        // V3 removes the obsolete FP16 mid round trip: scaled INT32 -> INT8.
        f[i]=rounded_code(realv,invs);
    }
    return MQ(f);
}
void dumpdot(ACC a,uint off,uint row,uint col,uint stride) {
    // Optional integer diagnostic for one full window only; production p7.x=0.
    if(pc.p7.x!=0 && gl_WorkGroupID.x==1u && gl_WorkGroupID.y==1u) {
        MF f=MF(a);
        coopMatStore(f,dd,off+row*stride+col,stride,ROW);
    }
}
