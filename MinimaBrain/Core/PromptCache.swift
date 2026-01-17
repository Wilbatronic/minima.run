import Foundation

/// "The Muscle Memory"
/// Pre-tokenizes and caches the System Prompt KV states.
/// Formalized as an Actor for thread-safe state and disk I/O.
public actor PromptCache {
    public static let shared = PromptCache()
    
    private let cacheFileName = "system_prompt.cache"
    private var systemPromptTokens: [Int32]?
    
    private var cacheURL: URL {
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent(cacheFileName)
    }
    
    private init() {
        // Initialization in Actor
    }
    
    /// Call this once at startup to pre-tokenize the system prompt
    public func warmUp(systemPrompt: String, tokenizer: @escaping @Sendable (String) async -> [Int32]) async {
        let contentHash = String(systemPrompt.hashValue)
        
        // Load from disk if not in memory
        if systemPromptTokens == nil {
            await loadFromDisk()
        }
        
        if systemPromptTokens != nil, UserDefaults.standard.string(forKey: "minima.promptHash") == contentHash {
            print("[PromptCache] Cache hit.")
            return
        }
        
        let tokens = await tokenizer(systemPrompt)
        self.systemPromptTokens = tokens
        await saveToDisk()
        UserDefaults.standard.set(contentHash, forKey: "minima.promptHash")
        print("[PromptCache] Tokenized and cached \(tokens.count) system tokens.")
    }
    
    private func saveToDisk() {
        guard let tokens = systemPromptTokens else { return }
        let data = Data(buffer: UnsafeBufferPointer(start: tokens, count: tokens.count))
        try? data.write(to: cacheURL)
    }
    
    private func loadFromDisk() {
        guard let data = try? Data(contentsOf: cacheURL) else { return }
        let count = data.count / MemoryLayout<Int32>.stride
        systemPromptTokens = data.withUnsafeBytes { ptr in
            Array(UnsafeBufferPointer(start: ptr.baseAddress?.assumingMemoryBound(to: Int32.self), count: count))
        }
        print("[PromptCache] Loaded \(count) tokens from disk.")
    }
    
    /// Returns the cached tokens if available
    public func getCachedTokens() -> [Int32]? {
        return systemPromptTokens
    }
    
    /// Clears the cache
    public func invalidate() async {
        systemPromptTokens = nil
        try? FileManager.default.removeItem(at: cacheURL)
        UserDefaults.standard.removeObject(forKey: "minima.promptHash")
    }
}
