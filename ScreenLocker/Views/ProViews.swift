import SwiftUI

struct ProUpsellCard: View {
    var body: some View {
        NavigationLink {
            ProUnlockView()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(AppTheme.warning.opacity(0.16))
                        .frame(width: 48, height: 48)

                    Image(systemName: "crown.fill")
                        .foregroundStyle(AppTheme.warning)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Go Pro")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryText)

                    Text("Unlock advanced insights, multiple modes and Deep Lock.")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.mutedText)
            }
            .detoxCard()
        }
        .buttonStyle(.plain)
    }
}

struct ProUnlockView: View {
    @EnvironmentObject private var purchaseManager: PurchaseManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 42))
                        .foregroundStyle(AppTheme.warning)

                    Text("Detox Pro")
                        .font(.largeTitle.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryText)

                    Text("A one-time unlock for deeper insights, schedules, more modes, and guided Deep Lock setup.")
                        .font(.body)
                        .foregroundStyle(AppTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: 0) {
                    ForEach(ProFeature.allCases) { feature in
                        ProFeatureRow(feature: feature)

                        if feature != ProFeature.allCases.last {
                            Divider().overlay(Color.white.opacity(0.08))
                        }
                    }
                }
                .detoxCard()

                PrimaryButton(
                    title: purchaseManager.isProUnlocked ? "Pro Active" : "Unlock Pro Placeholder",
                    systemImage: purchaseManager.isProUnlocked ? "checkmark.seal.fill" : "crown.fill",
                    isDisabled: purchaseManager.isProUnlocked
                ) {
                    purchaseManager.purchaseProPlaceholder()
                }

                Text("StoreKit product loading and transaction verification are intentionally left as TODOs until product IDs are configured.")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(20)
            .padding(.bottom, 30)
        }
        .screenBackground()
        .navigationTitle("Go Pro")
    }
}

private struct ProFeatureRow: View {
    let feature: ProFeature

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: feature.iconName)
                .font(.headline)
                .foregroundStyle(AppTheme.cyan)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)

                Text(feature.subtitle)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Spacer()
        }
        .padding(.vertical, 12)
    }
}

struct ModesView: View {
    @EnvironmentObject private var settingsStore: SettingsStore
    @EnvironmentObject private var purchaseManager: PurchaseManager

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                DetoxModeCard(mode: .defaultMode(blockedAppCount: settingsStore.blockedAppCount))

                VStack(spacing: 0) {
                    ForEach(DetoxMode.proModes) { mode in
                        HStack(spacing: 14) {
                            Image(systemName: mode.iconName)
                                .font(.headline)
                                .foregroundStyle(AppTheme.cyan)
                                .frame(width: 28)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(mode.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppTheme.primaryText)
                                Text("\(mode.blockedAppCount) apps")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }

                            Spacer()

                            Image(systemName: purchaseManager.isProUnlocked ? "chevron.right" : "lock.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(purchaseManager.isProUnlocked ? AppTheme.mutedText : AppTheme.warning)
                        }
                        .padding(.vertical, 14)

                        if mode.id != DetoxMode.proModes.last?.id {
                            Divider().overlay(Color.white.opacity(0.08))
                        }
                    }
                }
                .detoxCard()

                if !purchaseManager.isProUnlocked {
                    lockedBanner("Unlock unlimited modes with Pro.")
                }
            }
            .padding(20)
            .padding(.bottom, 30)
        }
        .screenBackground()
        .navigationTitle("Modes")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                } label: {
                    Image(systemName: "plus")
                }
                .disabled(!purchaseManager.isProUnlocked)
                .accessibilityLabel("Add mode")
            }
        }
    }
}

struct SchedulesView: View {
    @EnvironmentObject private var purchaseManager: PurchaseManager

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                schedulePreview(title: "Weekdays", time: "10:00 PM - 7:00 AM", days: "Mon Tue Wed Thu Fri")
                schedulePreview(title: "Focus Time", time: "9:00 AM - 12:00 PM", days: "Mon Tue Wed Thu Fri")
                schedulePreview(title: "Evening Detox", time: "8:00 PM - 11:00 PM", days: "Every day")

                if !purchaseManager.isProUnlocked {
                    lockedBanner("Unlock schedules with Pro.")
                }
            }
            .padding(20)
            .padding(.bottom, 30)
        }
        .screenBackground()
        .navigationTitle("Schedules")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                } label: {
                    Image(systemName: "plus")
                }
                .disabled(!purchaseManager.isProUnlocked)
                .accessibilityLabel("Add schedule")
            }
        }
    }

    private func schedulePreview(title: String, time: String, days: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)

                Text(time)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)

                Text(days)
                    .font(.caption)
                    .foregroundStyle(AppTheme.mutedText)
            }

            Spacer()

            Toggle("", isOn: .constant(true))
                .labelsHidden()
                .tint(AppTheme.cyan)
                .disabled(true)
        }
        .detoxCard()
    }
}

struct DeepLockView: View {
    @State private var showingSetupGuide = false

    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 22) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(AppTheme.accentGradient)
                    .padding(.top, 20)

                Text("Deep Lock")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)

                Text("Deep Lock helps you stay committed by reducing common escape routes.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppTheme.secondaryText)
                    .padding(.horizontal, 10)

                VStack(spacing: 0) {
                    deepLockRow(
                        icon: "iphone.slash",
                        title: "Block uninstall & disabling",
                        subtitle: "Guide to set up via Screen Time"
                    )
                    Divider().overlay(Color.white.opacity(0.08))
                    deepLockRow(
                        icon: "gear.badge.xmark",
                        title: "Block system settings access",
                        subtitle: "Prevent changes during sessions"
                    )
                    Divider().overlay(Color.white.opacity(0.08))
                    deepLockRow(
                        icon: "lock.fill",
                        title: "Require passcode to exit",
                        subtitle: "Add an extra layer of protection"
                    )
                }
                .detoxCard()

                PrimaryButton(title: "Set Up Deep Lock", systemImage: "shield.lefthalf.filled") {
                    showingSetupGuide = true
                }
            }
            .padding(20)
            .padding(.bottom, 30)
        }
        .screenBackground()
        .navigationTitle("Deep Lock")
        .sheet(isPresented: $showingSetupGuide) {
            DeepLockSetupGuideView()
        }
    }

    private func deepLockRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(AppTheme.cyan)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Spacer()
        }
        .padding(.vertical, 14)
    }
}

private struct DeepLockSetupGuideView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Guide to set up via Screen Time")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryText)

                    Text("Deep Lock is a guided setup. iOS controls these restrictions, so Detox helps you reduce common escape routes instead of claiming absolute prevention.")
                        .font(.body)
                        .foregroundStyle(AppTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    guideStep("1", "Open iOS Settings and choose Screen Time.")
                    guideStep("2", "Use Content & Privacy Restrictions to reduce app deletion and account changes.")
                    guideStep("3", "Set a Screen Time passcode that is not easy to bypass during a detox session.")
                    guideStep("4", "Return to Detox and start a session with your selected app shields.")
                }
                .padding(20)
            }
            .screenBackground()
            .navigationTitle("Deep Lock Setup")
            .navigationBarTitleDisplayMode(.inline)
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
    }

    private func guideStep(_ number: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(Circle().fill(AppTheme.purple))

            Text(text)
                .font(.subheadline)
                .foregroundStyle(AppTheme.primaryText)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .detoxCard(padding: 14, cornerRadius: 16)
    }
}

struct AdvancedInsightsView: View {
    @EnvironmentObject private var settingsStore: SettingsStore
    @EnvironmentObject private var sessionViewModel: DetoxSessionViewModel

    private var stats: DetoxStats {
        sessionViewModel.stats(settingsStore: settingsStore)
    }

    var body: some View {
        WeeklyInsightsContent(stats: stats, isPreview: true)
            .navigationTitle("Advanced Insights")
    }
}

struct WeeklyInsightsView: View {
    @EnvironmentObject private var settingsStore: SettingsStore
    @EnvironmentObject private var sessionViewModel: DetoxSessionViewModel

    private var stats: DetoxStats {
        sessionViewModel.stats(settingsStore: settingsStore)
    }

    var body: some View {
        WeeklyInsightsContent(stats: stats, isPreview: false)
            .navigationTitle("Weekly Trend")
    }
}

private struct WeeklyInsightsContent: View {
    let stats: DetoxStats
    var isPreview: Bool

    private var bestDay: DailyProtectedTime? {
        stats.weeklyProtectedTime.max { $0.protectedSeconds < $1.protectedSeconds }
    }

    private var weeklyTotal: TimeInterval {
        stats.weeklyProtectedTime.reduce(0) { $0 + $1.protectedSeconds }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .lastTextBaseline) {
                    Text(Formatters.compactDuration(weeklyTotal))
                        .font(.system(size: 34, weight: .light, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(AppTheme.primaryText)

                    Text("This week")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)

                    Spacer()

                    Text(isPreview ? "Pro preview" : "+0% vs last week")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.cyan)
                }

                WeeklyBarChartView(days: stats.weeklyProtectedTime)
                    .detoxCard()

                VStack(spacing: 0) {
                    insightRow("Best day", bestDay.map { $0.date.formatted(.dateTime.weekday(.wide)) } ?? "None")
                    Divider().overlay(Color.white.opacity(0.08))
                    insightRow("Best time", "8PM - 11PM")
                    Divider().overlay(Color.white.opacity(0.08))
                    insightRow("Most improved", Formatters.compactDuration(stats.extendedTimeTotal))
                    Divider().overlay(Color.white.opacity(0.08))
                    insightRow("Broken sessions", "\(stats.brokenSessionCount)")
                }
                .detoxCard()

                if isPreview {
                    lockedBanner("Advanced insights are part of Pro.")
                }
            }
            .padding(20)
            .padding(.bottom, 30)
        }
        .screenBackground()
    }

    private func insightRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText)

            Spacer()

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.primaryText)
        }
        .padding(.vertical, 14)
    }
}

@ViewBuilder
private func lockedBanner(_ text: String) -> some View {
    HStack(spacing: 10) {
        Image(systemName: "lock.fill")
            .foregroundStyle(AppTheme.warning)

        Text(text)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(AppTheme.secondaryText)

        Spacer()
    }
    .detoxCard()
}
