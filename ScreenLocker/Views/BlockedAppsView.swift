import SwiftUI

#if canImport(FamilyControls)
import FamilyControls
#endif

struct BlockedAppsView: View {
    @EnvironmentObject private var settingsStore: SettingsStore
    @EnvironmentObject private var appBlockingManager: AppBlockingManager

    #if canImport(FamilyControls)
    @State private var selection = FamilyActivitySelection()
    #endif

    @State private var mockCount = 5

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label("Screen Time", systemImage: "checkmark.shield.fill")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(AppTheme.primaryText)

                        Spacer()

                        Text(appBlockingManager.authorizationState.title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(statusColor)
                    }

                    Text("Select apps, categories, or web domains to shield during active detox sessions.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)

                    PrimaryButton(title: "Request Authorization", systemImage: "lock.shield") {
                        Task {
                            await appBlockingManager.requestAuthorization()
                        }
                    }
                }
                .detoxCard()

                if let message = appBlockingManager.lastErrorMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(AppTheme.warning)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .detoxCard(padding: 14, cornerRadius: 16)
                }

                #if canImport(FamilyControls)
                VStack(alignment: .leading, spacing: 14) {
                    Text("Blocked Apps")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryText)

                    FamilyActivityPicker(selection: $selection)
                        .frame(minHeight: 360)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                    PrimaryButton(title: "Save Selection", systemImage: "checkmark") {
                        settingsStore.updateActivitySelection(selection)
                    }
                }
                .detoxCard()
                .onAppear {
                    selection = settingsStore.activitySelection
                    mockCount = settingsStore.blockedAppCount
                    appBlockingManager.refreshAuthorizationStatus()
                }
                #else
                unavailablePicker
                    .onAppear {
                        mockCount = settingsStore.blockedAppCount
                    }
                #endif

                VStack(alignment: .leading, spacing: 12) {
                    Text("Fallback Count")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryText)

                    Stepper(value: $mockCount, in: 0...50) {
                        Text("\(mockCount) apps")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.primaryText)
                    }
                    .onChange(of: mockCount) { _, newValue in
                        settingsStore.updateMockBlockedAppCount(newValue)
                    }

                    Text("Use this count for simulator demos or when Screen Time entitlement setup is not complete.")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .detoxCard()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Manual setup note")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryText)

                    Text("FamilyControls and ManagedSettings require Apple Developer entitlement configuration. This build keeps the API code behind AppBlockingManager and falls back to local timer behavior when authorization is unavailable.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .detoxCard()
            }
            .padding(20)
            .padding(.bottom, 30)
        }
        .screenBackground()
        .navigationTitle("Blocked Apps")
    }

    private var statusColor: Color {
        switch appBlockingManager.authorizationState {
        case .approved:
            AppTheme.cyan
        case .denied:
            AppTheme.warning
        case .notDetermined:
            AppTheme.secondaryText
        case .unavailable:
            AppTheme.warning
        }
    }

    private var unavailablePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Picker Unavailable")
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppTheme.primaryText)

            Text("FamilyActivityPicker is not available in this build environment. The app will still run with mock blocked-app behavior.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText)
        }
        .detoxCard()
    }
}
