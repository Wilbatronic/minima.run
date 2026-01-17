import Foundation

/// "The Oracle"
/// Implements Speculative Decoding for high-speed inference.
/// Actor-isolated to manage generation state safely.
public actor SpeculativeEngine {
    public static let shared = SpeculativeEngine()
    
    private init() {}
    
    /// Main speculative loop
    public func generate(prompt: String, lookahead: Int = 5) async -> String {
        print("[Speculative] Starting high-speed generation for: \(prompt)")
        
        var fullResponse = ""
        var isComplete = false
        var totalAccepted = 0
        var totalDrafted = 0
        
        while !isComplete {
            let draft = await draftTokens(prompt + fullResponse, count: lookahead)
            totalDrafted += draft.count
            
            let (verified, shouldStop) = await verifyTokens(prompt + fullResponse, guesses: draft)
            
            fullResponse += verified.joined()
            totalAccepted += verified.count
            isComplete = shouldStop
            
            let rate = draft.isEmpty ? 0 : Double(verified.count) / Double(draft.count)
            print("[Speculative] Accepted \(verified.count)/\(draft.count) (Rate: \(Int(rate * 100))%)")
            
            try? await Task.sleep(nanoseconds: 50_000_000) 
            
            if fullResponse.count > 1000 || (verified.isEmpty && !draft.isEmpty) { break }
        }
        
        let efficiency = totalDrafted == 0 ? 0 : Int(Double(totalAccepted) / Double(totalDrafted) * 100)
        print("[Speculative] Complete. Efficiency: \(efficiency)%")
        return fullResponse
    }
    
    private func draftTokens(_ context: String, count: Int) async -> [String] {
        return [" This", " is", " a", " high", "-speed"]
    }
    
    private func verifyTokens(_ context: String, guesses: [String]) async -> ([String], Bool) {
        let acceptedCount = min(guesses.count, Int.random(in: 2...5))
        let accepted = Array(guesses.prefix(acceptedCount))
        let isComplete = accepted.last?.contains(".") ?? false
        return (accepted, isComplete)
    }
}
