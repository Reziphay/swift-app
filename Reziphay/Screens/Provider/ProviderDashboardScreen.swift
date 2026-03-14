import SwiftUI

// MARK: - ViewModel

@Observable
@MainActor
final class ProviderDashboardViewModel {
    var pendingReservations: [Reservation] = []
    var todayReservations: [Reservation] = []
    var ownedBrands: [Brand] = []
    var isLoading: Bool = false

    func load(apiClient: APIClient) async {
        isLoading = true
        defer { isLoading = false }

        await withTaskGroup(of: Void.self) { group in
            group.addTask { [weak self] in
                guard let self else { return }
                do {
                    let result: [Reservation] = try await apiClient.get(
                        APIEndpoints.incomingReservations,
                        query: ["status": "PENDING"]
                    )
                    await MainActor.run { self.pendingReservations = result }
                } catch { }
            }
            group.addTask { [weak self] in
                guard let self else { return }
                do {
                    let result: [Reservation] = try await apiClient.get(
                        APIEndpoints.incomingReservations,
                        query: ["date": "today"]
                    )
                    await MainActor.run { self.todayReservations = result }
                } catch { }
            }
            group.addTask { [weak self] in
                guard let self else { return }
                do {
                    let result: [Brand] = try await apiClient.get(
                        APIEndpoints.brands,
                        query: ["role": "owner"]
                    )
                    await MainActor.run { self.ownedBrands = result }
                } catch { }
            }
        }
    }

    func quickAccept(reservationId: String, apiClient: APIClient) async throws {
        let _: Reservation = try await apiClient.post(APIEndpoints.reservationAccept(reservationId), body: EmptyBody())
        pendingReservations.removeAll { $0.id == reservationId }
    }

    func quickReject(reservationId: String, apiClient: APIClient) async throws {
        struct RejectBody: Encodable { let reason: String }
        let _: Reservation = try await apiClient.post(
            APIEndpoints.reservationReject(reservationId),
            body: RejectBody(reason: "Declined by provider")
        )
        pendingReservations.removeAll { $0.id == reservationId }
    }

    var hasSetup: Bool {
        !ownedBrands.isEmpty
    }

    var completedThisMonthCount: Int {
        todayReservations.filter { $0.status == .completed }.count
    }
}

private struct EmptyBody: Encodable {}

// MARK: - Screen

struct ProviderDashboardScreen: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = ProviderDashboardViewModel()

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private var userName: String {
        appState.authManager.currentUser?.fullName.components(separatedBy: " ").first ?? "there"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                headerSection
                    .padding(.horizontal, RZSpacing.screenHorizontal)
                    .padding(.top, 52)
                    .padding(.bottom, RZSpacing.md)

                if viewModel.isLoading {
                    skeletonContent
                } else {
                    dashboardContent
                }
            }
        }
        .background(Color.rzBackground)
        .ignoresSafeArea(edges: .top)
        .refreshable {
            await viewModel.load(apiClient: appState.apiClient)
        }
        .task {
            await viewModel.load(apiClient: appState.apiClient)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(greeting),")
                    .font(.rzBody)
                    .foregroundStyle(.rzTextSecondary)
                Text(userName)
                    .font(.rzH2)
                    .foregroundStyle(.rzTextPrimary)
            }
            Spacer()
            RZIconButton(icon: "qrcode") {
                appState.router.push(.providerQR, forRole: .uso)
            }
        }
    }

    // MARK: - Dashboard Content

    private var dashboardContent: some View {
        VStack(spacing: RZSpacing.sectionVertical) {
            if !viewModel.hasSetup {
                setupChecklist
                    .padding(.horizontal, RZSpacing.screenHorizontal)
            }

            if !viewModel.pendingReservations.isEmpty {
                pendingSection
            }

            todaySection

            statsRow
                .padding(.horizontal, RZSpacing.screenHorizontal)

            quickLinksSection
                .padding(.horizontal, RZSpacing.screenHorizontal)
                .padding(.bottom, RZSpacing.xl)
        }
    }

    // MARK: - Setup Checklist

    private var setupChecklist: some View {
        RZCard {
            VStack(alignment: .leading, spacing: RZSpacing.xs) {
                HStack(spacing: RZSpacing.xxs) {
                    Image(systemName: "checklist")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.rzPrimary)
                    Text("Get Started")
                        .font(.rzH4)
                        .foregroundStyle(.rzTextPrimary)
                }

                Text("Set up your business to start accepting reservations.")
                    .font(.rzBody)
                    .foregroundStyle(.rzTextSecondary)

                VStack(alignment: .leading, spacing: RZSpacing.xxs) {
                    onboardingStep(
                        icon: "building.2",
                        title: "Create your first brand",
                        isDone: !viewModel.ownedBrands.isEmpty
                    )
                    onboardingStep(
                        icon: "calendar.badge.plus",
                        title: "Add a service",
                        isDone: false
                    )
                }
                .padding(.top, RZSpacing.xxxs)

                RZButton(title: "Create Brand", variant: .primary, isFullWidth: true) {
                    appState.router.push(.createBrand, forRole: .uso)
                }
                .padding(.top, RZSpacing.xxs)
            }
        }
    }

    private func onboardingStep(icon: String, title: String, isDone: Bool) -> some View {
        HStack(spacing: RZSpacing.xs) {
            Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 16))
                .foregroundStyle(isDone ? .rzSuccess : .rzTextTertiary)
            Text(title)
                .font(.rzBody)
                .foregroundStyle(isDone ? .rzTextSecondary : .rzTextPrimary)
                .strikethrough(isDone)
        }
    }

    // MARK: - Pending Section

    private var pendingSection: some View {
        VStack(alignment: .leading, spacing: RZSpacing.xs) {
            HStack(spacing: RZSpacing.xxs) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.rzWarning)
                Text("Urgent: Pending Approval")
                    .font(.rzH4)
                    .foregroundStyle(.rzWarning)
                Spacer()
                RZStatusPill(text: "\(viewModel.pendingReservations.count)", color: .rzWarning)
            }
            .padding(.horizontal, RZSpacing.screenHorizontal)

            VStack(spacing: RZSpacing.xs) {
                ForEach(viewModel.pendingReservations) { reservation in
                    PendingReservationCard(
                        reservation: reservation,
                        onAccept: {
                            Task {
                                do {
                                    try await viewModel.quickAccept(
                                        reservationId: reservation.id,
                                        apiClient: appState.apiClient
                                    )
                                    appState.showToast("Reservation accepted.", type: .success)
                                } catch {
                                    appState.showToast("Failed to accept.", type: .error)
                                }
                            }
                        },
                        onReject: {
                            Task {
                                do {
                                    try await viewModel.quickReject(
                                        reservationId: reservation.id,
                                        apiClient: appState.apiClient
                                    )
                                    appState.showToast("Reservation rejected.", type: .info)
                                } catch {
                                    appState.showToast("Failed to reject.", type: .error)
                                }
                            }
                        },
                        onTap: {
                            appState.router.push(.reservationDetail(id: reservation.id), forRole: .uso)
                        }
                    )
                    .padding(.horizontal, RZSpacing.screenHorizontal)
                }
            }
        }
    }

    // MARK: - Today Section

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: RZSpacing.xs) {
            RZSectionHeader(
                title: "Today's Appointments",
                actionTitle: viewModel.todayReservations.count > 3 ? "See All" : nil
            ) {
                appState.router.push(.reservationDetail(id: ""), forRole: .uso)
            }
            .padding(.horizontal, RZSpacing.screenHorizontal)

            if viewModel.todayReservations.isEmpty {
                RZEmptyState(
                    icon: "calendar",
                    title: "No appointments today",
                    subtitle: "Your schedule is clear for today."
                )
                .padding(.horizontal, RZSpacing.screenHorizontal)
            } else {
                VStack(spacing: RZSpacing.xs) {
                    ForEach(viewModel.todayReservations) { reservation in
                        ReservationCard(reservation: reservation) {
                            appState.router.push(.reservationDetail(id: reservation.id), forRole: .uso)
                        }
                        .padding(.horizontal, RZSpacing.screenHorizontal)
                    }
                }
            }
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: RZSpacing.xs) {
            statCard(
                icon: "checkmark.circle.fill",
                value: "\(viewModel.completedThisMonthCount)",
                label: "Completed",
                color: .rzSuccess
            )
            statCard(
                icon: "clock.fill",
                value: "\(viewModel.pendingReservations.count)",
                label: "Pending",
                color: .rzWarning
            )
            statCard(
                icon: "calendar",
                value: "\(viewModel.todayReservations.count)",
                label: "Today",
                color: .rzPrimary
            )
        }
    }

    private func statCard(icon: String, value: String, label: String, color: Color) -> some View {
        RZCard {
            VStack(spacing: RZSpacing.xxxs) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(color)
                Text(value)
                    .font(.rzH3)
                    .foregroundStyle(.rzTextPrimary)
                Text(label)
                    .font(.rzCaption)
                    .foregroundStyle(.rzTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, RZSpacing.xxs)
        }
    }

    // MARK: - Quick Links

    private var quickLinksSection: some View {
        VStack(alignment: .leading, spacing: RZSpacing.xs) {
            Text("Quick Links")
                .font(.rzH4)
                .foregroundStyle(.rzTextPrimary)

            HStack(spacing: RZSpacing.xs) {
                quickLinkButton(icon: "building.2.fill", title: "My Brands") {
                    appState.router.push(.createBrand, forRole: .uso)
                }
                quickLinkButton(icon: "calendar.badge.plus", title: "My Services") {
                    appState.router.push(.createService, forRole: .uso)
                }
            }
        }
    }

    private func quickLinkButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: RZSpacing.xxs) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.rzPrimary)
                Text(title)
                    .font(.rzBodySmall)
                    .fontWeight(.medium)
                    .foregroundStyle(.rzTextPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.rzTextTertiary)
            }
            .padding(RZSpacing.sm)
            .background(Color.rzSurface)
            .clipShape(RoundedRectangle(cornerRadius: RZRadius.card))
            .rzShadow(RZShadow.sm)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Skeleton

    private var skeletonContent: some View {
        VStack(spacing: RZSpacing.sectionVertical) {
            VStack(spacing: RZSpacing.xs) {
                ForEach(0..<3, id: \.self) { _ in
                    RZSkeletonView(height: 88, radius: RZRadius.card)
                        .padding(.horizontal, RZSpacing.screenHorizontal)
                }
            }
        }
    }
}

// MARK: - Pending Reservation Card

private struct PendingReservationCard: View {
    let reservation: Reservation
    let onAccept: () -> Void
    let onReject: () -> Void
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            RZCard {
                VStack(alignment: .leading, spacing: RZSpacing.xs) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: RZSpacing.xxxs) {
                            Text(reservation.customer?.fullName ?? "Customer")
                                .font(.rzBodyLarge)
                                .fontWeight(.semibold)
                                .foregroundStyle(.rzTextPrimary)
                            Text(reservation.serviceName ?? reservation.service?.name ?? "Service")
                                .font(.rzBodySmall)
                                .foregroundStyle(.rzTextSecondary)
                            Text(reservation.formattedDateTime)
                                .font(.rzCaption)
                                .foregroundStyle(.rzTextTertiary)
                        }
                        Spacer()
                        if let expiresAt = reservation.approvalExpiresAt {
                            CountdownText(expiresAt: expiresAt)
                        }
                    }

                    HStack(spacing: RZSpacing.xxs) {
                        RZButton(title: "Accept", variant: .primary, size: .small, isFullWidth: true) {
                            onAccept()
                        }
                        RZButton(title: "Reject", variant: .destructive, size: .small, isFullWidth: true) {
                            onReject()
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .overlay(
            RoundedRectangle(cornerRadius: RZRadius.card)
                .strokeBorder(Color.rzWarning.opacity(0.3), lineWidth: 1)
        )
    }
}
