#version 450
#extension GL_EXT_shader_8bit_storage : require
#extension GL_EXT_shader_explicit_arithmetic_types_int8 : require
















layout(local_size_x = 64) in;
layout(set = 0, binding = 0, std430) buffer Act { uint8_t data[]; };




layout(set = 0, binding = 0, std430) buffer Act4 { uvec4 data4[]; };
layout(push_constant) uniform Push {
    uint src, dst, W, H, C, inverse;
} pc;
uint at(uint token, uint channel) {
    return( (token / 16u) * (pc.C / 16u) + channel / 16u) * 256u
           + (token % 16u) * 16u + channel % 16u;
}
void main() {
    uint i = gl_GlobalInvocationID.x;

    if (i >= pc.W * pc.H * (pc.C / 16u)) return;
    uint raster = i / (pc.C / 16u), c = (i % (pc.C / 16u)) * 16u;




    uint x = raster % pc.W, y = raster / pc.W;
    uint tile = ( (y / 4u) * (pc.W / 4u) + x / 4u) * 16u
                + (y % 4u) * 4u + x % 4u;
    uint a = pc.inverse == 0u ? tile : raster;
    uint b = pc.inverse == 0u ? raster : tile;

    data4[ (pc.dst + at(b, c)) / 16u] = data4[ (pc.src + at(a, c)) / 16u];



}

