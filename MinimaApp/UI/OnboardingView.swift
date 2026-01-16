import SwiftUI

/// First-Time User Onboarding Flow
struct OnboardingView: View {
    @State private var currentPage = 0
    @Binding var isOnboardingComplete: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                // Page 1: Welcome
                VStack(spacing: 24) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 80))
                        .foregroundStyle(.linearGradient(colors: [.purple, .blue], startPoint: .top, endPoint: .bottom))
                    
                    Text("Welcome to Minima")
                        .font(.largeTitle.bold())
                    
                    Text("Your private AI assistant that runs entirely on-device.")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .tag(0)
                
                // Page 2: Screen Recording Permission
                VStack(spacing: 24) {
                    Image(systemName: "rectangle.dashed.badge.record")
                        .font(.system(size: 80))
                        .foregroundColor(.orange)
                    
                    Text("Enable Vision")
                        .font(.largeTitle.bold())
                    
                    Text("Minima needs Screen Recording permission to see what you're working on.")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Open System Settings") {
                        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .tag(1)
                
                // Page 3: Accessibility Permission
                VStack(spacing: 24) {
                    Image(systemName: "hand.tap")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                    
                    Text("Enable Control")
                        .font(.largeTitle.bold())
                    
                    Text("For hands-free automation, Minima needs Accessibility permission to click and type.")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Grant Permission") {
                        AXBridge.shared.requestPermission()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .tag(2)
                
                // Page 4: Ready
                VStack(spacing: 24) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                    
                    Text("You're All Set!")
                        .font(.largeTitle.bold())
                    
                    Text("Press ⌘ Space anywhere to summon Minima.")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    Button("Get Started") {
                        isOnboardingComplete = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Page Indicators
            HStack(spacing: 8) {
                ForEach(0..<4) { index in
                    Circle()
                        .fill(index == currentPage ? Color.primary : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.bottom, 20)
            
            // Navigation
            HStack {
                if currentPage > 0 {
                    Button("Back") {
                        withAnimation { currentPage -= 1 }
                    }
                }
                Spacer()
                if currentPage < 3 {
                    Button("Next") {
                        withAnimation { currentPage += 1 }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 20)
        }
        .frame(width: 500, height: 450)
        .glassBackground()
    }
}
