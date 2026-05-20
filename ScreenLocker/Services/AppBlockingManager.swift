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
            let message = "Screen Time access is not approved. The local timer will continue without app shielding."
            lastErrorMessage = message
            return .fallback(selectedItemCount: settingsStore.blockedAppCount, message: message)
        }

        let selection = settingsStore.activitySelection
        let selectedItemCount = selection.applicationTokens.count + selection.categoryTokens.count + selection.webDomainTokens.count

        managedSettingsStore.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        managedSettingsStore.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
        managedSettingsStore.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens

        isShieldingActive = selectedItemCount > 0

        if isShieldingActive {
            lastErrorMessage = nil
            return .applied(selectedItemCount: selectedItemCount)
        } else {
            let message = "No Screen Time apps are selected. Mock blocked app count is shown in the UI."
            lastErrorMessage = message
            return .fallback(selectedItemCount: settingsStore.blockedAppCount, message: message)
        }
        #else
        isShieldingActive = false
        let message = "Screen Time shielding is unavailable in this build."
        lastErrorMessage = message
        return .fallback(selectedItemCount: settingsStore.blockedAppCount, message: message)
        #endif
    }

    func clearBlocking() {
        #if canImport(ManagedSettings)
        managedSettingsStore.clearAllSettings()
        #endif
        isShieldingActive = false
    }

    func configureDeviceActivityMonitoringPlaceholder() {
        // TODO: Add DeviceActivity schedules when the Pro schedules feature is unlocked and the entitlement is configured.
    }
}
