import SwiftUI

struct UnlockReasonRow: View {
    let reason: UnlockReason
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.body)
                    .foregroundStyle(isSelected ? AppTheme.cyan : AppTheme.secondaryText)

                Text(reason.title)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.primaryText)

                Spacer()
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(reason.title)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }
}
