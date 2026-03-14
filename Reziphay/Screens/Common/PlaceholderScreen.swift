import SwiftUI

/// Generic placeholder used by tab shells until real screens are implemented.
struct PlaceholderScreen: View {
    let title: String

    var body: some View {
        ZStack {
            Color.rzBackground.ignoresSafeArea()
            VStack(spacing: RZSpacing.xs) {
                Image(systemName: "hammer.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.rzTextTertiary)
                Text(title)
                    .font(.rzH3)
                    .foregroundStyle(.rzTextSecondary)
                Text("Coming soon")
                    .font(.rzBody)
                    .foregroundStyle(.rzTextTertiary)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Stubs for screens referenced by tab shells but not yet implemented
