import SwiftUI

struct WelcomeScreen: View {
    let onLogin: () -> Void
    let onRegister: () -> Void

    var body: some View {
        ZStack {
            Color.rzBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Brand mark
                VStack(spacing: RZSpacing.xs) {
                    Text("Reziphay")
                        .font(.rzDisplay)
                        .foregroundStyle(.rzPrimary)

                    Text("Book services. Manage your business.")
                        .font(.rzBodyLarge)
                        .foregroundStyle(.rzTextSecondary)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                // Action buttons
                VStack(spacing: RZSpacing.xs) {
                    RZButton(title: "I'm a Customer", variant: .primary, size: .large, isFullWidth: true) {
                        onRegister()
                    }

                    RZButton(title: "I'm a Service Provider", variant: .secondary, size: .large, isFullWidth: true) {
                        onRegister()
                    }

                    RZButton(title: "Sign in", variant: .ghost, size: .large, isFullWidth: true) {
                        onLogin()
                    }
                }
                .padding(.horizontal, RZSpacing.screenHorizontal)

                // Legal caption
                Text("By continuing you agree to our Terms of Service and Privacy Policy.")
                    .font(.rzCaption)
                    .foregroundStyle(.rzTextTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, RZSpacing.xl)
                    .padding(.top, RZSpacing.md)
                    .padding(.bottom, RZSpacing.xl)
            }
        }
        .navigationBarHidden(true)
    }
}
