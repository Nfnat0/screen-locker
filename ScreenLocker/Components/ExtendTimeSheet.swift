import SwiftUI

struct ExtendTimeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: DetoxSessionViewModel
    let session: DetoxSessionRecord

    @State private var customMinutesText = ""

    private var customMinutes: Int {
        Int(customMinutesText) ?? 0
    }

    private var previewMinutes: Int {
        max(customMinutes, 0)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Text("Extend")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(AppTheme.primaryText)

                        Text("Add more time to your session.")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    .padding(.top, 12)

                    VStack(spacing: 10) {
                        extendButton(title: "+5 min", minutes: 5)
                        extendButton(title: "+15 min", minutes: 15)
                        extendButton(title: "+30 min", minutes: 30)

                        VStack(alignment: .leading, spacing: 12) {
                            Label("Custom minutes", systemImage: "clock.badge.plus")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(AppTheme.primaryText)

                            TextField("Minutes", text: $customMinutesText)
                                .keyboardType(.numberPad)
                                .textInputAutocapitalization(.never)
                                .font(.title3.monospacedDigit())
                                .foregroundStyle(AppTheme.primaryText)
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color.white.opacity(0.07))
                                )

                            PrimaryButton(title: "Add Custom Time", systemImage: "plus", isDisabled: customMinutes <= 0) {
                                add(minutes: customMinutes)
                            }
                        }
                        .detoxCard()
                    }

                    VStack(alignment: .leading, spacing: 18) {
                        Text("Total session")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)

                        Text("\(session.totalPlannedMinutes) min -> \(session.totalPlannedMinutes + previewMinutes) min")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(AppTheme.primaryText)
                            .monospacedDigit()

                        VStack(alignment: .leading, spacing: 6) {
                            Text("New remaining time")
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText)

                            Text(Formatters.clockDuration(session.remainingTime(at: viewModel.now) + TimeInterval(previewMinutes * 60)))
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(AppTheme.cyan)
                                .monospacedDigit()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .detoxCard()
                }
                .padding(20)
            }
            .screenBackground()
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
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func extendButton(title: String, minutes: Int) -> some View {
        Button {
            add(minutes: minutes)
        } label: {
            HStack {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)
                Spacer()
            }
            .detoxCard()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Extend by \(minutes) minutes")
    }

    private func add(minutes: Int) {
        viewModel.extendActiveSession(by: minutes)
        dismiss()
    }
}
