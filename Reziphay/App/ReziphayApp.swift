import SwiftUI

@main
struct ReziphayApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .rzToast($appState.toast)
        }
    }
}

struct RootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            switch appState.router.screen {
            case .splash:
                SplashScreen()
            case .auth:
                AuthFlowView()
            case .suspended(let until):
                AccountSuspendedScreen(suspendedUntil: until)
            case .closed:
                AccountClosedScreen()
            case .main:
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: RZDuration.pageTransition), value: screenKey)
    }

    private var screenKey: String {
        switch appState.router.screen {
        case .splash: "splash"
        case .auth: "auth"
        case .suspended: "suspended"
        case .closed: "closed"
        case .main: "main"
        }
    }
}

struct AuthFlowView: View {
    @State private var showLogin = false
    @State private var showRegister = false

    var body: some View {
        NavigationStack {
            WelcomeScreen(
                onLogin: { showLogin = true },
                onRegister: { showRegister = true }
            )
            .navigationDestination(isPresented: $showLogin) {
                LoginScreen()
            }
            .navigationDestination(isPresented: $showRegister) {
                RegisterScreen()
            }
        }
    }
}

struct MainTabView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        if appState.isCustomer {
            CustomerTabView()
        } else {
            ProviderTabView()
        }
    }
}
