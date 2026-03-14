import Foundation

enum APIEndpoints {
    // Auth
    static let requestPhoneOTP = "/auth/request-phone-otp"
    static let verifyPhoneOTP = "/auth/verify-phone-otp"
    static let requestEmailMagicLink = "/auth/request-email-magic-link"
    static let verifyEmailMagicLink = "/auth/verify-email-magic-link"
    static let refresh = "/auth/refresh"
    static let logout = "/auth/logout"
    static let authMe = "/auth/me"

    // Users
    static let usersMe = "/users/me"
    static let activateUSO = "/users/me/activate-uso"
    static let userRoles = "/users/me/roles"
    static let switchRole = "/users/me/switch-role"
    static let notificationSettings = "/users/me/notification-settings"

    // Brands
    static let brands = "/brands"
    static func brand(_ id: String) -> String { "/brands/\(id)" }
    static func brandLogo(_ id: String) -> String { "/brands/\(id)/logo" }
    static func brandJoinRequests(_ id: String) -> String { "/brands/\(id)/join-requests" }
    static func brandJoinRequestAction(_ brandId: String, _ requestId: String, _ action: String) -> String {
        "/brands/\(brandId)/join-requests/\(requestId)/\(action)"
    }
    static func brandTransferOwnership(_ id: String) -> String { "/brands/\(id)/transfer-ownership" }
    static func brandMembers(_ id: String) -> String { "/brands/\(id)/members" }

    // Services
    static let services = "/services"
    static let servicesNearby = "/services/nearby"
    static func service(_ id: String) -> String { "/services/\(id)" }
    static func serviceAvailabilityRules(_ id: String) -> String { "/services/\(id)/availability-rules" }
    static func serviceAvailabilityExceptions(_ id: String) -> String { "/services/\(id)/availability-exceptions" }
    static func serviceManualBlocks(_ id: String) -> String { "/services/\(id)/manual-blocks" }
    static func serviceAvailability(_ id: String) -> String { "/services/\(id)/availability" }
    static func servicePhotos(_ id: String) -> String { "/services/\(id)/photos" }
    static func servicePhoto(_ serviceId: String, _ photoId: String) -> String { "/services/\(serviceId)/photos/\(photoId)" }

    // Categories
    static let categories = "/categories"

    // Reservations
    static let reservations = "/reservations"
    static let myReservations = "/reservations/my"
    static let incomingReservations = "/reservations/incoming"
    static func reservation(_ id: String) -> String { "/reservations/\(id)" }
    static func reservationAccept(_ id: String) -> String { "/reservations/\(id)/accept" }
    static func reservationReject(_ id: String) -> String { "/reservations/\(id)/reject" }
    static func reservationCancelByCustomer(_ id: String) -> String { "/reservations/\(id)/cancel-by-customer" }
    static func reservationCancelByOwner(_ id: String) -> String { "/reservations/\(id)/cancel-by-owner" }
    static func reservationChangeRequests(_ id: String) -> String { "/reservations/\(id)/change-requests" }
    static func changeRequestAccept(_ id: String) -> String { "/reservations/change-requests/\(id)/accept" }
    static func changeRequestReject(_ id: String) -> String { "/reservations/change-requests/\(id)/reject" }
    static func reservationDelayStatus(_ id: String) -> String { "/reservations/\(id)/delay-status" }
    static func reservationCompleteManually(_ id: String) -> String { "/reservations/\(id)/complete-manually" }
    static func reservationCompleteByQR(_ id: String) -> String { "/reservations/\(id)/complete-by-qr" }
    static func reservationObjections(_ id: String) -> String { "/reservations/\(id)/objections" }

    // Reviews
    static let reviews = "/reviews"
    static func review(_ id: String) -> String { "/reviews/\(id)" }
    static func reviewReplies(_ id: String) -> String { "/reviews/\(id)/replies" }
    static func reviewReport(_ id: String) -> String { "/reviews/\(id)/report" }

    // Notifications
    static let notifications = "/notifications"
    static func notificationRead(_ id: String) -> String { "/notifications/\(id)/read" }
    static let notificationsReadAll = "/notifications/read-all"
    static let notificationsUnreadCount = "/notifications/unread-count"

    // Push tokens
    static let pushTokens = "/push-tokens"

    // Reports
    static let reports = "/reports"

    // Penalties
    static let penaltiesMe = "/penalties/me"

    // Search
    static let search = "/search"
    static let serviceOwners = "/service-owners"

    // Locations
    static let locationSearch = "/locations/search"
    static let locationReverse = "/locations/reverse"

    // Health
    static let health = "/health"
}
