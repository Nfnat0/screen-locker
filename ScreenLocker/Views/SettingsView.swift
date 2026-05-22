import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settingsStore: SettingsStore
    @EnvironmentObject private var purchaseManager: PurchaseManager

    @State private var showingPurchaseMessage = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                settingsSection("GENERAL") {
                    NavigationLink {
                        BlockedAppsView()
                    } label: {
                        SettingRowView(title: "Blocked Apps", iconName: "apps.iphone", value: "\(settingsStore.blockedAppCount) apps")
                    }

                    Divider().overlay(Color.white.opacity(0.08))

                    NavigationLink {
                        DefaultDurationSettingsView()
                    } label: {
                        SettingRowView(title: "Default Duration", iconName: "timer", value: Formatters.minutesLabel(settingsStore.defaultDurationMinutes))
                    }

                    Divider().overlay(Color.white.opacity(0.08))

                    NavigationLink {
                        UnlockDelaySettingsView()
                    } label: {
                        SettingRowView(title: "Unlock Delay", iconName: "hourglass", value: "\(settingsStore.unlockDelaySeconds) sec")
                    }

                    Divider().overlay(Color.white.opacity(0.08))

                    Toggle(isOn: $settingsStore.notificationsEnabled) {
                        Label("Notifications", systemImage: "bell.fill")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.primaryText)
                    }
                    .tint(AppTheme.cyan)
                    .padding(.vertical, 12)

                    Divider().overlay(Color.white.opacity(0.08))

                    NavigationLink {
                        AppearanceSettingsView()
                    } label: {
                        SettingRowView(title: "Appearance", iconName: "moon.fill", value: settingsStore.appearance)
                    }
                }

                settingsSection("ADVANCED") {
                    NavigationLink {
                        StatsDataView()
                    } label: {
                        SettingRowView(title: "Stats & Data", iconName: "externaldrive.fill")
                    }

                    Divider().overlay(Color.white.opacity(0.08))

                    Button {
                        Task {
                            await purchaseManager.restorePurchases()
                            showingPurchaseMessage = true
                        }
                    } label: {
                        SettingRowView(title: "Restore Purchase", iconName: "arrow.clockwise")
                    }
                    .buttonStyle(.plain)
                }

                settingsSection("PRO") {
                    NavigationLink {
                        ModesView()
                    } label: {
                        SettingRowView(title: "Modes", iconName: "square.grid.2x2.fill", isLocked: !purchaseManager.isProUnlocked)
                    }

                    Divider().overlay(Color.white.opacity(0.08))

                    NavigationLink {
                        SchedulesView()
                    } label: {
                        SettingRowView(title: "Schedules", iconName: "calendar.badge.clock", isLocked: !purchaseManager.isProUnlocked)
                    }

                    Divider().overlay(Color.white.opacity(0.08))

                    NavigationLink {
                        DeepLockView()
                    } label: {
                        SettingRowView(title: "Deep Lock", iconName: "lock.shield.fill", isLocked: !purchaseManager.isProUnlocked)
                    }

                    Divider().overlay(Color.white.opacity(0.08))

                    NavigationLink {
                        AdvancedInsightsView()
                    } label: {
                        SettingRowView(title: "Advanced Insights", iconName: "chart.xyaxis.line", isLocked: !purchaseManager.isProUnlocked)
                    }
                }
            }
            .padding(20)
            .padding(.bottom, 30)
        }
        .screenBackground()
        .navigationTitle("Settings")
        .alert("Purchase", isPresented: $showingPurchaseMessage) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(purchaseManager.lastMessage ?? "")
        }
    }

    private func settingsSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(AppTheme.mutedText)
                .padding(.horizontal, 2)

            VStack(spacing: 0) {
                content()
            }
            .detoxCard()
        }
    }
}

private struct DefaultDurationSettingsView: View {
    @EnvironmentObject private var settingsStore: SettingsStore

    var body: some View {
        Form {
            Picker("Default Duration", selection: $settingsStore.defaultDurationMinutes) {
                ForEach([15, 30, 45, 60, 90, 120, 180], id: \.self) { minutes in
                    Text(Formatters.minutesLabel(minutes)).tag(minutes)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .screenBackground()
        .navigationTitle("Default Duration")
    }
}

private struct UnlockDelaySettingsView: View {
    @EnvironmentObject private var settingsStore: SettingsStore

    var body: some View {
        Form {
            Picker("Unlock Delay", selection: $settingsStore.unlockDelaySeconds) {
                ForEach([10, 30, 60], id: \.self) { seconds in
                    Text("\(seconds) sec").tag(seconds)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .screenBackground()
        .navigationTitle("Unlock Delay")
    }
}

private struct AppearanceSettingsView: View {
    @EnvironmentObject private var settingsStore: SettingsStore

    var body: some View {
        Form {
            Picker("Appearance", selection: $settingsStore.appearance) {
                Text("Dark").tag("Dark")
                Text("System").tag("System")
            }

            Section {
                Text("Custom themes are part of Pro and are prepared as locked structure for a later StoreKit build.")
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
        .scrollContentBackground(.hidden)
        .screenBackground()
        .navigationTitle("Appearance")
    }
}

private struct StatsDataView: View {
    @EnvironmentObject private var sessionViewModel: DetoxSessionViewModel
    @State private var showingResetConfirmation = false

    var body: some View {
        List {
            Section {
                HStack {
                    Text("Stored Sessions")
                    Spacer()
                    Text("\(sessionViewModel.sessions.count)")
                        .foregroundStyle(AppTheme.secondaryText)
                }

                Button(role: .destructive) {
                    showingResetConfirmation = true
                } label: {
                    Text("Delete Session History")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .screenBackground()
        .navigationTitle("Stats & Data")
        .confirmationDialog("Delete all sessions?", isPresented: $showingResetConfirmation, titleVisibility: .visible) {
            Button("Delete Session History", role: .destructive) {
                sessionViewModel.deleteAllSessions()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This removes local detox session records from SwiftData.")
        }
    }
}
