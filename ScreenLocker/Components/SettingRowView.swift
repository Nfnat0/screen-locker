import SwiftUI

struct SettingRowView: View {
    let title: String
    var subtitle: String?
    var iconName: String?
    var value: String?
    var isLocked = false

    var body: some View {
        HStack(spacing: 12) {
            if let iconName {
                Image(systemName: iconName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isLocked ? AppTheme.warning : AppTheme.cyan)
                    .frame(width: 22)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.primaryText)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 12)

            if let value {
                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(1)
            }

            Image(systemName: isLocked ? "lock.fill" : "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.mutedText)
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
