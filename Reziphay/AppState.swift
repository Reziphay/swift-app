// AppState.swift
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import SwiftUI

// MARK: - Auth State

enum AuthState: Sendable {
    case loading
    case unauthenticated
    case needsRegistration(phone: String)
    case authenticated(user: User)
}

// MARK: - App State

@MainActor
@Observable
final class AppState {
    static let shared = AppState()

    var authState: AuthState = .loading
    var selectedRole: UserRole = .ucr

    private init() {}

    var isAuthenticated: Bool {
        if case .authenticated = authState { return true }
        return false
    }

    var currentUser: User? {
        if case .authenticated(let user) = authState { return user }
        return nil
    }

    // MARK: - Bootstrap

    func bootstrap() async {
        guard let user = await AuthService.shared.validateSession() else {
            authState = .unauthenticated
            return
        }
        authState = .authenticated(user: user)
    }

    // MARK: - Auth Actions

    func onOTPVerified(response: OTPVerifyResponse) {
        let user = response.user
        if user.isNewUser {
            authState = .needsRegistration(phone: user.phone ?? "")
        } else {
            authState = .authenticated(user: user)
        }
    }

    func onRegistrationComplete(user: User) {
        authState = .authenticated(user: user)
    }

    func onUserUpdated(user: User) {
        authState = .authenticated(user: user)
    }

    func signOut() async {
        try? await AuthService.shared.logout()
        authState = .unauthenticated
    }
}
