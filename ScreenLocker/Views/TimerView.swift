import SwiftUI

struct TimerView: View {
    @EnvironmentObject private var settingsStore: SettingsStore
    @EnvironmentObject private var appBlockingManager: AppBlockingManager
    @EnvironmentObject private var sessionViewModel: DetoxSessionViewModel

    @State private var selectedDurationMinutes = 60
    @State private var showingDurationPicker = false
    @State private var showingPermissionSheet = false

    private var stats: DetoxStats {
        sessionViewModel.stats(settingsStore: settingsStore)
    }

    private var goalProgress: Double {
        guard settingsStore.dailyGoalMinutes > 0 else { return 0 }
        return min(1, stats.protectedTimeToday / TimeInterval(settingsStore.dailyGoalMinutes * 60))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                protectedTodayCard

                NavigationLink {
                    BlockedAppsView()
                } label: {
                    DetoxModeCard(mode: .defaultMode(blockedAppCount: settingsStore.blockedAppCount))
                }
                .buttonStyle(.plain)

                Button {
                    showingDurationPicker = true
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Duration")
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText)

                            Text(Formatters.minutesLabel(selectedDurationMinutes))
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(AppTheme.primaryText)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.mutedText)
                    }
                    .detoxCard()
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Session duration \(Formatters.minutesLabel(selectedDurationMinutes))")

                if appBlockingManager.authorizationState != .approved || !appBlockingManager.isShieldingActive {
                    ScreenTimeStatusView(
                        authorizationState: appBlockingManager.authorizationState,
                        shieldingResult: appBlockingManager.authorizationState == .approved ? appBlockingManager.lastShieldingResult : nil
                    )
                }

                PrimaryButton(title: "Start Detox", systemImage: "play.fill") {
                    startTapped()
                }
                .padding(.top, 2)
            }
            .padding(20)
            .padding(.bottom, 30)
        }
        .screenBackground()
        .navigationTitle("Timer")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    ProUnlockView()
                } label: {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(AppTheme.warning)
                }
                .accessibilityLabel("Go Pro")
            }
        }
        .onAppear {
            selectedDurationMinutes = settingsStore.defaultDurationMinutes
            appBlockingManager.refreshAuthorizationStatus()
        }
        .sheet(isPresented: $showingDurationPicker) {
            DurationPickerSheet(selectedDurationMinutes: $selectedDurationMinutes)
        }
        .sheet(isPresented: $showingPermissionSheet) {
            ScreenTimePermissionSheet {
                showingPermissionSheet = false
                sessionViewModel.startSession(durationMinutes: selectedDurationMinutes)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Protected today")
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText)

            Text(Formatters.compactDuration(stats.protectedTimeToday))
                .font(.system(size: 38, weight: .light, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(AppTheme.primaryText)
        }
        .accessibilityElement(children: .combine)
    }

    private var protectedTodayCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Daily goal \(Formatters.compactDuration(TimeInterval(settingsStore.dailyGoalMinutes * 60)))")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)

                Spacer()

                Text(Formatters.percentage(goalProgress))
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(AppTheme.primaryText)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                    Capsule()
                        .fill(AppTheme.accentGradient)
                        .frame(width: proxy.size.width * goalProgress)
                }
            }
            .frame(height: 5)
            .accessibilityLabel("Daily goal progress")
            .accessibilityValue(Formatters.percentage(goalProgress))
        }
    }

    private func startTapped() {
        if appBlockingManager.authorizationState == .approved {
            sessionViewModel.startSession(durationMinutes: selectedDurationMinutes)
        } else {
            showingPermissionSheet = true
        }
    }
}

private struct DurationPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDurationMinutes: Int
    @State private var customMinutes = 60

    private let presets = [15, 30, 45, 60, 90, 120, 180]

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text("Duration")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 10)], spacing: 10) {
                    ForEach(presets, id: \.self) { minutes in
                        Button {
                            selectedDurationMinutes = minutes
                        } label: {
                            Text(Formatters.minutesLabel(minutes))
                                .font(.headline)
                                .foregroundStyle(selectedDurationMinutes == minutes ? .white : AppTheme.primaryText)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(selectedDurationMinutes == minutes ? AnyShapeStyle(AppTheme.accentGradient) : AnyShapeStyle(Color.white.opacity(0.07)))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }

                Stepper(value: $customMinutes, in: 1...360, step: 5) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Custom")
                            .font(.headline)
                            .foregroundStyle(AppTheme.primaryText)
                        Text("\(customMinutes) min")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }
                .detoxCard()

                PrimaryButton(title: "Use \(Formatters.minutesLabel(customMinutes))", systemImage: "checkmark") {
                    selectedDurationMinutes = customMinutes
                    dismiss()
                }

                Spacer()
            }
            .padding(20)
            .screenBackground()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.cyan)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .onAppear {
            customMinutes = selectedDurationMinutes
        }
    }
}

private struct ScreenTimePermissionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appBlockingManager: AppBlockingManager
    let startWithoutBlocking: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(AppTheme.accentGradient)

                Text("Screen Time Access")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)

                Text("Detox can use Screen Time to shield selected apps during a session. If authorization or entitlements are not ready, the local timer still works and records your progress.")
                    .font(.body)
                    .foregroundStyle(AppTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                if let message = appBlockingManager.lastErrorMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(AppTheme.warning)
                        .detoxCard(padding: 14, cornerRadius: 16)
                }

                PrimaryButton(title: "Request Screen Time Access", systemImage: "checkmark.shield") {
                    Task {
                        await appBlockingManager.requestAuthorization()
                        if appBlockingManager.authorizationState == .approved {
                            dismiss()
                        }
                    }
                }

                Button {
                    startWithoutBlocking()
                    dismiss()
                } label: {
                    Text("Start without app blocking")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .foregroundStyle(AppTheme.primaryText)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                        )
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(22)
            .screenBackground()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.cyan)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
