import SwiftUI

// MARK: - ViewModel

@Observable
@MainActor
final class ProviderReservationDetailViewModel {
    var reservation: Reservation?
    var isLoading: Bool = false
    var isActing: Bool = false

    func load(id: String, apiClient: APIClient) async {
        isLoading = true
        defer { isLoading = false }
        do {
            reservation = try await apiClient.get(APIEndpoints.reservation(id))
        } catch { }
    }

    func accept(id: String, apiClient: APIClient) async throws {
        isActing = true
        defer { isActing = false }
        struct EmptyBody: Encodable {}
        let updated: Reservation = try await apiClient.post(APIEndpoints.reservationAccept(id), body: EmptyBody())
        reservation = updated
    }

    func reject(id: String, reason: String, apiClient: APIClient) async throws {
        isActing = true
        defer { isActing = false }
        struct RejectBody: Encodable { let reason: String }
        let updated: Reservation = try await apiClient.post(
            APIEndpoints.reservationReject(id),
            body: RejectBody(reason: reason)
        )
        reservation = updated
    }

    func cancelByOwner(id: String, reason: String, apiClient: APIClient) async throws {
        isActing = true
        defer { isActing = false }
        struct CancelBody: Encodable { let reason: String }
        let updated: Reservation = try await apiClient.post(
            APIEndpoints.reservationCancelByOwner(id),
            body: CancelBody(reason: reason)
        )
        reservation = updated
    }

    func completeManually(id: String, apiClient: APIClient) async throws {
        isActing = true
        defer { isActing = false }
        struct EmptyBody: Encodable {}
        let updated: Reservation = try await apiClient.post(
            APIEndpoints.reservationCompleteManually(id),
            body: EmptyBody()
        )
        reservation = updated
    }

    func acceptChangeRequest(crId: String, apiClient: APIClient) async throws {
        isActing = true
        defer { isActing = false }
        struct EmptyBody: Encodable {}
        try await apiClient.postVoid(APIEndpoints.changeRequestAccept(crId), body: EmptyBody())
        if let id = reservation?.id {
            await load(id: id, apiClient: apiClient)
        }
    }

    func rejectChangeRequest(crId: String, apiClient: APIClient) async throws {
        isActing = true
        defer { isActing = false }
        struct EmptyBody: Encodable {}
        try await apiClient.postVoid(APIEndpoints.changeRequestReject(crId), body: EmptyBody())
        if let id = reservation?.id {
            await load(id: id, apiClient: apiClient)
        }
    }

    var pendingChangeRequest: ReservationChangeRequest? {
        reservation?.changeRequests?.first { $0.status == "PENDING" }
    }
}

// MARK: - Screen

struct ProviderReservationDetailScreen: View {
    let reservationId: String

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = ProviderReservationDetailViewModel()
    @State private var showRejectSheet = false
    @State private var showCancelSheet = false
    @State private var showChangeRequestSheet = false
    @State private var showCompleteConfirm = false
    @State private var rejectReason = ""

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.rzBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                RZTopBar(title: "Reservation Detail") {
                    RZIconButton(icon: "chevron.left") { dismiss() }
                }

                if viewModel.isLoading {
                    skeletonContent
                } else if let reservation = viewModel.reservation {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: RZSpacing.sm) {
                            statusBanner(reservation: reservation)
                            customerInfoCard(reservation: reservation)
                            serviceCard(reservation: reservation)
                            dateTimeCard(reservation: reservation)

                            if let history = reservation.statusHistory, !history.isEmpty {
                                timelineSection(history: history)
                            }

                            if let cr = viewModel.pendingChangeRequest {
                                changeRequestBlock(cr: cr)
                            }

                            if let note = reservation.customerNote, !note.isEmpty {
                                customerNoteCard(note: note)
                            }

                            if let reason = reservation.rejectionReason {
                                reasonCard(title: "Rejection Reason", reason: reason, color: .rzError)
                            }

                            if let reason = reservation.cancellationReason {
                                reasonCard(title: "Cancellation Reason", reason: reason, color: .rzWarning)
                            }
                        }
                        .padding(.horizontal, RZSpacing.screenHorizontal)
                        .padding(.top, RZSpacing.sm)
                        .padding(.bottom, actionAreaHeight(reservation: reservation) + RZSpacing.xl)
                    }
                } else {
                    RZEmptyState(
                        icon: "exclamationmark.circle",
                        title: "Not Found",
                        subtitle: "Could not load reservation details."
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }

            if let reservation = viewModel.reservation {
                actionArea(reservation: reservation)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showRejectSheet) {
            rejectSheet
        }
        .sheet(isPresented: $showCancelSheet) {
            if let reservation = viewModel.reservation {
                ProviderCancelReservationSheet(
                    reservationId: reservation.id,
                    isPresented: $showCancelSheet
                ) {
                    Task { await viewModel.load(id: reservation.id, apiClient: appState.apiClient) }
                }
            }
        }
        .sheet(isPresented: $showChangeRequestSheet) {
            if let reservation = viewModel.reservation {
                ProviderChangeRequestSheet(
                    reservationId: reservation.id,
                    currentDateTime: reservation.formattedDateTime,
                    isPresented: $showChangeRequestSheet
                ) {
                    Task { await viewModel.load(id: reservation.id, apiClient: appState.apiClient) }
                }
            }
        }
        .rzConfirmationDialog(
            isPresented: $showCompleteConfirm,
            title: "Complete Reservation",
            message: "Mark this reservation as manually completed?",
            confirmTitle: "Complete",
            confirmVariant: .primary
        ) {
            guard let id = viewModel.reservation?.id else { return }
            Task {
                do {
                    try await viewModel.completeManually(id: id, apiClient: appState.apiClient)
                    appState.showToast("Reservation completed.", type: .success)
                } catch {
                    appState.showToast("Failed to complete.", type: .error)
                }
            }
        }
        .task {
            await viewModel.load(id: reservationId, apiClient: appState.apiClient)
        }
    }

    // MARK: - Status Banner

    private func statusBanner(reservation: Reservation) -> some View {
        HStack(spacing: RZSpacing.xxs) {
            Image(systemName: reservation.status.iconName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(reservation.status.displayColor)
            Text(reservation.status.displayLabel)
                .font(.rzBodyLarge)
                .fontWeight(.semibold)
                .foregroundStyle(reservation.status.displayColor)
            Spacer()
            if reservation.status == .pending, let expiresAt = reservation.approvalExpiresAt {
                CountdownText(expiresAt: expiresAt)
            } else {
                RZStatusPill(text: reservation.status.displayLabel, color: reservation.status.displayColor)
            }
        }
        .padding(RZSpacing.sm)
        .background(reservation.status.displayColor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: RZRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: RZRadius.card)
                .strokeBorder(reservation.status.displayColor.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Customer Info

    private func customerInfoCard(reservation: Reservation) -> some View {
        RZCard {
            VStack(alignment: .leading, spacing: RZSpacing.xxs) {
                Text("Customer")
                    .font(.rzLabel)
                    .foregroundStyle(.rzTextTertiary)
                    .textCase(.uppercase)

                HStack(spacing: RZSpacing.xs) {
                    RZAvatarView(
                        name: reservation.customer?.fullName ?? "?",
                        size: 40
                    )
                    VStack(alignment: .leading, spacing: RZSpacing.xxxs) {
                        Text(reservation.customer?.fullName ?? "Unknown Customer")
                            .font(.rzBodyLarge)
                            .fontWeight(.semibold)
                            .foregroundStyle(.rzTextPrimary)
                        if let email = reservation.customer?.email {
                            Text(email)
                                .font(.rzBodySmall)
                                .foregroundStyle(.rzTextSecondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Service Card

    private func serviceCard(reservation: Reservation) -> some View {
        RZCard {
            VStack(alignment: .leading, spacing: RZSpacing.xxs) {
                Text("Service")
                    .font(.rzLabel)
                    .foregroundStyle(.rzTextTertiary)
                    .textCase(.uppercase)

                Text(reservation.serviceName ?? reservation.service?.name ?? "Service")
                    .font(.rzBodyLarge)
                    .fontWeight(.semibold)
                    .foregroundStyle(.rzTextPrimary)

                if let brandName = reservation.brandName ?? reservation.brand?.name {
                    HStack(spacing: RZSpacing.xxxs) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.rzTextTertiary)
                        Text(brandName)
                            .font(.rzBodySmall)
                            .foregroundStyle(.rzTextSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Date / Time Card

    private func dateTimeCard(reservation: Reservation) -> some View {
        RZCard {
            VStack(alignment: .leading, spacing: RZSpacing.xs) {
                Text("Date & Time")
                    .font(.rzLabel)
                    .foregroundStyle(.rzTextTertiary)
                    .textCase(.uppercase)

                HStack(spacing: RZSpacing.xs) {
                    Image(systemName: "calendar")
                        .font(.system(size: 16))
                        .foregroundStyle(.rzPrimary)
                    Text(reservation.formattedDateTime)
                        .font(.rzBody)
                        .foregroundStyle(.rzTextPrimary)
                }

                if let address = reservation.service?.address {
                    HStack(spacing: RZSpacing.xs) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.rzTextTertiary)
                        Text(address.city)
                            .font(.rzBody)
                            .foregroundStyle(.rzTextSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Timeline

    private func timelineSection(history: [ReservationStatusEvent]) -> some View {
        VStack(alignment: .leading, spacing: RZSpacing.xs) {
            Text("Status History")
                .font(.rzH4)
                .foregroundStyle(.rzTextPrimary)

            RZCard {
                VStack(spacing: 0) {
                    ForEach(Array(history.enumerated()), id: \.element.id) { index, event in
                        RZTimelineItem(
                            title: event.status.displayLabel,
                            subtitle: event.note,
                            date: event.createdAt,
                            isLast: index == history.count - 1
                        )
                    }
                }
            }
        }
    }

    // MARK: - Change Request Block

    private func changeRequestBlock(cr: ReservationChangeRequest) -> some View {
        VStack(alignment: .leading, spacing: RZSpacing.xs) {
            HStack(spacing: RZSpacing.xxs) {
                Image(systemName: "clock.arrow.2.circlepath")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.rzWarning)
                Text("Change Request")
                    .font(.rzH4)
                    .foregroundStyle(.rzWarning)
            }

            RZCard {
                VStack(alignment: .leading, spacing: RZSpacing.xs) {
                    HStack {
                        VStack(alignment: .leading, spacing: RZSpacing.xxxs) {
                            Text("Current")
                                .font(.rzCaption)
                                .foregroundStyle(.rzTextTertiary)
                            Text(viewModel.reservation?.formattedDateTime ?? "—")
                                .font(.rzBodySmall)
                                .fontWeight(.medium)
                                .foregroundStyle(.rzTextPrimary)
                        }
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14))
                            .foregroundStyle(.rzTextTertiary)
                            .padding(.horizontal, RZSpacing.xxs)
                        VStack(alignment: .leading, spacing: RZSpacing.xxxs) {
                            Text("Requested")
                                .font(.rzCaption)
                                .foregroundStyle(.rzTextTertiary)
                            Text(cr.requestedStartAt ?? "—")
                                .font(.rzBodySmall)
                                .fontWeight(.medium)
                                .foregroundStyle(.rzPrimary)
                        }
                        Spacer()
                    }

                    if let reason = cr.reason, !reason.isEmpty {
                        Text(reason)
                            .font(.rzBodySmall)
                            .foregroundStyle(.rzTextSecondary)
                    }

                    HStack(spacing: RZSpacing.xxs) {
                        RZButton(
                            title: "Accept Change",
                            variant: .primary,
                            size: .small,
                            isFullWidth: true,
                            isLoading: viewModel.isActing
                        ) {
                            Task {
                                do {
                                    try await viewModel.acceptChangeRequest(crId: cr.id, apiClient: appState.apiClient)
                                    appState.showToast("Change request accepted.", type: .success)
                                } catch {
                                    appState.showToast("Failed to accept change.", type: .error)
                                }
                            }
                        }
                        RZButton(
                            title: "Reject",
                            variant: .ghost,
                            size: .small,
                            isFullWidth: true,
                            isLoading: viewModel.isActing
                        ) {
                            Task {
                                do {
                                    try await viewModel.rejectChangeRequest(crId: cr.id, apiClient: appState.apiClient)
                                    appState.showToast("Change request rejected.", type: .info)
                                } catch {
                                    appState.showToast("Failed to reject change.", type: .error)
                                }
                            }
                        }
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: RZRadius.card)
                    .strokeBorder(Color.rzWarning.opacity(0.25), lineWidth: 1)
            )
        }
    }

    // MARK: - Customer Note

    private func customerNoteCard(note: String) -> some View {
        RZCard {
            VStack(alignment: .leading, spacing: RZSpacing.xxs) {
                HStack(spacing: RZSpacing.xxxs) {
                    Image(systemName: "note.text")
                        .font(.system(size: 14))
                        .foregroundStyle(.rzTextTertiary)
                    Text("Customer Note")
                        .font(.rzLabel)
                        .foregroundStyle(.rzTextTertiary)
                        .textCase(.uppercase)
                }
                Text(note)
                    .font(.rzBody)
                    .foregroundStyle(.rzTextPrimary)
            }
        }
    }

    // MARK: - Reason Card

    private func reasonCard(title: String, reason: String, color: Color) -> some View {
        RZCard {
            VStack(alignment: .leading, spacing: RZSpacing.xxs) {
                Text(title)
                    .font(.rzLabel)
                    .foregroundStyle(color)
                    .textCase(.uppercase)
                Text(reason)
                    .font(.rzBody)
                    .foregroundStyle(.rzTextPrimary)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: RZRadius.card)
                .strokeBorder(color.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Action Area

    private func actionAreaHeight(reservation: Reservation) -> CGFloat {
        switch reservation.status {
        case .pending: return 120
        case .confirmed, .changeRequestedByCustomer: return 140
        default: return 0
        }
    }

    @ViewBuilder
    private func actionArea(reservation: Reservation) -> some View {
        switch reservation.status {
        case .pending:
            pendingActions(reservation: reservation)
        case .confirmed:
            confirmedActions(reservation: reservation)
        case .changeRequestedByCustomer:
            changeRequestedActions(reservation: reservation)
        default:
            EmptyView()
        }
    }

    private func pendingActions(reservation: Reservation) -> some View {
        VStack(spacing: RZSpacing.xxs) {
            Divider()
            VStack(spacing: RZSpacing.xxs) {
                RZButton(
                    title: "Accept Reservation",
                    variant: .primary,
                    size: .large,
                    isFullWidth: true,
                    isLoading: viewModel.isActing
                ) {
                    Task {
                        do {
                            try await viewModel.accept(id: reservation.id, apiClient: appState.apiClient)
                            appState.showToast("Reservation accepted!", type: .success)
                        } catch {
                            appState.showToast("Failed to accept.", type: .error)
                        }
                    }
                }
                RZButton(
                    title: "Reject",
                    variant: .destructive,
                    size: .large,
                    isFullWidth: true,
                    isLoading: viewModel.isActing
                ) {
                    showRejectSheet = true
                }
            }
            .padding(.horizontal, RZSpacing.screenHorizontal)
            .padding(.vertical, RZSpacing.sm)
        }
        .background(Color.rzBackground)
    }

    private func confirmedActions(reservation: Reservation) -> some View {
        VStack(spacing: 0) {
            Divider()
            VStack(spacing: RZSpacing.xxs) {
                HStack(spacing: RZSpacing.xxs) {
                    RZButton(
                        title: "Complete Manually",
                        variant: .primary,
                        isFullWidth: true,
                        isLoading: viewModel.isActing
                    ) {
                        showCompleteConfirm = true
                    }
                    RZButton(
                        title: "Propose Change",
                        variant: .secondary,
                        isFullWidth: true
                    ) {
                        showChangeRequestSheet = true
                    }
                }
                RZButton(
                    title: "Cancel Reservation",
                    variant: .destructive,
                    isFullWidth: true
                ) {
                    showCancelSheet = true
                }
            }
            .padding(.horizontal, RZSpacing.screenHorizontal)
            .padding(.vertical, RZSpacing.sm)
        }
        .background(Color.rzBackground)
    }

    private func changeRequestedActions(reservation: Reservation) -> some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: RZSpacing.xxs) {
                RZButton(
                    title: "Accept Change",
                    variant: .primary,
                    isFullWidth: true,
                    isLoading: viewModel.isActing
                ) {
                    guard let cr = viewModel.pendingChangeRequest else { return }
                    Task {
                        do {
                            try await viewModel.acceptChangeRequest(crId: cr.id, apiClient: appState.apiClient)
                            appState.showToast("Change accepted.", type: .success)
                        } catch {
                            appState.showToast("Failed.", type: .error)
                        }
                    }
                }
                RZButton(
                    title: "Reject Change",
                    variant: .destructive,
                    isFullWidth: true,
                    isLoading: viewModel.isActing
                ) {
                    guard let cr = viewModel.pendingChangeRequest else { return }
                    Task {
                        do {
                            try await viewModel.rejectChangeRequest(crId: cr.id, apiClient: appState.apiClient)
                            appState.showToast("Change rejected.", type: .info)
                        } catch {
                            appState.showToast("Failed.", type: .error)
                        }
                    }
                }
            }
            .padding(.horizontal, RZSpacing.screenHorizontal)
            .padding(.vertical, RZSpacing.sm)
        }
        .background(Color.rzBackground)
    }

    // MARK: - Reject Sheet

    private var rejectSheet: some View {
        RZBottomSheet(isPresented: $showRejectSheet) {
            VStack(alignment: .leading, spacing: RZSpacing.md) {
                Text("Reject Reservation")
                    .font(.rzH3)
                    .foregroundStyle(.rzTextPrimary)

                RZTextArea(
                    title: "Reason (required)",
                    placeholder: "Explain why you are rejecting this reservation...",
                    text: $rejectReason
                )

                RZButton(
                    title: "Confirm Rejection",
                    variant: .destructive,
                    isFullWidth: true,
                    isLoading: viewModel.isActing
                ) {
                    guard !rejectReason.trimmingCharacters(in: .whitespaces).isEmpty,
                          let id = viewModel.reservation?.id else {
                        appState.showToast("Please provide a reason.", type: .error)
                        return
                    }
                    Task {
                        do {
                            try await viewModel.reject(id: id, reason: rejectReason, apiClient: appState.apiClient)
                            appState.showToast("Reservation rejected.", type: .info)
                            showRejectSheet = false
                        } catch {
                            appState.showToast("Failed to reject.", type: .error)
                        }
                    }
                }

                RZButton(title: "Keep", variant: .ghost, isFullWidth: true) {
                    showRejectSheet = false
                }
            }
            .padding(.horizontal, RZSpacing.screenHorizontal)
        }
    }

    // MARK: - Skeleton

    private var skeletonContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: RZSpacing.xs) {
                ForEach(0..<4, id: \.self) { _ in
                    RZSkeletonView(height: 80, radius: RZRadius.card)
                }
            }
            .padding(.horizontal, RZSpacing.screenHorizontal)
            .padding(.top, RZSpacing.sm)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Extensions

private extension ReservationStatus {

// MARK: - RZConfirmationDialog extension helper

extension View {
    func rzConfirmationDialog(
        isPresented: Binding<Bool>,
        title: String,
        message: String,
        confirmTitle: String,
        confirmVariant: RZButtonVariant,
        onConfirm: @escaping () -> Void
    ) -> some View {
        self.sheet(isPresented: isPresented) {
            RZConfirmationDialog(
                isPresented: isPresented,
                title: title,
                message: message,
                confirmTitle: confirmTitle,
                confirmVariant: confirmVariant,
                onConfirm: onConfirm
            )
        }
    }
}
