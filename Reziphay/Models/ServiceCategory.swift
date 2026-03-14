import Foundation

struct ServiceCategory: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let slug: String
    let parentId: String?
    let isActive: Bool
    let children: [ServiceCategory]?
}
