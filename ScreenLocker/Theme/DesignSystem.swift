import SwiftUI

enum AppTheme {
    static let background = Color(red: 0.015, green: 0.018, blue: 0.024)
    static let elevatedBackground = Color(red: 0.055, green: 0.065, blue: 0.078)
    static let cardBackground = Color.white.opacity(0.065)
    static let cardStroke = Color.white.opacity(0.08)
    static let primaryText = Color.white
    static let secondaryText = Color.white.opacity(0.62)
    static let mutedText = Color.white.opacity(0.42)
    static let cyan = Color(red: 0.28, green: 0.90, blue: 0.86)
    static let purple = Color(red: 0.47, green: 0.28, blue: 0.95)
    static let blue = Color(red: 0.32, green: 0.52, blue: 0.96)
    static let warning = Color(red: 1.00, green: 0.72, blue: 0.28)

    static let accentGradient = LinearGradient(
        colors: [purple, blue, cyan],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let verticalAccentGradient = LinearGradient(
        colors: [purple, blue, cyan],
        startPoint: .bottom,
        endPoint: .top
    )
}

struct DetoxCardModifier: ViewModifier {
    var padding: CGFloat
    var cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AppTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(AppTheme.cardStroke, lineWidth: 1)
                    )
            )
    }
}

extension View {
    func detoxCard(padding: CGFloat = 16, cornerRadius: CGFloat = 22) -> some View {
        modifier(DetoxCardModifier(padding: padding, cornerRadius: cornerRadius))
    }

    func screenBackground() -> some View {
        background(
            ZStack {
                AppTheme.background.ignoresSafeArea()
                LinearGradient(
                    colors: [
                        AppTheme.purple.opacity(0.16),
                        .clear,
                        AppTheme.cyan.opacity(0.10)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
        )
    }
}

enum Formatters {
    static func compactDuration(_ seconds: TimeInterval) -> String {
        let minutes = max(0, Int(seconds.rounded()) / 60)
        let hours = minutes / 60
        let remainder = minutes % 60

        if hours > 0 && remainder > 0 {
            return "\(hours)h \(remainder)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(remainder)m"
        }
    }

    static func minutesLabel(_ minutes: Int) -> String {
        minutes >= 60 ? compactDuration(TimeInterval(minutes * 60)) : "\(minutes) min"
    }

    static func clockDuration(_ seconds: TimeInterval) -> String {
        let totalSeconds = max(0, Int(seconds.rounded()))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    static func percentage(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }

    static func digitalTime(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }

    static func weekdaySymbol(for date: Date, calendar: Calendar = .current) -> String {
        let index = calendar.component(.weekday, from: date) - 1
        return calendar.shortWeekdaySymbols[index].prefix(1).uppercased()
    }
}
