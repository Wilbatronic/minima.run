import Cocoa
import ApplicationServices

/// "The Eyes That Read"
/// Bridges to macOS Accessibility APIs to read UI elements.
/// Enables the agent to understand buttons, menus, text fields without vision.
public class AXBridge {
    public static let shared = AXBridge()
    
    private init() {}
    
    /// Checks if we have Accessibility permissions
    public var hasPermission: Bool {
        return AXIsProcessTrusted()
    }
    
    /// Prompts user to grant Accessibility permissions
    public func requestPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    /// Gets the focused UI element
    public func getFocusedElement() -> AXUIElement? {
        var focusedApp: AnyObject?
        let systemWide = AXUIElementCreateSystemWide()
        
        guard AXUIElementCopyAttributeValue(systemWide, kAXFocusedApplicationAttribute as CFString, &focusedApp) == .success,
              let app = focusedApp else { return nil }
        
        var focusedElement: AnyObject?
        guard AXUIElementCopyAttributeValue(app as! AXUIElement, kAXFocusedUIElementAttribute as CFString, &focusedElement) == .success else { return nil }
        
        return focusedElement as! AXUIElement?
    }
    
    /// Gets all UI elements under a point
    public func getElementAt(point: CGPoint) -> [String: Any]? {
        let systemWide = AXUIElementCreateSystemWide()
        var element: AXUIElement?
        
        guard AXUIElementCopyElementAtPosition(systemWide, Float(point.x), Float(point.y), &element) == .success,
              let el = element else { return nil }
        
        return describeElement(el)
    }
    
    /// Describes a UI element as a dictionary
    public func describeElement(_ element: AXUIElement) -> [String: Any] {
        var info: [String: Any] = [:]
        
        // Role
        var role: AnyObject?
        if AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &role) == .success {
            info["role"] = role as? String
        }
        
        // Title
        var title: AnyObject?
        if AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &title) == .success {
            info["title"] = title as? String
        }
        
        // Value
        var value: AnyObject?
        if AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &value) == .success {
            info["value"] = value as? String
        }
        
        // Description
        var desc: AnyObject?
        if AXUIElementCopyAttributeValue(element, kAXDescriptionAttribute as CFString, &desc) == .success {
            info["description"] = desc as? String
        }
        
        // Position
        var positionValue: AnyObject?
        if AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &positionValue) == .success {
            var point = CGPoint.zero
            AXValueGetValue(positionValue as! AXValue, .cgPoint, &point)
            info["position"] = ["x": point.x, "y": point.y]
        }
        
        // Size
        var sizeValue: AnyObject?
        if AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeValue) == .success {
            var size = CGSize.zero
            AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)
            info["size"] = ["width": size.width, "height": size.height]
        }
        
        return info
    }
    
    /// Performs an action on a UI element (click, press, etc.)
    public func performAction(_ action: String, on element: AXUIElement) -> Bool {
        return AXUIElementPerformAction(element, action as CFString) == .success
    }
    
    /// Common actions
    public func click(_ element: AXUIElement) -> Bool {
        return performAction(kAXPressAction as String, on: element)
    }
}
