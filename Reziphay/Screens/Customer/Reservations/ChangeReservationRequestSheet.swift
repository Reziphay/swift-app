import SwiftUI

struct ChangeReservationRequestSheet: View {
    let reservationId: String
    let currentDateTime: String
    @Binding var isPresented: Bool
    let onSubmit: () -> Void

    @Environment(AppState.self) private var appState

    @State private var newDate: Date = Date()
    @State private var newTimeText: String = ""
    @State private var reason: String = ""
    @State private var reasonError: String? = nil
    @State private var timeError: String? = nil
    @State private var isSubmitting: Bool = false

    var body: some View {
        RZBottomSheet(title: "Request Change") {
            VStack(spacing: RZSpacing.md) {
                // Current datetime display
                HStack(spacing: RZSpacing.xs) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 16))
                        .foregroundStyle(.rzTextTertiary)
                    VStack(alignment: .leading, spacing: RZSpacing.xxxs) {
                        Text("Current Reservation")
                            .font(.rzCaption)
                            .foregroundStyle(.rzTextTertiary)
                        Text(currentDateTime)
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

                Divider()

                // New date section
                VStack(alignment: .leading, spacing: RZSpacing.xs) {
                    Text("New Date & Time")
                        .font(.rzH4)
                        .foregroundStyle(.rzTextPrimary)

                    DatePicker(
                        "Select New Date",
                        selection: $newDate,
                        in: Date()...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .tint(.rzPrimary)

                    RZTextField(
                        title: "New Time (HH:mm)",
                        placeholder: "e.g. 15:00",
                        text: $newTimeText,
                        error: timeError
                    )
                }

                // Reason field
                RZTextArea(
                    label: "Reason for Change",
                    text: $reason,
                    placeholder: "Please explain why you need to change the reservation...",
                    error: reasonError
                )

                // Submit button
                RZButton(
                    title: "Submit Change Request",
                    variant: .primary,
                    size: .large,
                    isFullWidth: true,
                    isLoading: isSubmitting
                ) {
                    handleSubmit()
                }

                RZButton(
                    title: "Cancel",
                    variant: .ghost,
                    size: .medium,
                    isFullWidth: true
                ) {
                    isPresented = false
                }
            }
        } onDismiss: {
            isPresented = false
        }
    }

    private func handleSubmit() {
        reasonError = nil
        timeError = nil

        let trimmedReason = reason.trimmingCharacters(in: .whitespaces)
        let trimmedTime = newTimeText.trimmingCharacters(in: .whitespaces)

        guard !trimmedReason.isEmpty else {
            reasonError = "Reason is required."
            return
        }

        guard trimmedReason.count >= 10 else {
            reasonError = "Reason must be at least 10 characters."
            return
        }

        guard !trimmedTime.isEmpty else {
            timeError = "Please enter a time."
            return
        }

        let timeParts = trimmedTime.split(separator: ":").map { Int($0) }
        guard timeParts.count == 2,
              let hour = timeParts[0], let minute = timeParts[1],
              (0...23).contains(hour), (0...59).contains(minute) else {
            timeError = "Invalid time format. Use HH:mm."
            return
        }

        var comps = Calendar.current.dateComponents([.year, .month, .day], from: newDate)
        comps.hour = hour
        comps.minute = minute
        comps.second = 0
        let combined = Calendar.current.date(from: comps) ?? newDate

        isSubmitting = true
        Task {
            defer { isSubmitting = false }
            do {
                struct ChangeBody: Encodable {
                    let requestedStartAt: String
                    let reason: String
                }
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                let body = ChangeBody(requestedStartAt: formatter.string(from: combined), reason: trimmedReason)
                let _: ReservationChangeRequest = try await appState.apiClient.post(
                    APIEndpoints.reservationChangeRequests(reservationId),
                    body: body
                )
                appState.showToast("Change request submitted.", type: .success)
                isPresented = false
                onSubmit()
            } catch {
                appState.showToast(error.localizedDescription, type: .error)
            }
        }
    }
}
