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
    
    /// Get current context for inference, including RAG-retrieved memories
    public func getContext(query: String? = nil) async -> (summary: [Float]?, tokens: [Int32], memories: [String]) {
        var memories: [String] = []
        
        if let query = query {
            memories = await retrieveRelevantContext(for: query)
        }
        
        return (compressedSummary, tokens, memories)
    }
    
    private func retrieveRelevantContext(for query: String) async -> [String] {
        // Use keyword-based search from ConversationHistory
        let messages = await ConversationHistory.shared.searchMessages(query: query)
        
        // Take top 3 most recent relevant messages
        return messages.prefix(3).map { "[\($0.role)]: \($0.content)" }
    }
    
    /// Compress old tokens into a summary embedding
    private func compress() {
        let tokensToCompress = tokens.count - windowSize
        guard tokensToCompress > 0 else { return }
        
        // Extract tokens to compress
        let oldTokens = Array(tokens.prefix(tokensToCompress))
        
        // Keep recent tokens
        tokens = Array(tokens.suffix(windowSize))
        
        // Generate summary embedding
        compressedSummary = generateSummaryEmbedding(from: oldTokens)
        
        print("[SlidingWindow] Compressed \(tokensToCompress) tokens into summary.")
    }
    
    private func generateSummaryEmbedding(from tokens: [Int32]) -> [Float] {
        // Simple mean pooling simulation (fixed size 4096)
        return Array(repeating: Float(tokens.reduce(0, +)) / Float(max(1, tokens.count)), count: 4096)
    }
    
    /// Clear all context
    public func clear() {
        tokens = []
        compressedSummary = nil
    }
}
