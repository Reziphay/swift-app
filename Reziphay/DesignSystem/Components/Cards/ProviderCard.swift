import SwiftUI

struct ProviderCard: View {
    let provider: ProviderProfile
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button { onTap?() } label: {
            HStack(spacing: RZSpacing.xs) {
                RZAvatarView(name: provider.fullName, size: 48)

                VStack(alignment: .leading, spacing: RZSpacing.xxxs) {
                    Text(provider.fullName)
                        .font(.rzBody)
                        .fontWeight(.semibold)
                        .foregroundStyle(.rzTextPrimary)
                        .lineLimit(1)

                    if let brandNames = provider.brandNames, !brandNames.isEmpty {
                        Text(brandNames.joined(separator: ", "))
                            .font(.rzBodySmall)
                            .foregroundStyle(.rzTextSecondary)
                            .lineLimit(1)
                    }

                    if let stats = provider.ratingStats {
                        RZRatingRow(rating: stats.avgRating, reviewCount: stats.reviewCount, size: 11)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.rzTextTertiary)
            }
            .padding(RZSpacing.sm)
            .background(Color.rzSurface)
            .clipShape(RoundedRectangle(cornerRadius: RZRadius.card))
            .rzShadow(RZShadow.sm)
        }
        .buttonStyle(.plain)
    }
}
