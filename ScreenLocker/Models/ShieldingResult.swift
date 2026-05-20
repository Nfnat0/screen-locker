import Foundation

struct ShieldingResult: Equatable {
    let didApplyShields: Bool
    let selectedItemCount: Int
    let message: String?

    static func applied(selectedItemCount: Int) -> ShieldingResult {
        ShieldingResult(
            didApplyShields: true,
            selectedItemCount: selectedItemCount,
            message: nil
        )
    }

    static func fallback(selectedItemCount: Int, message: String) -> ShieldingResult {
        ShieldingResult(
            didApplyShields: false,
            selectedItemCount: selectedItemCount,
            message: message
        )
    }
}
