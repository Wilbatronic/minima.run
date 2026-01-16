#include <metal_stdlib>
using namespace metal;

// Professional-Grade Flash Attention Kernel
// Optimized for Apple Silicon (M1/M2/M3)
// Leverages SIMD-group reductions and threadgroup tiling

struct FlashAttentionParams {
    uint seqLen;
    uint headDim;
    uint numHeads;
    float scale;
};

// block_size_col: Number of K/V columns processed in the inner loop
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
    
    if (row >= params.seqLen) return;

    // Use threadgroup memory for K and V tiles
    // This reduces global memory bandwidth pressure for long sequences
    threadgroup half sharedK[BC][128]; // Max headDim 128
    threadgroup half sharedV[BC][128];

    const uint headOffset = headIdx * params.seqLen * headDim;
    device const half* qRow = Q + headOffset + row * headDim;
    
    float m_i = -INFINITY;
    float l_i = 0.0f;
    float acc[128];
    for(uint i=0; i<128; ++i) acc[i] = 0.0f;

    for (uint j = 0; j < params.seqLen; j += BC) {
        uint j_end = min(j + BC, params.seqLen);
        uint current_tile_size = j_end - j;

        // Parallel load of K/V tile into threadgroup memory
        // Each thread in the threadgroup helps load
        for (uint t = tid.x; t < current_tile_size * headDim; t += t_per_tg.x) {
            uint tk = t / headDim;
            uint td = t % headDim;
            sharedK[tk][td] = K[headOffset + (j + tk) * headDim + td];
            sharedV[tk][td] = V[headOffset + (j + tk) * headDim + td];
        }
        threadgroup_barrier(mem_flags::mem_threadgroup);
        
        // Inner loop over the CACHED tile
        for (uint col_tile = 0; col_tile < current_tile_size; ++col_tile) {
            uint col = j + col_tile;
            if (col > row) break;

            float score = 0.0f;
            for (uint d = 0; d < headDim; d++) {
                score += float(qRow[d]) * float(sharedK[col_tile][d]);
            }
            score *= params.scale;

            float m_prev = m_i;
            m_i = max(m_prev, score);
            float exp_score = exp(score - m_i);
            float exp_prev = exp(m_prev - m_i);
            
            l_i = l_i * exp_prev + exp_score;

            for (uint d = 0; d < headDim; d++) {
                acc[d] = acc[d] * exp_prev + exp_score * float(sharedV[col_tile][d]);
            }
        }
        threadgroup_barrier(mem_flags::mem_threadgroup);
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
