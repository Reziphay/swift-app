import Foundation

struct AppNotification: Codable, Identifiable, Hashable {
    let id: String
    let userId: String
    let type: NotificationType
    let title: String
    let body: String
    let dataJson: NotificationData?
    let isRead: Bool
    let readAt: String?
    let createdAt: String

    var formattedDate: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: createdAt) else { return "" }
        let display = RelativeDateTimeFormatter()
        display.unitsStyle = .abbreviated
        return display.localizedString(for: date, relativeTo: Date())
    }
}

struct NotificationData: Codable, Hashable {
    let reservationId: String?
    let serviceId: String?
    let brandId: String?
    let reviewId: String?
}
