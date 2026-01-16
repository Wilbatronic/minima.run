import Foundation

/// "The Sleeper"
/// Manages lazy loading of LLM models.
/// The 3B "Scout" is always warm. The 7B "Sovereign" only loads on first Pro query.
/// Saves 2GB+ idle RAM and 3-5 seconds of launch time.
public class ModelLoader: ObservableObject {
    public static let shared = ModelLoader()
    
    public enum ModelTier {
        case scout      // 3B - Always loaded
        case sovereign  // 7B - Loaded on demand
    }
    
    @Published public var scoutLoaded: Bool = false
    @Published public var sovereignLoaded: Bool = false
    @Published public var isLoadingSovereign: Bool = false
    
    // Paths (would be configured via app bundle)
    private let scoutPath = "Models/qwen-3b-q4_k_s.gguf"
    private let sovereignPath = "Models/qwen-7b-q5_k_m.gguf"
    
    // References (in real impl, these would be llama_model pointers)
    private var scoutModel: Any?
    private var sovereignModel: Any?
    
    private init() {}
    
    /// Called at app launch - only loads the small model
    public func warmUp() {
        DispatchQueue.global(qos: .userInitiated).async {
            print("[ModelLoader] Loading Scout (3B)...")
            // LLMBridge.loadModel(self.scoutPath)
            Thread.sleep(forTimeInterval: 0.5) // Simulated load
            
            DispatchQueue.main.async {
                self.scoutLoaded = true
                print("[ModelLoader] Scout ready.")
            }
        }
    }
    
    /// Called on first Pro-tier query
    public func loadSovereignIfNeeded() async {
        guard !sovereignLoaded && !isLoadingSovereign else { return }
        
        await MainActor.run {
            self.isLoadingSovereign = true
        }
        
        print("[ModelLoader] Loading Sovereign (7B)...")
        // LLMBridge.loadModel(self.sovereignPath)
        try? await Task.sleep(nanoseconds: 2_000_000_000) // Simulated load (2s)
        
        await MainActor.run {
            self.sovereignLoaded = true
            self.isLoadingSovereign = false
            print("[ModelLoader] Sovereign ready.")
        }
    }
    
    /// Returns the best available model based on thermal state and what's loaded
    public func bestAvailableModel() -> ModelTier {
        // Check thermal constraints first
        if !ThermalManager.shared.shouldUseLargeModel {
            return .scout
        }
        
        // Check if user is Pro
        if !BillingManager.shared.isPro {
            return .scout
        }
        
        // Check if sovereign is loaded
        if sovereignLoaded {
            return .sovereign
        }
        
        // Trigger lazy load for next time
        Task {
            await loadSovereignIfNeeded()
        }
        
        // For now, use scout
        return .scout
    }
}
