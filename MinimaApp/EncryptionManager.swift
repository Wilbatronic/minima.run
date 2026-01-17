import Foundation
import CryptoKit

/// "The Vault"
/// Encrypts conversation history at rest using device-bound keys.
/// Now formalized as an Actor for thread-safe isolation.
public actor EncryptionManager {
    public static let shared = EncryptionManager()
    
    private var symmetricKey: SymmetricKey?
    private let service = "minima.run"
    private let account = "encryption.key"
    
    private init() {
        // Actors can't call async in init easily, so we lazy-load or use an initializer
    }
    
    public func ensureKeyLoaded() throws {
        if symmetricKey != nil { return }
        
        if let data: Data = try? KeychainHelper.load(service: service, account: account) {
            symmetricKey = SymmetricKey(data: data)
        } else {
            let key = SymmetricKey(size: .bits256)
            let data = key.withUnsafeBytes { Data($0) }
            try KeychainHelper.save(data, service: service, account: account)
            symmetricKey = key
        }
    }
    
    /// Encrypt data
    public func encrypt(_ data: Data) throws -> Data {
        try ensureKeyLoaded()
        guard let key = symmetricKey else { throw EncryptionError.noKey }
        
        let sealedBox = try AES.GCM.seal(data, using: key)
        guard let combined = sealedBox.combined else { throw EncryptionError.encryptionFailed }
        return combined
    }
    
    /// Decrypt data
    public func decrypt(_ data: Data) throws -> Data {
        try ensureKeyLoaded()
        guard let key = symmetricKey else { throw EncryptionError.noKey }
        
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: key)
    }
    
    /// Encrypt a string
    public func encryptString(_ string: String) throws -> Data {
        guard let data = string.data(using: .utf8) else { throw EncryptionError.invalidInput }
        return try encrypt(data)
    }
    
    /// Decrypt to string
    public func decryptString(_ data: Data) throws -> String {
        let decrypted = try decrypt(data)
        guard let string = String(data: decrypted, encoding: .utf8) else { throw EncryptionError.invalidInput }
        return string
    }
}

public enum EncryptionError: Error {
    case noKey
    case encryptionFailed
    case decryptionFailed
    case invalidInput
}
