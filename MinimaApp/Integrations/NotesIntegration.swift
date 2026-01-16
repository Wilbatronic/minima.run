import Foundation

/// "The Scribe"
/// Saves AI responses to Apple Notes.
public class NotesIntegration {
    public static let shared = NotesIntegration()
    
    private init() {}
    
    /// Save to Notes via AppleScript (macOS) or URL scheme (iOS)
    public func saveToNotes(title: String, content: String) {
        #if os(macOS)
        saveToNotesMac(title: title, content: content)
        #else
        saveToNotesIOS(title: title, content: content)
        #endif
    }
    
    #if os(macOS)
    private func saveToNotesMac(title: String, content: String) {
        let escapedTitle = title.replacingOccurrences(of: "\"", with: "\\\"")
        let escapedContent = content.replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
        
        let script = """
        tell application "Notes"
            tell account "iCloud"
                make new note at folder "Notes" with properties {name:"\(escapedTitle)", body:"\(escapedContent)"}
            end tell
        end tell
        """
        
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&error)
            
            if let error = error {
                print("[Notes] AppleScript error: \(error)")
            } else {
                print("[Notes] Saved note: \(title)")
            }
        }
    }
    #endif
    
    #if os(iOS)
    private func saveToNotesIOS(title: String, content: String) {
        // On iOS, we can use the share sheet or create a Shortcut
        // For direct integration, user needs to install our Shortcut
        let fullContent = "# \(title)\n\n\(content)"
        
        // Create temporary file for sharing
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(title).txt")
        
        do {
            try fullContent.write(to: tempURL, atomically: true, encoding: .utf8)
            // Would present share sheet here in actual UI
        } catch {
            print("[Notes] Failed to save: \(error)")
        }
    }
    #endif
    
    /// Format a conversation for saving
    public func formatConversation(query: String, response: String) -> (title: String, content: String) {
        let title = String(query.prefix(50))
        let content = """
        **Question:**
        \(query)
        
        **Minima's Response:**
        \(response)
        
        ---
        *Saved from Minima on \(Date().formatted())*
        """
        return (title, content)
    }
}
