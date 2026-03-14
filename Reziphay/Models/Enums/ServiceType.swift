import Foundation

enum ServiceType: String, Codable {
    case solo = "SOLO"
    case multi = "MULTI"

    var displayName: String {
        switch self {
        case .solo: "Solo"
        case .multi: "Multi"
        }
    }
}

enum ApprovalMode: String, Codable {
    case manual = "MANUAL"
    case auto = "AUTO"

    var displayName: String {
        switch self {
        case .manual: "Manual Approval"
        case .auto: "Auto Confirm"
        }
    }
}
