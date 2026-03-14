import Foundation

@Observable
final class AppState {
    let apiClient: APIClient
    let authManager: AuthManager
    let router: AppRouter
    var toast: ToastData?
    var unreadNotificationCount: Int = 0

    init() {
        let apiClient = APIClient()
        self.apiClient = apiClient
        self.authManager = AuthManager(apiClient: apiClient)
        self.router = AppRouter()
    }

    var activeRole: AppRole {
        authManager.activeRole
    }

    var isCustomer: Bool { activeRole == .ucr }
    var isProvider: Bool { activeRole == .uso }

    func showToast(_ message: String, type: RZToastType = .info) {
        toast = ToastData(message: message, type: type)
    }

    func bootstrap() async {
        await authManager.restoreSession()

        if authManager.isAuthenticated {
            guard let user = authManager.currentUser else {
                router.navigateToAuth()
                return
            }
            switch user.status {
            case .active:
                router.navigateToMain()
            case .suspended:
                router.navigateToSuspended(until: user.suspendedUntil)
            case .closed:
                router.navigateToClosed()
            }
        } else {
            router.navigateToAuth()
        }
    }

    func handleLogin() async {
        guard let user = authManager.currentUser else { return }
        switch user.status {
        case .active:
            router.navigateToMain()
        case .suspended:
            router.navigateToSuspended(until: user.suspendedUntil)
        case .closed:
            router.navigateToClosed()
        }
    }

    func handleLogout() async {
        await authManager.logout()
        router.navigateToAuth()
    }

    func handleRoleSwitch(to role: AppRole) async throws {
        try await authManager.switchRole(to: role)
        router.popToRoot(forRole: role)
    }
}
