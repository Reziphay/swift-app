// KeychainStore.swift
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import Foundation
import Security

actor KeychainStore {
    static let shared = KeychainStore()

    private let accessTokenKey = "com.reziphay.app.accessToken"
    private let refreshTokenKey = "com.reziphay.app.refreshToken"
    private let service = "com.reziphay.app"

    private init() {}

    // MARK: - Read

    var accessToken: String? {
        read(key: accessTokenKey)
    }

    var refreshToken: String? {
        read(key: refreshTokenKey)
    }

    // MARK: - Write

    func save(accessToken: String, refreshToken: String) {
        write(value: accessToken, forKey: accessTokenKey)
        write(value: refreshToken, forKey: refreshTokenKey)
    }

    func clearTokens() {
        delete(key: accessTokenKey)
        delete(key: refreshTokenKey)
    }

    // MARK: - Private

    private func read(key: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func write(value: String, forKey key: String) {
        guard let data = value.data(using: .utf8) else { return }

        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]

        let updateAttributes: [CFString: Any] = [kSecValueData: data]

        let status = SecItemUpdate(query as CFDictionary, updateAttributes as CFDictionary)

        if status == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData] = data
            addQuery[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlock
            SecItemAdd(addQuery as CFDictionary, nil)
        }
    }

    private func delete(key: String) {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
