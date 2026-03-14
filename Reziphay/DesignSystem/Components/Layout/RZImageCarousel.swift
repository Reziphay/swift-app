import SwiftUI

struct RZImageCarousel: View {
    let imageURLs: [URL]
    var height: CGFloat = 240

    @State private var currentPage = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $currentPage) {
                if imageURLs.isEmpty {
                    placeholderView
                        .tag(0)
                } else {
                    ForEach(imageURLs.indices, id: \.self) { index in
                        AsyncImage(url: imageURLs[index]) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            RZSkeletonView(height: height, radius: 0)
                        }
                        .tag(index)
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: height)

            if imageURLs.count > 1 {
                HStack(spacing: RZSpacing.xxxs) {
                    ForEach(imageURLs.indices, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.white : Color.white.opacity(0.5))
                            .frame(width: 6, height: 6)
                    }
                }
                .padding(.bottom, RZSpacing.xs)
            }
        }
    }

    private var placeholderView: some View {
        ZStack {
            Color.rzInputBackground
            Image(systemName: "photo")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.rzTextTertiary)
        }
    }
}
