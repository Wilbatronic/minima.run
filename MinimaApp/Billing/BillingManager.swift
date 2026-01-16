import StoreKit
import Combine

/// "The Vault"
/// Manages Subscriptions and Entitlements via StoreKit 2.
public class BillingManager: ObservableObject {
    public static let shared = BillingManager()
    
    @Published public var isPro: Bool = false
    @Published public var products: [Product] = []
    
    // Product IDs
    private let proMonthlyId = "com.minima.pro.monthly"
    private let proYearlyId = "com.minima.pro.yearly"
    
    private var updates: Task<Void, Never>?
    
    public init() {
        // Start listening for transaction updates (happens in background)
        updates = Task {
            for await _ in Transaction.updates {
                await self.updateEntitlements()
            }
        }
    }
    
    deinit {
        updates?.cancel()
    }
    
    public func fetchProducts() async {
        do {
            let storeProducts = try await Product.products(for: [proMonthlyId, proYearlyId])
            DispatchQueue.main.async {
                self.products = storeProducts
            }
        } catch {
            print("[Billing] Failed to fetch products: \(error)")
        }
    }
    
    public func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            // Check if the transaction is verified
            let transaction = try checkVerified(verification)
            
            // The transaction is valid. Unlock content.
            await updateEntitlements()
            
            await transaction.finish()
            
        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
    }
    
    public func updateEntitlements() async {
        // Iterate through all "current" entitlements
        var newProState = false
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                // Check if this is one of our Pro products
                if [proMonthlyId, proYearlyId].contains(transaction.productID) {
                    newProState = true
                }
            } catch {
                print("[Billing] Failed verification: \(error)")
            }
        }
        
        DispatchQueue.main.async {
            self.isPro = newProState
            print("[Billing] Entitlement Updated: Pro = \(self.isPro)")
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        // Check if the transaction passes StoreKit verification.
        switch result {
        case .unverified:
            throw NSError(domain: "StoreKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unverified transaction"])
        case .verified(let safe):
            return safe
        }
    }
}
