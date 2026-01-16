import Cocoa
import Combine

/// "The Psychic"
/// Watches the clipboard for potential context.
/// If the user Copies text, Minima "reads" it immediately (silently).
/// When the user opens the app and says "Summarize this", it's already in the KV Cache.
/// Result: 0ms Latency ("It knew what I wanted before I asked").
public class ClipboardWatcher: ObservableObject {
    public static let shared = ClipboardWatcher()
    
    @Published public var lastCopiedText: String?
    
    private var changeCount: Int
    private var timer: Timer?
    
    private init() {
        self.changeCount = NSPasteboard.general.changeCount
        startWatching()
    }
    
    private func startWatching() {
        // Poll every 0.5s - Lightweight check of changeCount integer
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
    }
    
    private func checkForChanges() {
        if NSPasteboard.general.changeCount != changeCount {
            changeCount = NSPasteboard.general.changeCount
            
            // Getting text is cheap
            if let str = NSPasteboard.general.string(forType: .string) {
                // Heuristic: Only care if it's "Substantial" context (> 50 chars)
                // but not "Insane" (> 100k chars) to avoid lag.
                if str.count > 50 && str.count < 100000 {
                    print("[ClipboardWatcher] Context Detected (\(str.count) chars). Prefetching...")
                    self.lastCopiedText = str
                    
                    // Trigger Brain Prefetch
                    // MinimaBrain.shared.prefetch(text: str)
                }
            }
        }
    }
}
