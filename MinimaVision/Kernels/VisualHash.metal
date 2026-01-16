#include <metal_stdlib>
using namespace metal;

// 4. Perceptual Hash (Optimized Parallel Reduction)
// We downsample the input texture to an 8x8 grid.
// Each 8x8 block is summed in parallel using threadgroup memory and SIMD reductions.

kernel void perceptualHash(
    texture2d<half, access::read> inTexture [[texture(0)]],
    device float *outHashGrid [[buffer(0)]], 
    uint2 gid [[thread_position_in_grid]],
    uint2 tid [[thread_position_in_threadgroup]],
    uint2 t_per_tg [[threads_per_threadgroup]])
{
    // Launch with a threadgroup size that covers one 8x8 block region
    // e.g., 16x16 threads per threadgroup
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    
    // Each threadgroup handles one of the 8x8 output grid cells
    uint gridX = gid.x / t_per_tg.x;
    uint gridY = gid.y / t_per_tg.y;
    
    if (gridX >= 8 || gridY >= 8) return;
    
    uint blockW = width / 8;
    uint blockH = height / 8;
    
    uint startX = gridX * blockW;
    uint startY = gridY * blockH;
    
    // Each thread in the threadgroup processes a subset of the block
    float localSum = 0.0f;
    for (uint y = startY + tid.y; y < startY + blockH; y += t_per_tg.y) {
        for (uint x = startX + tid.x; x < startX + blockW; x += t_per_tg.x) {
            half4 c = inTexture.read(uint2(x, y));
            localSum += float(c.r) * 0.2126f + float(c.g) * 0.7152f + float(c.b) * 0.0722f;
        }
    }
    
    // SIMD-group reduction
    localSum = simd_sum(localSum);
    
    // Threadgroup reduction using shared memory if needed, 
    // but for 16x16=256 threads, 8-32 SIMD groups is enough for atomic add to shared
    threadgroup float sharedSum;
    if (all(tid == uint2(0))) {
        sharedSum = 0.0f;
    }
    threadgroup_barrier(mem_flags::mem_threadgroup);
    
    if (lane_id_in_simdgroup == 0) {
        atomic_fetch_add_explicit((threadgroup atomic_float*)&sharedSum, localSum, memory_order_relaxed);
    }
    
    threadgroup_barrier(mem_flags::mem_threadgroup);
    
    if (all(tid == uint2(0))) {
        outHashGrid[gridY * 8 + gridX] = sharedSum;
    }
}
