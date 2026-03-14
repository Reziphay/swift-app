import SwiftUI

struct CustomerTabView: View {
    @Environment(AppState.self) private var appState

    private let tabs: [RZTabItem] = [
        RZTabItem(id: "home",          title: "Home",    icon: "house",           activeIcon: "house.fill"),
        RZTabItem(id: "search",        title: "Search",  icon: "magnifyingglass", activeIcon: "magnifyingglass"),
        RZTabItem(id: "reservations",  title: "Bookings",icon: "calendar",        activeIcon: "calendar"),
        RZTabItem(id: "notifications", title: "Inbox",   icon: "bell",            activeIcon: "bell.fill"),
        RZTabItem(id: "profile",       title: "Profile", icon: "person",          activeIcon: "person.fill"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Tab content area
            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Tab bar with optional notification badge
            ZStack(alignment: .topTrailing) {
                RZTabBar(
                    tabs: tabs,
                    selected: Binding(
                        get: { appState.router.selectedCustomerTab },
                        set: { appState.router.selectedCustomerTab = $0 }
                    )
                )

                if appState.unreadNotificationCount > 0 {
                    unreadBadge
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Tab content

    @ViewBuilder
    private var tabContent: some View {
        let selected = appState.router.selectedCustomerTab

        Group {
            if selected == "home" {
                NavigationStack(path: customerPath) {
                    CustomerHomeScreen()
                        .navigationDestination(for: Route.self, destination: customerDestination)
                }
            } else if selected == "search" {
                NavigationStack(path: customerPath) {
                    SearchScreen()
                        .navigationDestination(for: Route.self, destination: customerDestination)
                }
            } else if selected == "reservations" {
                NavigationStack(path: customerPath) {
                    CustomerReservationsListScreen()
                        .navigationDestination(for: Route.self, destination: customerDestination)
                }
            } else if selected == "notifications" {
                NavigationStack {
                    NotificationsScreen()
                }
            } else {
                NavigationStack(path: customerPath) {
                    ProfileScreen()
                        .navigationDestination(for: Route.self, destination: customerDestination)
                }
            }
        }
    }

    private var customerPath: Binding<NavigationPath> {
        Binding(
            get: { appState.router.customerPath },
            set: { appState.router.customerPath = $0 }
        )
    }

    // MARK: - Notification badge

    /// Small dot badge positioned over the notifications tab icon.
    private var unreadBadge: some View {
        // The tab bar has 5 equal-width tabs. The notifications tab is the 4th (index 3).
        // We offset it to align approximately above that tab's icon.
        GeometryReader { geo in
            let tabWidth = geo.size.width / CGFloat(tabs.count)
            let badgeX = tabWidth * 3 + tabWidth / 2 + 10
            Circle()
                .fill(Color.rzError)
                .frame(width: 8, height: 8)
                .position(x: badgeX, y: 8)
        }
        .frame(height: 16)
        .allowsHitTesting(false)
    }

    // MARK: - Navigation destinations

    @ViewBuilder
    private func customerDestination(for route: Route) -> some View {
        switch route {
        case .serviceDetail(let id):
            CustomerServiceDetailPlaceholder(id: id)
        case .brandDetail(let id):
            CustomerBrandDetailPlaceholder(id: id)
        case .providerDetail(let id):
            CustomerProviderDetailPlaceholder(id: id)
        case .categoryListing(let id, let name):
            CustomerCategoryListingPlaceholder(id: id, name: name)
        case .nearbyMap:
            PlaceholderScreen(title: "Nearby Map")
        case .createReservation(let serviceId):
            CustomerCreateReservationPlaceholder(serviceId: serviceId)
        case .reservationDetail(let id):
            CustomerReservationDetailPlaceholder(id: id)
        case .reservationSuccess(let id, let isAutoConfirmed):
            CustomerReservationSuccessPlaceholder(id: id, isAutoConfirmed: isAutoConfirmed)
        case .qrScan(let reservationId):
            CustomerQRScanPlaceholder(reservationId: reservationId)
        case .createReview(let reservationId):
            CustomerCreateReviewPlaceholder(reservationId: reservationId)
        case .settings:
            SettingsScreen()
        case .penaltySummary:
            PlaceholderScreen(title: "Penalty Summary")
        case .searchResults(let query):
            CustomerSearchResultsPlaceholder(query: query)
        default:
            EmptyView()
        }
    }
}

// MARK: - Route placeholder screens for customer navigation

private struct CustomerServiceDetailPlaceholder: View {
    let id: String
    var body: some View { PlaceholderScreen(title: "Service") }
}
private struct CustomerBrandDetailPlaceholder: View {
    let id: String
    var body: some View { PlaceholderScreen(title: "Brand") }
}
private struct CustomerProviderDetailPlaceholder: View {
    let id: String
    var body: some View { PlaceholderScreen(title: "Provider") }
}
private struct CustomerCategoryListingPlaceholder: View {
    let id: String; let name: String
    var body: some View { PlaceholderScreen(title: name) }
}
private struct CustomerCreateReservationPlaceholder: View {
    let serviceId: String
    var body: some View { PlaceholderScreen(title: "Book Service") }
}
private struct CustomerReservationDetailPlaceholder: View {
    let id: String
    var body: some View { PlaceholderScreen(title: "Reservation") }
}
private struct CustomerReservationSuccessPlaceholder: View {
    let id: String; let isAutoConfirmed: Bool
    var body: some View { PlaceholderScreen(title: "Booking Confirmed") }
}
private struct CustomerQRScanPlaceholder: View {
    let reservationId: String
    var body: some View { PlaceholderScreen(title: "Scan QR") }
}
private struct CustomerCreateReviewPlaceholder: View {
    let reservationId: String
    var body: some View { PlaceholderScreen(title: "Leave Review") }
}
private struct CustomerSearchResultsPlaceholder: View {
    let query: String?
    var body: some View { PlaceholderScreen(title: "Results") }
}
