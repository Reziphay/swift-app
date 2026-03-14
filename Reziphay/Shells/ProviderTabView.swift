import SwiftUI

struct ProviderTabView: View {
    @Environment(AppState.self) private var appState

    private let tabs: [RZTabItem] = [
        RZTabItem(id: "dashboard",    title: "Dashboard",   icon: "chart.bar",      activeIcon: "chart.bar.fill"),
        RZTabItem(id: "reservations", title: "Bookings",    icon: "calendar",       activeIcon: "calendar"),
        RZTabItem(id: "services",     title: "Services",    icon: "scissors",       activeIcon: "scissors"),
        RZTabItem(id: "brands",       title: "Brands",      icon: "building.2",     activeIcon: "building.2.fill"),
        RZTabItem(id: "profile",      title: "Profile",     icon: "person",         activeIcon: "person.fill"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            RZTabBar(
                tabs: tabs,
                selected: Binding(
                    get: { appState.router.selectedProviderTab },
                    set: { appState.router.selectedProviderTab = $0 }
                )
            )
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Tab content

    @ViewBuilder
    private var tabContent: some View {
        let selected = appState.router.selectedProviderTab

        Group {
            if selected == "dashboard" {
                NavigationStack(path: providerPath) {
                    ProviderDashboardScreen()
                        .navigationDestination(for: Route.self, destination: providerDestination)
                }
            } else if selected == "reservations" {
                NavigationStack(path: providerPath) {
                    ProviderReservationsListScreen()
                        .navigationDestination(for: Route.self, destination: providerDestination)
                }
            } else if selected == "services" {
                NavigationStack(path: providerPath) {
                    ServicesListScreen()
                        .navigationDestination(for: Route.self, destination: providerDestination)
                }
            } else if selected == "brands" {
                NavigationStack(path: providerPath) {
                    BrandListScreen()
                        .navigationDestination(for: Route.self, destination: providerDestination)
                }
            } else {
                NavigationStack(path: providerPath) {
                    ProfileScreen()
                        .navigationDestination(for: Route.self, destination: providerDestination)
                }
            }
        }
    }

    private var providerPath: Binding<NavigationPath> {
        Binding(
            get: { appState.router.providerPath },
            set: { appState.router.providerPath = $0 }
        )
    }

    // MARK: - Navigation destinations

    @ViewBuilder
    private func providerDestination(for route: Route) -> some View {
        switch route {
        case .serviceDetail(let id):
            ProviderServiceDetailPlaceholder(id: id)
        case .brandDetail(let id):
            ProviderBrandDetailPlaceholder(id: id)
        case .providerDetail(let id):
            ProviderProviderDetailPlaceholder(id: id)
        case .reservationDetail(let id):
            ProviderReservationDetailPlaceholder(id: id)
        case .qrScan(let reservationId):
            ProviderQRScanPlaceholder(reservationId: reservationId)
        case .providerQR:
            PlaceholderScreen(title: "My QR Code")
        case .createBrand:
            PlaceholderScreen(title: "Create Brand")
        case .editBrand(let id):
            ProviderEditBrandPlaceholder(id: id)
        case .brandManage(let id):
            ProviderBrandManagePlaceholder(id: id)
        case .brandJoinRequests(let id):
            ProviderBrandJoinRequestsPlaceholder(id: id)
        case .createService:
            PlaceholderScreen(title: "Create Service")
        case .editService(let id):
            ProviderEditServicePlaceholder(id: id)
        case .settings:
            SettingsScreen()
        case .penaltySummary:
            PlaceholderScreen(title: "Penalty Summary")
        default:
            EmptyView()
        }
    }
}

// MARK: - Route placeholder screens for provider navigation

private struct ProviderServiceDetailPlaceholder: View {
    let id: String
    var body: some View { PlaceholderScreen(title: "Service") }
}
private struct ProviderBrandDetailPlaceholder: View {
    let id: String
    var body: some View { PlaceholderScreen(title: "Brand") }
}
private struct ProviderProviderDetailPlaceholder: View {
    let id: String
    var body: some View { PlaceholderScreen(title: "Provider") }
}
private struct ProviderReservationDetailPlaceholder: View {
    let id: String
    var body: some View { PlaceholderScreen(title: "Reservation") }
}
private struct ProviderQRScanPlaceholder: View {
    let reservationId: String
    var body: some View { PlaceholderScreen(title: "Scan QR") }
}
private struct ProviderEditBrandPlaceholder: View {
    let id: String
    var body: some View { PlaceholderScreen(title: "Edit Brand") }
}
private struct ProviderBrandManagePlaceholder: View {
    let id: String
    var body: some View { PlaceholderScreen(title: "Manage Brand") }
}
private struct ProviderBrandJoinRequestsPlaceholder: View {
    let id: String
    var body: some View { PlaceholderScreen(title: "Join Requests") }
}
private struct ProviderEditServicePlaceholder: View {
    let id: String
    var body: some View { PlaceholderScreen(title: "Edit Service") }
}
