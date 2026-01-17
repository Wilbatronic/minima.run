import SwiftUI
import AppKit

struct GlassEffect: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .hudWindow
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

struct LiquidGlassModifier: ViewModifier {
    var cornerRadius: CGFloat = 16
    var saturation: Double = 1.8
    var brightness: Double = 1.2
    var showMesh: Bool = false
    
    @State private var shimmerOffset: CGFloat = -1.0
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    if showMesh {
                        if #available(macOS 15.0, *) {
                            MeshGradient(
                                width: 3,
                                height: 3,
                                points: [
                                    [0, 0], [0.5, 0], [1, 0],
                                    [0, 0.5], [0.5, 0.5], [1, 0.5],
                                    [0, 1], [0.5, 1], [1, 1]
                                ],
                                colors: [
                                    .purple.opacity(0.3), .blue.opacity(0.2), .indigo.opacity(0.3),
                                    .blue.opacity(0.2), .purple.opacity(0.1), .blue.opacity(0.2),
                                    .indigo.opacity(0.3), .blue.opacity(0.2), .purple.opacity(0.3)
                                ]
                            )
                            .blur(radius: 20)
                        } else {
                            LinearGradient(colors: [.purple.opacity(0.1), .blue.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        }
                    }
                    
                    GlassEffect()
                        .saturation(saturation)
                        .brightness(brightness - 1.0)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
            )
            .overlay(
                // Shimmering Highlight
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.2), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: geo.size.width * 0.5)
                    .offset(x: geo.size.width * shimmerOffset)
                    .rotationEffect(.degrees(20))
                }
                .mask(RoundedRectangle(cornerRadius: cornerRadius))
            )
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            .onAppear {
                withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                    shimmerOffset = 2.0
                }
            }
    }
}

extension View {
    func liquidGlass(cornerRadius: CGFloat = 16) -> some View {
        self.modifier(LiquidGlassModifier(cornerRadius: cornerRadius))
    }
    
    func glassBackground() -> some View {
        self.background(GlassEffect())
    }
}
