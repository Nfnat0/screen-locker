import SwiftUI

struct WeeklyBarChartView: View {
    let days: [DailyProtectedTime]

    private var maxSeconds: TimeInterval {
        max(days.map(\.protectedSeconds).max() ?? 1, 1)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 14) {
            ForEach(days) { day in
                VStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(day.protectedSeconds == 0 ? AnyShapeStyle(Color.white.opacity(0.12)) : AnyShapeStyle(AppTheme.verticalAccentGradient))
                        .frame(height: barHeight(for: day))
                        .frame(maxHeight: 132, alignment: .bottom)
                        .accessibilityHidden(true)

                    Text(Formatters.weekdaySymbol(for: day.date))
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(day.date.formatted(date: .abbreviated, time: .omitted)), \(Formatters.compactDuration(day.protectedSeconds)) protected")
            }
        }
        .frame(height: 172)
        .padding(.top, 8)
    }

    private func barHeight(for day: DailyProtectedTime) -> CGFloat {
        if day.protectedSeconds <= 0 {
            return 42
        }

        return max(42, CGFloat(day.protectedSeconds / maxSeconds) * 132)
    }
}
