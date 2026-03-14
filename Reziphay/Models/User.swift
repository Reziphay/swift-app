import Foundation

struct User: Codable, Identifiable, Hashable {
    let id: String
    let fullName: String
    let email: String?
    let phone: String
    let emailVerifiedAt: String?
    let phoneVerifiedAt: String?
    let status: UserStatus
    let suspendedUntil: String?
    let closedReason: String?
    let roles: [UserRole]?
    let activeRole: AppRole?
    let createdAt: String
    let updatedAt: String

    var isEmailVerified: Bool { emailVerifiedAt != nil }
    var isPhoneVerified: Bool { phoneVerifiedAt != nil }
}

struct UserRole: Codable, Hashable {
    let id: String
    let role: AppRole
}

struct AuthTokens: Codable {
    let accessToken: String
    let refreshToken: String
}

struct AuthResponse: Codable {
    let user: User
    let accessToken: String
    let refreshToken: String
}

struct RatingStats: Codable, Hashable {
    let avgRating: Double
    let reviewCount: Int
}

struct PopularityStats: Codable, Hashable {
    let popularityScore: Int
}
