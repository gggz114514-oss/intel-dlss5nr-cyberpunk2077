// generated_i8_adapter.glsl — GENERATED from the measured B580 fragment maps.
// source: candidates/dsh-int8-same-family-20261023/abi-probe/evidence/I8-ABI-MEASURED.json
// regenerate: python tools/abi_generate_adapter.py      do not hand-edit
// A 8x32 = columns 0..15 from CH_lo, 16..31 from CH_hi (2 source fragments).
// B 32x16 = rows 8k..8k+7 from CH_k (4 source fragments).
// Each CH element is quantised ONCE when its code word is packed (H01).
#ifndef GENERATED_I8_ADAPTER_GLSL
#define GENERATED_I8_ADAPTER_GLSL
#extension GL_KHR_shader_subgroup_shuffle : require

int i8code(float16_t v, float invs) {
    precise float scaled = float(v) * invs;
    return int(clamp(roundEven(scaled), -127.0, 127.0));
}
uint i8pack4(float16_t a, float16_t b, float16_t c, float16_t d, float invs) {
    return (uint(i8code(a, invs) & 0xFF)) | (uint(i8code(b, invs) & 0xFF) << 8)
         | (uint(i8code(c, invs) & 0xFF) << 16) | (uint(i8code(d, invs) & 0xFF) << 24);
}
int i8s(uint p, uint byteix) {
    uint v = (p >> (8u * byteix)) & 0xFFu;
    return v >= 128u ? int(v) - 256 : int(v);
}

// ---- A: owning lane, byte and source word per (component, lane) ----
const uint I8A_FRAG[8][32] = {
    { 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u },
    { 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u },
    { 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u },
    { 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u },
    { 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u },
    { 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u },
    { 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u },
    { 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u },
};
const uint I8A_LANE[8][32] = {
    { 0u, 1u, 2u, 3u, 4u, 5u, 6u, 7u, 8u, 9u, 10u, 11u, 12u, 13u, 14u, 15u, 0u, 1u, 2u, 3u, 4u, 5u, 6u, 7u, 8u, 9u, 10u, 11u, 12u, 13u, 14u, 15u },
    { 16u, 17u, 18u, 19u, 20u, 21u, 22u, 23u, 24u, 25u, 26u, 27u, 28u, 29u, 30u, 31u, 16u, 17u, 18u, 19u, 20u, 21u, 22u, 23u, 24u, 25u, 26u, 27u, 28u, 29u, 30u, 31u },
    { 0u, 1u, 2u, 3u, 4u, 5u, 6u, 7u, 8u, 9u, 10u, 11u, 12u, 13u, 14u, 15u, 0u, 1u, 2u, 3u, 4u, 5u, 6u, 7u, 8u, 9u, 10u, 11u, 12u, 13u, 14u, 15u },
    { 16u, 17u, 18u, 19u, 20u, 21u, 22u, 23u, 24u, 25u, 26u, 27u, 28u, 29u, 30u, 31u, 16u, 17u, 18u, 19u, 20u, 21u, 22u, 23u, 24u, 25u, 26u, 27u, 28u, 29u, 30u, 31u },
    { 0u, 1u, 2u, 3u, 4u, 5u, 6u, 7u, 8u, 9u, 10u, 11u, 12u, 13u, 14u, 15u, 0u, 1u, 2u, 3u, 4u, 5u, 6u, 7u, 8u, 9u, 10u, 11u, 12u, 13u, 14u, 15u },
    { 16u, 17u, 18u, 19u, 20u, 21u, 22u, 23u, 24u, 25u, 26u, 27u, 28u, 29u, 30u, 31u, 16u, 17u, 18u, 19u, 20u, 21u, 22u, 23u, 24u, 25u, 26u, 27u, 28u, 29u, 30u, 31u },
    { 0u, 1u, 2u, 3u, 4u, 5u, 6u, 7u, 8u, 9u, 10u, 11u, 12u, 13u, 14u, 15u, 0u, 1u, 2u, 3u, 4u, 5u, 6u, 7u, 8u, 9u, 10u, 11u, 12u, 13u, 14u, 15u },
    { 16u, 17u, 18u, 19u, 20u, 21u, 22u, 23u, 24u, 25u, 26u, 27u, 28u, 29u, 30u, 31u, 16u, 17u, 18u, 19u, 20u, 21u, 22u, 23u, 24u, 25u, 26u, 27u, 28u, 29u, 30u, 31u },
};
const uint I8A_BYTE[8][32] = {
    { 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u },
    { 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u },
    { 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u },
    { 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u },
    { 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u },
    { 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u },
    { 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u },
    { 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u },
};
// ---- B: owning lane, byte and source word per (component, lane) ----
const uint I8B_FRAG[16][32] = {
    { 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u },
    { 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u },
    { 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u },
    { 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u },
    { 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u },
    { 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u },
    { 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u },
    { 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u, 1u },
    { 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u },
    { 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u },
    { 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u },
    { 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u, 2u },
    { 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u },
    { 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u },
    { 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u },
    { 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u, 3u },
};
const uint I8B_LANE[16][32] = {
    { 0u, 16u, 0u, 16u, 1u, 17u, 1u, 17u, 2u, 18u, 2u, 18u, 3u, 19u, 3u, 19u, 4u, 20u, 4u, 20u, 5u, 21u, 5u, 21u, 6u, 22u, 6u, 22u, 7u, 23u, 7u, 23u },
    { 8u, 24u, 8u, 24u, 9u, 25u, 9u, 25u, 10u, 26u, 10u, 26u, 11u, 27u, 11u, 27u, 12u, 28u, 12u, 28u, 13u, 29u, 13u, 29u, 14u, 30u, 14u, 30u, 15u, 31u, 15u, 31u },
    { 0u, 16u, 0u, 16u, 1u, 17u, 1u, 17u, 2u, 18u, 2u, 18u, 3u, 19u, 3u, 19u, 4u, 20u, 4u, 20u, 5u, 21u, 5u, 21u, 6u, 22u, 6u, 22u, 7u, 23u, 7u, 23u },
    { 8u, 24u, 8u, 24u, 9u, 25u, 9u, 25u, 10u, 26u, 10u, 26u, 11u, 27u, 11u, 27u, 12u, 28u, 12u, 28u, 13u, 29u, 13u, 29u, 14u, 30u, 14u, 30u, 15u, 31u, 15u, 31u },
    { 0u, 16u, 0u, 16u, 1u, 17u, 1u, 17u, 2u, 18u, 2u, 18u, 3u, 19u, 3u, 19u, 4u, 20u, 4u, 20u, 5u, 21u, 5u, 21u, 6u, 22u, 6u, 22u, 7u, 23u, 7u, 23u },
    { 8u, 24u, 8u, 24u, 9u, 25u, 9u, 25u, 10u, 26u, 10u, 26u, 11u, 27u, 11u, 27u, 12u, 28u, 12u, 28u, 13u, 29u, 13u, 29u, 14u, 30u, 14u, 30u, 15u, 31u, 15u, 31u },
    { 0u, 16u, 0u, 16u, 1u, 17u, 1u, 17u, 2u, 18u, 2u, 18u, 3u, 19u, 3u, 19u, 4u, 20u, 4u, 20u, 5u, 21u, 5u, 21u, 6u, 22u, 6u, 22u, 7u, 23u, 7u, 23u },
    { 8u, 24u, 8u, 24u, 9u, 25u, 9u, 25u, 10u, 26u, 10u, 26u, 11u, 27u, 11u, 27u, 12u, 28u, 12u, 28u, 13u, 29u, 13u, 29u, 14u, 30u, 14u, 30u, 15u, 31u, 15u, 31u },
    { 0u, 16u, 0u, 16u, 1u, 17u, 1u, 17u, 2u, 18u, 2u, 18u, 3u, 19u, 3u, 19u, 4u, 20u, 4u, 20u, 5u, 21u, 5u, 21u, 6u, 22u, 6u, 22u, 7u, 23u, 7u, 23u },
    { 8u, 24u, 8u, 24u, 9u, 25u, 9u, 25u, 10u, 26u, 10u, 26u, 11u, 27u, 11u, 27u, 12u, 28u, 12u, 28u, 13u, 29u, 13u, 29u, 14u, 30u, 14u, 30u, 15u, 31u, 15u, 31u },
    { 0u, 16u, 0u, 16u, 1u, 17u, 1u, 17u, 2u, 18u, 2u, 18u, 3u, 19u, 3u, 19u, 4u, 20u, 4u, 20u, 5u, 21u, 5u, 21u, 6u, 22u, 6u, 22u, 7u, 23u, 7u, 23u },
    { 8u, 24u, 8u, 24u, 9u, 25u, 9u, 25u, 10u, 26u, 10u, 26u, 11u, 27u, 11u, 27u, 12u, 28u, 12u, 28u, 13u, 29u, 13u, 29u, 14u, 30u, 14u, 30u, 15u, 31u, 15u, 31u },
    { 0u, 16u, 0u, 16u, 1u, 17u, 1u, 17u, 2u, 18u, 2u, 18u, 3u, 19u, 3u, 19u, 4u, 20u, 4u, 20u, 5u, 21u, 5u, 21u, 6u, 22u, 6u, 22u, 7u, 23u, 7u, 23u },
    { 8u, 24u, 8u, 24u, 9u, 25u, 9u, 25u, 10u, 26u, 10u, 26u, 11u, 27u, 11u, 27u, 12u, 28u, 12u, 28u, 13u, 29u, 13u, 29u, 14u, 30u, 14u, 30u, 15u, 31u, 15u, 31u },
    { 0u, 16u, 0u, 16u, 1u, 17u, 1u, 17u, 2u, 18u, 2u, 18u, 3u, 19u, 3u, 19u, 4u, 20u, 4u, 20u, 5u, 21u, 5u, 21u, 6u, 22u, 6u, 22u, 7u, 23u, 7u, 23u },
    { 8u, 24u, 8u, 24u, 9u, 25u, 9u, 25u, 10u, 26u, 10u, 26u, 11u, 27u, 11u, 27u, 12u, 28u, 12u, 28u, 13u, 29u, 13u, 29u, 14u, 30u, 14u, 30u, 15u, 31u, 15u, 31u },
};
const uint I8B_BYTE[16][32] = {
    { 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u },
    { 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u },
    { 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u },
    { 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u },
    { 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u },
    { 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u },
    { 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u },
    { 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u },
    { 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u },
    { 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u },
    { 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u },
    { 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u },
    { 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u },
    { 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u, 0u, 0u, 1u, 1u },
    { 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u },
    { 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u, 2u, 2u, 3u, 3u },
};

// two CH code words (lo = columns 0..15, hi = 16..31) -> one A 8x32 fragment
MAT_I8A i8_join_A(uint chLo, uint chHi) {
    MAT_I8A q;
    uint l = gl_SubgroupInvocationID;
    for (int ci = 0; ci < q.length(); ++ci) {
        q[ci] = int8_t(i8s(subgroupShuffle(I8A_FRAG[ci][l] == 0u ? chLo : chHi,
                           I8A_LANE[ci][l]), I8A_BYTE[ci][l]));
    }
    return q;
}

// four CH code words (rows 0..7, 8..15, 16..23, 24..31) -> one B 32x16 fragment
MAT_I8B i8_join_B(uint ch0, uint ch1, uint ch2, uint ch3) {
    MAT_I8B q;
    uint l = gl_SubgroupInvocationID;
    for (int ci = 0; ci < q.length(); ++ci) {
        uint f = I8B_FRAG[ci][l];
        uint w = (f == 0u) ? ch0 : (f == 1u) ? ch1 : (f == 2u) ? ch2 : ch3;
        q[ci] = int8_t(i8s(subgroupShuffle(w, I8B_LANE[ci][l]), I8B_BYTE[ci][l]));
    }
    return q;
}

#endif
