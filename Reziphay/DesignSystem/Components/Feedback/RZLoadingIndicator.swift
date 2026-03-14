import SwiftUI

struct RZLoadingIndicator: View {
    var message: String? = nil
    var color: Color = .rzPrimary

    var body: some View {
        VStack(spacing: RZSpacing.xs) {
            ProgressView()
                .tint(color)
            if let message {
                Text(message)
                    .font(.rzBodySmall)
                    .foregroundStyle(.rzTextSecondary)
            }
        }
    }
}

struct RZFullScreenLoader: View {
    var message: String? = nil

    var body: some View {
        ZStack {
            Color.rzBackground.ignoresSafeArea()
            RZLoadingIndicator(message: message)
        }
    }
}
