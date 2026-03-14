import SwiftUI

struct ProviderCancelReservationSheet: View {
    let reservationId: String
    @Binding var isPresented: Bool
    let onCancelled: () -> Void

    @Environment(AppState.self) private var appState
    @State private var reason: String = ""
    @State private var isSubmitting: Bool = false

    var body: some View {
        RZBottomSheet(isPresented: $isPresented) {
            VStack(alignment: .leading, spacing: RZSpacing.md) {
                VStack(alignment: .leading, spacing: RZSpacing.xxxs) {
                    Text("Cancel Reservation")
                        .font(.rzH3)
                        .foregroundStyle(.rzTextPrimary)
                    Text("Please provide a reason. This will be visible to the customer.")
                        .font(.rzBodySmall)
                        .foregroundStyle(.rzTextSecondary)
                }

                infoNote

                RZTextArea(
                    title: "Reason (required)",
                    placeholder: "Explain why you are cancelling this reservation...",
                    text: $reason
                )

                VStack(spacing: RZSpacing.xxs) {
                    RZButton(
                        title: "Confirm Cancellation",
                        variant: .destructive,
                        isFullWidth: true,
                        isLoading: isSubmitting
                    ) {
                        handleCancel()
                    }

                    RZButton(title: "Keep Reservation", variant: .ghost, isFullWidth: true) {
                        isPresented = false
                    }
                }
            }
            .padding(.horizontal, RZSpacing.screenHorizontal)
        }
    }

    // MARK: - Info Note

    private var infoNote: some View {
        HStack(alignment: .top, spacing: RZSpacing.xs) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14))
                .foregroundStyle(.rzWarning)
            Text("Provider cancellations may affect your reliability score. A reason is required.")
                .font(.rzBodySmall)
                .foregroundStyle(.rzTextSecondary)
        }
        .padding(RZSpacing.xs)
        .background(Color.rzWarning.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: RZRadius.input))
    }

    // MARK: - Action

    private func handleCancel() {
        let trimmed = reason.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            appState.showToast("Please provide a cancellation reason.", type: .error)
            return
        }

        Task {
            isSubmitting = true
            defer { isSubmitting = false }

            struct CancelBody: Encodable { let reason: String }
            do {
                let _: Reservation = try await appState.apiClient.post(
                    APIEndpoints.reservationCancelByOwner(reservationId),
                    body: CancelBody(reason: trimmed)
                )
                appState.showToast("Reservation cancelled.", type: .info)
                isPresented = false
                onCancelled()
            } catch {
                appState.showToast("Failed to cancel reservation.", type: .error)
            }
        }
    }
}
