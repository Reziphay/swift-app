import SwiftUI

enum AppScreen {
    case splash
    case auth
    case suspended(until: String?)
    case closed
    case main
}

@Observable
final class AppRouter {
    var screen: AppScreen = .splash
    var customerPath = NavigationPath()
    var providerPath = NavigationPath()
    var selectedCustomerTab = "home"
    var selectedProviderTab = "dashboard"

    func navigateToMain() {
        screen = .main
    }

    func navigateToAuth() {
        screen = .auth
        customerPath = NavigationPath()
        providerPath = NavigationPath()
    }

    func navigateToSuspended(until: String?) {
        screen = .suspended(until: until)
    }

    func navigateToClosed() {
        screen = .closed
    }

    func push(_ route: Route, forRole role: AppRole) {
        switch role {
        case .ucr:
            customerPath.append(route)
        case .uso, .admin:
            providerPath.append(route)
        }
    }

    func popToRoot(forRole role: AppRole) {
        switch role {
        case .ucr:
            customerPath = NavigationPath()
        case .uso, .admin:
            providerPath = NavigationPath()
        }
    }
}
