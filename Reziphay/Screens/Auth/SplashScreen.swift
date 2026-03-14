import SwiftUI

struct SplashScreen: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            Color.rzBackground
                .ignoresSafeArea()

            VStack(spacing: RZSpacing.lg) {
                Text("Reziphay")
                    .font(.rzH1)
                    .foregroundStyle(.rzPrimary)

                ProgressView()
                    .tint(.rzSecondary)
                    .scaleEffect(0.9)
            }
        }
        .task {
            await appState.bootstrap()
        }
    }
}
