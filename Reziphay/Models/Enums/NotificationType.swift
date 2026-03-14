import Foundation

enum NotificationType: String, Codable {
    case reservationReceived = "RESERVATION_RECEIVED"
    case reservationConfirmed = "RESERVATION_CONFIRMED"
    case reservationRejected = "RESERVATION_REJECTED"
    case reservationCancelled = "RESERVATION_CANCELLED"
    case reservationChangeRequested = "RESERVATION_CHANGE_REQUESTED"
    case reservationDelayUpdated = "RESERVATION_DELAY_UPDATED"
    case reservationReminder = "RESERVATION_REMINDER"
    case reservationCompleted = "RESERVATION_COMPLETED"
    case reservationExpired = "RESERVATION_EXPIRED"
    case reservationNoShow = "RESERVATION_NO_SHOW"
    case penaltyApplied = "PENALTY_APPLIED"
    case reviewReceived = "REVIEW_RECEIVED"
    case reportReceived = "REPORT_RECEIVED"
    case reviewReported = "REVIEW_REPORTED"
    case objectionReceived = "OBJECTION_RECEIVED"
}
