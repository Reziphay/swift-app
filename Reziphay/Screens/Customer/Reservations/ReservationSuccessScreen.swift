import SwiftUI

struct ReservationSuccessScreen: View {
    let reservationId: String
    let isAutoConfirmed: Bool

    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            Color.rzBackground.ignoresSafeArea()

            VStack(spacing: RZSpacing.xl) {
                Spacer()

                // Icon
                Image(systemName: isAutoConfirmed ? "checkmark.circle.fill" : "clock.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(isAutoConfirmed ? Color.rzSuccess : Color.rzWarning)
                    .symbolEffect(.bounce, value: true)

                // Text content
                VStack(spacing: RZSpacing.xs) {
                    Text(isAutoConfirmed ? "Reservation Confirmed!" : "Pending Approval")
                        .font(.rzH2)
                        .foregroundStyle(.rzTextPrimary)
                        .multilineTextAlignment(.center)

                    Text(isAutoConfirmed
                        ? "Your reservation has been automatically confirmed. See you there!"
                        : "Your request has been sent to the provider. They have 5 minutes to respond.")
                        .font(.rzBody)
                        .foregroundStyle(.rzTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, RZSpacing.xl)

                    if !isAutoConfirmed {
                        HStack(spacing: RZSpacing.xxxs) {
                            Image(systemName: "bell.badge.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.rzWarning)
                            Text("You'll receive a notification when the provider responds.")
                                .font(.rzCaption)
                                .foregroundStyle(.rzTextTertiary)
                        }
                        .padding(.top, RZSpacing.xxxs)
                    }
                }

                // Reservation ID card
                HStack(spacing: RZSpacing.xxs) {
                    Image(systemName: "number")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.rzTextTertiary)
                    Text("Reservation ID:")
                        .font(.rzBodySmall)
                        .foregroundStyle(.rzTextSecondary)
                    Text(String(reservationId.prefix(8)).uppercased())
                        .font(.rzBodySmall)
                        .fontWeight(.semibold)
                        .foregroundStyle(.rzTextPrimary)
                        .monospaced()
                }
                .padding(.horizontal, RZSpacing.md)
                .padding(.vertical, RZSpacing.xs)
                .background(Color.rzSurface)
                .clipShape(RoundedRectangle(cornerRadius: RZRadius.card))
                .rzShadow(RZShadow.sm)

                Spacer()

                // Action buttons
                VStack(spacing: RZSpacing.xs) {
                    RZButton(
                        title: "View Reservation",
                        variant: .primary,
                        size: .large,
                        isFullWidth: true
                    ) {
                        appState.router.push(.reservationDetail(id: reservationId), forRole: .ucr)
                    }

                    RZButton(
                        title: "Back to Home",
                        variant: .ghost,
                        size: .large,
                        isFullWidth: true
                    ) {
                        appState.router.popToRoot(forRole: .ucr)
                    }
                }
                .padding(.horizontal, RZSpacing.screenHorizontal)
                .padding(.bottom, RZSpacing.xl)
            }
        }
        .navigationBarHidden(true)
    }
}
