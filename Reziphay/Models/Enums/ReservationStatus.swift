import Foundation
import SwiftUI

enum ReservationStatus: String, Codable, CaseIterable {
    case pending = "PENDING"
    case confirmed = "CONFIRMED"
    case rejected = "REJECTED"
    case cancelledByCustomer = "CANCELLED_BY_CUSTOMER"
    case cancelledByOwner = "CANCELLED_BY_OWNER"
    case changeRequestedByCustomer = "CHANGE_REQUESTED_BY_CUSTOMER"
    case changeRequestedByOwner = "CHANGE_REQUESTED_BY_OWNER"
    case completed = "COMPLETED"
    case noShow = "NO_SHOW"
    case expired = "EXPIRED"

    var displayLabel: String {
        switch self {
        case .pending: return "Pending Approval"
        case .confirmed: return "Confirmed"
        case .completed: return "Completed"
        case .cancelledByCustomer, .cancelledByOwner: return "Cancelled"
        case .rejected: return "Rejected"
        case .noShow: return "No Show"
        case .changeRequestedByCustomer, .changeRequestedByOwner: return "Change Requested"
        case .expired: return "Expired"
        }
    }

    var displayColor: Color {
        switch self {
        case .pending: return .rzWarning
        case .confirmed: return .rzSuccess
        case .completed: return .rzPrimary
        case .cancelledByCustomer, .cancelledByOwner, .rejected, .expired: return .rzError
        case .noShow: return .rzTextTertiary
        case .changeRequestedByCustomer, .changeRequestedByOwner: return .rzSecondary
        }
    }

    var iconName: String {
        switch self {
        case .pending: return "clock.fill"
        case .confirmed: return "checkmark.circle.fill"
        case .completed: return "star.circle.fill"
        case .cancelledByCustomer, .cancelledByOwner: return "xmark.circle.fill"
        case .rejected: return "minus.circle.fill"
        case .noShow: return "person.slash.fill"
        case .changeRequestedByCustomer, .changeRequestedByOwner: return "clock.arrow.2.circlepath"
        case .expired: return "exclamationmark.circle.fill"
        }
    }

    var isActive: Bool {
        switch self {
        case .pending, .confirmed, .changeRequestedByCustomer, .changeRequestedByOwner:
            return true
        default:
            return false
        }
    }

    var isTerminal: Bool {
        switch self {
        case .rejected, .cancelledByCustomer, .cancelledByOwner, .completed, .noShow, .expired:
            return true
        default:
            return false
        }
    }
}
