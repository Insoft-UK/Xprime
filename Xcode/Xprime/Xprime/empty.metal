// EmptyShader.metal
#include <metal_stdlib>
using namespace metal;

kernel void emptyShader(uint3 gid [[thread_position_in_grid]]) { }
