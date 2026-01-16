import Foundation

/// "The Forget-Me-Not"
/// Implements sliding window context compression.
/// When context exceeds limit, compresses old tokens into a summary embedding.
public class SlidingWindowContext {
    public static let shared = SlidingWindowContext()
    
    // Max tokens before compression kicks in
    private let maxContextTokens = 4096
    private let windowSize = 3072        // Keep recent
    private let compressionTarget = 512  // Compress old to this size
    
    // Current context state
    private var tokens: [Int32] = []
    private var compressedSummary: [Float]? // Embedding of old context
    
    private init() {}
    
    /// Add new tokens to context
    public func append(newTokens: [Int32]) {
        tokens.append(contentsOf: newTokens)
        
        if tokens.count > maxContextTokens {
            compress()
        }
    }
    
    /// Get current context for inference
    public func getContext() -> (summary: [Float]?, tokens: [Int32]) {
        return (compressedSummary, tokens)
    }
    
    /// Compress old tokens into a summary embedding
    private func compress() {
        let tokensToCompress = tokens.count - windowSize
        guard tokensToCompress > 0 else { return }
        
        // Extract tokens to compress
        let oldTokens = Array(tokens.prefix(tokensToCompress))
        
        // Keep recent tokens
        tokens = Array(tokens.suffix(windowSize))
        
        // Generate summary embedding (would use the LLM's hidden states)
        // For now, placeholder - in real impl, run a pooling layer
        compressedSummary = generateSummaryEmbedding(from: oldTokens)
        
        print("[SlidingWindow] Compressed \(tokensToCompress) tokens into summary.")
    }
    
    private func generateSummaryEmbedding(from tokens: [Int32]) -> [Float] {
        // Placeholder: In real implementation, this would:
        // 1. Run tokens through the model
        // 2. Extract the last hidden state
        // 3. Apply mean pooling
        // 4. Return a fixed-size embedding (e.g., 4096 floats)
        return Array(repeating: 0.0, count: 4096)
    }
    
    /// Clear all context
    public func clear() {
        tokens = []
        compressedSummary = nil
    }
}
