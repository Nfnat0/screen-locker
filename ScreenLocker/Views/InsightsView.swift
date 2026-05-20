import SwiftUI

struct InsightsView: View {
    @EnvironmentObject private var settingsStore: SettingsStore
    @EnvironmentObject private var sessionViewModel: DetoxSessionViewModel

    @State private var selectedScope = "Today"
    private let scopes = ["Today", "Week", "Month", "Year"]

    private var stats: DetoxStats {
        sessionViewModel.stats(settingsStore: settingsStore)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Picker("Range", selection: $selectedScope) {
                    ForEach(scopes, id: \.self) { scope in
                        Text(scope).tag(scope)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Insights range")

                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Protected Time")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(AppTheme.secondaryText)

                            Text(Formatters.compactDuration(stats.protectedTimeToday))
                                .font(.system(size: 34, weight: .light, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(AppTheme.primaryText)
                        }

                        Spacer()

                        NavigationLink("View all") {
                            WeeklyInsightsView()
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.cyan)
                    }

                    WeeklyBarChartView(days: stats.weeklyProtectedTime)
                }
                .detoxCard()

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    StatCardView(title: "Sessions", value: "\(stats.sessionCountToday)", iconName: "checkmark.circle.fill", accent: AppTheme.purple)
                    StatCardView(title: "Avg. Session", value: Formatters.compactDuration(stats.averageSessionLength), iconName: "timer", accent: AppTheme.blue)
                    StatCardView(title: "Completion Rate", value: Formatters.percentage(stats.completionRate), iconName: "percent", accent: AppTheme.cyan)
                    StatCardView(title: "Streak", value: "\(stats.currentStreak) days", iconName: "flame.fill", accent: AppTheme.warning)
                    StatCardView(title: "Total Protected", value: Formatters.compactDuration(stats.protectedTimeAllTime), iconName: "clock.arrow.circlepath", accent: AppTheme.cyan)
                    StatCardView(title: "Extended", value: Formatters.compactDuration(stats.extendedTimeTotal), iconName: "plus.circle.fill", accent: AppTheme.blue)
                }

                if sessionViewModel.sessions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("No sessions yet")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(AppTheme.primaryText)

                        Text("Start a detox session from the Timer tab and your protected time will appear here.")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .detoxCard()
                }

                ProUpsellCard()
            }
            .padding(20)
            .padding(.bottom, 30)
        }
        .screenBackground()
        .navigationTitle("Insights")
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
    }
}
