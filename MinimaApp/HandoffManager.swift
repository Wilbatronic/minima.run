import Foundation
import Combine

/// "The Bridge"
/// Enables Handoff between Mac and iPhone.
/// Pick up a conversation mid-sentence on another device.
public class HandoffManager: NSObject, ObservableObject {
    public static let shared = HandoffManager()
    
    // Handoff activity type
    private let activityType = "com.minima.conversation"
    
    @Published public var incomingConversation: HandoffPayload?
    
    private override init() {
        super.init()
    }
    
    /// Start advertising current conversation for Handoff
    public func advertise(conversationId: String, currentQuery: String, partialResponse: String) {
        #if os(macOS)
        let activity = NSUserActivity(activityType: activityType)
        activity.title = "Continue in Minima"
        activity.isEligibleForHandoff = true
        activity.userInfo = [
            "conversationId": conversationId,
            "query": currentQuery,
            "partialResponse": partialResponse,
            "timestamp": Date().timeIntervalSince1970
        ]
        activity.becomeCurrent()
        #endif
    }
    
    /// Handle incoming Handoff (called from AppDelegate/SceneDelegate)
    public func handleIncoming(_ userActivity: NSUserActivity) -> Bool {
        guard userActivity.activityType == activityType,
              let userInfo = userActivity.userInfo else { return false }
        
        let payload = HandoffPayload(
            conversationId: userInfo["conversationId"] as? String ?? "",
            query: userInfo["query"] as? String ?? "",
            partialResponse: userInfo["partialResponse"] as? String ?? ""
        )
        
        DispatchQueue.main.async {
            self.incomingConversation = payload
        }
        
        print("[Handoff] Received conversation: \(payload.conversationId)")
        return true
    }
}

public struct HandoffPayload {
    public let conversationId: String
    public let query: String
    public let partialResponse: String
}

// MARK: - App Integration
// In your App.swift or SceneDelegate:
/*
 .onContinueUserActivity("com.minima.conversation") { activity in
     _ = HandoffManager.shared.handleIncoming(activity)
 }
*/
