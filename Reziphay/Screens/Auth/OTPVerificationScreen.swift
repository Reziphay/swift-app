import SwiftUI

struct OTPVerificationScreen: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let phone: String
    let purpose: OtpPurpose
    var fullName: String? = nil
    var email: String? = nil

    @State private var code = ""
    @State private var isVerifying = false
    @State private var isResending = false
    @State private var errorMessage: String? = nil
    @State private var secondsRemaining: Int = 60
    @State private var canResend = false
    @State private var timer: Timer? = nil

    var body: some View {
        ZStack {
            Color.rzBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                RZTopBar(title: "Verification") {
                    RZIconButton(icon: "chevron.left") {
                        dismiss()
                    }
                }

                ScrollView {
                    VStack(spacing: RZSpacing.lg) {
                        // Header
                        VStack(spacing: RZSpacing.xxs) {
                            Text("Enter the code")
                                .font(.rzH2)
                                .foregroundStyle(.rzTextPrimary)

                            Text("We sent a 6-digit code to")
                                .font(.rzBody)
                                .foregroundStyle(.rzTextSecondary)

                            Text(maskedPhone)
                                .font(.rzBodyLarge)
                                .fontWeight(.semibold)
                                .foregroundStyle(.rzTextPrimary)
                        }
                        .multilineTextAlignment(.center)
                        .padding(.top, RZSpacing.md)

                        // OTP field
                        RZOTPField(code: $code, length: 6, error: errorMessage)
                            .onChange(of: code) { _, newValue in
                                if errorMessage != nil { errorMessage = nil }
                                if newValue.count == 6 {
                                    handleVerify()
                                }
                            }

                        // Verify button
                        RZButton(
                            title: "Verify",
                            variant: .primary,
                            size: .large,
                            isFullWidth: true,
                            isLoading: isVerifying,
                            isDisabled: code.count < 6
                        ) {
                            handleVerify()
                        }

                        // Resend / countdown
                        if canResend {
                            RZButton(
                                title: "Resend Code",
                                variant: .ghost,
                                size: .medium,
                                isFullWidth: false,
                                isLoading: isResending
                            ) {
                                handleResend()
                            }
                        } else {
                            Text("Resend code in \(secondsRemaining)s")
                                .font(.rzBody)
                                .foregroundStyle(.rzTextTertiary)
                        }
                    }
                    .padding(.horizontal, RZSpacing.screenHorizontal)
                    .padding(.bottom, RZSpacing.xxl)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            startCountdown()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    // MARK: - Computed

    private var maskedPhone: String {
        let digits = phone.filter { $0.isNumber }
        guard digits.count >= 4 else { return phone }
        let last2 = String(digits.suffix(2))
        let first = String(digits.prefix(min(4, digits.count - 4)))
        return "+\(first) XXXX•••••\(last2)"
    }

    // MARK: - Actions

    private func handleVerify() {
        guard code.count == 6, !isVerifying else { return }
        isVerifying = true
        errorMessage = nil
        Task {
            defer { isVerifying = false }
            do {
                try await appState.authManager.verifyOTP(
                    phone: phone,
                    code: code,
                    purpose: purpose,
                    fullName: fullName,
                    email: email
                )
                await appState.handleLogin()
            } catch let apiError as APIError {
                errorMessage = apiErrorMessage(for: apiError)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func handleResend() {
        isResending = true
        Task {
            defer { isResending = false }
            do {
                try await appState.authManager.requestOTP(
                    phone: phone,
                    purpose: purpose,
                    fullName: fullName,
                    email: email
                )
                code = ""
                errorMessage = nil
                canResend = false
                secondsRemaining = 60
                startCountdown()
                appState.showToast("Code sent.", type: .success)
            } catch {
                appState.showToast(error.localizedDescription, type: .error)
            }
        }
    }

    private func startCountdown() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { t in
            if secondsRemaining > 0 {
                secondsRemaining -= 1
            } else {
                canResend = true
                t.invalidate()
            }
        }
    }

    private func apiErrorMessage(for error: APIError) -> String {
        switch error {
        case .serverError(let code, let message):
            switch code {
            case "INVALID_OTP", "INVALID_CODE":
                return "Invalid code. Please try again."
            case "OTP_EXPIRED", "CODE_EXPIRED":
                return "The code has expired. Please request a new one."
            case "TOO_MANY_ATTEMPTS", "RATE_LIMITED":
                return "Too many attempts. Please wait and try again."
            default:
                return message
            }
        case .unauthorized:
            return "Invalid code. Please try again."
        default:
            return error.localizedDescription
        }
    }
}
