import SwiftUI

struct ProviderChangeRequestSheet: View {
    let reservationId: String
    let currentDateTime: String
    @Binding var isPresented: Bool
    let onSubmit: () -> Void

    @Environment(AppState.self) private var appState
    @State private var newDate: Date = Date()
    @State private var newTimeText: String = ""
    @State private var reason: String = ""
    @State private var isSubmitting: Bool = false
    @State private var timeError: String? = nil

    var body: some View {
        RZBottomSheet(isPresented: $isPresented) {
            VStack(alignment: .leading, spacing: RZSpacing.md) {
                VStack(alignment: .leading, spacing: RZSpacing.xxxs) {
                    Text("Propose New Time")
                        .font(.rzH3)
                        .foregroundStyle(.rzTextPrimary)
                    Text("Send a time change request to the customer.")
                        .font(.rzBodySmall)
                        .foregroundStyle(.rzTextSecondary)
                }

                currentTimeRow

                VStack(alignment: .leading, spacing: RZSpacing.xs) {
                    Text("New Date & Time")
                        .font(.rzH4)
                        .foregroundStyle(.rzTextPrimary)

                    RZCard {
                        VStack(spacing: RZSpacing.sm) {
                            DatePicker(
                                "New Date",
                                selection: $newDate,
                                in: Date()...,
                                displayedComponents: .date
                            )
                            .datePickerStyle(.compact)
                            .tint(.rzPrimary)

                            Divider()

                            RZTextField(
                                title: "New Time (HH:mm)",
                                placeholder: "e.g. 15:00",
                                text: $newTimeText,
                                error: timeError
                            )
                        }
                    }
                }

                RZTextArea(
                    title: "Reason (required)",
                    placeholder: "Explain why you need to change the time...",
                    text: $reason
                )

                VStack(spacing: RZSpacing.xxs) {
                    RZButton(
                        title: "Send Change Request",
                        variant: .primary,
                        isFullWidth: true,
                        isLoading: isSubmitting
                    ) {
                        handleSubmit()
                    }

                    RZButton(title: "Cancel", variant: .ghost, isFullWidth: true) {
                        isPresented = false
                    }
                }
            }
            .padding(.horizontal, RZSpacing.screenHorizontal)
        }
        .onAppear {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            newTimeText = formatter.string(from: Date())
        }
    }

    // MARK: - Current Time Row

    private var currentTimeRow: some View {
        HStack(spacing: RZSpacing.xs) {
            VStack(alignment: .leading, spacing: RZSpacing.xxxs) {
                Text("Current")
                    .font(.rzCaption)
                    .foregroundStyle(.rzTextTertiary)
                Text(currentDateTime)
                    .font(.rzBodySmall)
                    .fontWeight(.medium)
                    .foregroundStyle(.rzTextSecondary)
            }

            Image(systemName: "arrow.right")
                .font(.system(size: 14))
                .foregroundStyle(.rzTextTertiary)

            VStack(alignment: .leading, spacing: RZSpacing.xxxs) {
                Text("Proposed")
                    .font(.rzCaption)
                    .foregroundStyle(.rzTextTertiary)
                Text("(set below)")
                    .font(.rzBodySmall)
                    .foregroundStyle(.rzPrimary)
            }
        }
        .padding(RZSpacing.xs)
        .background(Color.rzSurface)
        .clipShape(RoundedRectangle(cornerRadius: RZRadius.input))
    }

    // MARK: - Submit

    private func handleSubmit() {
        timeError = nil
        let trimmedTime = newTimeText.trimmingCharacters(in: .whitespaces)
        let trimmedReason = reason.trimmingCharacters(in: .whitespaces)

        guard !trimmedReason.isEmpty else {
            appState.showToast("Please provide a reason for the change.", type: .error)
            return
        }

        let timeParts = trimmedTime.split(separator: ":").map { Int($0) }
        guard timeParts.count == 2,
              let hour = timeParts[0], let minute = timeParts[1],
              (0...23).contains(hour), (0...59).contains(minute) else {
            timeError = "Invalid time format. Use HH:mm (e.g. 15:00)."
            return
        }

        var comps = Calendar.current.dateComponents([.year, .month, .day], from: newDate)
        comps.hour = hour
        comps.minute = minute
        comps.second = 0
        guard let combined = Calendar.current.date(from: comps) else { return }

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let requestedStartAt = iso.string(from: combined)

        Task {
            isSubmitting = true
            defer { isSubmitting = false }

            struct ChangeRequestBody: Encodable {
                let requestedStartAt: String
                let reason: String
            }

            do {
                try await appState.apiClient.postVoid(
                    APIEndpoints.reservationChangeRequests(reservationId),
                    body: ChangeRequestBody(requestedStartAt: requestedStartAt, reason: trimmedReason)
                )
                appState.showToast("Change request sent to customer.", type: .success)
                isPresented = false
                onSubmit()
            } catch {
                appState.showToast("Failed to send change request.", type: .error)
            }
        }
    }
}
