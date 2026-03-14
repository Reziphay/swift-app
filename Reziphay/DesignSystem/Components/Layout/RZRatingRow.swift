import SwiftUI

struct RZRatingRow: View {
    let rating: Double
    var reviewCount: Int? = nil
    var size: CGFloat = 14

    var body: some View {
        HStack(spacing: RZSpacing.xxxs) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: starImageName(for: index))
                    .font(.system(size: size))
                    .foregroundStyle(.rzWarning)
            }

            Text(String(format: "%.1f", rating))
                .font(.rzLabel)
                .foregroundStyle(.rzTextPrimary)

            if let reviewCount {
                Text("(\(reviewCount))")
                    .font(.rzCaption)
                    .foregroundStyle(.rzTextTertiary)
            }
        }
    }

    private func starImageName(for index: Int) -> String {
        let value = Double(index)
        if rating >= value { return "star.fill" }
        if rating >= value - 0.5 { return "star.leadinghalf.filled" }
        return "star"
    }
}
