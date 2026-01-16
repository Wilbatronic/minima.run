import Foundation

/// "The Watcher"
/// Privacy-first analytics using TelemetryDeck.
/// All data is anonymized and aggregated. No PII collected.
public class Analytics {
    public static let shared = Analytics()
    
    // TelemetryDeck App ID (Get from telemetrydeck.com)
    private let appID = "YOUR_APP_ID_HERE"
    
    // User opt-in status
    public var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "minima.analyticsEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "minima.analyticsEnabled") }
    }
    
    private init() {}
    
    /// Track an event
    public func track(_ event: AnalyticsEvent) {
        guard isEnabled else { return }
        
        // In production, this would call TelemetryDeck SDK
        // TelemetryDeck.signal(event.name, parameters: event.parameters)
        
        print("[Analytics] \(event.name): \(event.parameters)")
    }
    
    /// Standard events
    public func trackAppLaunch() {
        track(.appLaunch)
    }
    
    public func trackQuery(modelTier: String, latencyMs: Int) {
        track(.query(modelTier: modelTier, latencyMs: latencyMs))
    }
    
    public func trackSubscription(action: String) {
        track(.subscription(action: action))
    }
    
    public func trackFeatureUsed(_ feature: String) {
        track(.featureUsed(feature))
    }
}

public enum AnalyticsEvent {
    case appLaunch
    case query(modelTier: String, latencyMs: Int)
    case subscription(action: String)
    case featureUsed(String)
    
    var name: String {
        switch self {
        case .appLaunch: return "app_launch"
        case .query: return "query"
        case .subscription: return "subscription"
        case .featureUsed: return "feature_used"
        }
    }
    
    var parameters: [String: String] {
        switch self {
        case .appLaunch:
            return ["platform": ProcessInfo.processInfo.operatingSystemVersionString]
        case .query(let tier, let latency):
            return ["model_tier": tier, "latency_ms": String(latency)]
        case .subscription(let action):
            return ["action": action]
        case .featureUsed(let feature):
            return ["feature": feature]
        }
    }
}
