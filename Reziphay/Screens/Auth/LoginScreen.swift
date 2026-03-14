import SwiftUI

struct LoginScreen: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var phone = ""
    @State private var phoneError: String? = nil
    @State private var isLoading = false
    @State private var navigateToOTP = false

    var body: some View {
        ZStack {
            Color.rzBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                RZTopBar(title: "Sign In") {
                    RZIconButton(icon: "chevron.left") {
                        dismiss()
                    }
                }

                ScrollView {
                    VStack(spacing: RZSpacing.lg) {
                        // Header
                        VStack(alignment: .leading, spacing: RZSpacing.xxs) {
                            Text("Welcome back")
                                .font(.rzH2)
                                .foregroundStyle(.rzTextPrimary)
                            Text("Enter your phone number and we'll send a verification code.")
                                .font(.rzBody)
                                .foregroundStyle(.rzTextSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, RZSpacing.md)

                        // Phone field
                        RZPhoneField(
                            label: "Phone Number",
                            phone: $phone,
                            error: phoneError
                        )

                        // Send Code button
                        RZButton(
                            title: "Send Code",
                            variant: .primary,
                            size: .large,
                            isFullWidth: true,
                            isLoading: isLoading
                        ) {
                            handleSendCode()
                        }
                        .padding(.top, RZSpacing.xxs)

                        // Register link
                        Button {
                            dismiss()
                        } label: {
                            Text("Don't have an account? ")
                                .font(.rzBody)
                                .foregroundStyle(.rzTextSecondary)
                            + Text("Register")
                                .font(.rzBody)
                                .foregroundStyle(.rzPrimary)
                        }
                        .padding(.top, RZSpacing.xxs)
                    }
                    .padding(.horizontal, RZSpacing.screenHorizontal)
                    .padding(.bottom, RZSpacing.xxl)
                }
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $navigateToOTP) {
            OTPVerificationScreen(phone: phone, purpose: .login)
        }
    }

    private func handleSendCode() {
        phoneError = nil
        let trimmed = phone.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            phoneError = "Phone number is required."
            return
        }
        guard trimmed.count >= 7 else {
            phoneError = "Enter a valid phone number."
            return
        }

        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                try await appState.authManager.requestOTP(phone: phone, purpose: .login)
                navigateToOTP = true
            } catch {
                appState.showToast(error.localizedDescription, type: .error)
            }
        }
    }
}
