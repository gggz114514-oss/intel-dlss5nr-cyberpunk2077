    // AN6: one standard direct-Y A fragment feeds all six Q/K/V fragments.
    // ---------------------------------------------------------------- N05-c
    // n05c-f05-mbatch (2026-10-27): restricted-token-batch weight-pair reuse
    // across M, in the only form this kernel's register file can hold.
    //
    // The parent walks the same 96 weight tiles twice, once per row_phase, with
    // six f32 accumulators live (6 x 8 = 48 GRF; the measured QKV-window peak is
    // 71/128 GRF).  Holding all twelve accumulators at once (12 x 8 = 96 GRF)
    // cannot be allocated here: 96 + the 30 GRF of non-accumulator live values
    // that survive in the parent's QKV window is already 126 GRF, above the ~120
    // ceiling, before the second M fragment's A return is counted (BUDGET.md).
    //
    // The candidate therefore splits by N: pass 1 keeps the eight Q/K
    // accumulators of both M blocks (64 GRF) and loads each Q/K weight tile once
    // for two independent MMAs; pass 2 does the same for V with four
    // accumulators.  Q and K must stay in one pass because the sealed norm tree
    // consumes q0,q1,k0,k1 together (nr_norm_qk_pair).
    //
    //   per subgroup, full 64-token window          parent   candidate
    //     weight tile loads                            96          48   -48 (-50%)
    //     A row loads                                 128         256   +128
    //     DPAS (8x16x16)                               96          96     +0
    //     peak MAT_C accumulators in the QKV phase      6           8     +2 (16 GRF)
    //
    // No token/head remap, no WG-count change, no shared-memory change, no change
    // to score/den/PV targets, no change to any store address: m0a is the old
    // row_phase 0 token block and m0b = m0a+32 the old row_phase 1 block.  Every
    // accumulator still consumes ki = 0..7 in the same order with the same
    // operand values, so the result is bit-exact.
    {
    const uint m0a = (sg % 4u) * 8u;
    const uint m0b = m0a + 32u;
    { // ---- pass 1: Q and K of both M blocks, each weight tile consumed once ----
        MAT_C accQ0a = MAT_C(float16_t(0.0));
        MAT_C accQ1a = MAT_C(float16_t(0.0));
        MAT_C accK0a = MAT_C(float16_t(0.0));
        MAT_C accK1a = MAT_C(float16_t(0.0));
        MAT_C accQ0b = MAT_C(float16_t(0.0));
        MAT_C accQ1b = MAT_C(float16_t(0.0));
        MAT_C accK0b = MAT_C(float16_t(0.0));
        MAT_C accK1b = MAT_C(float16_t(0.0));
        for (uint ki = 0u; ki < 8u; ++ki) {
            uint k0 = ki * 16u;
            MAT_A a0; coopMatLoad(a0, gY, (w * 64u + m0a) * 128u + k0, 128u, LROW);
            MAT_A a1; coopMatLoad(a1, gY, (w * 64u + m0b) * 128u + k0, 128u, LROW);
            {
                MAT_B b0, b1;
                coopMatLoad(b0, pack, wq + (((96u * h + 0u) / 16u) * 8u + ki) * 256u, 16u, LCOL);
                coopMatLoad(b1, pack, wq + (((96u * h + 16u) / 16u) * 8u + ki) * 256u, 16u, LCOL);
                accQ0a = coopMatMulAdd(a0, b0, accQ0a);
                accQ0b = coopMatMulAdd(a1, b0, accQ0b);
                accQ1a = coopMatMulAdd(a0, b1, accQ1a);
                accQ1b = coopMatMulAdd(a1, b1, accQ1b);
            }
            {
                MAT_B b0, b1;
                coopMatLoad(b0, pack, wq + (((96u * h + 32u) / 16u) * 8u + ki) * 256u, 16u, LCOL);
                coopMatLoad(b1, pack, wq + (((96u * h + 48u) / 16u) * 8u + ki) * 256u, 16u, LCOL);
                accK0a = coopMatMulAdd(a0, b0, accK0a);
                accK0b = coopMatMulAdd(a1, b0, accK0b);
                accK1a = coopMatMulAdd(a0, b1, accK1a);
                accK1b = coopMatMulAdd(a1, b1, accK1b);
            }
        }
        // Retire one M block at a time so only four half fragments are live at
        // any point, exactly like the parent's per-phase epilogue (the parent's
        // row_phase 0 is m0a and row_phase 1 is m0b, so the store order is the
        // parent's order as well).
        {
            MAT_H q0=MAT_H(accQ0a),q1=MAT_H(accQ1a);
            MAT_H k0=MAT_H(accK0a),k1=MAT_H(accK1a);
            if(debug) { coopMatStore(q0,dbg,90112u+m0a*128u+32u*h,128u,LROW); coopMatStore(q1,dbg,90112u+m0a*128u+32u*h+16u,128u,LROW); }
            if(debug) { coopMatStore(k0,dbg,98304u+m0a*128u+32u*h,128u,LROW); coopMatStore(k1,dbg,98304u+m0a*128u+32u*h+16u,128u,LROW); }
            nr_norm_qk_pair(q0,q1,k0,k1,float16_t(auxf[uint(pc.p5.x)+h]),lane);
            coopMatStore(q0,qkv,((gl_SubgroupID / 4u) * 6144u) + 0u+m0a*32u,32u,LROW);
            coopMatStore(q1,qkv,((gl_SubgroupID / 4u) * 6144u) + 0u+m0a*32u+16u,32u,LROW);
            if(debug) { coopMatStore(q0,dbg,114688u+m0a*128u+32u*h,128u,LROW); coopMatStore(q1,dbg,114688u+m0a*128u+32u*h+16u,128u,LROW); }
            coopMatStore(k0,qkv,((gl_SubgroupID / 4u) * 6144u) + 2048u+(m0a/8u*2u+0u)*128u,8u,LCOL);
            coopMatStore(k1,qkv,((gl_SubgroupID / 4u) * 6144u) + 2048u+(m0a/8u*2u+1u)*128u,8u,LCOL);
            if(debug) { coopMatStore(k0,dbg,122880u+m0a*128u+32u*h,128u,LROW); coopMatStore(k1,dbg,122880u+m0a*128u+32u*h+16u,128u,LROW); }
        }
        {
            MAT_H q0=MAT_H(accQ0b),q1=MAT_H(accQ1b);
            MAT_H k0=MAT_H(accK0b),k1=MAT_H(accK1b);
            if(debug) { coopMatStore(q0,dbg,90112u+m0b*128u+32u*h,128u,LROW); coopMatStore(q1,dbg,90112u+m0b*128u+32u*h+16u,128u,LROW); }
            if(debug) { coopMatStore(k0,dbg,98304u+m0b*128u+32u*h,128u,LROW); coopMatStore(k1,dbg,98304u+m0b*128u+32u*h+16u,128u,LROW); }
            nr_norm_qk_pair(q0,q1,k0,k1,float16_t(auxf[uint(pc.p5.x)+h]),lane);
            coopMatStore(q0,qkv,((gl_SubgroupID / 4u) * 6144u) + 0u+m0b*32u,32u,LROW);
            coopMatStore(q1,qkv,((gl_SubgroupID / 4u) * 6144u) + 0u+m0b*32u+16u,32u,LROW);
            if(debug) { coopMatStore(q0,dbg,114688u+m0b*128u+32u*h,128u,LROW); coopMatStore(q1,dbg,114688u+m0b*128u+32u*h+16u,128u,LROW); }
            coopMatStore(k0,qkv,((gl_SubgroupID / 4u) * 6144u) + 2048u+(m0b/8u*2u+0u)*128u,8u,LCOL);
            coopMatStore(k1,qkv,((gl_SubgroupID / 4u) * 6144u) + 2048u+(m0b/8u*2u+1u)*128u,8u,LCOL);
            if(debug) { coopMatStore(k0,dbg,122880u+m0b*128u+32u*h,128u,LROW); coopMatStore(k1,dbg,122880u+m0b*128u+32u*h+16u,128u,LROW); }
        }
    }
    { // ---- pass 2: V of both M blocks, each weight tile consumed once ----
        MAT_C accV0a = MAT_C(float16_t(0.0));
        MAT_C accV1a = MAT_C(float16_t(0.0));
        MAT_C accV0b = MAT_C(float16_t(0.0));
        MAT_C accV1b = MAT_C(float16_t(0.0));
        for (uint ki = 0u; ki < 8u; ++ki) {
            uint k0 = ki * 16u;
            MAT_A a0; coopMatLoad(a0, gY, (w * 64u + m0a) * 128u + k0, 128u, LROW);
            MAT_A a1; coopMatLoad(a1, gY, (w * 64u + m0b) * 128u + k0, 128u, LROW);
            MAT_B b0, b1;
            coopMatLoad(b0, pack, wq + (((96u * h + 64u) / 16u) * 8u + ki) * 256u, 16u, LCOL);
            coopMatLoad(b1, pack, wq + (((96u * h + 80u) / 16u) * 8u + ki) * 256u, 16u, LCOL);
            accV0a = coopMatMulAdd(a0, b0, accV0a);
            accV0b = coopMatMulAdd(a1, b0, accV0b);
            accV1a = coopMatMulAdd(a0, b1, accV1a);
            accV1b = coopMatMulAdd(a1, b1, accV1b);
        }
        MAT_H narrowed;
        narrowed = MAT_H(accV0a);
        coopMatStore(narrowed, qkv, ((gl_SubgroupID / 4u) * 6144u) + 4096u + m0a * 32u, 32u, LROW);
        narrowed = MAT_H(accV1a);
        coopMatStore(narrowed, qkv, ((gl_SubgroupID / 4u) * 6144u) + 4096u + m0a * 32u + 16u, 32u, LROW);
        narrowed = MAT_H(accV0b);
        coopMatStore(narrowed, qkv, ((gl_SubgroupID / 4u) * 6144u) + 4096u + m0b * 32u, 32u, LROW);
        narrowed = MAT_H(accV1b);
        coopMatStore(narrowed, qkv, ((gl_SubgroupID / 4u) * 6144u) + 4096u + m0b * 32u + 16u, 32u, LROW);
    }
    } // both M blocks retire before the publication barrier
