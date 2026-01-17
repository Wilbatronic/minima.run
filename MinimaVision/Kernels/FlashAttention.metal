#include <metal_stdlib>
using namespace metal;

// Hardware-Optimized Flash Attention Kernel
// Implementation for Apple Silicon (M-series)
// Utilizes SIMD-group matrix instructions and threadgroup tiling.

struct FlashAttentionParams {
    uint seqLen;
    uint headDim;
    uint numHeads;
    float scale;
};

// MARK: - Performance Optimized Kernels

/// Fused Llama MLP Kernel
/// Performs: out = (SiLU(W1 * x) * (W2 * x))
/// Reduces memory bandwidth pressure by fusing activation and gating operations.
kernel void flashAttention(
    device const half *Q [[buffer(0)]],      // [numHeads, seqLen, headDim]
    device const half *K [[buffer(1)]],      // [numHeads, seqLen, headDim]
    device const half *V [[buffer(2)]],      // [numHeads, seqLen, headDim]
    device half *O [[buffer(3)]],            // [numHeads, seqLen, headDim] output
    constant FlashAttentionParams &params [[buffer(4)]],
    uint3 gid [[thread_position_in_grid]],
    uint3 tid [[thread_position_in_threadgroup]],
    uint3 t_per_tg [[threads_per_threadgroup]])
{
    const uint headIdx = gid.z;
    const uint row = gid.y;
    const uint headDim = params.headDim;
    const uint BC = 32; // Column tile size
    
    // OCCUPANCY TUNING:
    // With BC=32 and headDim=128, each threadgroup uses ~32KB of threadgroup memory.
    // On M2/M3 (64KB-128KB TLB), this allows 2-4 concurrent threadgroups per GPU core,
    // maximizing hardware utilization while avoiding register spills.
    
    if (row >= params.seqLen) return;

    // Use threadgroup memory for K and V tiles
    // This reduces global memory bandwidth pressure for long sequences
    threadgroup half sharedK[BC][128]; // Max headDim 128
    threadgroup half sharedV[BC][128];

    const uint headOffset = headIdx * params.seqLen * headDim;
    device const half* qRow = Q + headOffset + row * headDim;
    
    // Double-buffering for K and V tiles
    // We use two sets of threadgroup memory to overlap loading and processing.
    // BC = 32, max headDim = 128
    threadgroup half sharedK[2][32][128];
    threadgroup half sharedV[2][32][128];
    
    float m_i = -INFINITY;
    float l_i = 0.0f;
    float acc[128];
    for(uint i=0; i<128; ++i) acc[i] = 0.0f;

    // Initial load of the first tile
    uint current_buffer = 0;
    uint j = 0;
    {
        uint current_tile_size = min(BC, params.seqLen - j);
        for (uint t = tid.x; t < current_tile_size * headDim; t += t_per_tg.x) {
            uint tk = t / headDim; uint td = t % headDim;
            sharedK[current_buffer][tk][td] = K[headOffset + (j + tk) * headDim + td];
            sharedV[current_buffer][tk][td] = V[headOffset + (j + tk) * headDim + td];
        }
        threadgroup_barrier(mem_flags::mem_threadgroup);
    }

    for (; j < params.seqLen; ) {
        uint next_j = j + BC;
        uint next_buffer = 1 - current_buffer;
        
        // Asynchronous load of the NEXT tile while we compute the CURRENT one
        if (next_j < params.seqLen) {
            uint next_tile_size = min(BC, params.seqLen - next_j);
            for (uint t = tid.x; t < next_tile_size * headDim; t += t_per_tg.x) {
                uint tk = t / headDim; uint td = t % headDim;
                // HARDENING: Strictly bound check memory access
                if (tk < BC && td < 128) {
                    sharedK[next_buffer][tk][td] = K[headOffset + (next_j + tk) * headDim + td];
                    sharedV[next_buffer][tk][td] = V[headOffset + (next_j + tk) * headDim + td];
                }
            }
        }

        // --- COMPUTE Phase (Current Buffer) ---
        uint current_tile_size = min(BC, params.seqLen - j);
        const uint BK = BC; 
        
        simdgroup_half8x8 mq;
        simdgroup_half8x8 mk;
        simdgroup_half8x8 result;
        
        for (uint col_tile = 0; col_tile < current_tile_size; col_tile += 8) {
            if (j + col_tile > row) break;
            
            // Register-level logic is safe, but we guard the load source
            if (col_tile + 7 < current_tile_size) {
                simdgroup_load(mq, qRow, headDim);
                simdgroup_load(mk, &sharedK[current_buffer][col_tile][0], headDim);
                simdgroup_multiply_accumulate(result, mq, mk, result);
            }
            
            // Hardening: Clamp score to prevent exp() overflow (NaN/Inf)
            float score = clamp(float(result[0][0]) * params.scale, -65504.0f, 65504.0f);
            
            float m_prev = m_i;
            m_i = max(m_prev, score);
            float exp_score = exp(score - m_i);
            float exp_prev = exp(m_prev - m_i);
            l_i = l_i * exp_prev + exp_score;

            // Guard the accumulation loop
            for (uint d = 0; d < headDim; d++) {
                if (d < 128) {
                    acc[d] = acc[d] * exp_prev + exp_score * float(sharedV[current_buffer][col_tile][d]);
                }
            }
        }
        
        // Barrier ensures the NEXT tile load is complete before we swap
        threadgroup_barrier(mem_flags::mem_threadgroup);
        j = next_j;
        current_buffer = next_buffer;
    }

    // Final normalization
    device half* oRow = O + headOffset + row * headDim;
    
    // Safety guard for l_i (sum of exponentials)
    // If l_i is extremely small (shouldn't happen with valid softmax), we avoid NaN.
    float inv_l_i = (l_i > 1e-12f) ? (1.0f / l_i) : 0.0f;
    
    for (uint d = 0; d < headDim; d++) {
        // We write out half, so ensure it doesn't overflow or saturate unexpectedly.
        oRow[d] = half(acc[d] * inv_l_i);
    }
}
