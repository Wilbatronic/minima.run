# Minima: Invisible OS Intelligence

Minima is a privacy-first, high-performance intelligence layer that integrates directly into macOS and iOS. It leverages state-of-the-art vision-language models (Qwen-VL) to understand and control your operating system locally, without data ever leaving your device.

## Core Features

- **Local Vision**: Real-time screen and camera understanding powered by optimized Metal kernels (Flash Attention, Parallel Reductions).
- **Invisible UI**: Glassmorphism-driven design that stays out of your way until needed.
- **Proactive Agency**: Direct OS control via Accessibility bridges for task automation.
- **Privacy-First**: All inference happens on-device using `llama.cpp` and Apple Silicon neural engines.

## Architecture

- **Engine**: Custom Swift actor system wrapping `llama.cpp` (GGUF).
- **Vision Pipeline**: "Coarse-to-Fine" foveated vision for high-resolution patch analysis.
- **Optimizations**: Vectorized Metal shaders, SIMD-group reductions, and FP16 precision.

## Development

Minima is built with Swift 6 and Metal, targeting macOS 14.0+ and iOS 17.0+.

```bash
# Generate the Xcode project
./generate_xcode.sh
```

---
*Built for speed. Optimized for privacy.*
