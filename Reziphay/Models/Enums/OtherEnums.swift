import Foundation

enum BrandStatus: String, Codable {
    case active = "ACTIVE"
    case flagged = "FLAGGED"
    case closed = "CLOSED"
}

enum BrandMembershipRole: String, Codable {
    case owner = "OWNER"
    case member = "MEMBER"
}

enum BrandJoinRequestStatus: String, Codable {
    case pending = "PENDING"
    case accepted = "ACCEPTED"
    case rejected = "REJECTED"
    case cancelled = "CANCELLED"
}

enum ReservationChangeRequestStatus: String, Codable {
    case pending = "PENDING"
    case accepted = "ACCEPTED"
    case rejected = "REJECTED"
    case cancelled = "CANCELLED"
}

enum ReservationCompletionMethod: String, Codable {
    case qr = "QR"
    case manual = "MANUAL"
}

enum ReservationDelayStatus: String, Codable {
    case none = "NONE"
    case runningLate = "RUNNING_LATE"
    case arrived = "ARRIVED"
}

enum ReservationActorType: String, Codable {
    case system = "SYSTEM"
    case customer = "CUSTOMER"
    case owner = "OWNER"
    case admin = "ADMIN"
}

enum PenaltyReason: String, Codable {
    case noShow = "NO_SHOW"
}

enum PenaltyActionType: String, Codable {
    case suspend1Month = "SUSPEND_1_MONTH"
    case closeIndefinitely = "CLOSE_INDEFINITELY"
}

enum ReservationObjectionType: String, Codable {
    case noShowDispute = "NO_SHOW_DISPUTE"
    case other = "OTHER"
}

enum ReservationObjectionStatus: String, Codable {
    case pending = "PENDING"
    case accepted = "ACCEPTED"
    case rejected = "REJECTED"
}

enum ReviewTargetType: String, Codable {
    case service = "SERVICE"
    case serviceOwner = "SERVICE_OWNER"
    case brand = "BRAND"
}

enum ReportTargetType: String, Codable {
    case user = "USER"
    case brand = "BRAND"
    case service = "SERVICE"
    case review = "REVIEW"
}

enum ReportStatus: String, Codable {
    case open = "OPEN"
    case underReview = "UNDER_REVIEW"
    case resolved = "RESOLVED"
    case dismissed = "DISMISSED"
}

enum PushPlatform: String, Codable {
    case ios = "IOS"
    case android = "ANDROID"
    case web = "WEB"
}

enum OtpPurpose: String, Codable {
    case register = "REGISTER"
    case login = "LOGIN"
    case verifyPhone = "VERIFY_PHONE"
    case changePhone = "CHANGE_PHONE"
}

enum SearchSortMode: String, Codable, CaseIterable {
    case relevance = "RELEVANCE"
    case proximity = "PROXIMITY"
    case rating = "RATING"
    case priceLow = "PRICE_LOW"
    case priceHigh = "PRICE_HIGH"
    case popularity = "POPULARITY"
    case availability = "AVAILABILITY"

    var displayName: String {
        switch self {
        case .relevance: "Relevance"
        case .proximity: "Nearest"
        case .rating: "Highest Rated"
        case .priceLow: "Price: Low to High"
        case .priceHigh: "Price: High to Low"
        case .popularity: "Most Popular"
        case .availability: "Available First"
        }
    }
}
