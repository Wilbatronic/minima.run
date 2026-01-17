import Foundation
import Combine
import CoreML

@available(macOS 14.0, iOS 17.0, *)
@MainActor
public class MinimaBrain: ObservableObject {
    
    // Subsystems
    private let eyes = ScreenEyes()
    private let vision = VisionProcessor()
    private let llm: LLMBridge // This would be injected or shared
    
    // State
    @Published public var isThinking: Bool = false
    @Published public var currentThought: String = ""
    @Published public var answer: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    public init() {
        // Initialize bridging (Mock path for now)
        self.llm = LLMBridge(modelPath: "path/to/qwen-7b-q5_k_m.gguf")
        
        setupPipeline()
    }
    
    private func setupPipeline() {
        // 1. Eye -> Vision Processor
        // ScreenEyes actor pushes frames to us via a callback or stream.
        // We'll use the callback we defined in ScreenEyes.
        Task {
            await eyes.onFrameReady = { [weak self] metalBuffer in
                self?.handleNewFrame(buffer: metalBuffer)
            }
        }
        
        // 2. Vision -> Brain (Vanguard Delta-Gating)
        vision.onEmbeddingsGenerated = { [weak self] embeddings in
            Task { @MainActor in
                guard let self = self else { return }
                
                // Vanguard Optimization: Only ingest if the visual delta is above threshold
                // This prevents redundant "eye" processing on static screens.
                let delta = await self.eyes.getLastFrameDelta()
                if delta > 0.05 { // 5% change threshold
                    self.handleVisualEmbeddings(embeddings)
                } else {
                    print("[Vanguard] Visual Delta (\(delta)) below threshold. Skipping redundant ingestion.")
                }
            }
        }
        
        // 3. Synapse (Mesh) -> Brain
        Synapse.shared.incomingThoughts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] thought in
                print("[Brain] Received telepathic thought: \(thought)")
                self?.currentThought = thought
                self?.isThinking = true
                // In a full implementation, we might ingest this as 'User Context' or 'Shared Memory'
            }
            .store(in: &cancellables)
            
        // Start Mesh
        Synapse.shared.start()
    }
    
    // MARK: - Public Intents
    
    public func startLooking() {
        Task {
            do {
                try await eyes.startCapture()
            } catch {
                print("Failed to start eyes: \(error)")
            }
        }
    }
    
    public func stopLooking() {
        Task {
            await eyes.stopCapture()
        }
    }
    
    public func ask(_ prompt: String) {
        DispatchQueue.main.async {
            self.isThinking = true
            self.currentThought = "Analyzing..."
        }
        
        // In a real app, this would be triggering the LLM generation loop
        // We simulate it here using the Bridge
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            let response = await self.llm.generateResponse(forPrompt: prompt)
            
            await MainActor.run {
                self.answer = response
                self.isThinking = false
            }
        }
    }
    
    // MARK: - Pipeline Handlers
    
    private func handleNewFrame(buffer: MTLBuffer) {
        // This is where "The Glance" happens.
        // In this architecture, we pass the buffer to VisionProcessor to get CoreML embeddings.
        // We need to convert buffer back to texture or refactor VisionProcessor to accept buffer.
        // For now, let's assume VisionProcessor runs its logic.
        // In the real code, we'd pass the texture direct from ScreenEyes -> VisionProcessor.
        // Let's correct the flow: ScreenEyes -> (MTLTexture) -> VisionProcessor.
        
        // Since ScreenEyes currently emits MTLBuffer (normalized), we might skip VisionProcessor 
        // if we are feeding raw pixels to LLM (unlikely for Qwen).
        // Let's assume ScreenEyes *also* allows access to the texture for the CoreML encoder.
        
        print("Brain received frame buffer of size: \(buffer.length)")
    }
    
    private func handleVisualEmbeddings(_ embeddings: MLMultiArray) {
        // Pass embeddings to LLM
        // LLMBridge takes float pointer.
        let count = embeddings.count
        embeddings.withUnsafeBufferPointer(ofType: Float.self) { ptr in
            if let baseAddress = ptr.baseAddress {
               // self.llm.ingestImageEmbeddings(baseAddress, length: count)
            }
        }
        print("Brain ingested visual embeddings.")
    }
}
