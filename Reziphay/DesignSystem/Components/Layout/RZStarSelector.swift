import SwiftUI

struct RZStarSelector: View {
    @Binding var rating: Int
    var maxRating: Int = 5
    var size: CGFloat = 32

    var body: some View {
        HStack(spacing: RZSpacing.xxs) {
            ForEach(1...maxRating, id: \.self) { index in
                Image(systemName: index <= rating ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundStyle(index <= rating ? .rzWarning : .rzBorder)
                    .onTapGesture { rating = index }
            }
        }
    }
}
