import Foundation

@MainActor
final class PurchaseManager: ObservableObject {
    @Published private(set) var isProUnlocked: Bool
    @Published var lastMessage: String?

    private let defaults: UserDefaults
    private let proKey = "isProUnlocked"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.isProUnlocked = defaults.bool(forKey: proKey)
    }

    func purchaseProPlaceholder() {
        // TODO: Replace with StoreKit 2 product loading and purchase verification.
        isProUnlocked = true
        defaults.set(true, forKey: proKey)
        lastMessage = "Pro unlocked locally for this MVP build."
    }

    func restorePurchases() {
        // TODO: Restore verified StoreKit transactions when product IDs are configured.
        lastMessage = isProUnlocked ? "Pro access is already active." : "No purchases found in this placeholder build."
    }
}
