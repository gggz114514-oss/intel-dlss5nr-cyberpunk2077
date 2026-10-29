#version 460
#extension GL_GOOGLE_include_directive : require
#extension GL_EXT_shader_explicit_arithmetic_types_float16 : require




layout(local_size_x = 8, local_size_y = 8) in;
layout(set = 0, binding = 0, std430) buffer NoiseOut { uint nr_noise_u32[]; };
layout(push_constant) uniform Push {
    uint off;
    uint width, height;
    uint seed;
    float noise;
} pc;
#line 1 "D:/nr-work-20261011/_mochi/DLSSNR-AMD-main/windows/shaders/rdna4/include/image_noise.glsl"




float nr_g0, nr_g1, nr_g2;
uint nr_pcg(uint v) {
    v = (v >> ( (v >> 28) + 4u)) ^ v;
    v *= 0x108EF2D9u;
    return v;
}
float nr_u(uint stream) {
    const uint t = nr_pcg(stream);
    return float( ( (t >> 30) ^ (t >> 8)) + 1u) * 5.9604644775390625e-08;
}
void nr_gauss3(uint x, uint y, uint seed) {
    const uint base = (x * 0x8DA6B343u) ^ (seed * 0x9E3779B9u) ^ (y * 0xD8163841u) ^ 0x243F6A88u;
    const uint t = nr_pcg(base), h = (t >> 22) ^ t;
    const float uA = nr_u(h * 0x2C9277B5u + 0xAC564B05u);
    const float uB = nr_u(h * 0xFA6DC5F9u + 0x4712A88Eu);
    const float uC = nr_u(h * 0xCAA5B80Du + 0x21DD796Bu);
    const float uD = nr_u(h * 0x83232C31u + 0x3463E0ACu);
    const float rA = sqrt(- 2.0 * log(uA)), rC = sqrt(- 2.0 * log(uC));
    const float a1 = uB * 6.28318530718, a2 = uD * 6.28318530718;
    nr_g0 = rA * cos(a1); nr_g1 = rA * sin(a1); nr_g2 = rC * cos(a2);
}

#line 17 "D:\nr-work-20261011\_mochi\DLSSNR-AMD-main\windows\shaders\rdna4\noise_field.comp"
 void main() {
    const uint x = gl_GlobalInvocationID.x, y = gl_GlobalInvocationID.y;
    if (x >= pc.width || y >= pc.height) return;
    nr_gauss3(x, y, pc.seed);
    const float16_t a = float16_t(pc.noise * nr_g0), b = float16_t(pc.noise * nr_g1),
                    c = float16_t(pc.noise * nr_g2);
    const uint i = pc.off + (y * pc.width + x) * 2u;
    nr_noise_u32[i] = packFloat2x16(f16vec2(a, b));
    nr_noise_u32[i + 1u] = packFloat2x16(f16vec2(c, float16_t(0.0)));
}

