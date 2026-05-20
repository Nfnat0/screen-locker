import SwiftUI

struct LockScreenView: View {
    @EnvironmentObject private var settingsStore: SettingsStore
    @EnvironmentObject private var sessionViewModel: DetoxSessionViewModel

    let session: DetoxSessionRecord
    @State private var showingExtendSheet = false
    @State private var showingUnlockFlow = false

    private var stats: DetoxStats {
        sessionViewModel.stats(settingsStore: settingsStore)
    }

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 10)

            LockScreenTimerView(session: session, now: sessionViewModel.now)

            Button {
                showingExtendSheet = true
            } label: {
                HStack(spacing: 10) {
                    Text("Extend")
                        .font(.headline.weight(.semibold))
                    Image(systemName: "plus.circle.fill")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .foregroundStyle(AppTheme.primaryText)
                .background(Capsule().fill(Color.white.opacity(0.10)))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 56)
            .accessibilityLabel("Extend session")

            Text("Today protected: \(Formatters.compactDuration(stats.protectedTimeToday))")
                .font(.footnote)
                .foregroundStyle(AppTheme.secondaryText)
                .monospacedDigit()

            Spacer()

            VStack(spacing: 6) {
                Image(systemName: "lock.open")
                    .font(.body)
                    .foregroundStyle(AppTheme.secondaryText)

                Text("Unlock")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.secondaryText)

                Text("Hold for 2s")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.mutedText)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 66)
            .background(Capsule().fill(Color.white.opacity(0.055)))
            .padding(.horizontal, 38)
            .contentShape(Capsule())
            .onLongPressGesture(minimumDuration: 2) {
                showingUnlockFlow = true
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Unlock")
            .accessibilityHint("Hold for two seconds to request an early unlock")
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 22)
        .screenBackground()
        .sheet(isPresented: $showingExtendSheet) {
            ExtendTimeSheet(viewModel: sessionViewModel, session: session)
        }
        .sheet(isPresented: $showingUnlockFlow) {
            UnlockRequestView(delaySeconds: settingsStore.unlockDelaySeconds)
        }
    }
}
