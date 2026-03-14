import SwiftUI

struct CancelReservationSheet: View {
    let reservationId: String
    let reservationSummary: String
    @Binding var isPresented: Bool
    let onCancel: () -> Void

    @Environment(AppState.self) private var appState

    @State private var reason: String = ""
    @State private var reasonError: String? = nil
    @State private var isSubmitting: Bool = false

    var body: some View {
        RZBottomSheet(title: "Cancel Reservation") {
            VStack(spacing: RZSpacing.md) {
                // Reservation summary
                HStack(spacing: RZSpacing.xs) {
                    Image(systemName: "calendar")
                        .font(.system(size: 16))
                        .foregroundStyle(.rzTextTertiary)
                    VStack(alignment: .leading, spacing: RZSpacing.xxxs) {
                        Text("Reservation")
                            .font(.rzCaption)
                            .foregroundStyle(.rzTextTertiary)
                        Text(reservationSummary)
                            .font(.rzBodySmall)
                            .fontWeight(.semibold)
                            .foregroundStyle(.rzTextPrimary)
                    }
                    Spacer()
                }
                .padding(RZSpacing.sm)
                .background(Color.rzSurface)
                .clipShape(RoundedRectangle(cornerRadius: RZRadius.card))
                .rzShadow(RZShadow.sm)

                // Reason text area
                RZTextArea(
                    label: "Cancellation Reason",
                    text: $reason,
                    placeholder: "Please let the provider know why you are cancelling...",
                    error: reasonError
                )

                // Policy note
                HStack(alignment: .top, spacing: RZSpacing.xxs) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.rzPrimary)
                    Text("Free cancellation may apply depending on the service policy and time before your appointment.")
                        .font(.rzCaption)
                        .foregroundStyle(.rzTextSecondary)
                }
                .padding(RZSpacing.xs)
                .background(Color.rzPrimary.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: RZRadius.card))

                // Buttons
                RZButton(
                    title: "Confirm Cancellation",
                    variant: .destructive,
                    size: .large,
                    isFullWidth: true,
                    isLoading: isSubmitting
                ) {
                    handleCancel()
                }

                RZButton(
                    title: "Keep Reservation",
                    variant: .ghost,
                    size: .large,
                    isFullWidth: true
                ) {
                    isPresented = false
                }
            }
        } onDismiss: {
            isPresented = false
        }
    }

    private func handleCancel() {
        reasonError = nil
        let trimmed = reason.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            reasonError = "Cancellation reason is required."
            return
        }
        guard trimmed.count >= 10 else {
            reasonError = "Reason must be at least 10 characters."
            return
        }

        isSubmitting = true
        Task {
            defer { isSubmitting = false }
            do {
                struct CancelBody: Encodable { let reason: String }
                let _: Reservation = try await appState.apiClient.post(
                    APIEndpoints.reservationCancelByCustomer(reservationId),
                    body: CancelBody(reason: trimmed)
                )
                appState.showToast("Reservation cancelled.", type: .info)
                isPresented = false
                onCancel()
            } catch {
                appState.showToast(error.localizedDescription, type: .error)
            }
        }
    }
}
