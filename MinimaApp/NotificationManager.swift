import UserNotifications

/// "The Herald"
/// Manages system notifications for background events.
public class NotificationManager {
    public static let shared = NotificationManager()
    
    private init() {}
    
    public func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }
    
    /// Notify when a background task completes
    public func notifyTaskComplete(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    /// Notify when a Synapse device connects
    public func notifyDeviceConnected(deviceName: String) {
        notifyTaskComplete(title: "Device Connected", body: "\(deviceName) joined your Minima mesh.")
    }
    
    /// Notify subscription status
    public func notifySubscriptionExpiring() {
        notifyTaskComplete(title: "Pro Subscription", body: "Your Minima Pro subscription is expiring soon.")
    }
}
