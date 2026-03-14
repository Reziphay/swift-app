import Foundation

enum AppRole: String, Codable, CaseIterable, Hashable {
    case ucr = "UCR"
    case uso = "USO"
    case admin = "ADMIN"

    var displayName: String {
        switch self {
        case .ucr: "Customer"
        case .uso: "Service Provider"
        case .admin: "Admin"
        }
    }

    var icon: String {
        switch self {
        case .ucr: "person.fill"
        case .uso: "briefcase.fill"
        case .admin: "shield.fill"
        }
    }
}
