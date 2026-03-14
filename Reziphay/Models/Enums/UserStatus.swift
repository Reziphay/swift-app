import Foundation

enum UserStatus: String, Codable {
    case active = "ACTIVE"
    case suspended = "SUSPENDED"
    case closed = "CLOSED"
}
