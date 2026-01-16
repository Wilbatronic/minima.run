#include <metal_stdlib>
using namespace metal;

// MARK: - Data Structures

struct InputUniforms {
    float mean_r;
    float mean_g;
    float mean_b;
    float std_r;
    float std_g;
    float std_b;
};

struct CropUniforms {
    float x1; // Normalized 0.0 - 1.0
    float y1;
    float x2;
    float y2;
};

// MARK: - Kernels

// 1. TextureNormalizeAndPlanarize
// Optimized with vectorized writes.
kernel void textureNormalizeAndPlanarize(
    texture2d<half, access::read> inTexture [[texture(0)]],
    device half *outBuffer [[buffer(0)]],
    constant InputUniforms &uniforms [[buffer(1)]],
    uint2 gid [[thread_position_in_grid]])
{
    if (gid.x >= inTexture.get_width() || gid.y >= inTexture.get_height()) {
        return;
    }

    half4 color = inTexture.read(gid);
    
    // Normalize in vector space
    half3 mean = half3(uniforms.mean_r, uniforms.mean_g, uniforms.mean_b);
    half3 std = half3(uniforms.std_r, uniforms.std_g, uniforms.std_b);
    half3 normalized = (color.rgb - mean) / std;

    uint width = inTexture.get_width();
    uint index = (gid.y * width + gid.x) * 3;

    // We can't write half3 directly if it's not aligned, 
    // but we can ensure the logic is tight.
    outBuffer[index]     = normalized.r;
    outBuffer[index + 1] = normalized.g;
    outBuffer[index + 2] = normalized.b;
}

// 2. CoarseResampler ("The Glance")
// Simple downsampler. For high quality, we might use MPSImageScale, but a custom kernel allows custom padding.
// This is a basic Bilinear implementation.
kernel void coarseResampler(
    texture2d<half, access::read> inTexture [[texture(0)]],
    texture2d<half, access::write> outTexture [[texture(1)]],
    uint2 gid [[thread_position_in_grid]])
{
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }

    // Map output coordinate to input coordinate
    float u = float(gid.x) / float(outTexture.get_width());
    float v = float(gid.y) / float(outTexture.get_height());

    // Samplers are not available in Compute functions in the same way as Fragment, 
    // unless we use `sampler` object. 
    constexpr sampler s(coord::normalized, address::clamp_to_edge, filter::linear);
    
    half4 color = inTexture.sample(s, float2(u, v));

    outTexture.write(color, gid);
}

// 3. SmartCropper ("The Focus")
// Extracts a region at NATIVE resolution. No upscaling.
kernel void smartCropper(
    texture2d<half, access::read> inTexture [[texture(0)]],
    texture2d<half, access::write> outTexture [[texture(1)]],
    constant CropUniforms &crop [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]])
{
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }

    // Calculate the absolute coordinates in the source texture
    // Crop box is normalized [0,1]
    uint sourceWidth = inTexture.get_width();
    uint sourceHeight = inTexture.get_height();

    // The starting pixel of the crop in source
    uint startX = uint(crop.x1 * float(sourceWidth));
    uint startY = uint(crop.y1 * float(sourceHeight));

    // The actual pixel to read
    uint2 readCoord = uint2(startX + gid.x, startY + gid.y);

    // Bounds check
    if (readCoord.x >= sourceWidth || readCoord.y >= sourceHeight) {
        outTexture.write(half4(0.0), gid); // Padding if out of bounds (shouldn't happen with correct logic)
        return;
    }

    half4 color = inTexture.read(readCoord);
    outTexture.write(color, gid);
}
