import SwiftUI

struct LockScreenTimerView: View {
    let session: DetoxSessionRecord
    let now: Date

    var body: some View {
        VStack(spacing: 30) {
            Text(Formatters.digitalTime(now))
                .font(.system(size: 38, weight: .light, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(AppTheme.primaryText)
                .accessibilityLabel("Current time \(Formatters.digitalTime(now))")

            ProgressRingView(progress: session.progress(at: now), lineWidth: 14, size: 246) {
                VStack(spacing: 8) {
                    Text(Formatters.clockDuration(session.remainingTime(at: now)))
                        .font(.system(size: 44, weight: .light, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(AppTheme.primaryText)
                        .minimumScaleFactor(0.72)
                        .lineLimit(1)

                    Text("remaining")
                        .font(.callout)
                        .foregroundStyle(AppTheme.secondaryText)

                    Text("\(Formatters.percentage(session.progress(at: now))) complete")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(AppTheme.primaryText.opacity(0.78))
                        .padding(.top, 6)
                }
                .padding(.horizontal, 24)
            }

            Label(session.modeName, systemImage: "leaf.fill")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.cyan)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(Capsule().fill(Color.white.opacity(0.08)))
                .accessibilityLabel("Current detox mode, \(session.modeName)")
        }
    }
}
