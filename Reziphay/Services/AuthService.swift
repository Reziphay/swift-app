// AuthService.swift
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import Foundation

struct AuthService {
    static let shared = AuthService()
    private init() {}

    private var client: APIClient { APIClient.shared }

    // MARK: - OTP

    func requestOTP(
        phone: String,
        purpose: OTPPurpose,
        fullName: String? = nil,
        email: String? = nil
    ) async throws {
        _ = try await client.request(
            .requestOTP(phone: phone, purpose: purpose, fullName: fullName, email: email),
            responseType: OTPRequestResponse.self
        )
    }

    func verifyOTP(phone: String, code: String, purpose: OTPPurpose) async throws -> OTPVerifyResponse {
        let response = try await client.request(
            .verifyOTP(phone: phone, code: code, purpose: purpose),
            responseType: OTPVerifyResponse.self
        )
        await KeychainStore.shared.save(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken
        )
        return response
    }

    // MARK: - Magic Link

    func requestMagicLink(email: String) async throws {
        _ = try await client.request(
            .requestMagicLink(email: email),
            responseType: MagicLinkResponse.self
        )
    }

    // MARK: - Session

    func logout() async throws {
        try? await client.requestEmpty(.logout)
        await KeychainStore.shared.clearTokens()
    }

    func getMe() async throws -> User {
        try await client.request(.me, responseType: User.self)
    }

    // MARK: - Registration

    func completeRegistration(fullName: String, email: String?) async throws -> User {
        try await client.request(
            .updateProfile(fullName: fullName, email: email),
            responseType: User.self
        )
    }

    // MARK: - Role Management

    func activateUSO() async throws -> User {
        try await client.request(.activateUSO, responseType: User.self)
    }

    func switchRole(to role: UserRole) async throws -> User {
        try await client.request(.switchRole(to: role), responseType: User.self)
    }

    // MARK: - Token Validation

    func validateSession() async -> User? {
        guard let _ = await KeychainStore.shared.accessToken else { return nil }
        return try? await getMe()
    }
}
