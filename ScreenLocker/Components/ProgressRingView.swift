import SwiftUI

struct ProgressRingView<CenterContent: View>: View {
    let progress: Double
    var lineWidth: CGFloat = 16
    var size: CGFloat = 230
    @ViewBuilder var centerContent: () -> CenterContent

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(
                    AngularGradient(
                        colors: [AppTheme.purple, AppTheme.blue, AppTheme.cyan, AppTheme.purple],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.86), value: progress)

            centerContent()
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Session progress")
        .accessibilityValue(Formatters.percentage(progress))
    }
}
