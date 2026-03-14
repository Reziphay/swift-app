// PhoneEntryView.swift
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import SwiftUI

struct PhoneEntryView: View {
    let role: UserRole

    @State private var phone         = ""
    @State private var isLoading     = false
    @State private var errorMessage: String?

    // Registration fields (shown when phone not found)
    @State private var isNewUser     = false
    @State private var fullName      = ""
    @State private var email         = ""

    // Navigation
    @State private var navigateToOTP  = false
    @State private var resolvedPurpose: OTPPurpose = .login

    @FocusState private var focusedField: Field?

    private enum Field { case phone, fullName, email }

    var body: some View {
        ZStack {
            Color.reziphayBackground.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                headerSection
                    .padding(.top, 16)
                    .padding(.horizontal, 24)

                Spacer()

                inputSection
                    .padding(.horizontal, 24)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isNewUser)

                Spacer()

                bottomSection
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
            }
        }
        .navigationBarBackButtonHidden(false)
        .navigationTitle("")
        .onAppear { focusedField = .phone }
        .navigationDestination(isPresented: $navigateToOTP) {
            OTPView(phone: formattedPhone, purpose: resolvedPurpose)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: role == .ucr ? "person.crop.circle" : "briefcase.circle")
                .font(.system(size: 36))
                .foregroundStyle(Color.reziphayPrimary)
                .padding(.bottom, 8)

            Text(isNewUser ? "Create your account" : "Enter your phone number")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.primary)
                .animation(.none, value: isNewUser)

            Text(isNewUser
                 ? "Fill in your details to get started"
                 : "We'll send you a one-time code to verify your identity")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .animation(.none, value: isNewUser)
        }
    }

    // MARK: - Input

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Phone row
            VStack(alignment: .leading, spacing: 12) {
                Text("Phone Number")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    Text("+994")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 14)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.reziphaySecondaryBackground)
                        )

                    TextField("XX 123 45 67", text: $phone)
                        .keyboardType(.phonePad)
                        .font(.system(size: 17))
                        .focused($focusedField, equals: .phone)
                        .disabled(isNewUser)   // locked once we proceed to registration
                        .padding(.horizontal, 16)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.reziphaySecondaryBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            focusedField == .phone ? Color.reziphayPrimary : Color.clear,
                                            lineWidth: 1.5
                                        )
                                )
                        )
                        .onChange(of: phone) { _, newValue in
                            phone = String(newValue.filter { $0.isNumber }.prefix(9))
                        }
                }
            }

            // Registration extra fields — slide in when isNewUser
            if isNewUser {
                VStack(alignment: .leading, spacing: 16) {
                    inputField(
                        label: "Full Name",
                        placeholder: "Your full name",
                        text: $fullName,
                        field: .fullName,
                        keyboard: .default
                    )

                    inputField(
                        label: "Email",
                        placeholder: "your@email.com",
                        text: $email,
                        field: .email,
                        keyboard: .emailAddress
                    )
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if let error = errorMessage {
                Label(error, systemImage: "exclamationmark.circle.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.red)
            }
        }
    }

    @ViewBuilder
    private func inputField(
        label: String,
        placeholder: String,
        text: Binding<String>,
        field: Field,
        keyboard: UIKeyboardType
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)

            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .autocorrectionDisabled()
                .textInputAutocapitalization(field == .email ? .never : .words)
                .font(.system(size: 17))
                .focused($focusedField, equals: field)
                .padding(.horizontal, 16)
                .frame(height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.reziphaySecondaryBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    focusedField == field ? Color.reziphayPrimary : Color.clear,
                                    lineWidth: 1.5
                                )
                        )
                )
        }
    }

    // MARK: - Bottom

    private var bottomSection: some View {
        VStack(spacing: 16) {
            Button {
                Task { await handleSendCode() }
            } label: {
                ZStack {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Send Code")
                    }
                }
            }
            .primaryButtonStyle()
            .disabled(!canProceed || isLoading)
            .opacity(!canProceed ? 0.5 : 1.0)

            if isNewUser {
                Button {
                    withAnimation { isNewUser = false; errorMessage = nil }
                } label: {
                    Text("Use a different number")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.reziphayPrimary)
                }
            } else {
                Text("By continuing, you agree to our Terms of Service and Privacy Policy")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Helpers

    private var formattedPhone: String { "+994\(phone)" }

    private var canProceed: Bool {
        guard phone.count == 9 else { return false }
        if isNewUser {
            return fullName.count >= 2 && email.contains("@")
        }
        return true
    }

    // MARK: - Actions

    private func handleSendCode() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            if isNewUser {
                // REGISTER flow — user already filled name + email
                try await AuthService.shared.requestOTP(
                    phone: formattedPhone,
                    purpose: .register,
                    fullName: fullName.trimmingCharacters(in: .whitespaces),
                    email: email.trimmingCharacters(in: .whitespaces).lowercased()
                )
                resolvedPurpose = .register
                navigateToOTP   = true
            } else {
                // Try LOGIN first
                try await AuthService.shared.requestOTP(phone: formattedPhone, purpose: .login)
                resolvedPurpose = .login
                navigateToOTP   = true
            }
        } catch NetworkError.unauthorized {
            // "No account exists for this phone number" — switch to register mode
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                isNewUser = true
                focusedField = .fullName
            }
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Something went wrong. Please try again."
        }
    }
}
