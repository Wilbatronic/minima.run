import SwiftUI

@main
struct MinimaApp: App {
    // Ensure Hardware Check runs on launch
    init() {
        do {
            try HardwareGuard.validate()
        } catch {
            print("Hardware Validation Failed: \(error.localizedDescription)")
            // In a real app, we'd show an alert window or fallback mode.
        }
    }
    
    var body: some Scene {
        WindowGroup {
            GhostBarView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.all)
                .colorScheme(.dark) // Default to dark mode for that sleek look
        }
        .windowStyle(.hiddenTitleBar) // No traffic lights
        .windowResizability(.contentSize)
    }
}

// macOS Specific Window Tweak to make it truly floating/transparent if needed
// Usually done via NSWindowDelegate in a host app delegate.
