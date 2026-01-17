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
            
            // 1. Context Indicator
            Button(action: {
                captureContext()
            }) {
                Image(systemName: "eye")
                    .font(.system(size: 18, weight: .medium))
                    .symbolEffect(.bounce, value: isThinking)
                    .foregroundColor(isThinking ? .purple : .secondary)
            }
            .buttonStyle(.plain)
            
            // 2. Input Field
            TextField("Ask Minima...", text: $inputText)
                .textFieldStyle(.plain)
                .font(.system(size: 20, weight: .light, design: .rounded))
                .onSubmit {
                    submitQuery()
                }
            
            // 3. Status/Thinking Pulse
            if isThinking {
                LuminousThinkingPulse()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            ZStack {
                // Dynamic Luminous Border
                RoundedRectangle(cornerRadius: 28)
                    .stroke(
                        LinearGradient(colors: [.purple, .blue, .purple], startPoint: .leading, endPoint: .trailing),
                        lineWidth: isThinking ? 2.0 : 0.5
                    )
                    .opacity(isThinking ? 1.0 : 0.3)
                    .blur(radius: isThinking ? 4 : 0)
                
                // Base Glass
                Color.black.opacity(0.05)
                    .liquidGlass(cornerRadius: 28)
            }
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

struct LuminousThinkingPulse: View {
    @State private var pulse = 0.0
    
    var body: some View {
        Circle()
            .fill(RadialGradient(colors: [.purple, .clear], center: .center, startRadius: 0, endRadius: 10))
            .frame(width: 12, height: 12)
            .scaleEffect(1.0 + pulse)
            .opacity(1.0 - pulse)
            .onAppear {
                withAnimation(.easeOut(duration: 1.2).repeatForever(autoreverses: false)) {
                    pulse = 1.0
                }
            }
    }
}
