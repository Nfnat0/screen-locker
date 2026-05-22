import SwiftUI

struct ScreenTimeStatusView: View {
    let authorizationState: BlockingAuthorizationState
    let shieldingResult: ShieldingResult?
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: iconName)
                    .font(.headline)
                    .foregroundStyle(statusColor)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Screen Time")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryText)

                    Text(authorizationState.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(statusColor)
                }

                Spacer()
            }

            Text(shieldingResult?.message ?? authorizationState.detail)
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            if let actionTitle, let action {
                PrimaryButton(title: actionTitle, systemImage: "lock.shield") {
                    action()
                }
            }
        }
        .detoxCard()
        .accessibilityElement(children: .combine)
    }

    private var iconName: String {
        switch authorizationState {
        case .approved:
            "checkmark.shield.fill"
        case .denied, .restricted, .unavailable:
            "exclamationmark.shield.fill"
        case .notDetermined:
            "shield.lefthalf.filled"
        }
    }

    private var statusColor: Color {
        switch authorizationState {
        case .approved:
            AppTheme.cyan
        case .denied, .restricted, .unavailable:
            AppTheme.warning
        case .notDetermined:
            AppTheme.secondaryText
        }
    }
}
