import SwiftUI

// MARK: - ViewModel

@Observable
@MainActor
final class CustomerReservationsViewModel {
    var reservations: [Reservation] = []
    var selectedFilter: String = "Upcoming"
    var isLoading: Bool = false
    var error: String? = nil

    private var appState: AppState?

    let filterOptions = ["Upcoming", "Pending", "Completed", "Cancelled"]

    func setup(appState: AppState) {
        self.appState = appState
    }

    var filteredReservations: [Reservation] {
        switch selectedFilter {
        case "Upcoming":
            return reservations.filter { $0.status == .confirmed || $0.status == .changeRequestedByCustomer || $0.status == .changeRequestedByOwner }
        case "Pending":
            return reservations.filter { $0.status == .pending }
        case "Completed":
            return reservations.filter { $0.status == .completed }
        case "Cancelled":
            return reservations.filter {
                $0.status == .cancelledByCustomer ||
                $0.status == .cancelledByOwner ||
                $0.status == .rejected ||
                $0.status == .noShow ||
                $0.status == .expired
            }
        default:
            return reservations
        }
    }

    func load() async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            let result: [Reservation] = try await appState?.apiClient.get(APIEndpoints.myReservations) ?? []
            reservations = result.sorted { lhs, rhs in
                lhs.requestedStartAt > rhs.requestedStartAt
            }
        } catch {
            self.error = error.localizedDescription
            appState?.showToast("Failed to load reservations.", type: .error)
        }
    }
}

// MARK: - Screen

struct CustomerReservationsListScreen: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = CustomerReservationsViewModel()

    var body: some View {
        ZStack {
            Color.rzBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                RZTopBar(title: "My Reservations")

                RZSegmentedControl(
                    options: viewModel.filterOptions,
                    selected: Binding(
                        get: { viewModel.selectedFilter },
                        set: { viewModel.selectedFilter = $0 }
                    )
                )
                .padding(.horizontal, RZSpacing.screenHorizontal)
                .padding(.vertical, RZSpacing.xs)

                if viewModel.isLoading {
                    skeletonList
                } else if viewModel.filteredReservations.isEmpty {
                    emptyState
                } else {
                    reservationList
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            viewModel.setup(appState: appState)
            await viewModel.load()
        }
    }

    // MARK: - Reservation List

    private var reservationList: some View {
        ScrollView {
            LazyVStack(spacing: RZSpacing.xs) {
                ForEach(viewModel.filteredReservations) { reservation in
                    ReservationCard(reservation: reservation) {
                        appState.router.push(.reservationDetail(id: reservation.id), forRole: .ucr)
                    }
                }
            }
            .padding(.horizontal, RZSpacing.screenHorizontal)
            .padding(.vertical, RZSpacing.sm)
        }
        .refreshable {
            await viewModel.load()
        }
    }

    // MARK: - Skeleton

    private var skeletonList: some View {
        ScrollView {
            LazyVStack(spacing: RZSpacing.xs) {
                ForEach(0..<5, id: \.self) { _ in
                    RZCard {
                        VStack(alignment: .leading, spacing: RZSpacing.xxs) {
                            RZSkeletonView(height: 16, radius: 8)
                                .frame(width: 100)
                            RZSkeletonView(height: 18, radius: 6)
                            RZSkeletonView(height: 14, radius: 4)
                                .frame(width: 160)
                        }
                    }
                }
            }
            .padding(.horizontal, RZSpacing.screenHorizontal)
            .padding(.vertical, RZSpacing.sm)
        }
        .disabled(true)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        Spacer().overlay(
            emptyContent
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyContent: some View {
        RZEmptyState(
            icon: emptyStateIcon,
            title: emptyStateTitle,
            subtitle: emptyStateSubtitle,
            actionTitle: "Browse Services"
        ) {
            appState.router.popToRoot(forRole: .ucr)
        }
    }

    private var emptyStateIcon: String {
        switch viewModel.selectedFilter {
        case "Completed": return "checkmark.circle"
        case "Cancelled": return "xmark.circle"
        case "Pending": return "clock"
        default: return "calendar.badge.plus"
        }
    }

    private var emptyStateTitle: String {
        "No \(viewModel.selectedFilter) Reservations"
    }

    private var emptyStateSubtitle: String {
        switch viewModel.selectedFilter {
        case "Upcoming": return "Book a service to get started."
        case "Pending": return "No reservations waiting for approval."
        case "Completed": return "Your completed reservations will appear here."
        case "Cancelled": return "No cancelled reservations."
        default: return ""
        }
    }
}
