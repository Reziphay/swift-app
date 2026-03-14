import Foundation

struct PenaltyPoint: Codable, Identifiable, Hashable {
    let id: String
    let userId: String
    let reservationId: String?
    let points: Int
    let reason: PenaltyReason
    let expiresAt: String
    let isActive: Bool
    let createdAt: String
}

struct PenaltyAction: Codable, Identifiable, Hashable {
    let id: String
    let userId: String
    let triggeredByPoints: Int
    let action: PenaltyActionType
    let startsAt: String
    let endsAt: String?
    let isActive: Bool
}

struct PenaltySummary: Codable {
    let points: [PenaltyPoint]
    let actions: [PenaltyAction]
    let activePointsTotal: Int
}

struct ReservationObjection: Codable, Identifiable, Hashable {
    let id: String
    let reservationId: String
    let userId: String
    let objectionType: ReservationObjectionType
    let reason: String
    let status: ReservationObjectionStatus
    let createdAt: String
}
