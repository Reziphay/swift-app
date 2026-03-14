import SwiftUI

private enum EmailLinkState {
    case loading
    case success
    case expired
    case invalid
    case alreadyUsed
}

struct EmailLinkResultScreen: View {
    @Environment(AppState.self) private var appState

    let token: String

    @State private var state: EmailLinkState = .loading

    var body: some View {
        ZStack {
            Color.rzBackground
                .ignoresSafeArea()

            switch state {
            case .loading:
                loadingView
            case .success:
                resultView(
                    icon: "checkmark.circle.fill",
                    iconColor: .rzSuccess,
                    heading: "Email Verified",
                    explanation: "Your email address has been successfully verified. You're being signed in.",
                    ctaTitle: nil,
                    ctaAction: nil
                )
            case .expired:
                resultView(
                    icon: "clock.badge.exclamationmark.fill",
                    iconColor: .rzWarning,
                    heading: "Link Expired",
                    explanation: "This magic link has expired. Please request a new one from the sign-in page.",
                    ctaTitle: "Return to Login",
                    ctaAction: { appState.router.navigateToAuth() }
                )
            case .invalid:
                resultView(
                    icon: "xmark.circle.fill",
                    iconColor: .rzError,
                    heading: "Invalid Link",
                    explanation: "This link is not valid. It may have been modified or is incomplete.",
                    ctaTitle: "Return to Login",
                    ctaAction: { appState.router.navigateToAuth() }
                )
            case .alreadyUsed:
                resultView(
                    icon: "checkmark.seal.fill",
                    iconColor: .rzTextTertiary,
                    heading: "Already Used",
                    explanation: "This link has already been used. Please sign in again to continue.",
                    ctaTitle: "Return to Login",
                    ctaAction: { appState.router.navigateToAuth() }
                )
            }
        }
        .task {
            await verifyToken()
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack(spacing: RZSpacing.lg) {
            ProgressView()
                .tint(.rzPrimary)
                .scaleEffect(1.2)
            Text("Verifying your link…")
                .font(.rzBody)
                .foregroundStyle(.rzTextSecondary)
        }
    }

    private func resultView(
        icon: String,
        iconColor: Color,
        heading: String,
        explanation: String,
        ctaTitle: String?,
        ctaAction: (() -> Void)?
    ) -> some View {
        VStack(spacing: RZSpacing.lg) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 64, weight: .semibold))
                .foregroundStyle(iconColor)

            VStack(spacing: RZSpacing.xxs) {
                Text(heading)
                    .font(.rzH2)
                    .foregroundStyle(.rzTextPrimary)

                Text(explanation)
                    .font(.rzBody)
                    .foregroundStyle(.rzTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, RZSpacing.xl)
            }

            Spacer()

            if let ctaTitle, let ctaAction {
                RZButton(title: ctaTitle, variant: .secondary, size: .large, isFullWidth: true) {
                    ctaAction()
                }
                .padding(.horizontal, RZSpacing.screenHorizontal)
                .padding(.bottom, RZSpacing.xxl)
            }
        }
    }

    // MARK: - Logic

    private func verifyToken() async {
        do {
            try await appState.authManager.verifyEmailMagicLink(token: token)
            state = .success
            await appState.handleLogin()
        } catch let apiError as APIError {
            switch apiError {
            case .serverError(let code, _):
                switch code {
                case "TOKEN_EXPIRED", "LINK_EXPIRED":
                    state = .expired
                case "TOKEN_ALREADY_USED", "LINK_ALREADY_USED":
                    state = .alreadyUsed
                default:
                    state = .invalid
                }
            case .notFound:
                state = .invalid
            default:
                state = .invalid
            }
        } catch {
            state = .invalid
        }
    }
}
