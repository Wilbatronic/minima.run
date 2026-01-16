import Foundation

/// "The Ambassador"
/// Referral system for viral growth: "Give Pro, Get Pro"
public class ReferralManager: ObservableObject {
    public static let shared = ReferralManager()
    
    @Published public var referralCode: String?
    @Published public var referralCount: Int = 0
    
    private let codeKey = "minima.referralCode"
    private let countKey = "minima.referralCount"
    
    private init() {
        loadState()
    }
    
    private func loadState() {
        referralCode = UserDefaults.standard.string(forKey: codeKey)
        referralCount = UserDefaults.standard.integer(forKey: countKey)
        
        if referralCode == nil {
            generateCode()
        }
    }
    
    /// Generate a unique referral code
    private func generateCode() {
        // Use first 8 chars of hashed user ID
        let userId = AuthManager.shared.userId ?? UUID().uuidString
        let hash = userId.data(using: .utf8)!.base64EncodedString()
        referralCode = String(hash.prefix(8)).uppercased()
        UserDefaults.standard.set(referralCode, forKey: codeKey)
    }
    
    /// Apply a referral code (when new user signs up)
    public func applyCode(_ code: String) async -> Bool {
        guard code != referralCode else { return false } // Can't refer yourself
        
        // In production, this would validate with a backend
        // For now, store locally
        UserDefaults.standard.set(code, forKey: "minima.appliedReferralCode")
        
        // Grant reward (e.g., 1 week Pro trial)
        print("[Referral] Applied code: \(code)")
        return true
    }
    
    /// Get shareable referral link
    public func getShareLink() -> URL {
        return URL(string: "https://minima.run/refer?code=\(referralCode ?? "")")!
    }
    
    /// Increment referral count when someone uses your code
    public func incrementReferralCount() {
        referralCount += 1
        UserDefaults.standard.set(referralCount, forKey: countKey)
        
        // Check for milestone rewards
        if referralCount == 3 {
            // Grant 1 month Pro free
            print("[Referral] Milestone reached: 3 referrals!")
        }
    }
}
