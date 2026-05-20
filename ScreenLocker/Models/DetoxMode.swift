import Foundation

struct DetoxMode: Identifiable, Hashable {
    let id: UUID
    let name: String
    let iconName: String
    let blockedAppCount: Int
    let isPro: Bool

    static let defaultModeID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!

    static func defaultMode(blockedAppCount: Int) -> DetoxMode {
        DetoxMode(
            id: defaultModeID,
            name: "Default Detox",
            iconName: "shield.fill",
            blockedAppCount: blockedAppCount,
            isPro: false
        )
    }

    static let proModes: [DetoxMode] = [
        DetoxMode(id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!, name: "Sleep Detox", iconName: "moon.fill", blockedAppCount: 8, isPro: true),
        DetoxMode(id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!, name: "Deep Focus", iconName: "target", blockedAppCount: 3, isPro: true),
        DetoxMode(id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!, name: "Evening Detox", iconName: "sunset.fill", blockedAppCount: 6, isPro: true),
        DetoxMode(id: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!, name: "Weekend Detox", iconName: "palm.tree.fill", blockedAppCount: 7, isPro: true)
    ]
}
