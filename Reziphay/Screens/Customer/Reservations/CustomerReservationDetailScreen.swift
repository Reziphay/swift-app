import SwiftUI

// MARK: - ViewModel

@Observable
@MainActor
final class CustomerReservationDetailViewModel {
    var reservation: Reservation?
    var isLoading: Bool = false

    private var appState: AppState?

    func setup(appState: AppState) {
        self.appState = appState
    }

    func load(id: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            reservation = try await appState?.apiClient.get(APIEndpoints.reservation(id))
        } catch {
            appState?.showToast("Failed to load reservation.", type: .error)
        }
    }

    func cancelReservation(id: String, reason: String) async throws {
        struct CancelBody: Encodable { let reason: String }
        let _: Reservation = try await appState!.apiClient.post(
            APIEndpoints.reservationCancelByCustomer(id),
            body: CancelBody(reason: reason)
        )
        await load(id: id)
    }

    func requestChange(id: String, newTime: Date, reason: String) async throws {
        struct ChangeBody: Encodable { let requestedStartAt: String; let reason: String }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let body = ChangeBody(requestedStartAt: formatter.string(from: newTime), reason: reason)
        let _: ReservationChangeRequest = try await appState!.apiClient.post(
            APIEndpoints.reservationChangeRequests(id),
            body: body
        )
        await load(id: id)
    }
}

// MARK: - Screen

struct CustomerReservationDetailScreen: View {
    let reservationId: String

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = CustomerReservationDetailViewModel()
    @State private var showCancelSheet = false
    @State private var showChangeSheet = false

    var body: some View {
        ZStack {
            Color.rzBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                RZTopBar(title: "Reservation") {
                    RZIconButton(icon: "chevron.left") { dismiss() }
                }

                if viewModel.isLoading && viewModel.reservation == nil {
                    loadingSkeleton
                } else if let reservation = viewModel.reservation {
                    ScrollView {
                        VStack(spacing: RZSpacing.sm) {
                            statusBanner(reservation: reservation)
                            serviceProviderCard(reservation: reservation)
                            dateTimeBlock(reservation: reservation)

                            if let history = reservation.statusHistory, !history.isEmpty {
                                statusTimeline(history: history)
                            }

                            if let changeRequests = reservation.changeRequests, !changeRequests.isEmpty {
                                changeRequestsSection(changeRequests: changeRequests)
                            }

                            if let reason = reservation.rejectionReason {
                                reasonCard(title: "Rejection Reason", reason: reason, color: .rzError)
                            }

                            if let reason = reservation.cancellationReason {
                                reasonCard(title: "Cancellation Reason", reason: reason, color: .rzTextSecondary)
                            }

                            Spacer(minLength: 100)
                        }
                        .padding(.horizontal, RZSpacing.screenHorizontal)
                        .padding(.top, RZSpacing.xs)
                    }
                    .overlay(alignment: .bottom) {
                        actionArea(reservation: reservation)
                    }
                } else {
                    RZEmptyState(
                        icon: "exclamationmark.circle",
                        title: "Not Found",
                        subtitle: "Could not load this reservation.",
                        actionTitle: "Go Back"
                    ) { dismiss() }
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            viewModel.setup(appState: appState)
            await viewModel.load(id: reservationId)
        }
        .sheet(isPresented: $showCancelSheet) {
            CancelReservationSheet(
                reservationId: reservationId,
                reservationSummary: viewModel.reservation?.formattedDateTime ?? "",
                isPresented: $showCancelSheet
            ) {
                Task { await viewModel.load(id: reservationId) }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showChangeSheet) {
            ChangeReservationRequestSheet(
                reservationId: reservationId,
                currentDateTime: viewModel.reservation?.formattedDateTime ?? "",
                isPresented: $showChangeSheet
            ) {
                Task { await viewModel.load(id: reservationId) }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Status Banner

    private func statusBanner(reservation: Reservation) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: RZSpacing.xxxs) {
                RZStatusPill(
                    text: reservation.status.displayLabel,
                    color: reservation.status.displayColor
                )

                if reservation.status == .pending, let expiresAt = reservation.approvalExpiresAt {
                    HStack(spacing: RZSpacing.xxxs) {
                        Image(systemName: "clock")
                            .font(.system(size: 11))
                            .foregroundStyle(.rzWarning)
                        Text("Expires in")
                            .font(.rzCaption)
                            .foregroundStyle(.rzTextSecondary)
                        CountdownText(expiresAt: expiresAt)
                    }
                }
            }
            Spacer()
        }
        .padding(RZSpacing.sm)
        .background(reservation.status.displayColor.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: RZRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: RZRadius.card)
                .strokeBorder(reservation.status.displayColor.opacity(0.18), lineWidth: 1)
        )
    }

    // MARK: - Service & Provider Card

    private func serviceProviderCard(reservation: Reservation) -> some View {
        RZCard {
            VStack(alignment: .leading, spacing: RZSpacing.xs) {
                if let service = reservation.service {
                    HStack {
                        VStack(alignment: .leading, spacing: RZSpacing.xxxs) {
                            Text(service.name)
                                .font(.rzH4)
                                .foregroundStyle(.rzTextPrimary)
                            if let brand = reservation.brand {
                                Text(brand.name)
                                    .font(.rzBodySmall)
                                    .foregroundStyle(.rzTextSecondary)
                            }
                        }
                        Spacer()
                        if let type = service.serviceType {
                            RZStatusPill(text: type.rawValue.capitalized, color: .rzPrimary)
                        }
                    }
                }

                if let owner = reservation.owner {
                    Divider()
                    HStack(spacing: RZSpacing.xs) {
                        RZAvatarView(name: owner.fullName, url: nil, size: 32)
                        VStack(alignment: .leading, spacing: RZSpacing.xxxs) {
                            Text("Provider")
                                .font(.rzCaption)
                                .foregroundStyle(.rzTextTertiary)
                            Text(owner.fullName)
                                .font(.rzBodySmall)
                                .fontWeight(.semibold)
                                .foregroundStyle(.rzTextPrimary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Date & Time Block

    private func dateTimeBlock(reservation: Reservation) -> some View {
        RZCard {
            VStack(spacing: RZSpacing.xs) {
                infoRow(icon: "calendar", label: "Date & Time", value: reservation.formattedDateTime)

                if let completedAt = reservation.completedAt {
                    Divider()
                    infoRow(icon: "checkmark.circle.fill", label: "Completed At", value: formatISO(completedAt))
                }
            }
        }
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: RZSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.rzPrimary)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: RZSpacing.xxxs) {
                Text(label)
                    .font(.rzCaption)
                    .foregroundStyle(.rzTextTertiary)
                Text(value)
                    .font(.rzBodySmall)
                    .fontWeight(.semibold)
                    .foregroundStyle(.rzTextPrimary)
            }
            Spacer()
        }
    }

    // MARK: - Status Timeline

    private func statusTimeline(history: [ReservationStatusEvent]) -> some View {
        RZCard {
            VStack(alignment: .leading, spacing: RZSpacing.xs) {
                Text("Status History")
                    .font(.rzH4)
                    .foregroundStyle(.rzTextPrimary)
                    .padding(.bottom, RZSpacing.xxxs)

                ForEach(Array(history.enumerated()), id: \.element.id) { index, event in
                    RZTimelineItem(
                        title: event.toStatus.displayLabel,
                        subtitle: event.reason,
                        timestamp: formatISO(event.createdAt),
                        isLast: index == history.count - 1
                    )
                }
            }
        }
    }

    // MARK: - Change Requests

    private func changeRequestsSection(changeRequests: [ReservationChangeRequest]) -> some View {
        RZCard {
            VStack(alignment: .leading, spacing: RZSpacing.xs) {
                Text("Change Requests")
                    .font(.rzH4)
                    .foregroundStyle(.rzTextPrimary)

                ForEach(changeRequests) { request in
                    VStack(alignment: .leading, spacing: RZSpacing.xxxs) {
                        HStack {
                            Text(formatISO(request.requestedStartAt))
                                .font(.rzBodySmall)
                                .fontWeight(.semibold)
                                .foregroundStyle(.rzTextPrimary)
                            Spacer()
                            RZStatusPill(
                                text: request.status.rawValue.capitalized,
                                color: changeRequestStatusColor(request.status)
                            )
                        }
                        Text(request.reason)
                            .font(.rzCaption)
                            .foregroundStyle(.rzTextSecondary)
                        Text(formatISO(request.createdAt))
                            .font(.rzCaption)
                            .foregroundStyle(.rzTextTertiary)
                    }
                    .padding(.vertical, RZSpacing.xxxs)
                    if request.id != changeRequests.last?.id {
                        Divider()
                    }
                }
            }
        }
    }

    private func changeRequestStatusColor(_ status: ReservationChangeRequestStatus) -> Color {
        switch status {
        case .pending: return .rzWarning
        case .accepted: return .rzSuccess
        case .rejected: return .rzError
        case .cancelled: return .rzTextTertiary
        }
    }

    // MARK: - Reason Card

    private func reasonCard(title: String, reason: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: RZSpacing.xs) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16))
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: RZSpacing.xxxs) {
                Text(title)
                    .font(.rzBodySmall)
                    .fontWeight(.semibold)
                    .foregroundStyle(color)
                Text(reason)
                    .font(.rzBodySmall)
                    .foregroundStyle(.rzTextSecondary)
            }
        }
        .padding(RZSpacing.sm)
        .background(color.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: RZRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: RZRadius.card)
                .strokeBorder(color.opacity(0.18), lineWidth: 1)
        )
    }

    // MARK: - Action Area

    private func actionArea(reservation: Reservation) -> some View {
        VStack(spacing: 0) {
            Divider()
            VStack(spacing: RZSpacing.xs) {
                switch reservation.status {
                case .pending:
                    RZButton(title: "Cancel Reservation", variant: .ghost, size: .large, isFullWidth: true) {
                        showCancelSheet = true
                    }

                case .confirmed, .changeRequestedByCustomer, .changeRequestedByOwner:
                    RZButton(title: "Scan QR Code", variant: .primary, size: .large, isFullWidth: true) {
                        appState.router.push(.qrScan(reservationId: reservation.id), forRole: .ucr)
                    }
                    HStack(spacing: RZSpacing.xs) {
                        RZButton(title: "Request Change", variant: .secondary, size: .medium, isFullWidth: true) {
                            showChangeSheet = true
                        }
                        RZButton(title: "Cancel", variant: .ghost, size: .medium, isFullWidth: true) {
                            showCancelSheet = true
                        }
                    }

                case .completed:
                    RZButton(title: "Leave a Review", variant: .primary, size: .large, isFullWidth: true) {
                        appState.router.push(.createReview(reservationId: reservation.id), forRole: .ucr)
                    }

                case .noShow:
                    RZButton(title: "Submit Objection", variant: .secondary, size: .large, isFullWidth: true) {
                        appState.router.push(.reservationDetail(id: reservation.id), forRole: .ucr)
                    }

                default:
                    EmptyView()
                }
            }
            .padding(.horizontal, RZSpacing.screenHorizontal)
            .padding(.vertical, RZSpacing.sm)
            .background(Color.rzBackground)
        }
    }

    // MARK: - Loading Skeleton

    private var loadingSkeleton: some View {
        ScrollView {
            VStack(spacing: RZSpacing.sm) {
                ForEach(0..<4, id: \.self) { _ in
                    RZCard {
                        VStack(alignment: .leading, spacing: RZSpacing.xxs) {
                            RZSkeletonView(height: 18, radius: 6)
                            RZSkeletonView(height: 14, radius: 4)
                                .frame(maxWidth: 200)
                            RZSkeletonView(height: 14, radius: 4)
                                .frame(maxWidth: 160)
                        }
                    }
                }
            }
            .padding(.horizontal, RZSpacing.screenHorizontal)
            .padding(.top, RZSpacing.xs)
        }
        .disabled(true)
    }

    // MARK: - Helpers

    private func formatISO(_ iso: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: iso) else { return iso }
        let display = DateFormatter()
        display.dateFormat = "MMM d, yyyy 'at' h:mm a"
        return display.string(from: date)
    }
}
