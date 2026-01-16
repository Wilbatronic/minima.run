import Foundation
import Metal
import CoreML
import Vision

@available(macOS 14.0, iOS 17.0, *)
public class VisionProcessor {
    
    // Dependencies
    private let textureUtils = TextureUtils.shared
    private let device: MTLDevice?
    
    // CoreML Model
    private var visionModel: VNCoreMLModel?
    
    // Buffers for intermediate state
    private var coarseTexture: MTLTexture?
    
    // Callback to the Brain (llama.cpp)
    public var onEmbeddingsGenerated: ((MLMultiArray) -> Void)?
    
    public init() {
        self.device = MTLCreateSystemDefaultDevice()
        setupCoreML()
    }
    
    private func setupCoreML() {
        // Placeholder for model loading logic
    }
    
    // MARK: - Pipeline Execution
    
    public func processFrame(texture: MTLTexture) {
        guard let device = device else {
            print("[VisionProcessor] Error: No Metal device available.")
            return
        }
        
        // Ensure we have a coarse texture target
        if coarseTexture == nil {
            let desc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba16Float, width: 448, height: 448, mipmapped: false)
            desc.usage = [.shaderWrite, .shaderRead]
            coarseTexture = device.makeTexture(descriptor: desc)
        }
        
        // Execute Vision Request
        guard let model = visionModel else { return }
        
        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            guard let self = self else { return }
            if let results = request.results as? [VNCoreMLFeatureValueObservation],
               let feature = results.first?.featureValue.multiArrayValue {
                self.onEmbeddingsGenerated?(feature)
            }
        }
        
        request.imageCropAndScaleOption = .scaleFill
        
        guard let pixelBuffer = texture.toCVPixelBuffer() else {
            print("[VisionProcessor] Error: Failed to convert texture to CVPixelBuffer.")
            return
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            print("Vision failed: \(error)")
        }
    }
}

// MARK: - Helper (Texture -> CVPixelBuffer)
// Needed because Vision.framework prefers CVPixelBuffers over raw MTLTextures usually,
// although it can handle CIImage(mtlTexture:).

extension MTLTexture {
    func toCVPixelBuffer() -> CVPixelBuffer? {
        // In a real optimized app, this would use a CVPixelBuffer created via CVMetalTextureCache
        // to avoid a copy. The backing IOSurface is shared.
        // This is just a stub to indicate the logic flow.
        return nil 
    }
}
