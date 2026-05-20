import Foundation

#if canImport(FamilyControls)
import FamilyControls
#endif

@MainActor
final class SettingsStore: ObservableObject {
    private enum Keys {
        static let defaultDurationMinutes = "defaultDurationMinutes"
        static let dailyGoalMinutes = "dailyGoalMinutes"
        static let unlockDelaySeconds = "unlockDelaySeconds"
        static let notificationsEnabled = "notificationsEnabled"
        static let appearance = "appearance"
        static let blockedAppCount = "blockedAppCount"
        static let activitySelection = "activitySelection"
    }

    private let defaults: UserDefaults

    @Published var defaultDurationMinutes: Int {
        didSet { defaults.set(defaultDurationMinutes, forKey: Keys.defaultDurationMinutes) }
    }

    @Published var dailyGoalMinutes: Int {
        didSet { defaults.set(dailyGoalMinutes, forKey: Keys.dailyGoalMinutes) }
    }

    @Published var unlockDelaySeconds: Int {
        didSet { defaults.set(unlockDelaySeconds, forKey: Keys.unlockDelaySeconds) }
    }

    @Published var notificationsEnabled: Bool {
        didSet { defaults.set(notificationsEnabled, forKey: Keys.notificationsEnabled) }
    }

    @Published var appearance: String {
        didSet { defaults.set(appearance, forKey: Keys.appearance) }
    }

    @Published var blockedAppCount: Int {
        didSet { defaults.set(blockedAppCount, forKey: Keys.blockedAppCount) }
    }

    #if canImport(FamilyControls)
    @Published private(set) var activitySelection: FamilyActivitySelection
    #endif

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.defaultDurationMinutes = defaults.object(forKey: Keys.defaultDurationMinutes) as? Int ?? 60
        self.dailyGoalMinutes = defaults.object(forKey: Keys.dailyGoalMinutes) as? Int ?? 240
        self.unlockDelaySeconds = defaults.object(forKey: Keys.unlockDelaySeconds) as? Int ?? 30
        self.notificationsEnabled = defaults.object(forKey: Keys.notificationsEnabled) as? Bool ?? true
        self.appearance = defaults.string(forKey: Keys.appearance) ?? "Dark"
        self.blockedAppCount = defaults.object(forKey: Keys.blockedAppCount) as? Int ?? 5

        #if canImport(FamilyControls)
        if let data = defaults.data(forKey: Keys.activitySelection),
           let decoded = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data) {
            self.activitySelection = decoded
            self.blockedAppCount = Self.countBlockedItems(in: decoded, fallback: self.blockedAppCount)
        } else {
            self.activitySelection = FamilyActivitySelection()
        }
        #endif
    }

    #if canImport(FamilyControls)
    func updateActivitySelection(_ selection: FamilyActivitySelection) {
        activitySelection = selection
        blockedAppCount = Self.countBlockedItems(in: selection, fallback: blockedAppCount)

        if let data = try? PropertyListEncoder().encode(selection) {
            defaults.set(data, forKey: Keys.activitySelection)
        }
    }

    private static func countBlockedItems(in selection: FamilyActivitySelection, fallback: Int) -> Int {
        let count = selection.applicationTokens.count + selection.categoryTokens.count + selection.webDomainTokens.count
        return count == 0 ? fallback : count
    }
    #endif

    func updateMockBlockedAppCount(_ count: Int) {
        blockedAppCount = max(0, count)
    }
}
