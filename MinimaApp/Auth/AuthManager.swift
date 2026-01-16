import AuthenticationServices
import Combine

/// "The Gatekeeper"
/// Manages User Identity via Sign in with Apple.
public class AuthManager: NSObject, ObservableObject {
    public static let shared = AuthManager()
    
    @Published public var userId: String?
    @Published public var isAuthenticated: Bool = false
    
    public func signIn() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    public func checkState() {
        // Check if existing user ID is still valid (fast check)
        if let storedId = UserDefaults.standard.string(forKey: "minima.userId") {
            let provider = ASAuthorizationAppleIDProvider()
            provider.getCredentialState(forUserID: storedId) { [weak self] state, error in
                DispatchQueue.main.async {
                    switch state {
                    case .authorized:
                        self?.userId = storedId
                        self?.isAuthenticated = true
                    case .revoked, .notFound, .transferred:
                        self?.isAuthenticated = false
                    @unknown default:
                        break
                    }
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
            
            // Save securely
            UserDefaults.standard.set(user, forKey: "minima.userId")
            
            DispatchQueue.main.async {
                self.userId = user
                self.isAuthenticated = true
            }
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
