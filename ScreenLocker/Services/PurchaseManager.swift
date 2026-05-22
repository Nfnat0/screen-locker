import Foundation

#if canImport(StoreKit)
import StoreKit
#endif

@MainActor
final class PurchaseManager: ObservableObject {
    @Published private(set) var isProUnlocked: Bool
    @Published private(set) var isLoading = false
    @Published var lastMessage: String?

    #if canImport(StoreKit)
    @Published private(set) var products: [Product] = []
    private var transactionUpdatesTask: Task<Void, Never>?
    #endif

    private let defaults: UserDefaults
    private let proKey = "isProUnlocked"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.isProUnlocked = defaults.bool(forKey: proKey)

        #if canImport(StoreKit)
        transactionUpdatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                await self?.handle(transactionVerification: update)
            }
        }
        #endif
    }

    deinit {
        #if canImport(StoreKit)
        transactionUpdatesTask?.cancel()
        #endif
    }

    var primaryProductPrice: String {
        #if canImport(StoreKit)
        products.first?.displayPrice ?? ProProduct.lifetimeUnlock.fallbackPrice
        #else
        ProProduct.lifetimeUnlock.fallbackPrice
        #endif
    }

    func loadProducts() async {
        #if canImport(StoreKit)
        isLoading = true
        defer { isLoading = false }

        do {
            products = try await Product.products(for: ProProduct.allCases.map(\.id))
            await refreshEntitlements()

            if products.isEmpty {
                enableLocalDemoAccess(message: "StoreKit products are not configured yet. Pro is enabled locally for this development build.")
            }
        } catch {
            enableLocalDemoAccess(message: "StoreKit products could not load. Pro is enabled locally for this development build.")
        }
        #else
        enableLocalDemoAccess(message: "StoreKit is unavailable in this build. Pro is enabled locally for demos.")
        #endif
    }

    func purchasePro() async {
        #if canImport(StoreKit)
        if products.isEmpty {
            await loadProducts()
        }

        guard let product = products.first else {
            enableLocalDemoAccess(message: "StoreKit product IDs are not configured yet. Pro is enabled locally for this development build.")
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                await handle(transactionVerification: verification)
            case .pending:
                lastMessage = "Your purchase is pending approval."
            case .userCancelled:
                lastMessage = "Purchase cancelled."
            @unknown default:
                lastMessage = "Purchase could not be completed."
            }
        } catch {
            lastMessage = "Purchase could not be completed. Please try again later."
        }
        #else
        enableLocalDemoAccess(message: "StoreKit is unavailable in this build. Pro is enabled locally for demos.")
        #endif
    }

    func enableLocalDemoAccess(message: String = "Pro unlocked locally for this development build.") {
        isProUnlocked = true
        defaults.set(true, forKey: proKey)
        lastMessage = message
    }

    func restorePurchases() async {
        #if canImport(StoreKit)
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            lastMessage = isProUnlocked ? "Pro access is active." : "No active Pro purchase was found."
        } catch {
            lastMessage = "Purchases could not be restored. Please try again later."
        }
        #else
        lastMessage = isProUnlocked ? "Pro access is active." : "StoreKit is unavailable in this build."
        #endif
    }

    #if canImport(StoreKit)
    private func refreshEntitlements() async {
        var hasVerifiedPro = false

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if ProProduct.allCases.map(\.id).contains(transaction.productID),
               transaction.revocationDate == nil {
                hasVerifiedPro = true
                break
            }
        }

        if hasVerifiedPro {
            isProUnlocked = true
            defaults.set(true, forKey: proKey)
        }
    }

    private func handle(transactionVerification: VerificationResult<Transaction>) async {
        switch transactionVerification {
        case .verified(let transaction):
            if ProProduct.allCases.map(\.id).contains(transaction.productID),
               transaction.revocationDate == nil {
                isProUnlocked = true
                defaults.set(true, forKey: proKey)
                lastMessage = "Pro access is active."
            }
            await transaction.finish()
        case .unverified:
            lastMessage = "The StoreKit transaction could not be verified."
        }
    }
    #endif
}
