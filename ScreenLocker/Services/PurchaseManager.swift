import Foundation
import StoreKit

@MainActor
final class PurchaseManager: ObservableObject {
    enum PurchaseState: Equatable {
        case idle
        case loading
        case purchasing
        case purchased
        case failed(String)
    }

    @Published private(set) var isProUnlocked: Bool
    @Published private(set) var products: [Product] = []
    @Published private(set) var state: PurchaseState = .idle
    @Published var lastMessage: String?

    private let defaults: UserDefaults
    private let proKey = "isProUnlocked"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.isProUnlocked = defaults.bool(forKey: proKey)

        Task {
            await refreshPurchasedProducts()
            await loadProducts()
        }
    }

    func loadProducts() async {
        state = .loading

        do {
            products = try await Product.products(for: Array(ProProduct.allProductIDs))
            state = isProUnlocked ? .purchased : .idle
        } catch {
            state = .failed("Products could not be loaded. Check StoreKit configuration.")
            lastMessage = "Products could not be loaded. Check StoreKit configuration."
        }
    }

    func purchasePro() async {
        if products.isEmpty {
            await loadProducts()
        }

        guard let product = products.first(where: { $0.id == ProProduct.lifetimeProductID }) else {
            unlockProForLocalDemo()
            return
        }

        state = .purchasing

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                unlockPro()
                await transaction.finish()
                lastMessage = "Pro access is active."
                state = .purchased
            case .userCancelled:
                state = .idle
                lastMessage = "Purchase cancelled."
            case .pending:
                state = .idle
                lastMessage = "Purchase is pending approval."
            @unknown default:
                state = .failed("Purchase could not be completed.")
                lastMessage = "Purchase could not be completed."
            }
        } catch {
            state = .failed("Purchase failed. Try again later.")
            lastMessage = "Purchase failed. Try again later."
        }
    }

    func restorePurchases() {
        Task {
            await refreshPurchasedProducts()
            lastMessage = isProUnlocked ? "Pro access is active." : "No active Pro purchase was found."
            state = isProUnlocked ? .purchased : .idle
        }
    }

    func unlockProForLocalDemo() {
        unlockPro()
        lastMessage = "Pro unlocked locally because no StoreKit product is configured."
        state = .purchased
    }

    private func refreshPurchasedProducts() async {
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result),
               transaction.productID == ProProduct.lifetimeProductID {
                unlockPro()
                state = .purchased
                return
            }
        }
    }

    private func unlockPro() {
        isProUnlocked = true
        defaults.set(true, forKey: proKey)
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified:
            throw PurchaseError.failedVerification
        }
    }

    private enum PurchaseError: Error {
        case failedVerification
    }
}
