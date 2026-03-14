import SwiftUI

struct RZEmptyState: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: RZSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.rzTextTertiary)

            Text(title)
                .font(.rzH4)
                .foregroundStyle(.rzTextPrimary)
                .multilineTextAlignment(.center)

            if let subtitle {
                Text(subtitle)
                    .font(.rzBody)
                    .foregroundStyle(.rzTextSecondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle, let action {
                RZButton(title: actionTitle, variant: .secondary, size: .medium, isFullWidth: false, action: action)
                    .padding(.top, RZSpacing.xxs)
            }
        }
        .padding(RZSpacing.xl)
    }
}
