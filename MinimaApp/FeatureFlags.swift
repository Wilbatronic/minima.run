import Foundation

/// "The Gatekeeper"
/// A/B Testing and Feature Flags for gradual rollout.
public class FeatureFlags: ObservableObject {
    public static let shared = FeatureFlags()
    
    // Feature flags with default values
    @Published public var flags: [String: Bool] = [
        "flashAttention": true,
        "slidingWindow": true,
        "voiceInput": true,
        "voiceOutput": true,
        "webSearch": true,
        "newOnboarding": false,
        "betaUI": false,
        "speculativeDecoding": false
    ]
    
    // A/B test assignments
    @Published public var experiments: [String: String] = [:]
    
    private init() {
        loadLocalOverrides()
        fetchRemoteFlags()
    }
    
    /// Check if a feature is enabled
    public func isEnabled(_ feature: String) -> Bool {
        return flags[feature] ?? false
    }
    
    /// Get experiment variant
    public func variant(for experiment: String) -> String {
        return experiments[experiment] ?? "control"
    }
    
    /// Assign user to an experiment
    public func assignExperiment(_ experiment: String, variants: [String], weights: [Double]? = nil) {
        guard experiments[experiment] == nil else { return } // Already assigned
        
        // Simple random assignment (equal weights if not specified)
        let selected = variants.randomElement() ?? "control"
        experiments[experiment] = selected
        
        // Persist
        saveExperiments()
        
        Analytics.shared.track(.featureUsed("experiment_\(experiment)_\(selected)"))
    }
    
    // MARK: - Persistence
    
    private func loadLocalOverrides() {
        if let stored = UserDefaults.standard.dictionary(forKey: "minima.featureFlags") as? [String: Bool] {
            for (key, value) in stored {
                flags[key] = value
            }
        }
        if let stored = UserDefaults.standard.dictionary(forKey: "minima.experiments") as? [String: String] {
            experiments = stored
        }
    }
    
    private func saveExperiments() {
        UserDefaults.standard.set(experiments, forKey: "minima.experiments")
    }
    
    private func fetchRemoteFlags() {
        // In production, fetch from Firebase Remote Config or similar
        // For now, use local values
    }
    
    /// Override a flag (for testing)
    public func setFlag(_ feature: String, enabled: Bool) {
        flags[feature] = enabled
        var stored = UserDefaults.standard.dictionary(forKey: "minima.featureFlags") as? [String: Bool] ?? [:]
        stored[feature] = enabled
        UserDefaults.standard.set(stored, forKey: "minima.featureFlags")
    }
}
