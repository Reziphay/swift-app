import Foundation

enum Route: Hashable {
    // Discovery
    case serviceDetail(id: String)
    case brandDetail(id: String)
    case providerDetail(id: String)
    case categoryListing(id: String, name: String)
    case nearbyMap

    // Reservations
    case createReservation(serviceId: String)
    case reservationDetail(id: String)
    case reservationSuccess(id: String, isAutoConfirmed: Bool)

    // QR
    case qrScan(reservationId: String)
    case providerQR

    // Reviews
    case createReview(reservationId: String)

    // Brands
    case createBrand
    case editBrand(id: String)
    case brandManage(id: String)
    case brandJoinRequests(id: String)

    // Services
    case createService
    case editService(id: String)

    // Profile & Settings
    case settings
    case penaltySummary

    // Search
    case searchResults(query: String?)
}
