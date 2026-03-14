import SwiftUI

// MARK: - ViewModel

@Observable
@MainActor
final class ProviderReservationsViewModel {
    var reservations: [Reservation] = []
    var isLoading: Bool = false
    var selectedFilter: String = "Incoming"

    private let filters = ["Incoming", "Today", "Upcoming", "Completed", "Cancelled"]

    func load(apiClient: APIClient) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let query = queryParams(for: selectedFilter)
            reservations = try await apiClient.get(APIEndpoints.incomingReservations, query: query)
        } catch {
            reservations = []
        }
    }

    private func queryParams(for filter: String) -> [String: String] {
        switch filter {
        case "Incoming":
            return ["status": "PENDING"]
        case "Today":
            return ["date": "today"]
        case "Upcoming":
            return ["status": "CONFIRMED", "timeframe": "future"]
        case "Completed":
            return ["status": "COMPLETED"]
        case "Cancelled":
            return ["status": "CANCELLED,NO_SHOW"]
        default:
            return [:]
        }
    }

    var filterOptions: [String] { filters }
}

// MARK: - Screen

struct ProviderReservationsListScreen: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = ProviderReservationsViewModel()

    var body: some View {
        VStack(spacing: 0) {
            RZTopBar(title: "Reservations")

            RZSegmentedControl(
                options: viewModel.filterOptions,
                selected: Binding(
                    get: { viewModel.selectedFilter },
                    set: { newVal in
                        viewModel.selectedFilter = newVal
                        Task { await viewModel.load(apiClient: appState.apiClient) }
                    }
                )
            )
            .padding(.horizontal, RZSpacing.screenHorizontal)
            .padding(.vertical, RZSpacing.xs)

            Divider()

            if viewModel.isLoading {
                skeletonList
            } else if viewModel.reservations.isEmpty {
                emptyState
            } else {
                reservationList
            }
        }
        .background(Color.rzBackground)
        .navigationBarHidden(true)
        .task {
            await viewModel.load(apiClient: appState.apiClient)
        }
    }

    // MARK: - Reservation List

    private var reservationList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: RZSpacing.xs) {
                ForEach(viewModel.reservations) { reservation in
                    ZStack(alignment: .topTrailing) {
                        ReservationCard(reservation: reservation) {
                            appState.router.push(.reservationDetail(id: reservation.id), forRole: .uso)
                        }

                        if reservation.status == .pending, let expiresAt = reservation.approvalExpiresAt {
                            CountdownText(expiresAt: expiresAt)
                                .padding(.top, RZSpacing.xs)
                                .padding(.trailing, RZSpacing.sm)
                        }
                    }
                    .padding(.horizontal, RZSpacing.screenHorizontal)
                }
            }
            .padding(.top, RZSpacing.sm)
            .padding(.bottom, RZSpacing.xl)
        }
        .refreshable {
            await viewModel.load(apiClient: appState.apiClient)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        let (icon, title, subtitle) = emptyStateContent(for: viewModel.selectedFilter)
        return RZEmptyState(
            icon: icon,
            title: title,
            subtitle: subtitle
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func emptyStateContent(for filter: String) -> (String, String, String) {
        switch filter {
        case "Incoming":
            return ("tray", "No pending requests", "New reservation requests will appear here.")
        case "Today":
            return ("calendar", "Nothing today", "Your schedule is clear for today.")
        case "Upcoming":
            return ("calendar.badge.clock", "No upcoming reservations", "Confirmed future reservations will appear here.")
        case "Completed":
            return ("checkmark.circle", "No completed reservations", "Completed reservations will be listed here.")
        case "Cancelled":
            return ("xmark.circle", "No cancellations", "Cancelled reservations will appear here.")
        default:
            return ("tray", "No reservations", "Nothing to show.")
        }
    }

    // MARK: - Skeleton

    private var skeletonList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: RZSpacing.xs) {
                ForEach(0..<5, id: \.self) { _ in
                    RZSkeletonView(height: 96, radius: RZRadius.card)
                        .padding(.horizontal, RZSpacing.screenHorizontal)
                }
            }
            .padding(.top, RZSpacing.sm)
        }
        .allowsHitTesting(false)
    }
}
