import LocalAuthentication
import SwiftUI

/// "The Sentinel"
/// Biometric authentication (Face ID / Touch ID) to protect the app.
public class BiometricLock: ObservableObject {
    public static let shared = BiometricLock()
    
    @Published public var isLocked: Bool = true
    @Published public var isEnabled: Bool = false
    @Published public var biometricType: BiometricType = .none
    
    private let context = LAContext()
    
    public enum BiometricType {
        case none
        case faceID
        case touchID
    }
    
    private init() {
        checkBiometricType()
        loadSettings()
    }
    
    private func checkBiometricType() {
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            biometricType = .none
            return
        }
        
        switch context.biometryType {
        case .faceID:
            biometricType = .faceID
        case .touchID:
            biometricType = .touchID
        default:
            biometricType = .none
        }
    }
    
    private func loadSettings() {
        isEnabled = UserDefaults.standard.bool(forKey: "minima.biometricEnabled")
        
        // If enabled, start locked
        if isEnabled {
            isLocked = true
        } else {
            isLocked = false
        }
    }
    
    /// Enable biometric lock
    public func enable() {
        isEnabled = true
        isLocked = true
        UserDefaults.standard.set(true, forKey: "minima.biometricEnabled")
    }
    
    /// Disable biometric lock
    public func disable() {
        isEnabled = false
        isLocked = false
        UserDefaults.standard.set(false, forKey: "minima.biometricEnabled")
    }
    
    /// Attempt to unlock
    public func unlock() async -> Bool {
        guard isEnabled else {
            isLocked = false
            return true
        }
        
        let reason = "Unlock Minima to access your conversations"
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            
            await MainActor.run {
                self.isLocked = !success
            }
            
            return success
        } catch {
            print("[Biometric] Auth failed: \(error)")
            return false
        }
    }
    
    /// Lock the app
    public func lock() {
        guard isEnabled else { return }
        isLocked = true
    }
}

// MARK: - SwiftUI View Modifier

struct BiometricLockModifier: ViewModifier {
    @ObservedObject var lock = BiometricLock.shared
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .blur(radius: lock.isLocked ? 20 : 0)
                .disabled(lock.isLocked)
            
            if lock.isLocked {
                VStack(spacing: 20) {
                    Image(systemName: lock.biometricType == .faceID ? "faceid" : "touchid")
                        .font(.system(size: 60))
                    
                    Text("Minima is Locked")
                        .font(.title2.bold())
                    
                    Button("Unlock") {
                        Task { await lock.unlock() }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.ultraThinMaterial)
            }
        }
        .task {
            if lock.isEnabled {
                await lock.unlock()
            }
        }
    }
}

extension View {
    public func biometricLock() -> some View {
        modifier(BiometricLockModifier())
    }
}
