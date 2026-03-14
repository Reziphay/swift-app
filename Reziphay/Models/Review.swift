import Foundation

struct Review: Codable, Identifiable, Hashable {
    let id: String
    let reservationId: String
    let authorUserId: String
    let rating: Int
    let comment: String
    let isDeleted: Bool
    let authorName: String?
    let targets: [ReviewTarget]?
    let reply: ReviewReply?
    let createdAt: String

    var formattedDate: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: createdAt) else { return "" }
        let display = DateFormatter()
        display.dateFormat = "MMM d, yyyy"
        return display.string(from: date)
    }
}

struct ReviewTarget: Codable, Identifiable, Hashable {
    let id: String
    let targetType: ReviewTargetType
    let targetId: String
}

struct ReviewReply: Codable, Identifiable, Hashable {
    let id: String
    let authorUserId: String
    let comment: String
    let createdAt: String
}
