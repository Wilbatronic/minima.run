import Cocoa
import CoreGraphics

/// Keyboard Input Driver
/// Handles programmatic keyboard event injection with simulated timing.
/// Interfaces with CoreGraphics/HID to simulate user input.
public class KeyboardDriver {
    public static let shared = KeyboardDriver()
    
    // Typing speed simulation (characters per second)
    private let typingSpeed: Double = 15.0 // ~90 WPM
    
    private init() {}
    
    /// Types a string with human-like delays
    public func type(_ text: String) async {
        for char in text {
            // Generate key event
            postKeyEvent(character: char)
            
            // Human-like delay
            let delay = 1.0 / typingSpeed + Double.random(in: -0.02...0.02)
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
    }
    
    /// Types instantly (for paste-like operations)
    public func typeInstant(_ text: String) {
        for char in text {
            postKeyEvent(character: char)
        }
    }
    
    /// Presses a special key (Enter, Tab, Escape, etc.)
    public func pressKey(_ keyCode: CGKeyCode, modifiers: CGEventFlags = []) {
        guard let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false) else { return }
        
        keyDown.flags = modifiers
        keyUp.flags = modifiers
        
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
    
    /// Common key shortcuts
    public func pressEnter() { pressKey(0x24) }
    public func pressTab() { pressKey(0x30) }
    public func pressEscape() { pressKey(0x35) }
    public func pressBackspace() { pressKey(0x33) }
    
    /// Keyboard shortcuts
    public func copy() { pressKey(0x08, modifiers: .maskCommand) } // Cmd+C
    public func paste() { pressKey(0x09, modifiers: .maskCommand) } // Cmd+V
    public func selectAll() { pressKey(0x00, modifiers: .maskCommand) } // Cmd+A
    
    private func postKeyEvent(character: Character) {
        let str = String(character)
        guard let unicodeScalar = str.unicodeScalars.first else { return }
        
        // For regular characters, use CGEvent with unicode
        guard let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false) else { return }
        
        var char = UniChar(unicodeScalar.value)
        keyDown.keyboardSetUnicodeString(stringLength: 1, unicodeString: &char)
        keyUp.keyboardSetUnicodeString(stringLength: 1, unicodeString: &char)
        
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}
