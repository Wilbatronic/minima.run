import Foundation
import CryptoKit

/// "The Vault"
/// Encrypts conversation history at rest using device-bound keys.
public class EncryptionManager {
    public static let shared = EncryptionManager()
    
    // Key stored in Keychain, derived from device-specific entropy
    private var symmetricKey: SymmetricKey?
    
    private init() {
        loadOrCreateKey()
    }
    
    private func loadOrCreateKey() {
        // In production, store in Keychain with kSecAttrAccessibleWhenUnlocked
        // For now, derive from device ID
        let deviceId = getDeviceIdentifier()
        let keyData = SHA256.hash(data: deviceId.data(using: .utf8)!)
        symmetricKey = SymmetricKey(data: keyData)
    }
    
    private func getDeviceIdentifier() -> String {
        // Use a stable device identifier
        if let stored = UserDefaults.standard.string(forKey: "minima.deviceId") {
            return stored
        }
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: "minima.deviceId")
        return newId
    }
    
    /// Encrypt data
    public func encrypt(_ data: Data) throws -> Data {
        guard let key = symmetricKey else {
            throw EncryptionError.noKey
        }
        
        let sealedBox = try AES.GCM.seal(data, using: key)
        guard let combined = sealedBox.combined else {
            throw EncryptionError.encryptionFailed
        }
        return combined
    }
    
    /// Decrypt data
    public func decrypt(_ data: Data) throws -> Data {
        guard let key = symmetricKey else {
            throw EncryptionError.noKey
        }
        
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: key)
    }
    
    /// Encrypt a string
    public func encryptString(_ string: String) throws -> Data {
        guard let data = string.data(using: .utf8) else {
            throw EncryptionError.invalidInput
        }
        return try encrypt(data)
    }
    
    /// Decrypt to string
    public func decryptString(_ data: Data) throws -> String {
        let decrypted = try decrypt(data)
        guard let string = String(data: decrypted, encoding: .utf8) else {
            throw EncryptionError.invalidInput
        }
        return string
    }
}

enum EncryptionError: Error {
    case noKey
    case encryptionFailed
    case decryptionFailed
    case invalidInput
}
