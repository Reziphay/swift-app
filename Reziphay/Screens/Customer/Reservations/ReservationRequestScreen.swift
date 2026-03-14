import SwiftUI

// MARK: - ViewModel

@Observable
@MainActor
final class ReservationRequestViewModel {
    var service: Service?
    var isLoading: Bool = false
    var isSubmitting: Bool = false

    var selectedDate: Date = Date()
    var selectedTimeText: String = ""
    var note: String = ""

    private var appState: AppState?

    func setup(appState: AppState) {
        self.appState = appState
    }

    func loadService(id: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            service = try await appState?.apiClient.get(APIEndpoints.service(id))
        } catch {
            appState?.showToast("Failed to load service details.", type: .error)
        }
    }

    func submit(serviceId: String) async throws -> Reservation {
        guard let appState else { throw URLError(.unknown) }
        isSubmitting = true
        defer { isSubmitting = false }

        let requestedStartAt = combinedDateISO()
        let body = CreateReservationBody(
            serviceId: serviceId,
            requestedStartAt: requestedStartAt,
            customerNote: note.isEmpty ? nil : note
        )
        let reservation: Reservation = try await appState.apiClient.post(APIEndpoints.reservations, body: body)
        return reservation
    }

    private func combinedDateISO() -> String {
        var combined = selectedDate
        let parts = selectedTimeText.split(separator: ":").map { Int($0) }
        if parts.count == 2, let hour = parts[0], let minute = parts[1] {
            var comps = Calendar.current.dateComponents([.year, .month, .day], from: selectedDate)
            comps.hour = hour
            comps.minute = minute
            comps.second = 0
            combined = Calendar.current.date(from: comps) ?? selectedDate
        }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: combined)
    }
}

private struct CreateReservationBody: Encodable {
    let serviceId: String
    let requestedStartAt: String
    let customerNote: String?
}

// MARK: - Screen

struct ReservationRequestScreen: View {
    let serviceId: String

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = ReservationRequestViewModel()
    @State private var timeError: String? = nil

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.rzBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                RZTopBar(title: "Book Reservation") {
                    RZIconButton(icon: "chevron.left") { dismiss() }
                }

                ScrollView {
                    VStack(spacing: RZSpacing.sectionVertical) {
                        if viewModel.isLoading {
                            serviceSkeleton
                        } else if let service = viewModel.service {
                            serviceCard(service: service)
                        }

                        dateTimeSection

                        if viewModel.service?.approvalMode == .manual {
                            manualApprovalBanner
                        }

                        noteSection
                    }
                    .padding(.horizontal, RZSpacing.screenHorizontal)
                    .padding(.top, RZSpacing.sm)
                    .padding(.bottom, 100)
                }
            }

            // Sticky bottom button
            VStack(spacing: 0) {
                Divider()
                RZButton(
                    title: "Confirm Reservation",
                    variant: .primary,
                    size: .large,
                    isFullWidth: true,
                    isLoading: viewModel.isSubmitting
                ) {
                    handleSubmit()
                }
                .padding(.horizontal, RZSpacing.screenHorizontal)
                .padding(.vertical, RZSpacing.sm)
                .background(Color.rzBackground)
            }
        }
        .navigationBarHidden(true)
        .task {
            viewModel.setup(appState: appState)
            await viewModel.loadService(id: serviceId)
            // Pre-fill time with current time
            if viewModel.selectedTimeText.isEmpty {
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                viewModel.selectedTimeText = formatter.string(from: Date())
            }
        }
    }

    // MARK: - Service Card

    private func serviceCard(service: Service) -> some View {
        RZCard {
            VStack(alignment: .leading, spacing: RZSpacing.xxs) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: RZSpacing.xxxs) {
                        Text(service.name)
                            .font(.rzH4)
                            .foregroundStyle(.rzTextPrimary)

                        if let brand = service.brand {
                            Text(brand.name)
                                .font(.rzBodySmall)
                                .foregroundStyle(.rzTextSecondary)
                        }

                        if let price = service.formattedPrice {
                            Text(price)
                                .font(.rzBodySmall)
                                .fontWeight(.semibold)
                                .foregroundStyle(.rzPrimary)
                        }
                    }
                    Spacer()

                    approvalModeBadge(mode: service.approvalMode)
                }

                if let address = service.address {
                    HStack(spacing: RZSpacing.xxxs) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.rzTextTertiary)
                        Text(address.city)
                            .font(.rzCaption)
                            .foregroundStyle(.rzTextTertiary)
                    }
                }
            }
        }
    }

    private func approvalModeBadge(mode: ApprovalMode) -> some View {
        let (label, color): (String, Color) = mode == .manual
            ? ("Manual Approval", Color.rzWarning)
            : ("Auto Confirm", Color.rzSuccess)
        return RZStatusPill(text: label, color: color)
    }

    private var serviceSkeleton: some View {
        RZCard {
            VStack(alignment: .leading, spacing: RZSpacing.xxs) {
                RZSkeletonView(height: 20, radius: 6)
                RZSkeletonView(height: 14, radius: 4)
            }
        }
    }

    // MARK: - Date & Time

    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: RZSpacing.sm) {
            Text("Select Date & Time")
                .font(.rzH4)
                .foregroundStyle(.rzTextPrimary)

            RZCard {
                VStack(spacing: RZSpacing.sm) {
                    DatePicker(
                        "Date",
                        selection: $viewModel.selectedDate,
                        in: Date()...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .tint(.rzPrimary)

                    Divider()

                    RZTextField(
                        title: "Time (HH:mm)",
                        placeholder: "e.g. 14:30",
                        text: $viewModel.selectedTimeText,
                        error: timeError
                    )

                    HStack(spacing: RZSpacing.xxxs) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 12))
                            .foregroundStyle(.rzTextTertiary)
                        Text("Flexible scheduling — exact time subject to provider availability.")
                            .font(.rzCaption)
                            .foregroundStyle(.rzTextTertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    // MARK: - Manual Approval Banner

    private var manualApprovalBanner: some View {
        HStack(alignment: .top, spacing: RZSpacing.xs) {
            Image(systemName: "clock.badge.exclamationmark")
                .font(.system(size: 18))
                .foregroundStyle(.rzWarning)

            VStack(alignment: .leading, spacing: RZSpacing.xxxs) {
                Text("Manual Approval Required")
                    .font(.rzBodySmall)
                    .fontWeight(.semibold)
                    .foregroundStyle(.rzWarning)
                Text("The provider has 5 minutes to respond to your request. You'll be notified immediately.")
                    .font(.rzCaption)
                    .foregroundStyle(.rzTextSecondary)
            }
        }
        .padding(RZSpacing.sm)
        .background(Color.rzWarning.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: RZRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: RZRadius.card)
                .strokeBorder(Color.rzWarning.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Note Section

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: RZSpacing.xs) {
            Text("Additional Note")
                .font(.rzH4)
                .foregroundStyle(.rzTextPrimary)

            RZTextArea(
                label: "Note (optional)",
                text: $viewModel.note,
                placeholder: "Any special requests or information for the provider..."
            )
        }
    }

    // MARK: - Actions

    private func handleSubmit() {
        timeError = nil
        let trimmedTime = viewModel.selectedTimeText.trimmingCharacters(in: .whitespaces)
        if trimmedTime.isEmpty {
            timeError = "Please enter a time."
            return
        }
        let timeParts = trimmedTime.split(separator: ":").map { Int($0) }
        guard timeParts.count == 2,
              let hour = timeParts[0], let minute = timeParts[1],
              (0...23).contains(hour), (0...59).contains(minute) else {
            timeError = "Invalid time format. Use HH:mm (e.g. 14:30)."
            return
        }

        Task {
            do {
                let reservation = try await viewModel.submit(serviceId: serviceId)
                let isAutoConfirmed = reservation.status == .confirmed
                appState.router.push(.reservationSuccess(id: reservation.id, isAutoConfirmed: isAutoConfirmed), forRole: .ucr)
            } catch {
                appState.showToast(error.localizedDescription, type: .error)
            }
        }
    }
}
