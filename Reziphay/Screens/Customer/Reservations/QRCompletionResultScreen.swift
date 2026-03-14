import SwiftUI

// MARK: - QR Result State

enum QRResultState {
    case success
    case invalid
    case expired
    case wrongContext
    case alreadyCompleted
    case fallback
}

// MARK: - Screen

struct QRCompletionResultScreen: View {
    let state: QRResultState
    let reservationId: String

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.rzBackground.ignoresSafeArea()

            VStack(spacing: RZSpacing.xl) {
                Spacer()

                // Icon
                Image(systemName: iconName)
                    .font(.system(size: 80))
                    .foregroundStyle(iconColor)
                    .symbolEffect(.bounce, value: true)

                // Text
                VStack(spacing: RZSpacing.xs) {
                    Text(title)
                        .font(.rzH2)
                        .foregroundStyle(.rzTextPrimary)
                        .multilineTextAlignment(.center)

                    Text(subtitle)
                        .font(.rzBody)
                        .foregroundStyle(.rzTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, RZSpacing.xl)
                }

                Spacer()

                // Actions
                VStack(spacing: RZSpacing.xs) {
                    RZButton(
                        title: primaryActionTitle,
                        variant: .primary,
                        size: .large,
                        isFullWidth: true
                    ) {
                        handlePrimaryAction()
                    }

                    if showSecondaryAction {
                        RZButton(
                            title: secondaryActionTitle,
                            variant: .ghost,
                            size: .large,
                            isFullWidth: true
                        ) {
                            handleSecondaryAction()
                        }
                    }
                }
                .padding(.horizontal, RZSpacing.screenHorizontal)
                .padding(.bottom, RZSpacing.xl)
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - State-based content

    private var iconName: String {
        switch state {
        case .success: return "checkmark.circle.fill"
        case .invalid: return "qrcode.viewfinder"
        case .expired: return "clock.badge.xmark"
        case .wrongContext: return "questionmark.circle.fill"
        case .alreadyCompleted: return "checkmark.seal.fill"
        case .fallback: return "exclamationmark.triangle.fill"
        }
    }

    private var iconColor: Color {
        switch state {
        case .success: return .rzSuccess
        case .alreadyCompleted: return .rzSuccess
        case .invalid, .expired, .wrongContext: return .rzError
        case .fallback: return .rzWarning
        }
    }

    private var title: String {
        switch state {
        case .success: return "Reservation Completed!"
        case .invalid: return "Invalid QR Code"
        case .expired: return "QR Code Expired"
        case .wrongContext: return "Wrong Reservation"
        case .alreadyCompleted: return "Already Completed"
        case .fallback: return "Something Went Wrong"
        }
    }

    private var subtitle: String {
        switch state {
        case .success:
            return "Your reservation has been successfully marked as completed. Thank you!"
        case .invalid:
            return "The QR code scanned does not match a valid reservation. Please try again."
        case .expired:
            return "This QR code has expired. Ask your provider to generate a new one."
        case .wrongContext:
            return "This QR code belongs to a different reservation. Please scan the correct code."
        case .alreadyCompleted:
            return "This reservation has already been completed."
        case .fallback:
            return "We couldn't process your scan. Please ask the provider to complete manually."
        }
    }

    private var primaryActionTitle: String {
        switch state {
        case .success: return "View Reservation"
        case .alreadyCompleted: return "View Reservation"
        case .invalid, .expired, .wrongContext: return "Try Again"
        case .fallback: return "Go Back"
        }
    }

    private var showSecondaryAction: Bool {
        switch state {
        case .success, .alreadyCompleted: return true
        case .fallback: return true
        default: return false
        }
    }

    private var secondaryActionTitle: String {
        switch state {
        case .success, .alreadyCompleted: return "Back to Home"
        case .fallback: return "Back to Home"
        default: return ""
        }
    }

    // MARK: - Actions

    private func handlePrimaryAction() {
        switch state {
        case .success, .alreadyCompleted:
            appState.router.push(.reservationDetail(id: reservationId), forRole: .ucr)
        case .invalid, .expired, .wrongContext:
            dismiss()
        case .fallback:
            dismiss()
        }
    }

    private func handleSecondaryAction() {
        appState.router.popToRoot(forRole: .ucr)
    }
}
