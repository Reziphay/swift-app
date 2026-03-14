import SwiftUI

struct RZConfirmationDialog: View {
    let title: String
    let message: String
    let confirmTitle: String
    var confirmVariant: RZButtonVariant = .destructive
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: RZSpacing.lg) {
            VStack(spacing: RZSpacing.xxs) {
                Text(title)
                    .font(.rzH3)
                    .foregroundStyle(.rzTextPrimary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.rzBody)
                    .foregroundStyle(.rzTextSecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: RZSpacing.xxs) {
                RZButton(title: confirmTitle, variant: confirmVariant, action: onConfirm)
                RZButton(title: "Cancel", variant: .ghost, action: onCancel)
            }
        }
        .padding(RZSpacing.lg)
    }
}
