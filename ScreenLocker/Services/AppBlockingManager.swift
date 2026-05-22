import Foundation

#if canImport(FamilyControls)
import FamilyControls
#endif

#if canImport(ManagedSettings)
import ManagedSettings
#endif

@MainActor
final class AppBlockingManager: ObservableObject {
    @Published private(set) var authorizationState: BlockingAuthorizationState = .notDetermined
    @Published private(set) var isShieldingActive = false
    @Published private(set) var lastShieldingResult: ShieldingResult = .noSelection
    @Published var lastErrorMessage: String?

    #if canImport(ManagedSettings)
    private let managedSettingsStore = ManagedSettingsStore()
    #endif

    init() {
        refreshAuthorizationStatus()
    }

    func refreshAuthorizationStatus() {
        #if canImport(FamilyControls)
        switch AuthorizationCenter.shared.authorizationStatus {
        case .notDetermined:
            authorizationState = .notDetermined
        case .denied:
            authorizationState = .denied
        case .approved:
            authorizationState = .approved
        default:
            authorizationState = .unavailable
        }
        #else
        authorizationState = .unavailable
        #endif
    }

    func requestAuthorization() async {
        #if canImport(FamilyControls)
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            refreshAuthorizationStatus()
            lastErrorMessage = nil
        } catch {
            refreshAuthorizationStatus()
            lastErrorMessage = "Screen Time authorization could not be completed. Check Family Controls entitlement setup in Xcode."
        }
        #else
        authorizationState = .unavailable
        lastErrorMessage = "Screen Time frameworks are not available in this build."
        #endif
    }

    @discardableResult
    func applyBlocking(from settingsStore: SettingsStore) -> ShieldingResult {
        #if canImport(FamilyControls) && canImport(ManagedSettings)
        guard authorizationState == .approved else {
            isShieldingActive = false
            let result = ShieldingResult.unauthorized(authorizationState)
            lastShieldingResult = result
            lastErrorMessage = result.message
            return result
        }

        let selection = settingsStore.activitySelection
        managedSettingsStore.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        managedSettingsStore.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
        managedSettingsStore.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens

        let shieldedItemCount = selection.applicationTokens.count + selection.categoryTokens.count + selection.webDomainTokens.count
        isShieldingActive = shieldedItemCount > 0

        let result: ShieldingResult = isShieldingActive ? .active(itemCount: shieldedItemCount) : .noSelection
        lastShieldingResult = result
        lastErrorMessage = isShieldingActive ? nil : result.message
        return result
        #else
        isShieldingActive = false
        lastShieldingResult = .unavailable
        lastErrorMessage = ShieldingResult.unavailable.message
        return .unavailable
        #endif
    }

    func clearBlocking() {
        #if canImport(ManagedSettings)
        managedSettingsStore.clearAllSettings()
        #endif
        isShieldingActive = false
    }
}
