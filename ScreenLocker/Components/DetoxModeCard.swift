import SwiftUI

struct DetoxModeCard: View {
    let mode: DetoxMode
    var appSymbols: [String] = ["camera.fill", "music.note", "play.fill", "message.fill", "globe"]

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppTheme.accentGradient)
                    .frame(width: 44, height: 44)

                Image(systemName: mode.iconName)
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text(mode.name)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryText)

                    if mode.isPro {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.warning)
                    }
                }

                Text("\(mode.blockedAppCount) apps blocked")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)

                HStack(spacing: -2) {
                    ForEach(Array(appSymbols.prefix(5).enumerated()), id: \.offset) { index, symbol in
                        ZStack {
                            Circle()
                                .fill(chipColor(index: index))
                                .frame(width: 26, height: 26)
                                .overlay(Circle().stroke(AppTheme.background, lineWidth: 2))

                            Image(systemName: symbol)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                        }
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.mutedText)
        }
        .detoxCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(mode.name), \(mode.blockedAppCount) apps blocked")
    }

    private func chipColor(index: Int) -> Color {
        let colors: [Color] = [.pink, .mint, .red, .white.opacity(0.16), .orange]
        return colors[index % colors.count]
    }
}
