import SwiftUI

struct RegisterScreen: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var fullName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var isLoading = false

    @State private var fullNameError: String? = nil
    @State private var emailError: String? = nil
    @State private var phoneError: String? = nil

    @State private var navigateToOTP = false

    var body: some View {
        ZStack {
            Color.rzBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                RZTopBar(title: "Create Account") {
                    RZIconButton(icon: "chevron.left") {
                        dismiss()
                    }
                }

                ScrollView {
                    VStack(spacing: RZSpacing.lg) {
                        // Header
                        VStack(alignment: .leading, spacing: RZSpacing.xxs) {
                            Text("Welcome to Reziphay")
                                .font(.rzH2)
                                .foregroundStyle(.rzTextPrimary)
                            Text("Enter your details to get started.")
                                .font(.rzBody)
                                .foregroundStyle(.rzTextSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, RZSpacing.md)

                        // Fields
                        VStack(spacing: RZSpacing.sm) {
                            RZTextField(
                                label: "Full Name",
                                text: $fullName,
                                placeholder: "John Doe",
                                error: fullNameError
                            )

                            RZTextField(
                                label: "Email (optional)",
                                text: $email,
                                placeholder: "john@example.com",
                                keyboardType: .emailAddress,
                                autocapitalization: .never,
                                error: emailError
                            )

                            RZPhoneField(
                                label: "Phone Number",
                                phone: $phone,
                                error: phoneError
                            )
                        }

                        // Continue button
                        RZButton(
                            title: "Continue",
                            variant: .primary,
                            size: .large,
                            isFullWidth: true,
                            isLoading: isLoading
                        ) {
                            handleContinue()
                        }
                        .padding(.top, RZSpacing.xxs)

                        // Sign in link
                        Button {
                            dismiss()
                        } label: {
                            Text("Already have an account? ")
                                .font(.rzBody)
                                .foregroundStyle(.rzTextSecondary)
                            + Text("Sign in")
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
            OTPVerificationScreen(
                phone: phone,
                purpose: .register,
                fullName: fullName.isEmpty ? nil : fullName,
                email: email.isEmpty ? nil : email
            )
        }
    }

    private func handleContinue() {
        clearErrors()
        guard validate() else { return }

        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                try await appState.authManager.requestOTP(
                    phone: phone,
                    purpose: .register,
                    fullName: fullName.isEmpty ? nil : fullName,
                    email: email.isEmpty ? nil : email
                )
                navigateToOTP = true
            } catch {
                appState.showToast(error.localizedDescription, type: .error)
            }
        }
    }

    private func validate() -> Bool {
        var valid = true
        if fullName.trimmingCharacters(in: .whitespaces).isEmpty {
            fullNameError = "Full name is required."
            valid = false
        }
        let trimmedPhone = phone.trimmingCharacters(in: .whitespaces)
        if trimmedPhone.isEmpty {
            phoneError = "Phone number is required."
            valid = false
        } else if trimmedPhone.count < 7 {
            phoneError = "Enter a valid phone number."
            valid = false
        }
        if !email.isEmpty {
            let emailRegex = #"^[A-Z0-9a-z._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
            if email.range(of: emailRegex, options: .regularExpression) == nil {
                emailError = "Enter a valid email address."
                valid = false
            }
        }
        return valid
    }

    private func clearErrors() {
        fullNameError = nil
        emailError = nil
        phoneError = nil
    }
}
