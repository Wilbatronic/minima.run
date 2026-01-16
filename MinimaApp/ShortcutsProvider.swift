import AppIntents

/// "The Voice"
/// Provides Siri Shortcuts integration for iOS/macOS.
/// Allows "Hey Siri, ask Minima..." commands.

@available(iOS 16.0, macOS 13.0, *)
struct AskMinimaIntent: AppIntent {
    static var title: LocalizedStringResource = "Ask Minima"
    static var description = IntentDescription("Ask Minima a question")
    
    @Parameter(title: "Question")
    var question: String
    
    static var parameterSummary: some ParameterSummary {
        Summary("Ask Minima \(\.$question)")
    }
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        // Route to MinimaBrain
        // let answer = await MinimaBrain.shared.ask(question)
        let answer = "This is a placeholder response from Minima."
        return .result(value: answer)
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct SummarizeClipboardIntent: AppIntent {
    static var title: LocalizedStringResource = "Summarize Clipboard"
    static var description = IntentDescription("Summarize the text in your clipboard")
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        #if os(macOS)
        guard let text = NSPasteboard.general.string(forType: .string) else {
            return .result(value: "No text in clipboard.")
        }
        #else
        guard let text = UIPasteboard.general.string else {
            return .result(value: "No text in clipboard.")
        }
        #endif
        
        // Summarize via MinimaBrain
        let summary = "Summary of \(text.prefix(50))... (placeholder)"
        return .result(value: summary)
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct MinimaShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AskMinimaIntent(),
            phrases: [
                "Ask \(.applicationName) \(\.$question)",
                "Hey \(.applicationName), \(\.$question)"
            ],
            shortTitle: "Ask Minima",
            systemImageName: "sparkles"
        )
        AppShortcut(
            intent: SummarizeClipboardIntent(),
            phrases: [
                "Summarize clipboard with \(.applicationName)",
                "\(.applicationName) summarize this"
            ],
            shortTitle: "Summarize Clipboard",
            systemImageName: "doc.text"
        )
    }
}
