import SwiftUI

struct BrandCard: View {
    let brand: Brand
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button { onTap?() } label: {
            HStack(spacing: RZSpacing.xs) {
                // Logo
                if let logoURL = brand.logoURL {
                    AsyncImage(url: logoURL) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        RZSkeletonView(width: 56, height: 56, radius: RZRadius.sm)
                    }
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: RZRadius.sm))
                } else {
                    RZAvatarView(name: brand.name, size: 56)
                }

                VStack(alignment: .leading, spacing: RZSpacing.xxxs) {
                    Text(brand.name)
                        .font(.rzBody)
                        .fontWeight(.semibold)
                        .foregroundStyle(.rzTextPrimary)
                        .lineLimit(1)

                    if let description = brand.description {
                        Text(description)
                            .font(.rzBodySmall)
                            .foregroundStyle(.rzTextSecondary)
                            .lineLimit(2)
                    }

                    if let stats = brand.ratingStats {
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
