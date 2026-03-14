// UserModels.swift
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import Foundation

// MARK: - User Role

enum UserRole: String, Codable, Sendable, CaseIterable {
    case ucr = "UCR"
    case uso = "USO"

    var displayName: String {
        switch self {
        case .ucr: return "Customer"
        case .uso: return "Service Provider"
        }
    }
}

// MARK: - User

struct User: Decodable, Sendable, Identifiable {
    let id: String
    let phone: String?
    let fullName: String?
    let email: String?
    let emailVerified: Bool?
    let roles: [UserRole]?
    let activeRole: UserRole?
    let penaltyPoints: Int?
    let suspended: Bool?
    let suspendedUntil: String?
    let closedAt: String?
    let createdAt: String?

    var isNewUser: Bool {
        fullName == nil || fullName?.isEmpty == true
    }

    var displayName: String {
        fullName ?? phone ?? "User"
    }

    var isUSOActive: Bool {
        roles?.contains(.uso) == true
    }
}

// MARK: - Notification Settings

struct NotificationSettings: Decodable, Sendable {
    let reminderEnabled: Bool?
    let reminderMinutesBefore: Int?
}
