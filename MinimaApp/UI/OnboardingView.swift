import SwiftUI

/// First-Time User Onboarding Flow
struct OnboardingView: View {
    @State private var currentPage = 0
    @Binding var isOnboardingComplete: Bool
    
    @State private var orbOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            // Background Orbs
            OrbBackground(currentPage: currentPage)
                .offset(orbOffset)
                .blur(radius: 60)
                .opacity(0.4)
            
            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    // Page 1: Welcome
                    OnboardingPage(
                        icon: "sparkles",
                        iconColor: .purple,
                        title: "Welcome to Minima",
                        description: "Your private AI assistant that runs entirely on-device."
                    )
                    .tag(0)
                    
                    // Page 2: Screen Recording Permission
                    OnboardingPage(
                        icon: "rectangle.dashed.badge.record",
                        iconColor: .orange,
                        title: "Enable Vision",
                        description: "Minima needs Screen Recording permission to see what you're working on.",
                        action: {
                            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
                        },
                        actionLabel: "Open System Settings"
                    )
                    .tag(1)
                    
                    // Page 3: Accessibility Permission
                    OnboardingPage(
                        icon: "hand.tap",
                        iconColor: .green,
                        title: "Enable Control",
                        description: "For hands-free automation, Minima needs Accessibility permission.",
                        action: {
                            AXBridge.shared.requestPermission()
                        },
                        actionLabel: "Grant Permission"
                    )
                    .tag(2)
                    
                    // Page 4: Ready
                    OnboardingPage(
                        icon: "checkmark.circle.fill",
                        iconColor: .green,
                        title: "You're All Set!",
                        description: "Press ⌘ Space anywhere to summon Minima.",
                        action: {
                            isOnboardingComplete = true
                        },
                        actionLabel: "Get Started",
                        isLargeAction: true
                    )
                    .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Navigation/Indicators
                OnboardingFooter(currentPage: $currentPage, totalPages: 4)
            }
        }
        .frame(width: 550, height: 480)
        .liquidGlass(cornerRadius: 32)
        .gesture(
            DragGesture()
                .onChanged { value in
                    orbOffset = CGSize(width: value.translation.width * 0.1, height: value.translation.height * 0.1)
                }
                .onEnded { _ in
                    withAnimation(.spring()) {
                        orbOffset = .zero
                    }
                }
        )
    }
}

struct OnboardingPage: View {
    var icon: String
    var iconColor: Color
    var title: String
    var description: String
    var action: (() -> Void)? = nil
    var actionLabel: String? = nil
    var isLargeAction: Bool = false
    
    var body: some View {
        VStack(spacing: 28) {
            Image(systemName: icon)
                .font(.system(size: 80, weight: .thin))
                .foregroundStyle(iconColor.gradient)
                .symbolEffect(.bounce, options: .repeating)
            
            VStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                
                Text(description)
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            if let action = action, let label = actionLabel {
                Button(action: action) {
                    Text(label)
                        .font(.headline)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                .background(iconColor.opacity(0.2))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(iconColor.opacity(0.5), lineWidth: 1))
                .scaleEffect(isLargeAction ? 1.1 : 1.0)
            }
        }
    }
}

struct OrbBackground: View {
    var currentPage: Int
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.purple)
                .frame(width: 200)
                .offset(x: -150, y: -100)
            
            Circle()
                .fill(Color.blue)
                .frame(width: 250)
                .offset(x: 100, y: 150)
        }
        .animation(.spring(response: 0.8, dampingFraction: 0.6), value: currentPage)
    }
}

struct OnboardingFooter: View {
    @Binding var currentPage: Int
    var totalPages: Int
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                ForEach(0..<totalPages) { index in
                    Capsule()
                        .fill(index == currentPage ? Color.primary : Color.secondary.opacity(0.2))
                        .frame(width: index == currentPage ? 20 : 6, height: 6)
                }
            }
            Spacer()
            if currentPage < totalPages - 1 {
                Button("Next") {
                    withAnimation { currentPage += 1 }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color.primary.opacity(0.1))
                .clipShape(Capsule())
            }
        }
        .padding(40)
    }
}
