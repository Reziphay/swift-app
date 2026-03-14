import SwiftUI

struct ReservationCard: View {
    let reservation: Reservation
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button { onTap?() } label: {
            HStack(spacing: RZSpacing.xs) {
                VStack(alignment: .leading, spacing: RZSpacing.xxxs) {
                    HStack(spacing: RZSpacing.xxs) {
                        RZStatusPill(
                            text: reservation.status.displayLabel,
                            color: reservation.status.displayColor
                        )

                        if reservation.status == .pending,
                           let expiresAt = reservation.approvalExpiresAt {
                            CountdownText(expiresAt: expiresAt)
                        }
                    }

                    Text(reservation.serviceName ?? "Service")
                        .font(.rzBody)
                        .fontWeight(.semibold)
                        .foregroundStyle(.rzTextPrimary)
                        .lineLimit(1)

                    if let brandName = reservation.brandName {
                        Text(brandName)
                            .font(.rzBodySmall)
                            .foregroundStyle(.rzTextSecondary)
                            .lineLimit(1)
                    }

                    Text(reservation.formattedDateTime)
                        .font(.rzCaption)
                        .foregroundStyle(.rzTextTertiary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.rzTextTertiary)
            }
            .padding(RZSpacing.sm)
            .background(Color.rzSurface)
            .clipShape(RoundedRectangle(cornerRadius: RZRadius.card))
            .rzShadow(RZShadow.sm)
        }
        .buttonStyle(.plain)
    }
}

struct CountdownText: View {
    let expiresAt: Date
    @State private var remaining: TimeInterval = 0
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Text(formattedRemaining)
            .font(.rzCaption)
            .fontWeight(.semibold)
            .foregroundStyle(remaining < 60 ? .rzError : .rzWarning)
            .onAppear { updateRemaining() }
            .onReceive(timer) { _ in updateRemaining() }
    }

    private var formattedRemaining: String {
        if remaining <= 0 { return "Expired" }
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }

    private func updateRemaining() {
        remaining = max(0, expiresAt.timeIntervalSinceNow)
    }
}
