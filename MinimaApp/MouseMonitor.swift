import Cocoa
import Combine

/// Tracks mouse velocity to provide "Volatility" feedback.
/// High volatility = User is actively trashing/navigating -> Vision should back off.
public class MouseMonitor: ObservableObject {
    public static let shared = MouseMonitor()
    
    @Published public var volatility: Float = 0.0
    
    private var lastLocation: NSPoint = .zero
    private var lastTime: TimeInterval = 0
    
    private init() {
        // Global monitor (Requires Accessibility permissions, but local event tap works for app-centric too)
        // For a background agent, we need Global.
        NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .dragged]) { [weak self] event in
            self?.update(event)
        }
        NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .dragged]) { [weak self] event in
            self?.update(event)
            return event
        }
    }
    
    private func update(_ event: NSEvent) {
        let currentLocation = NSEvent.mouseLocation
        let currentTime = Date().timeIntervalSince1970
        
        if lastTime != 0 {
            let dx = Float(currentLocation.x - lastLocation.x)
            let dy = Float(currentLocation.y - lastLocation.y)
            let dt = Float(currentTime - lastTime)
            
            // Velocity in pixels per second
            let speed = sqrt(dx*dx + dy*dy) / (dt + 0.001)
            
            // Decay the volatility slowly, spike it on move
            // Negative feedback loop: More movement = Higher Volatility
            // We clamp it [0, 1.0] where 1.0 is "Chaos"
            let instantVolatility = min(speed / 2000.0, 1.0) // 2000px/s is fast
            
            // Smooth it: 80% old, 20% new
            volatility = volatility * 0.8 + instantVolatility * 0.2
        }
        
        lastLocation = currentLocation
        lastTime = currentTime
    }
    
    /// Returns true if the vision pipeline should throttle based on mouse chaos.
    public func shouldThrottle() -> Bool {
        return volatility > 0.3 // Threshold for "Active Movement"
    }
}
