import SwiftUI

struct AccountSuspendedScreen: View {
    @Environment(AppState.self) private var appState

    let suspendedUntil: String?

    @State private var isLoggingOut = false

    var body: some View {
        ZStack {
            Color.rzBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: RZSpacing.lg) {
                    // Icon
                    Image(systemName: "lock.fill")
                        .font(.system(size: 56, weight: .semibold))
                        .foregroundStyle(.rzWarning)

                    // Title & details
                    VStack(spacing: RZSpacing.xxs) {
                        Text("Account Suspended")
                            .font(.rzH2)
                            .foregroundStyle(.rzTextPrimary)

                        if let until = formattedSuspensionDate {
                            Text("Your account is suspended until \(until).")
                                .font(.rzBodyLarge)
                                .foregroundStyle(.rzTextSecondary)
                                .multilineTextAlignment(.center)
                        } else {
                            Text("Your account has been temporarily suspended.")
                                .font(.rzBodyLarge)
                                .foregroundStyle(.rzTextSecondary)
                                .multilineTextAlignment(.center)
                        }

                        Text("Penalty points led to a temporary suspension of your account. You will regain access once the suspension period ends.")
                            .font(.rzBody)
                            .foregroundStyle(.rzTextTertiary)
                            .multilineTextAlignment(.center)
                            .padding(.top, RZSpacing.xxs)
                    }
                }
                .padding(.horizontal, RZSpacing.screenHorizontal)

                Spacer()

                // Actions
                VStack(spacing: RZSpacing.xs) {
                    RZButton(title: "View Penalties", variant: .secondary, size: .large, isFullWidth: true) {
                        // Navigate to penalty summary when within main navigation context
                    }

                    RZButton(
                        title: "Log Out",
                        variant: .destructive,
                        size: .large,
                        isFullWidth: true,
                        isLoading: isLoggingOut
                    ) {
                        handleLogout()
                    }
                }
                .padding(.horizontal, RZSpacing.screenHorizontal)
                .padding(.bottom, RZSpacing.xxl)
            }
        }
    }

    // MARK: - Computed

    private var formattedSuspensionDate: String? {
        guard let until = suspendedUntil else { return nil }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: until) {
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
        // Fallback: try without fractional seconds
        let iso2 = ISO8601DateFormatter()
        if let date = iso2.date(from: until) {
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
        return until
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
