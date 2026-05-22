import Foundation

enum ProProduct: String, CaseIterable, Identifiable {
    case lifetimeUnlock = "com.example.ScreenLocker.pro.lifetime"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .lifetimeUnlock:
            "Detox Pro Lifetime"
        }
    }

    var fallbackPrice: String {
        switch self {
        case .lifetimeUnlock:
            "$9.99"
        }
    }
}
