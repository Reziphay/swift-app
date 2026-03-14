import SwiftUI

struct AccountClosedScreen: View {
    @Environment(AppState.self) private var appState

    @State private var isLoggingOut = false

    var body: some View {
        ZStack {
            Color.rzBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: RZSpacing.lg) {
                    // Icon
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 56, weight: .semibold))
                        .foregroundStyle(.rzError)

                    // Title & explanation
                    VStack(spacing: RZSpacing.xxs) {
                        Text("Account Closed")
                            .font(.rzH2)
                            .foregroundStyle(.rzTextPrimary)

                        Text("Your account has been permanently closed.")
                            .font(.rzBodyLarge)
                            .foregroundStyle(.rzTextSecondary)
                            .multilineTextAlignment(.center)

                        Text("If you believe this is a mistake, please contact our support team.")
                            .font(.rzBody)
                            .foregroundStyle(.rzTextTertiary)
                            .multilineTextAlignment(.center)
                            .padding(.top, RZSpacing.xxs)
                    }
                }
                .padding(.horizontal, RZSpacing.screenHorizontal)

                Spacer()

                // Log out button
                RZButton(
                    title: "Log Out",
                    variant: .destructive,
                    size: .large,
                    isFullWidth: true,
                    isLoading: isLoggingOut
                ) {
                    handleLogout()
                }
                .padding(.horizontal, RZSpacing.screenHorizontal)
                .padding(.bottom, RZSpacing.xxl)
            }
        }
    }

    // MARK: - Actions

    private func handleLogout() {
        isLoggingOut = true
        Task {
            defer { isLoggingOut = false }
            await appState.handleLogout()
        }
    }
}
