import SwiftUI

struct RZBottomSheet<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    var onDismiss: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.rzBorder)
                .frame(width: 36, height: 5)
                .padding(.top, RZSpacing.xxs)

            // Header
            HStack {
                Text(title)
                    .font(.rzH4)
                    .foregroundStyle(.rzTextPrimary)

                Spacer()

                if let onDismiss {
                    RZIconButton(icon: "xmark", size: 32) {
                        onDismiss()
                    }
                }
            }
            .padding(.horizontal, RZSpacing.screenHorizontal)
            .padding(.top, RZSpacing.sm)
            .padding(.bottom, RZSpacing.xs)

            Divider()

            // Content
            ScrollView {
                content
                    .padding(.horizontal, RZSpacing.screenHorizontal)
                    .padding(.top, RZSpacing.sm)
                    .padding(.bottom, RZSpacing.xxl)
            }
        }
    }
}
