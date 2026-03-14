// PhoneEntryView.swift
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import SwiftUI

struct PhoneEntryView: View {
    let role: UserRole

    @State private var phone = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var navigateToOTP = false
    @FocusState private var isPhoneFocused: Bool

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

                Spacer()

                bottomSection
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
            }
        }
        .navigationBarBackButtonHidden(false)
        .navigationTitle("")
        .onAppear { isPhoneFocused = true }
        .navigationDestination(isPresented: $navigateToOTP) {
            OTPView(phone: formattedPhone)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: role == .ucr ? "person.crop.circle" : "briefcase.circle")
                .font(.system(size: 36))
                .foregroundStyle(Color.reziphayPrimary)
                .padding(.bottom, 8)

            Text("Enter your phone number")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.primary)

            Text("We'll send you a one-time code to verify your identity")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Input

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Phone Number")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Text("+1")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 14)
                    .frame(height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.reziphaySecondaryBackground)
                    )

                TextField("(555) 000-0000", text: $phone)
                    .keyboardType(.phonePad)
                    .font(.system(size: 17))
                    .focused($isPhoneFocused)
                    .padding(.horizontal, 16)
                    .frame(height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.reziphaySecondaryBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isPhoneFocused ? Color.reziphayPrimary : Color.clear, lineWidth: 1.5)
                            )
                    )
                    .onChange(of: phone) { _, newValue in
                        phone = String(newValue.filter { $0.isNumber }.prefix(15))
                    }
            }

            if let error = errorMessage {
                Label(error, systemImage: "exclamationmark.circle.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.red)
            }
        }
    }

    // MARK: - Bottom

    private var bottomSection: some View {
        VStack(spacing: 16) {
            Button {
                Task { await requestOTP() }
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
            .disabled(phone.count < 7 || isLoading)
            .opacity(phone.count < 7 ? 0.5 : 1.0)

            Text("By continuing, you agree to our Terms of Service and Privacy Policy")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Computed

    private var formattedPhone: String {
        "+1\(phone)"
    }

    // MARK: - Actions

    private func requestOTP() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            try await AuthService.shared.requestOTP(phone: formattedPhone)
            navigateToOTP = true
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Something went wrong. Please try again."
        }
    }
}
