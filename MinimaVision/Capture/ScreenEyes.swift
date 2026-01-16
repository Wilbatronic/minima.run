import ScreenCaptureKit
import CoreMedia
import Metal

@available(macOS 14.0, *)
public actor ScreenEyes: NSObject, SCStreamOutput, SCStreamDelegate {
    
    private let videoSampleBufferQueue = DispatchQueue(label: "com.minima.ScreenEyes.video", qos: .userInteractive)
    private var stream: SCStream?
    private let textureUtils = TextureUtils.shared
    
    // Callback for when a new normalized frame is ready for inference
    public var onFrameReady: ((MTLBuffer) -> Void)?
    
    private let device = MTLCreateSystemDefaultDevice()!
    
    public override init() {
        super.init()
    }
    
    public func startCapture() async throws {
        // 1. Get Shareable Content (Windows/Displays)
        let content = try await SCShareableContent.current
        
        guard let display = content.displays.first else {
            throw NSError(domain: "ScreenEyes", code: 1, userInfo: [NSLocalizedDescriptionKey: "No display found"])
        }
        
        // 2. Configure Filter (Capture entire screen, exclude nothing for now)
        let filter = SCContentFilter(display: display, excludingWindows: [])
        
        // 3. Configure Configuration (Resolution, Format)
        let config = SCStreamConfiguration()
        config.width = display.width
        config.height = display.height
        config.pixelFormat = kCVPixelFormatType_BGRA8Unorm // Metal friendly
        config.showsCursor = true
        config.queueDepth = 3 // Keep latency low, drop old frames
        
        // 4. Create Stream
        stream = SCStream(filter: filter, configuration: config, delegate: self)
        
        // 5. Add Output
        try stream?.addStreamOutput(self, type: .screen, sampleHandlerQueue: videoSampleBufferQueue)
        
        // 6. Start
        try await stream?.startCapture()
        print("ScreenEyes: Loop started on Display \(display.displayID)")
    }
    
    public func stopCapture() async {
        try? await stream?.stopCapture()
        stream = nil
    }
    
    // State for Hashing
    private var hashBuffer: MTLBuffer?
    private var lastHash: [Float] = Array(repeating: 0, count: 64)
    private var frameCount: Int = 0
    
    // MARK: - SCStreamOutput
    
    nonisolated public func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen, let imageBuffer = sampleBuffer.imageBuffer else { return }
        // setup state lazily
        if hashBuffer == nil {
             hashBuffer = device.makeBuffer(length: 64 * MemoryLayout<Float>.size, options: .storageModeShared)
        }
        
        // 0. NEGATIVE FEEDBACK LOOP: Mouse Volatility
        // If the user is moving the mouse rapidly, the screen is unstable. 
        // We skip processing to provide "Negative Feedback" to the sampler.
        if MouseMonitor.shared.shouldThrottle() {
            // print("Frame throttled due to mouse interaction.")
            return
        }
        
        // 1. Compute Hash ("The Trick")
        textureUtils.computeHash(texture: texture, into: hashBuffer!)
        
        // 2. Compare Hash
        let ptr = hashBuffer!.contents().bindMemory(to: Float.self, capacity: 64)
        var totalDelta: Float = 0
        var currentHash: [Float] = []
        
        for i in 0..<64 {
            let val = ptr[i]
            currentHash.append(val)
            totalDelta += abs(val - lastHash[i])
        }
        
        // Threshold: 10.0 is arbitrary, needs tuning based on luminance scale. 
        // If screen is effectively static, SKIP EVERYTHING.
        if totalDelta < 5.0 && frameCount > 0 {
             // print("Static frame skipped. Power saved.")
             return 
        }
        
        // Update History
        lastHash = currentHash
        frameCount += 1
        
        // 3. Proceed to Heavy Lifting if changed...
        // Create a destination buffer for the Tensor
        // OPTIMIZATION: Use Float16 (2 bytes) for "Hyper-Optimization" of bandwidth.
        // Size: Width * Height * 3 (RGB) * 2 (Float16)
        let tensorSize = texture.width * texture.height * 3 * 2 
        guard let outputBuffer = device.makeBuffer(length: tensorSize, options: .storageModeShared) else { return }
        
        // Dispatch to Metal
        let mean: [Float] = [0.48145466, 0.4578275, 0.40821073]
        let std: [Float] = [0.26862954, 0.26130258, 0.27577711]
        
        TextureUtils.shared.normalize(texture: texture, into: outputBuffer, mean: mean, std: std)
        
        Task {
            await self.notifyFrame(buffer: outputBuffer)
        }
    }
    
    private func notifyFrame(buffer: MTLBuffer) {
        onFrameReady?(buffer)
    }
    
    // Helper to wrap CVPixelBuffer in MTLTexture
    private func createMTLTexture(from pixelBuffer: CVPixelBuffer) -> MTLTexture? {
        var textureRef: CVMetalTexture?
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        // This is expensive to create every frame without a Cache, but valid for prototype
        // In prod: Use CVMetalTextureCache
        CVMetalTextureCacheCreateTextureFromImage(
            kCFAllocatorDefault,
            GlobalTextureCache.shared.cache!, // Assume global cache exists
            pixelBuffer,
            nil,
            .bgra8Unorm,
            width,
            height,
            0,
            &textureRef
        )
        
        if let textureRef = textureRef {
            return CVMetalTextureGetTexture(textureRef)
        }
        return nil
    }
}

// Minimal Global Cache helper
class GlobalTextureCache {
    static let shared = GlobalTextureCache()
    var cache: CVMetalTextureCache?
    private init() {
        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, MTLCreateSystemDefaultDevice()!, nil, &cache)
    }
}
