// AuthModels.swift
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import Foundation

// MARK: - Tokens

struct AuthTokens: Decodable, Sendable {
    let accessToken: String
    let refreshToken: String
}

// MARK: - OTP

struct OTPRequestResponse: Decodable, Sendable {
    let message: String?
}

struct OTPVerifyResponse: Decodable, Sendable {
    let accessToken: String
    let refreshToken: String
    let user: User
    let isNewUser: Bool?
}

// MARK: - Magic Link

struct MagicLinkResponse: Decodable, Sendable {
    let message: String?
}
