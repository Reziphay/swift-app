import SwiftUI

struct NotFoundScreen: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.rzBackground.ignoresSafeArea()

            VStack(spacing: RZSpacing.xl) {
                Spacer()

                // Icon
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 80, weight: .light))
                    .foregroundStyle(Color.rzTextTertiary)

                // Text
                VStack(spacing: RZSpacing.xs) {
                    Text("Not Found")
                        .font(.rzH2)
                        .foregroundStyle(.rzTextPrimary)

                    Text("The page or content you're looking for doesn't exist.")
                        .font(.rzBody)
                        .foregroundStyle(.rzTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, RZSpacing.xl)
                }

                Spacer()

                // Actions
                VStack(spacing: RZSpacing.xs) {
                    RZButton(
                        title: "Go Home",
                        variant: .primary,
                        size: .large,
                        isFullWidth: true
                    ) {
                        appState.router.popToRoot(forRole: .ucr)
                    }

                    RZButton(
                        title: "Go Back",
                        variant: .ghost,
                        size: .large,
                        isFullWidth: true
                    ) {
                        dismiss()
                    }
                }
                .padding(.horizontal, RZSpacing.screenHorizontal)
                .padding(.bottom, RZSpacing.xl)
            }
        }
        .navigationBarHidden(true)
    }
}
