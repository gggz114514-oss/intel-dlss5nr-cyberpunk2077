    // AN6: one standard direct-Y A fragment feeds all twelve Q/K/V fragments of
    // this workgroup's two heads.
    //
    // n05e A-side owner reblock (no SLM, no new barrier, no new array):
    //   parent: subgroup = ONE head + TWO 8-token m-blocks (row_phase 0/1); the two
    //           head halves of a workgroup therefore fetched the *same* gY row
    //           tiles, once per head  =>  2x per workgroup.
    //   here  : subgroup = ONE 8-token m-block (m0 = sg*8, the 8 subgroups cover
    //           all 64 tokens) + BOTH heads of the workgroup  =>  1x per workgroup.
    // Same A fragment feeds 12 independent MMAs (6 channel blocks x 2 heads) instead
    // of 6.  Weight tiles per subgroup and per ki are unchanged (6 per head), so the
    // per-workgroup weight message count is identical; only the A row fetch halves
    // and the live accumulator count doubles (6 -> 12).
    {
        const uint m0 = sg * 8u;                    // this subgroup's 8 tokens: 0,8,...,56
        const uint h0 = gl_WorkGroupID.z * 2u;      // first head of this workgroup
        const uint h1 = h0 + 1u;                    // second head (= h of subgroups 4..7)
        MAT_C accQ0 = MAT_C(float16_t(0.0));
        MAT_C accQ1 = MAT_C(float16_t(0.0));
        MAT_C accK0 = MAT_C(float16_t(0.0));
        MAT_C accK1 = MAT_C(float16_t(0.0));
        MAT_C accV0 = MAT_C(float16_t(0.0));
        MAT_C accV1 = MAT_C(float16_t(0.0));
        MAT_C accQ0b = MAT_C(float16_t(0.0));
        MAT_C accQ1b = MAT_C(float16_t(0.0));
        MAT_C accK0b = MAT_C(float16_t(0.0));
        MAT_C accK1b = MAT_C(float16_t(0.0));
        MAT_C accV0b = MAT_C(float16_t(0.0));
        MAT_C accV1b = MAT_C(float16_t(0.0));
        for (uint ki = 0u; ki < 8u; ++ki) {
            uint k0 = ki * 16u;
            MAT_A a; coopMatLoad(a, gY, (w * 64u + m0) * 128u + k0, 128u, LROW);
            {   // head h0 : Q
                MAT_B b0, b1;
                coopMatLoad(b0, pack, wq + (((96u * h0 + 0u) / 16u) * 8u + ki) * 256u, 16u, LCOL);
                coopMatLoad(b1, pack, wq + (((96u * h0 + 16u) / 16u) * 8u + ki) * 256u, 16u, LCOL);
                accQ0 = coopMatMulAdd(a, b0, accQ0);
                accQ1 = coopMatMulAdd(a, b1, accQ1);
            }
            {   // head h0 : K
                MAT_B b0, b1;
                coopMatLoad(b0, pack, wq + (((96u * h0 + 32u) / 16u) * 8u + ki) * 256u, 16u, LCOL);
                coopMatLoad(b1, pack, wq + (((96u * h0 + 48u) / 16u) * 8u + ki) * 256u, 16u, LCOL);
                accK0 = coopMatMulAdd(a, b0, accK0);
                accK1 = coopMatMulAdd(a, b1, accK1);
            }
            {   // head h0 : V
                MAT_B b0, b1;
                coopMatLoad(b0, pack, wq + (((96u * h0 + 64u) / 16u) * 8u + ki) * 256u, 16u, LCOL);
                coopMatLoad(b1, pack, wq + (((96u * h0 + 80u) / 16u) * 8u + ki) * 256u, 16u, LCOL);
                accV0 = coopMatMulAdd(a, b0, accV0);
                accV1 = coopMatMulAdd(a, b1, accV1);
            }
            {   // head h1 : Q
                MAT_B b0, b1;
                coopMatLoad(b0, pack, wq + (((96u * h1 + 0u) / 16u) * 8u + ki) * 256u, 16u, LCOL);
                coopMatLoad(b1, pack, wq + (((96u * h1 + 16u) / 16u) * 8u + ki) * 256u, 16u, LCOL);
                accQ0b = coopMatMulAdd(a, b0, accQ0b);
                accQ1b = coopMatMulAdd(a, b1, accQ1b);
            }
            {   // head h1 : K
                MAT_B b0, b1;
                coopMatLoad(b0, pack, wq + (((96u * h1 + 32u) / 16u) * 8u + ki) * 256u, 16u, LCOL);
                coopMatLoad(b1, pack, wq + (((96u * h1 + 48u) / 16u) * 8u + ki) * 256u, 16u, LCOL);
                accK0b = coopMatMulAdd(a, b0, accK0b);
                accK1b = coopMatMulAdd(a, b1, accK1b);
            }
            {   // head h1 : V
                MAT_B b0, b1;
                coopMatLoad(b0, pack, wq + (((96u * h1 + 64u) / 16u) * 8u + ki) * 256u, 16u, LCOL);
                coopMatLoad(b1, pack, wq + (((96u * h1 + 80u) / 16u) * 8u + ki) * 256u, 16u, LCOL);
                accV0b = coopMatMulAdd(a, b0, accV0b);
                accV1b = coopMatMulAdd(a, b1, accV1b);
            }
        }
        // Two publications, one per head, each owning its own shared region
        // (head index j -> qkv[j*6144 .. +6144), exactly the parent's
        // (gl_SubgroupID/4)*6144 values {0, 6144}).
        {
            MAT_H q0=MAT_H(accQ0),q1=MAT_H(accQ1);
            MAT_H k0=MAT_H(accK0),k1=MAT_H(accK1);
            if(debug) { coopMatStore(q0,dbg,90112u+m0*128u+32u*h0,128u,LROW); coopMatStore(q1,dbg,90112u+m0*128u+32u*h0+16u,128u,LROW); }
            if(debug) { coopMatStore(k0,dbg,98304u+m0*128u+32u*h0,128u,LROW); coopMatStore(k1,dbg,98304u+m0*128u+32u*h0+16u,128u,LROW); }
            nr_norm_qk_pair(q0,q1,k0,k1,float16_t(auxf[uint(pc.p5.x)+h0]),lane);
            coopMatStore(q0,qkv,0u+m0*32u,32u,LROW);
            coopMatStore(q1,qkv,0u+m0*32u+16u,32u,LROW);
            if(debug) { coopMatStore(q0,dbg,114688u+m0*128u+32u*h0,128u,LROW); coopMatStore(q1,dbg,114688u+m0*128u+32u*h0+16u,128u,LROW); }
            coopMatStore(k0,qkv,2048u+(m0/8u*2u+0u)*128u,8u,LCOL);
            coopMatStore(k1,qkv,2048u+(m0/8u*2u+1u)*128u,8u,LCOL);
            if(debug) { coopMatStore(k0,dbg,122880u+m0*128u+32u*h0,128u,LROW); coopMatStore(k1,dbg,122880u+m0*128u+32u*h0+16u,128u,LROW); }
            MAT_H narrowed;
            narrowed = MAT_H(accV0);
            coopMatStore(narrowed, qkv, 4096u + m0 * 32u, 32u, LROW);
            narrowed = MAT_H(accV1);
            coopMatStore(narrowed, qkv, 4096u + m0 * 32u + 16u, 32u, LROW);
        }
        {
            MAT_H q0=MAT_H(accQ0b),q1=MAT_H(accQ1b);
            MAT_H k0=MAT_H(accK0b),k1=MAT_H(accK1b);
            if(debug) { coopMatStore(q0,dbg,90112u+m0*128u+32u*h1,128u,LROW); coopMatStore(q1,dbg,90112u+m0*128u+32u*h1+16u,128u,LROW); }
            if(debug) { coopMatStore(k0,dbg,98304u+m0*128u+32u*h1,128u,LROW); coopMatStore(k1,dbg,98304u+m0*128u+32u*h1+16u,128u,LROW); }
            nr_norm_qk_pair(q0,q1,k0,k1,float16_t(auxf[uint(pc.p5.x)+h1]),lane);
            coopMatStore(q0,qkv,6144u+0u+m0*32u,32u,LROW);
            coopMatStore(q1,qkv,6144u+0u+m0*32u+16u,32u,LROW);
            if(debug) { coopMatStore(q0,dbg,114688u+m0*128u+32u*h1,128u,LROW); coopMatStore(q1,dbg,114688u+m0*128u+32u*h1+16u,128u,LROW); }
            coopMatStore(k0,qkv,6144u+2048u+(m0/8u*2u+0u)*128u,8u,LCOL);
            coopMatStore(k1,qkv,6144u+2048u+(m0/8u*2u+1u)*128u,8u,LCOL);
            if(debug) { coopMatStore(k0,dbg,122880u+m0*128u+32u*h1,128u,LROW); coopMatStore(k1,dbg,122880u+m0*128u+32u*h1+16u,128u,LROW); }
            MAT_H narrowed;
            narrowed = MAT_H(accV0b);
            coopMatStore(narrowed, qkv, 6144u + 4096u + m0 * 32u, 32u, LROW);
            narrowed = MAT_H(accV1b);
            coopMatStore(narrowed, qkv, 6144u + 4096u + m0 * 32u + 16u, 32u, LROW);
        }
    } // the twelve accumulators retire before the publication barrier
