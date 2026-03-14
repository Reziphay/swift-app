import SwiftUI

struct RZSkeletonView: View {
    var width: CGFloat? = nil
    var height: CGFloat = 16
    var radius: CGFloat = RZRadius.sm

    @State private var isAnimating = false

    var body: some View {
        RoundedRectangle(cornerRadius: radius)
            .fill(Color.rzBorder)
            .frame(width: width, height: height)
            .opacity(isAnimating ? 0.4 : 0.8)
            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
            .onAppear { isAnimating = true }
    }
}

struct RZSkeletonCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: RZSpacing.xs) {
            RZSkeletonView(height: 140, radius: RZRadius.card)
            RZSkeletonView(width: 180, height: 16)
            RZSkeletonView(width: 120, height: 12)
            HStack {
                RZSkeletonView(width: 60, height: 12)
                Spacer()
                RZSkeletonView(width: 40, height: 12)
            }
        }
        .padding(RZSpacing.xs)
        .background(Color.rzSurface)
        .clipShape(RoundedRectangle(cornerRadius: RZRadius.card))
        .rzShadow(RZShadow.sm)
    }
}

struct RZSkeletonListRow: View {
    var body: some View {
        HStack(spacing: RZSpacing.xs) {
            RZSkeletonView(width: 48, height: 48, radius: RZRadius.sm)
            VStack(alignment: .leading, spacing: RZSpacing.xxxs) {
                RZSkeletonView(width: 160, height: 14)
                RZSkeletonView(width: 100, height: 12)
            }
            Spacer()
        }
        .padding(.vertical, RZSpacing.xxs)
    }
}
