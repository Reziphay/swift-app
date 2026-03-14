// RegisterView.swift
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import SwiftUI

struct RegisterView: View {
    let phone: String

    @Environment(AppState.self) private var appState
    @State private var fullName = ""
    @State private var email = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?

    private enum Field { case name, email }

    var body: some View {
        ZStack {
            Color.reziphayBackground.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                headerSection
                    .padding(.top, 16)
                    .padding(.horizontal, 24)

                Spacer()

                formSection
                    .padding(.horizontal, 24)

                Spacer()

                bottomSection
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .onAppear { focusedField = .name }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "person.text.rectangle")
                .font(.system(size: 36))
                .foregroundStyle(Color.reziphayPrimary)
                .padding(.bottom, 8)

            Text("Create your profile")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.primary)

            Text("Tell us a bit about yourself to get started")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Form

    private var formSection: some View {
        VStack(spacing: 20) {
            FormField(
                label: "Full Name",
                placeholder: "Enter your full name",
                text: $fullName,
                keyboardType: .default,
                isFocused: focusedField == .name
            )
            .focused($focusedField, equals: .name)
            .submitLabel(.next)
            .onSubmit { focusedField = .email }

            VStack(alignment: .leading, spacing: 8) {
                FormField(
                    label: "Email Address",
                    placeholder: "Enter your email (optional)",
                    text: $email,
                    keyboardType: .emailAddress,
                    isFocused: focusedField == .email
                )
                .focused($focusedField, equals: .email)
                .submitLabel(.done)
                .onSubmit { focusedField = nil }

                Text("We'll send a verification link to confirm your email")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }

            if let error = errorMessage {
                Label(error, systemImage: "exclamationmark.circle.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Bottom

    private var bottomSection: some View {
        Button {
            Task { await register() }
        } label: {
            ZStack {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text("Get Started")
                }
            }
        }
        .primaryButtonStyle()
        .disabled(fullName.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
        .opacity(fullName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1.0)
    }

    // MARK: - Actions

    private func register() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        let trimmedName = fullName.trimmingCharacters(in: .whitespaces)
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)

        do {
            let user = try await AuthService.shared.completeRegistration(
                fullName: trimmedName,
                email: trimmedEmail.isEmpty ? nil : trimmedEmail
            )

            if !trimmedEmail.isEmpty {
                try? await AuthService.shared.requestMagicLink(email: trimmedEmail)
            }

            appState.onRegistrationComplete(user: user)
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Registration failed. Please try again."
        }
    }
}

// MARK: - Form Field

struct FormField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    let keyboardType: UIKeyboardType
    let isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)

            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .autocorrectionDisabled()
                .textInputAutocapitalization(keyboardType == .emailAddress ? .never : .words)
                .font(.system(size: 17))
                .padding(.horizontal, 16)
                .frame(height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.reziphaySecondaryBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isFocused ? Color.reziphayPrimary : Color.clear, lineWidth: 1.5)
                        )
                )
        }
    }
}
