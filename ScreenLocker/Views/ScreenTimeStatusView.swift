import SwiftUI

struct ScreenTimeStatusView: View {
    let authorizationState: BlockingAuthorizationState
    let isShieldingActive: Bool
    let message: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: iconName)
                    .foregroundStyle(tint)

                Text("Screen Time")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)

                Spacer()

                Text(authorizationState.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(tint)
            }

            Text(message ?? authorizationState.userMessage)
                .font(.footnote)
                .foregroundStyle(AppTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .detoxCard(padding: 14, cornerRadius: 16)
        .accessibilityElement(children: .combine)
    }

    private var iconName: String {
        if isShieldingActive {
            return "shield.checkered"
        }

        switch authorizationState {
        case .approved:
            return "checkmark.shield.fill"
        case .denied, .unavailable:
            return "exclamationmark.triangle.fill"
        case .notDetermined:
            return "shield"
        }
    }

    private var tint: Color {
        if isShieldingActive {
            return AppTheme.cyan
        }

        switch authorizationState {
        case .approved:
            return AppTheme.cyan
        case .denied, .unavailable:
            return AppTheme.warning
        case .notDetermined:
            return AppTheme.secondaryText
        }
    }
}
