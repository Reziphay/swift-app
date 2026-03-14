import Foundation

struct Report: Codable, Identifiable, Hashable {
    let id: String
    let reporterUserId: String
    let targetType: ReportTargetType
    let targetId: String
    let reason: String
    let status: ReportStatus
    let createdAt: String
}
