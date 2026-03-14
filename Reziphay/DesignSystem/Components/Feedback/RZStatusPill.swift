import SwiftUI

struct RZStatusPill: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.rzCaption)
            .fontWeight(.semibold)
            .foregroundStyle(color)
            .padding(.horizontal, RZSpacing.xxs)
            .padding(.vertical, RZSpacing.xxxs)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}

extension ReservationStatus {
    var displayLabel: String {
        switch self {
        case .pending: "Pending"
        case .confirmed: "Confirmed"
        case .rejected: "Rejected"
        case .cancelledByCustomer, .cancelledByOwner: "Cancelled"
        case .changeRequestedByCustomer, .changeRequestedByOwner: "Change Requested"
        case .completed: "Completed"
        case .noShow: "No-Show"
        case .expired: "Expired"
        }
    }

    var displayColor: Color {
        switch self {
        case .pending: .rzWarning
        case .confirmed: .rzSuccess
        case .rejected: .rzError
        case .cancelledByCustomer, .cancelledByOwner: .rzTextTertiary
        case .changeRequestedByCustomer, .changeRequestedByOwner: .rzSecondary
        case .completed: .rzSuccess
        case .noShow: .rzError
        case .expired: .rzTextTertiary
        }
    }
}
