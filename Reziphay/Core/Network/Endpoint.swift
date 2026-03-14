// Endpoint.swift
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import Foundation

enum HTTPMethod: String, Sendable {
    case GET
    case POST
    case PUT
    case PATCH
    case DELETE
}

struct Endpoint: Sendable {
    let path: String
    let method: HTTPMethod
    let body: [String: String]?
    let queryItems: [URLQueryItem]?
    let requiresAuth: Bool

    init(
        path: String,
        method: HTTPMethod = .GET,
        body: [String: String]? = nil,
        queryItems: [URLQueryItem]? = nil,
        requiresAuth: Bool = true
    ) {
        self.path = path
        self.method = method
        self.body = body
        self.queryItems = queryItems
        self.requiresAuth = requiresAuth
    }
}

// MARK: - Auth Endpoints

extension Endpoint {
    static func requestOTP(phone: String) -> Endpoint {
        Endpoint(
            path: "/auth/otp/request",
            method: .POST,
            body: ["phone": phone],
            requiresAuth: false
        )
    }

    static func verifyOTP(phone: String, code: String) -> Endpoint {
        Endpoint(
            path: "/auth/otp/verify",
            method: .POST,
            body: ["phone": phone, "code": code],
            requiresAuth: false
        )
    }

    static func requestMagicLink(email: String) -> Endpoint {
        Endpoint(
            path: "/auth/magic-link/request",
            method: .POST,
            body: ["email": email],
            requiresAuth: true
        )
    }

    static func refreshToken(token: String) -> Endpoint {
        Endpoint(
            path: "/auth/refresh",
            method: .POST,
            body: ["refreshToken": token],
            requiresAuth: false
        )
    }

    static let logout = Endpoint(path: "/auth/logout", method: .POST)

    static let me = Endpoint(path: "/auth/me")
}

// MARK: - User Endpoints

extension Endpoint {
    static let userMe = Endpoint(path: "/users/me")

    static func updateProfile(fullName: String?, email: String?) -> Endpoint {
        var body: [String: String] = [:]
        if let fullName { body["fullName"] = fullName }
        if let email { body["email"] = email }
        return Endpoint(path: "/users/me", method: .PATCH, body: body)
    }

    static let activateUSO = Endpoint(path: "/users/activate-uso", method: .POST)

    static let getRoles = Endpoint(path: "/users/roles")

    static func switchRole(to role: UserRole) -> Endpoint {
        Endpoint(path: "/users/switch-role", method: .POST, body: ["role": role.rawValue])
    }
}
