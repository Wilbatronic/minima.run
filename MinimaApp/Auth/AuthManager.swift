import AuthenticationServices
import Combine

/// "The Gatekeeper"
/// Manages User Identity via Sign in with Apple.
@MainActor
public class AuthManager: NSObject, ObservableObject {
    public static let shared = AuthManager()
    
    @Published public var userId: String?
    @Published public var isAuthenticated: Bool = false
    
    private let service = "minima.run"
    private let account = "user.id"
    
    public func signIn() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    public func checkState() async {
        // Load from Keychain generically
        guard let storedId: String = try? KeychainHelper.load(service: service, account: account) else {
            self.isAuthenticated = false
            return
        }
        
        let provider = ASAuthorizationAppleIDProvider()
        do {
            let state = try await provider.credentialState(forUserID: storedId)
            switch state {
            case .authorized:
                self.userId = storedId
                self.isAuthenticated = true
            case .revoked, .notFound, .transferred:
                self.isAuthenticated = false
                try? KeychainHelper.delete(service: service, account: account)
            @unknown default:
                break
            }
        } catch {
            self.isAuthenticated = false
        }
    }
}

extension ASAuthorizationAppleIDProvider {
    func credentialState(forUserID userId: String) async throws -> ASAuthorizationAppleIDProvider.CredentialState {
        try await withCheckedThrowingContinuation { continuation in
            self.getCredentialState(forUserID: userId) { state, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: state)
                }
            }
        }
    }
}

extension AuthManager: ASAuthorizationControllerDelegate {
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let user = credential.user
            print("[Auth] Signed in as: \(user)")
            
            // Save securely to Keychain
            try? KeychainHelper.save(user, service: service, account: account)
            
            self.userId = user
            self.isAuthenticated = true
        }
    }
    
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("[Auth] Error: \(error.localizedDescription)")
    }
}

extension AuthManager: ASAuthorizationControllerPresentationContextProviding {
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Return main window
        return NSApplication.shared.windows.first ?? ASPresentationAnchor()
    }
}
