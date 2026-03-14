import Foundation

@Observable
final class AuthManager {
    var currentUser: User?
    var isAuthenticated: Bool = false
    var isLoading: Bool = false

    private let apiClient: APIClient
    private let keychain: KeychainService

    init(apiClient: APIClient, keychain: KeychainService = .shared) {
        self.apiClient = apiClient
        self.keychain = keychain
    }

    // MARK: - Session restore

    func restoreSession() async {
        guard keychain.hasTokens else {
            isAuthenticated = false
            return
        }
        do {
            let user: User = try await apiClient.get(APIEndpoints.authMe)
            currentUser = user
            isAuthenticated = true
        } catch {
            keychain.clearTokens()
            isAuthenticated = false
        }
    }

    // MARK: - OTP flow

    func requestOTP(phone: String, purpose: OtpPurpose, fullName: String? = nil, email: String? = nil) async throws {
        var body: [String: String] = [
            "phone": phone,
            "purpose": purpose.rawValue
        ]
        if let fullName { body["fullName"] = fullName }
        if let email { body["email"] = email }
        try await apiClient.postVoid(APIEndpoints.requestPhoneOTP, body: body)
    }

    func verifyOTP(phone: String, code: String, purpose: OtpPurpose, fullName: String? = nil, email: String? = nil) async throws {
        var body: [String: String] = [
            "phone": phone,
            "code": code,
            "purpose": purpose.rawValue
        ]
        if let fullName { body["fullName"] = fullName }
        if let email { body["email"] = email }
        let response: AuthResponse = try await apiClient.post(APIEndpoints.verifyPhoneOTP, body: body)
        keychain.storeTokens(access: response.accessToken, refresh: response.refreshToken)
        currentUser = response.user
        if let role = response.user.activeRole ?? response.user.roles?.first?.role {
            keychain.setActiveRole(role)
        }
        isAuthenticated = true
    }

    // MARK: - Email magic link

    func requestEmailMagicLink(email: String? = nil) async throws {
        let body: [String: String] = email != nil ? ["email": email!] : [:]
        try await apiClient.postVoid(APIEndpoints.requestEmailMagicLink, body: body)
    }

    func verifyEmailMagicLink(token: String) async throws {
        let body = ["token": token]
        let response: AuthResponse = try await apiClient.post(APIEndpoints.verifyEmailMagicLink, body: body)
        keychain.storeTokens(access: response.accessToken, refresh: response.refreshToken)
        currentUser = response.user
        isAuthenticated = true
    }

    // MARK: - Role management

    func activateUSO() async throws {
        let user: User = try await apiClient.post(APIEndpoints.activateUSO)
        currentUser = user
    }

    func switchRole(to role: AppRole) async throws {
        let body = ["role": role.rawValue]
        let response: AuthResponse = try await apiClient.post(APIEndpoints.switchRole, body: body)
        keychain.storeTokens(access: response.accessToken, refresh: response.refreshToken)
        keychain.setActiveRole(role)
        currentUser = response.user
    }

    func fetchMe() async throws {
        let user: User = try await apiClient.get(APIEndpoints.usersMe)
        currentUser = user
    }

    // MARK: - Logout

    func logout() async {
        try? await apiClient.postVoid(APIEndpoints.logout)
        keychain.clearTokens()
        currentUser = nil
        isAuthenticated = false
    }

    var activeRole: AppRole {
        keychain.getActiveRole() ?? currentUser?.activeRole ?? .ucr
    }
}
