import Foundation

struct Reservation: Codable, Identifiable, Hashable {
    let id: String
    let serviceId: String
    let customerUserId: String
    let serviceOwnerUserId: String
    let brandId: String?
    let requestedStartAt: String
    let requestedEndAt: String?
    let status: ReservationStatus
    let approvalExpiresAt: Date?
    let customerNote: String?
    let rejectionReason: String?
    let cancellationReason: String?
    let freeCancellationEligibleAtCancellation: Bool?
    let delayStatus: ReservationDelayStatus?
    let estimatedArrivalMinutes: Int?
    let delayNote: String?
    let cancelledAt: String?
    let completedAt: String?
    let service: ServiceSummary?
    let customer: UserSummary?
    let owner: UserSummary?
    let brand: BrandSummary?
    let statusHistory: [ReservationStatusEvent]?
    let changeRequests: [ReservationChangeRequest]?
    let completionRecord: ReservationCompletionRecord?
    let delayHistory: [ReservationDelayUpdate]?
    let createdAt: String
    let updatedAt: String

    var serviceName: String? { service?.name }
    var brandName: String? { brand?.name }

    var formattedDateTime: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: requestedStartAt) else { return requestedStartAt }
        let display = DateFormatter()
        display.dateFormat = "MMM d, yyyy 'at' h:mm a"
        return display.string(from: date)
    }
}

struct ServiceSummary: Codable, Hashable {
    let id: String
    let name: String
    let serviceType: ServiceType?
    let approvalMode: ApprovalMode?
}

struct UserSummary: Codable, Hashable {
    let id: String
    let fullName: String
}

struct ReservationStatusEvent: Codable, Identifiable, Hashable {
    let id: String
    let fromStatus: ReservationStatus?
    let toStatus: ReservationStatus
    let reason: String?
    let actorType: ReservationActorType
    let createdAt: String
}

struct ReservationChangeRequest: Codable, Identifiable, Hashable {
    let id: String
    let reservationId: String
    let requestedByUserId: String
    let requestedStartAt: String
    let requestedEndAt: String?
    let reason: String
    let status: ReservationChangeRequestStatus
    let reviewedByUserId: String?
    let reviewedAt: String?
    let previousStatus: ReservationStatus?
    let createdAt: String
}

struct ReservationCompletionRecord: Codable, Hashable {
    let id: String
    let method: ReservationCompletionMethod
    let createdAt: String
}

struct ReservationDelayUpdate: Codable, Identifiable, Hashable {
    let id: String
    let status: ReservationDelayStatus
    let estimatedArrivalMinutes: Int?
    let note: String?
    let createdAt: String
}
