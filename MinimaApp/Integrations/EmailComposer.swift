import MessageUI
import AppKit

/// "The Courier"
/// Composes and sends emails via system Mail app.
public class EmailComposer {
    public static let shared = EmailComposer()
    
    private init() {}
    
    #if os(macOS)
    /// Open Mail.app with pre-composed email
    public func compose(to: String, subject: String, body: String) {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = to
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body)
        ]
        
        if let url = components.url {
            NSWorkspace.shared.open(url)
        }
    }
    #endif
    
    /// Parse email draft from LLM response
    public func parseDraft(from text: String) -> EmailDraft? {
        // Expected format:
        // TO: email@example.com
        // SUBJECT: Meeting Tomorrow
        // BODY: Hi, I wanted to follow up...
        
        var to = ""
        var subject = ""
        var body = ""
        
        let lines = text.components(separatedBy: "\n")
        var inBody = false
        
        for line in lines {
            if line.starts(with: "TO:") {
                to = line.replacingOccurrences(of: "TO:", with: "").trimmingCharacters(in: .whitespaces)
            } else if line.starts(with: "SUBJECT:") {
                subject = line.replacingOccurrences(of: "SUBJECT:", with: "").trimmingCharacters(in: .whitespaces)
            } else if line.starts(with: "BODY:") {
                body = line.replacingOccurrences(of: "BODY:", with: "").trimmingCharacters(in: .whitespaces)
                inBody = true
            } else if inBody {
                body += "\n" + line
            }
        }
        
        guard !to.isEmpty && !subject.isEmpty else { return nil }
        return EmailDraft(to: to, subject: subject, body: body)
    }
}

public struct EmailDraft {
    public let to: String
    public let subject: String
    public let body: String
}
