import SwiftUI
import UniformTypeIdentifiers

struct GhostBarView: View {
    @State private var inputText: String = ""
    @State private var isHovering: Bool = false
    @State private var isThinking: Bool = false
    
    // Mock dependency
    // @EnvironmentObject var brain: MinimaBrain
    
    var body: some View {
        HStack(spacing: 12) {
            
            // 1. Context Indicator / "Look" Button
            Button(action: {
                captureContext()
            }) {
                Image(systemName: "eye")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("Look at current screen")
            
            // 2. Input Field
            TextField("Ask Minima...", text: $inputText)
                .textFieldStyle(.plain)
                .font(.system(size: 20, weight: .light, design: .rounded))
                .onSubmit {
                    submitQuery()
                }
            
            // 3. Status/Thinking Pulse
            if isThinking {
                Circle()
                    .fill(Color.purple)
                    .frame(width: 8, height: 8)
                    .phaseAnimator([0.5, 1.0]) { content, phase in
                        content.opacity(phase).scaleEffect(phase)
                    } animation: { _ in
                        .easeInOut(duration: 0.8)
                    }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.black.opacity(0.1)) // Subtle tint
                .background(GlassEffect(material: .hudWindow, blendingMode: .behindWindow))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                )
        )
        // Drag & Drop
        .onDrop(of: [.fileURL, .image], isTargeted: $isHovering) { providers in
            handleDrop(providers)
            return true
        }
        .scaleEffect(isHovering ? 1.02 : 1.0) // Bouncy interaction
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
        .frame(width: 600)
    }
    
    private func submitQuery() {
        withAnimation { isThinking = true }
        // Trigger LLMBridge here...
        print("Query submitted: \(inputText)")
        
        // Mock finish
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { isThinking = false }
        }
    }
    
    private func captureContext() {
        print("Capturing screen context via ScreenEyes...")
        // ScreenEyes.shared.snapshot()
    }
    
    private func handleDrop(_ providers: [NSItemProvider]) {
        print("Dropped \(providers.count) items")
        // Handle files
    }
}
