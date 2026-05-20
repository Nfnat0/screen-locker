import SwiftUI

struct UnlockRequestView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var sessionViewModel: DetoxSessionViewModel

    let delaySeconds: Int
    @State private var remainingSeconds = 30
    @State private var selectedReason: UnlockReason?

    private var countdownProgress: Double {
        guard delaySeconds > 0 else { return 1 }
        return 1 - (Double(remainingSeconds) / Double(delaySeconds))
    }

    private var canEndSession: Bool {
        remainingSeconds == 0 && selectedReason != nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ProgressRingView(progress: countdownProgress, lineWidth: 8, size: 112) {
                        VStack(spacing: 2) {
                            Text("\(remainingSeconds)")
                                .font(.system(size: 32, weight: .light, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(AppTheme.primaryText)
                            Text("seconds")
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                    }
                    .padding(.top, 12)

                    Text(remainingSeconds > 0 ? "Please wait..." : "Select a reason to continue.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Why do you want to stop?")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(AppTheme.primaryText)
                            .padding(.bottom, 6)

                        ForEach(UnlockReason.allCases) { reason in
                            UnlockReasonRow(reason: reason, isSelected: selectedReason == reason) {
                                selectedReason = reason
                            }

                            if reason != UnlockReason.allCases.last {
                                Divider().overlay(Color.white.opacity(0.08))
                            }
                        }
                    }
                    .detoxCard()

                    Text("This session will be recorded as an early end.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .detoxCard()

                    PrimaryButton(title: "End Session", systemImage: "lock.open.fill", isDisabled: !canEndSession) {
                        guard let selectedReason else { return }
                        sessionViewModel.breakActiveSession(reason: selectedReason)
                        dismiss()
                    }
                }
                .padding(20)
            }
            .screenBackground()
            .navigationTitle("Unlock Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close", systemImage: "xmark") {
                        dismiss()
                    }
                    .labelStyle(.iconOnly)
                    .foregroundStyle(AppTheme.primaryText)
                    .accessibilityLabel("Close")
                }
            }
        }
        .task(id: delaySeconds) {
            remainingSeconds = max(0, delaySeconds)

            while remainingSeconds > 0 {
                try? await Task.sleep(for: .seconds(1))
                remainingSeconds -= 1
            }
        }
        .presentationDetents([.large])
    }
}
