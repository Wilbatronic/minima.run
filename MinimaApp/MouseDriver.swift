import Cocoa
import CoreGraphics

/// "The Spinal Cord"
/// Handles the actual movement of the mouse with a Negative Feedback Loop (PID Controller)
/// to ensure the cursor lands exactly where intended, countering macOS acceleration curves.
public class MouseDriver {
    public static let shared = MouseDriver()
    
    private var isDriving: Bool = false
    
    // PID Gains (Tuned for macOS Mouse Acceleration)
    private let Kp: CGFloat = 0.6  // Proportional (Speed to target)
    private let Ki: CGFloat = 0.01 // Integral (Accumulated error correction)
    private let Kd: CGFloat = 0.2  // Derivative (Damping to prevent overshoot)
    
    private var integralX: CGFloat = 0
    private var integralY: CGFloat = 0
    private var lastErrorX: CGFloat = 0
    private var lastErrorY: CGFloat = 0
    
    /// Moves the mouse to the target point using a control loop.
    /// This is blocking (for the actor) but runs smooth intervals.
    public func move(to target: CGPoint) async {
        isDriving = true
        defer { isDriving = false }
        
        var current = getCurrentMouseLocation()
        var errorX = target.x - current.x
        var errorY = target.y - current.y
        
        // Reset PID State
        integralX = 0; integralY = 0
        lastErrorX = errorX; lastErrorY = errorY
        
        // "The Loop": Run at 120Hz control frequency
        while abs(errorX) > 2.0 || abs(errorY) > 2.0 {
            // 1. Calculate PID Output
            integralX += errorX
            integralY += errorY
            
            let derivativeX = errorX - lastErrorX
            let derivativeY = errorY - lastErrorY
            
            // Output = Velocity vector
            let driveX = (Kp * errorX) + (Ki * integralX) + (Kd * derivativeX)
            let driveY = (Kp * errorY) + (Ki * integralY) + (Kd * derivativeY)
            
            // 2. Actuate (Apply movement)
            // We use CGEvent to warp position relative to current, or generate drag events
            postMouseEvent(x: current.x + driveX * 0.2, y: current.y + driveY * 0.2) // 0.2 is Delta Time factor approx
            
            // 3. Wait (Simulate Physics / Refresh Rate)
            try? await Task.sleep(nanoseconds: 8_000_000) // ~8ms
            
            // 4. Feedback Measure (Where are we actually?)
            current = getCurrentMouseLocation()
            
            // 5. Update Error (Negative Feedback)
            lastErrorX = errorX
            lastErrorY = errorY
            errorX = target.x - current.x
            errorY = target.y - current.y
            
            // Safety break
            if !isDriving { break }
        }
        
        // Final snap to ensure pixel perfection (Integral windup might leave us 1px off)
        postMouseEvent(x: target.x, y: target.y)
    }
    
    private func getCurrentMouseLocation() -> CGPoint {
        // In macOS, screen coords are bottom-left usually, but CGEvent uses top-left.
        // We assume CGEvent context here.
        return CGEvent(source: nil)?.location ?? .zero
    }
    
    private func postMouseEvent(x: CGFloat, y: CGFloat) {
        guard let event = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: CGPoint(x: x, y: y), mouseButton: .left) else { return }
        event.post(tap: .cghidEventTap)
    }
}
