import SwiftUI

struct RZCard<Content: View>: View {
    var padding: CGFloat = RZSpacing.sm
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(padding)
        .background(Color.rzSurface)
        .clipShape(RoundedRectangle(cornerRadius: RZRadius.card))
        .rzShadow(RZShadow.sm)
    }
}
