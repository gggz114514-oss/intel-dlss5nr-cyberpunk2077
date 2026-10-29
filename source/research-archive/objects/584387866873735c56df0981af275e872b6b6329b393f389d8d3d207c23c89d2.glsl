// C2 (c2-c32-regk32): register K32 for the C32 int8 contract.
//   The 128 hidden channels are produced 32 at a time as four CH8x16 fragments,
//   quantised once each (c2_i8_pack), joined into one B32x16 code fragment
//   (c2_i8_join_B) and consumed by the four contract accumulators before the
//   next 32 features start.  No E byte is staged in shared memory, so the
//   expand/contract publication barrier disappears with the stores.
//   The permutation is the closed form of the measured Intel B580 int8 B map
//   (source: candidates/dsh-int8-same-family-20261023/abi-probe/evidence/
//   I8-ABI-MEASURED.json, generated helper generated_i8_adapter.glsl).  It is
//   proved element-for-element, for all 32 lanes x 16 components, against both
//   the sealed measurement and the parent's shared coopMatLoad layout in
//   evidence/COORD-PROOF.json.
#ifndef C2_I8_REG_K32_GLSL
#define C2_I8_REG_K32_GLSL

// One code word per CH8x16 fragment: byte b carries component b of this lane.
// nr_i8_code is the parent's own quantiser -- same expression, same operands,
// same two rounding points, so the four codes are bit-identical to the four
// int8 bytes the parent stored in sE8.
uint c2_i8_pack(NRH_CH e, float inv) {
    return (uint(int(nr_i8_code(e[0], inv)) & 0xFF))
         | (uint(int(nr_i8_code(e[1], inv)) & 0xFF) << 8u)
         | (uint(int(nr_i8_code(e[2], inv)) & 0xFF) << 16u)
         | (uint(int(nr_i8_code(e[3], inv)) & 0xFF) << 24u);
}

// Byte b of a packed word as a signed int8 value (exact inverse of the insert).
int c2_i8_byte(uint p, uint byteix) {
    uint v = (p >> (8u * byteix)) & 0xFFu;
    return v >= 128u ? int(v) - 256 : int(v);
}

// Destination component c of lane L reads CH word w[c >> 2] from lane
// ((L & 1) << 4) | (L >> 2) plus 8 * (c & 1), byte (c & 2) | ((L >> 1) & 1).
uint c2_i8_src_lane(uint lane, uint khi) {
    return (((lane & 1u) << 4u) | (lane >> 2u)) + (khi << 3u);
}

// Four CH8x16 code words (features 0..7, 8..15, 16..23, 24..31) -> one B32x16.
// Two shuffles per word carry both K halves; the bytes are selected locally.
I8B c2_i8_join_B(uint w0, uint w1, uint w2, uint w3) {
    uint lane = gl_SubgroupInvocationID;
    uint lo = (lane >> 1u) & 1u;
    uint s0 = c2_i8_src_lane(lane, 0u);
    uint s1 = c2_i8_src_lane(lane, 1u);
    uint a0 = subgroupShuffle(w0, s0);
    uint b0 = subgroupShuffle(w0, s1);
    uint a1 = subgroupShuffle(w1, s0);
    uint b1 = subgroupShuffle(w1, s1);
    uint a2 = subgroupShuffle(w2, s0);
    uint b2 = subgroupShuffle(w2, s1);
    uint a3 = subgroupShuffle(w3, s0);
    uint b3 = subgroupShuffle(w3, s1);
    I8B q;
    q[0]  = int8_t(c2_i8_byte(a0, lo));
    q[1]  = int8_t(c2_i8_byte(b0, lo));
    q[2]  = int8_t(c2_i8_byte(a0, 2u + lo));
    q[3]  = int8_t(c2_i8_byte(b0, 2u + lo));
    q[4]  = int8_t(c2_i8_byte(a1, lo));
    q[5]  = int8_t(c2_i8_byte(b1, lo));
    q[6]  = int8_t(c2_i8_byte(a1, 2u + lo));
    q[7]  = int8_t(c2_i8_byte(b1, 2u + lo));
    q[8]  = int8_t(c2_i8_byte(a2, lo));
    q[9]  = int8_t(c2_i8_byte(b2, lo));
    q[10] = int8_t(c2_i8_byte(a2, 2u + lo));
    q[11] = int8_t(c2_i8_byte(b2, 2u + lo));
    q[12] = int8_t(c2_i8_byte(a3, lo));
    q[13] = int8_t(c2_i8_byte(b3, lo));
    q[14] = int8_t(c2_i8_byte(a3, 2u + lo));
    q[15] = int8_t(c2_i8_byte(b3, 2u + lo));
    return q;
}

// S01: per-E-channel static inverse.  Component i of a CH8x16 fragment owns row
// 2i + (lane>=16) of the 8-channel group, so the inverse index is
// FSC_INVE + ebase + 2i + (lane>=16); ebase = 32*step + 8*group.  This is a pure
// per-channel scale change -- same quantiser expression, same rounding, same clamp.
uint c2_i8_pack_c(NRH_CH e, uint ebase) {
    uint o = 0u;
    for (int i = 0; i < 4; ++i) {
        uvec2 rc = nrh_coord_CH(uint(i));
        o |= (uint(int(nr_i8_code(e[i], fsc[324u + ebase + rc.x])) & 0xFF) << (8u * uint(i)));
    }
    return o;
}
#endif
