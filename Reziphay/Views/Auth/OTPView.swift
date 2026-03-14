// OTPView.swift
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import SwiftUI

struct OTPView: View {
    let phone: String

    @Environment(AppState.self) private var appState
    @State private var otpDigits: [String] = Array(repeating: "", count: 6)
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var resendCooldown = 30
    @State private var canResend = false
    @State private var navigateToRegister = false
    @FocusState private var focusedIndex: Int?

    private var otpCode: String { otpDigits.joined() }
    private var isComplete: Bool { otpCode.count == 6 }

    var body: some View {
        ZStack {
            Color.reziphayBackground.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                headerSection
                    .padding(.top, 16)
                    .padding(.horizontal, 24)

                Spacer()

                otpInputSection
                    .padding(.horizontal, 24)

                Spacer()

                bottomSection
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
            }
        }
        .navigationBarBackButtonHidden(false)
        .navigationTitle("")
        .onAppear {
            focusedIndex = 0
            startResendTimer()
        }
        .navigationDestination(isPresented: $navigateToRegister) {
            RegisterView(phone: phone)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "message.badge.filled.fill")
                .font(.system(size: 36))
                .foregroundStyle(Color.reziphayPrimary)
                .padding(.bottom, 8)

            Text("Verify your number")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.primary)

            Text("Enter the 6-digit code sent to \(phone)")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - OTP Input

    private var otpInputSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 10) {
                ForEach(0..<6, id: \.self) { index in
                    OTPDigitField(
                        digit: $otpDigits[index],
                        isFocused: focusedIndex == index
                    )
                    .focused($focusedIndex, equals: index)
                    .onChange(of: otpDigits[index]) { _, newValue in
                        handleDigitChange(at: index, value: newValue)
                    }
                }
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
        VStack(spacing: 16) {
            Button {
                Task { await verifyOTP() }
            } label: {
                ZStack {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Verify")
                    }
                }
            }
            .primaryButtonStyle()
            .disabled(!isComplete || isLoading)
            .opacity(!isComplete ? 0.5 : 1.0)

            Button {
                Task { await resendOTP() }
            } label: {
                if canResend {
                    Text("Resend Code")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.reziphayPrimary)
                } else {
                    Text("Resend in \(resendCooldown)s")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }
            }
            .disabled(!canResend)
        }
    }

    // MARK: - Digit Handling

    private func handleDigitChange(at index: Int, value: String) {
        let filtered = value.filter { $0.isNumber }

        if filtered.count > 1 {
            // Handle paste: distribute digits
            let digits = Array(filtered.prefix(6 - index))
            for (offset, char) in digits.enumerated() {
                let targetIndex = index + offset
                if targetIndex < 6 {
                    otpDigits[targetIndex] = String(char)
                }
            }
            let nextIndex = min(index + digits.count, 5)
            focusedIndex = nextIndex
        } else if filtered.isEmpty && !value.isEmpty {
            // Backspace behavior
            otpDigits[index] = ""
            if index > 0 { focusedIndex = index - 1 }
        } else if filtered.count == 1 {
            otpDigits[index] = filtered
            if index < 5 { focusedIndex = index + 1 }
        } else {
            otpDigits[index] = ""
        }

        if isComplete {
            Task { await verifyOTP() }
        }
    }

    // MARK: - Timer

    private func startResendTimer() {
        resendCooldown = 30
        canResend = false
        Task {
            while resendCooldown > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await MainActor.run { resendCooldown -= 1 }
            }
            await MainActor.run { canResend = true }
        }
    }

    // MARK: - Actions

    private func verifyOTP() async {
        guard isComplete else { return }
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await AuthService.shared.verifyOTP(phone: phone, code: otpCode)
            if response.user.isNewUser {
                navigateToRegister = true
            } else {
                appState.onOTPVerified(response: response)
            }
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
            otpDigits = Array(repeating: "", count: 6)
            focusedIndex = 0
        } catch {
            errorMessage = "Invalid code. Please try again."
            otpDigits = Array(repeating: "", count: 6)
            focusedIndex = 0
        }
    }

    private func resendOTP() async {
        do {
            try await AuthService.shared.requestOTP(phone: phone)
            startResendTimer()
        } catch {
            errorMessage = "Failed to resend code. Please try again."
        }
    }
}

// MARK: - OTP Digit Field

private struct OTPDigitField: View {
    @Binding var digit: String
    let isFocused: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.reziphaySecondaryBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            isFocused ? Color.reziphayPrimary : Color.clear,
                            lineWidth: 2
                        )
                )
                .frame(height: 60)

            if digit.isEmpty {
                RoundedRectangle(cornerRadius: 3)
                    .fill(isFocused ? Color.reziphayPrimary : Color.secondary.opacity(0.3))
                    .frame(width: 20, height: 2)
                    .opacity(isFocused ? 1 : 0.5)
            } else {
                Text(digit)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.primary)
            }

            TextField("", text: $digit)
                .keyboardType(.numberPad)
                .frame(width: 1, height: 1)
                .opacity(0.001)
        }
    }
}
