import Foundation
import Security

final class KeychainService: @unchecked Sendable {
    static let shared = KeychainService()

    private let service = "com.reziphay.app"
    private enum Keys {
        static let accessToken = "accessToken"
        static let refreshToken = "refreshToken"
        static let activeRole = "activeRole"
    }

    func getAccessToken() -> String? { read(key: Keys.accessToken) }
    func setAccessToken(_ token: String) { write(key: Keys.accessToken, value: token) }

    func getRefreshToken() -> String? { read(key: Keys.refreshToken) }
    func setRefreshToken(_ token: String) { write(key: Keys.refreshToken, value: token) }

    func getActiveRole() -> AppRole? {
        guard let raw = read(key: Keys.activeRole) else { return nil }
        return AppRole(rawValue: raw)
    }
    func setActiveRole(_ role: AppRole) { write(key: Keys.activeRole, value: role.rawValue) }

    func storeTokens(access: String, refresh: String) {
        setAccessToken(access)
        setRefreshToken(refresh)
    }

    func clearTokens() {
        delete(key: Keys.accessToken)
        delete(key: Keys.refreshToken)
        delete(key: Keys.activeRole)
    }

    var hasTokens: Bool { getAccessToken() != nil }

    // MARK: - Keychain operations

    private func write(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        delete(key: key)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    private func read(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
