import Foundation

struct ShieldingResult: Equatable {
    enum Status: String {
        case active
        case noSelection
        case unauthorized
        case unavailable
    }

    let status: Status
    let shieldedItemCount: Int
    let message: String

    var isActive: Bool {
        status == .active
    }

    static func active(itemCount: Int) -> ShieldingResult {
        ShieldingResult(
            status: .active,
            shieldedItemCount: itemCount,
            message: "\(itemCount) selected item\(itemCount == 1 ? "" : "s") will be shielded during this session."
        )
    }

    static let noSelection = ShieldingResult(
        status: .noSelection,
        shieldedItemCount: 0,
        message: "No Screen Time apps are selected. The timer will still run with fallback tracking."
    )

    static func unauthorized(_ state: BlockingAuthorizationState) -> ShieldingResult {
        ShieldingResult(
            status: .unauthorized,
            shieldedItemCount: 0,
            message: "\(state.detail) The local timer will continue without app shielding."
        )
    }

    static let unavailable = ShieldingResult(
        status: .unavailable,
        shieldedItemCount: 0,
        message: "Screen Time shielding is unavailable in this build. The local timer will continue without app shielding."
    )
}
