import ActivityKit
import WidgetKit
import SwiftUI

/// "The Pulse"
/// Live Activities for Dynamic Island (iPhone 14+) and Lock Screen.
/// Shows real-time thinking status and token generation progress.

struct MinimaActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var status: String      // "Thinking...", "Generating...", "Done"
        var progress: Double    // 0.0 to 1.0
        var tokensGenerated: Int
        var estimatedTimeRemaining: Int // seconds
    }
    
    var query: String
    var startTime: Date
}

@available(iOS 16.1, *)
public class LiveActivityManager {
    public static let shared = LiveActivityManager()
    
    private var currentActivity: Activity<MinimaActivityAttributes>?
    
    private init() {}
    
    /// Start a new Live Activity when inference begins
    public func startActivity(query: String) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        let attributes = MinimaActivityAttributes(query: query, startTime: Date())
        let state = MinimaActivityAttributes.ContentState(
            status: "Thinking...",
            progress: 0.0,
            tokensGenerated: 0,
            estimatedTimeRemaining: 30
        )
        
        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
            print("[LiveActivity] Started for query: \(query)")
        } catch {
            print("[LiveActivity] Failed to start: \(error)")
        }
    }
    
    /// Update progress during generation
    public func updateProgress(tokens: Int, progress: Double, eta: Int) {
        Task {
            let state = MinimaActivityAttributes.ContentState(
                status: "Generating...",
                progress: progress,
                tokensGenerated: tokens,
                estimatedTimeRemaining: eta
            )
            await currentActivity?.update(.init(state: state, staleDate: nil))
        }
    }
    
    /// Complete the activity
    public func finishActivity(response: String) {
        Task {
            let state = MinimaActivityAttributes.ContentState(
                status: "Done",
                progress: 1.0,
                tokensGenerated: response.count / 4, // Rough estimate
                estimatedTimeRemaining: 0
            )
            await currentActivity?.end(.init(state: state, staleDate: nil), dismissalPolicy: .after(.now + 5))
            currentActivity = nil
        }
    }
}

// MARK: - Live Activity UI (for Widget Extension)

@available(iOS 16.1, *)
struct MinimaLiveActivityView: View {
    let context: ActivityViewContext<MinimaActivityAttributes>
    
    var body: some View {
        HStack {
            // Icon
            Image(systemName: "sparkles")
                .foregroundStyle(.purple)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(context.state.status)
                    .font(.headline)
                
                if context.state.progress < 1.0 {
                    ProgressView(value: context.state.progress)
                        .tint(.purple)
                }
            }
            
            Spacer()
            
            // Token count
            Text("\(context.state.tokensGenerated)")
                .font(.caption.monospacedDigit())
                .foregroundColor(.secondary)
        }
        .padding()
    }
}
