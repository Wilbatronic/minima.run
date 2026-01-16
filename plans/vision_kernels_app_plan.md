# Minima Vision App & Kernels Implementation Plan

This document outlines the technical steps to build the Minima Vision App, focusing on the high-performance "Vision Pipeline" (Metal Kernels) and the Swift-C++ integration for the "Coarse-to-Fine" cognitive loop.

## 1. Project Initialization & Core Architecture

The core philosophy is "Zero Copy". We aim to keep pixel data on the GPU from Capture -> Pre-processing -> Inference (where possible) to minimize latency.

### 1.1. Hybrid Stack Setup (The "Sovereign" Mix)
*   **Target**: iOS 17+ / macOS 14+.
*   **Philosophy**: "Right Processor for the Right Job".
    *   **Vision Encoder (ViT)**: **CoreML** (Targeting the **ANE** / Neural Engine). This keeps the GPU free during the "Look" phase.
    *   **Inference (LLM)**: **llama.cpp** (Targeting **Metal** / GPU). Best for bandwidth-bound token generation.
*   **Structure**:
    *   `MinimaApp`: SwiftUI.
    *   `MinimaVision`: CoreML Wrapper for the Qwen-Vision encoder.
    *   `MinimaKernels`: Metal Shaders for pre-processing.
    *   `MinimaBrain`: llama.cpp for text generation.

### 1.2. Dependency Management
*   Add `llama.cpp` as a submodule or swift package.
*   Configure build settings to link `Accelerate` and `MetalKit`.

---

## 2. The Vision Pipeline (Metal Kernels)

We require a set of highly optimized Metal Compute Shaders (`.metal`) to handle the "Smart Zoom" logic without CPU overhead.

### 2.1. Kernel: `TextureNormalizeAndPlanarize`
**Goal**: Convert the captured screen surface (BGRA, 8-bit) directly into the format expected by the LLM (RGB, Float32, Planar if needed, or Interleaved).
*   **Input**: `MTLTexture` (ReadOnly, BGRA8Unorm)
*   **Output**: `MTLBuffer` (ReadWrite, Float32) - This buffer acts as the input tensor for the model.
*   **Logic**:
    *   Read pixel $(x, y)$.
    *   Swizzle BGR -> RGB.
    *   Normalize `(color / 255.0 - mean) / std`.
    *   Write to linear memory index.

### 2.2. Kernel: `CoarseResampler` ("The Glance")
**Goal**: Efficiently downsample the 4K/5K screen to the model's native resolution (e.g., 896x896 or 1024x1024) for the initial categorization step.
*   **Algorithm**: Bicubic or Lanczos resampling (better than nearest neighbor for text readability at low res).
*   **Optimization**: Use Metal Performance Shaders (MPS) `MPSImageScale`, or a custom compute kernel if tailored padding is needed for specific aspect ratios.

### 2.3. Kernel: `SmartCropper` ("The Focus")
**Goal**: Extract a high-saliency region at **native resolution**.
*   **Input**:
    *   Source Texture (Full Screen).
    *   Crop Box (Normalized Coordinates `[x1, y1, x2, y2]`) provided by the "Glance" inference.
*   **Output**:
    *   Cropped Texture (Variable size).
*   **Process**:
    *   Map normalized coordinates to pixel coordinates.
    *   Copy sub-region to a new `MTLTexture`.
    *   *Crucially*: Do NOT rescale up. Keep 1:1 pixel density to allow the model to read small UI text.

### 2.4. Kernel: `PatchGridExtractor` (Dynamic Resolution)
**Goal**: Support NaViT-style processing where the image is split into 14x14 patches without resizing the aspect ratio.
*   **Logic**:
    *   Divide the input texture into a grid of $N \times M$ patches.
    *   Flatten each 14x14 patch into a vector.
    *   Discard "empty" patches (e.g., purely uniform padding color) if the architecture supports sparse masking.

---

## 3. Swift Logic & Actors

### 3.1. `ScreenEyes` Actor (ScreenCaptureKit)
This actor manages the continuous stream of frames.
*   **Responsibility**:
    *   Setup `SCStream` with `SCContentFilter` (Active Display or Window).
    *   Receive `CMSampleBuffer`.
    *   Extract `IOSurface` -> Wrap in `MTLTexture`.
    *   Pass `MTLTexture` to the `VisionProcessor`.

### 3.2. `VisionProcessor` (Metal + ANE Coordinator)
Non-actor class (performance critical) managing the `MTLCommandBuffer` and `CoreML` Request.
*   **Pipeline**:
    1.  **Wait** for next frame.
    2.  **Encode** `CoarseResampler` & `TextureNormalize` (Metal).
    3.  **Execute** CoreML Prediction (`QwenVisionEncoder.mlpackage`) on the ANE.
        *   *Note*: This requires passing the `MTLBuffer` or `IOSurface` directly to CoreML to avoid CPU copy.
    4.  **Extract** Embeddings (Float16 MultiArray).
    5.  **Pass** Embeddings to `Mind` (llama.cpp).

### 3.3. `Mind` Actor (Inference Loop)
Handles the "Coarse-to-Fine" logic state machine.
*   **State: Glance**:
    *   Input: Coarse Tensor.
    *   Prompt: *"Check screen. Is user asking about specific text? Return bbox or NULL."*
    *   Run Inference (3B Model / Mobile Scout).
*   **State: Focus** (if bbox detected):
    *   Command `VisionProcessor` to run `SmartCropper` with new bbox.
    *   Input: High-Res Crop Tensor.
    *   Prompt: *"Read text in region. Answer user question."*
    *   Run Inference (7B Model / Desktop Sovereign).

---

## 4. C++ Integration (llama.cpp)

We need a clean bridge to inject the `MTLBuffer` (created by our custom kernels) directly into `llama.cpp`'s context without copying back to CPU RAM.

### 4.1. `LLMEngine_Bridge.mm` (Objective-C++)
*   **Function**: `setInputImage(id<MTLBuffer> pixelBuffer, int width, int height)`
*   **Internal**:
    *   Takes the pointer to the Metal Buffer.
    *   Wraps it in a `ggml_tensor` struct (backend: `GGML_BACKEND_METAL`).
    *   Ensures `llama.cpp` does not try to re-upload this data (it's already on GPU).
    *   Triggers `llama_decode`.

---

## 5. Directory Structure & Files

```text
Minima/
├── Plans/
│   └── vision_kernels_implementation.md (This File)
├── MinimaApp/
│   ├── UI/ ...
│   └── App.swift
├── MinimaVision/
│   ├── Capture/
│   │   └── ScreenEyes.swift       // SCStream handler
│   ├── Kernels/
│   │   ├── Shaders.metal          // THE KERNELS
│   │   └── TextureUtils.swift     // Swift wrapper for pipelines
│   └── Processor/
│       └── VisionPipeline.swift   // Managing CommandBuffers
├── MinimaBrain/
│   ├── Bridge/
│   │   ├── LLMBridge.h
│   │   └── LLMBridge.mm           // C++ Binding
│   └── Core/
│       └── CoarseFineLoop.swift   // The Logic State Machine
└── External/
    └── llama.cpp/
```

---

## 6. Hardware Requirements & Validation

We must strictly enforce hardware limits to avoid crash-loops on unsupported devices.

### 6.1. Minimum Specifications
*   **macOS**:
    *   **Chip**: Apple Silicon **M1** or newer (Intel is unsupported).
    *   **RAM**: 8GB (Runs "Mobile Scout" 3B model). 16GB+ recommended for 7B.
    *   **OS**: macOS 14.0 (Sonoma) - Required for latest Metal/BNNS instructions.
*   **iOS**:
    *   **Chip**: **A17 Pro** (iPhone 15 Pro) or newer.
    *   **RAM**: **8GB** Required. 
    *   *Rationale*: The 6GB RAM on A16 (iPhone 14 Pro) is too tight for the OS + Vision Encoder (500MB) + 3B Model (2.2GB) + KV Cache.

### 6.2. Runtime Check (`HardwareGuard.swift`)
*   **Logic**:
    *   Check `sysctl("hw.memsize")`.
    *   Check `MTLCreateSystemDefaultDevice().supportsFamily(.apple7)`.
    *   If fail -> Show "Compatibility Mode" (Cloud Relay only) or "Unsupported" screen.

---

## 7. Next Steps

1.  **Prototype `Shaders.metal`**: Write the basic Normalize and Resize kernels.
2.  **Build `ScreenEyes`**: specific for macOS `ScreenCaptureKit` to get a live texture.
3.  **Bridge Test**: Pass a dummy Metal buffer to `llama.cpp` and ensure it accepts it as input.
