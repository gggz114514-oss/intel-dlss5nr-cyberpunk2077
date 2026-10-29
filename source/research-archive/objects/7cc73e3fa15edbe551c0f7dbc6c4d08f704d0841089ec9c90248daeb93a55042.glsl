#ifndef B30_L34_COMMON_GLSL
#define B30_L34_COMMON_GLSL
// Candidate-local ABI for the block30 l3/l4 INT8 kernels.  Bindings 0..9 and
// the push constant layout are inherited from the S24/S25 split16 parent.
layout(set=0,binding=0) readonly buffer Weights { float16_t weights[]; };
layout(set=0,binding=1) readonly buffer Auxiliary { float aux[]; };
layout(set=0,binding=2) readonly buffer Input { float16_t gx[]; };
layout(set=0,binding=3) buffer Ffwd { float16_t gf[]; };
layout(set=0,binding=4) buffer Residual { float16_t gy[]; };
layout(set=0,binding=5) buffer Context { float16_t gt[]; };
layout(set=0,binding=6) buffer Output { float16_t go[]; };
layout(set=0,binding=7) buffer Pool { float16_t gp[]; };
layout(set=0,binding=8) buffer FinalHead { float16_t gh[]; };
layout(set=0,binding=9) buffer Debug { float dbg[]; };
// new INT8 pack: 792584 B
layout(set=0,binding=10) readonly buffer W8PackB30 {
    int8_t w3[262144];   // l3 512x512, 32x32 blocked
    float  wsc3[512];    // sT*sW3[n]
    int8_t w4[524288];   // l4 1024x512, 32x32 blocked
    float  wsc4[1024];   // sPool*sW4[n]
    float  invs[2];      // [0]=1/sT, [1]=1/sPool
};
layout(set=0,binding=11) readonly buffer QT8 { int8_t qt[]; };     // l3 only, 1056x512 tiled
layout(set=0,binding=12) buffer QPool8 { int8_t qp[]; };           // l3 writes, l4 reads, 288x512 tiled
layout(push_constant) uniform Push {
    ivec4 p0; ivec4 p1; ivec4 p2; ivec4 p3;
    ivec4 p4; ivec4 p5; ivec4 p6; ivec4 p7;
} pc;
#define MA coopmat<float16_t,gl_ScopeSubgroup,8,16,gl_MatrixUseA>
#define MB coopmat<float16_t,gl_ScopeSubgroup,16,16,gl_MatrixUseB>
#define MC coopmat<float,gl_ScopeSubgroup,8,16,gl_MatrixUseAccumulator>
#define MH coopmat<float16_t,gl_ScopeSubgroup,8,16,gl_MatrixUseAccumulator>
#define CIA coopmat<int8_t,gl_ScopeSubgroup,8,32,gl_MatrixUseA>
#define CIB coopmat<int8_t,gl_ScopeSubgroup,32,16,gl_MatrixUseB>
#define CA coopmat<int,gl_ScopeSubgroup,8,16,gl_MatrixUseAccumulator>
#define CF coopmat<float,gl_ScopeSubgroup,8,16,gl_MatrixUseAccumulator>
#define ROW gl_CooperativeMatrixLayoutRowMajor
#define COL gl_CooperativeMatrixLayoutColumnMajor
uint tiled(uint token,uint c,uint C) {
    return ((token/16u)*(C/16u)+c/16u)*256u+(token%16u)*16u+c%16u;
}
uint blk_token(uint px,uint py) {
    return ((py/4u)*uint(pc.p0.x/4u)+px/4u)*16u+4u*(py%4u)+px%4u;
}
uint spatial_token(uint tile,uint slot) { return tile*16u+slot; }
uint window_token(uint wx,uint wy,uint t,out bool valid) {
    int tx=2*int(wx)+pc.p1.z+int(t/16u&1u);
    int ty=2*int(wy)+pc.p1.w+int(t/32u);
    valid=tx>=0 && ty>=0 && tx<pc.p0.x/4 && ty<pc.p0.y/4;
    return blk_token(uint(tx)*4u+uint(t%4u),uint(ty)*4u+uint(t%16u/4u));
}
// 32x32 blocked, n-block stride 16*1024 for K=512 (the l0 stage1 form)
uint w8_tile(uint n,uint k) { return ((n/32u)*16u+(k/32u))*1024u+(n%32u)*32u+(k%32u); }
int8_t q_half(float16_t x,float inv) {
    return int8_t(clamp(roundEven(float(x)*inv),-127.0,127.0));
}
#endif
