import Metal
import MetalKit
import Accelerate

public class TextureUtils {
    public static let shared = TextureUtils()
    
    private let device: MTLDevice
    private let library: MTLLibrary?
    private let commandQueue: MTLCommandQueue?
    
    // Pipelines
    private var normalizePipeline: MTLComputePipelineState?
    private var resamplePipeline: MTLComputePipelineState?
    private var cropPipeline: MTLComputePipelineState?
    private var hashPipeline: MTLComputePipelineState?
    
    // MARK: - Perceptual Hash
    public func computeHash(texture: MTLTexture, into buffer: MTLBuffer) {
        guard let pipeline = hashPipeline,
              let cmdBuffer = commandQueue?.makeCommandBuffer(),
              let encoder = cmdBuffer.makeComputeCommandEncoder() else { return }
        
        encoder.setComputePipelineState(pipeline)
        encoder.setTexture(texture, index: 0)
        encoder.setBuffer(buffer, offset: 0, index: 0)
        
        // 8x8 Grid = 64 threads exactly. One threadgroup.
        let threadsPerGrid = MTLSizeMake(8, 8, 1)
        let threadsPerGroup = MTLSizeMake(8, 8, 1)
        
        encoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerGroup)
        encoder.endEncoding()
        
        // Block here? Or Async? Hash is needed for decision logic immediately.
        // Let's block for safety in this version to return a synchronous decision.
        cmdBuffer.commit()
        cmdBuffer.waitUntilCompleted()
    }

    public init() {
        guard let dev = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device.")
        }
        self.device = dev
        self.commandQueue = dev.makeCommandQueue()
        
        // Load default library
        do {
            self.library = try dev.makeDefaultLibrary(bundle: Bundle.main)
        } catch {
            print("Failed to load Metal library: \(error)")
            self.library = nil
        }
        
        setupPipelines()
    }
    
    private func setupPipelines() {
        guard let library = library else { return }
        
        do {
            if let normalizeFunc = library.makeFunction(name: "textureNormalizeAndPlanarize") {
                self.normalizePipeline = try device.makeComputePipelineState(function: normalizeFunc)
            }
            if let resampleFunc = library.makeFunction(name: "coarseResampler") {
                self.resamplePipeline = try device.makeComputePipelineState(function: resampleFunc)
            }
            if let cropFunc = library.makeFunction(name: "smartCropper") {
                self.cropPipeline = try device.makeComputePipelineState(function: cropFunc)
            }
            if let hashFunc = library.makeFunction(name: "perceptualHash") {
                self.hashPipeline = try device.makeComputePipelineState(function: hashFunc)
            }
        } catch {
            print("Failed to create pipelines: \(error)")
        }
    }
    
    // MARK: - Safe Execution Wrapper
    
    public func normalize(texture: MTLTexture, into buffer: MTLBuffer, mean: [Float], std: [Float]) {
        guard let pipeline = normalizePipeline,
              let cmdBuffer = commandQueue?.makeCommandBuffer(),
              let encoder = cmdBuffer.makeComputeCommandEncoder() else { return }
        
        encoder.setComputePipelineState(pipeline)
        encoder.setTexture(texture, index: 0)
        encoder.setBuffer(buffer, offset: 0, index: 0)
        
        var uniforms = InputUniforms(
            mean_r: mean[0], mean_g: mean[1], mean_b: mean[2],
            std_r: std[0], std_g: std[1], std_b: std[2]
        )
        encoder.setBytes(&uniforms, length: MemoryLayout<InputUniforms>.stride, index: 1)
        
        let width = pipeline.threadExecutionWidth
        let height = pipeline.maxTotalThreadsPerThreadgroup / width
        let threadsPerGroup = MTLSizeMake(width, height, 1)
        let threadsPerGrid = MTLSizeMake(texture.width, texture.height, 1)
        
        encoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerGroup)
        encoder.endEncoding()
        
        // ASYNC OPTIMIZATION: Do not block.
        cmdBuffer.addCompletedHandler { _ in
            // Optional: Signal a semaphore if needed, but for now we let the GPU fly.
        }
        cmdBuffer.commit()
    }
    
    // MARK: - FP16 Helper
    // Calculate required bytes for FP16 buffer
    public func requiredBufferSize(width: Int, height: Int) -> Int {
        return width * height * 3 * 2 // 2 bytes per half
    }
struct InputUniforms {
    var mean_r: Float
    var mean_g: Float
    var mean_b: Float
    var std_r: Float
    var std_g: Float
    var std_b: Float
}
