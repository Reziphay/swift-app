import SwiftUI

struct ServiceCard: View {
    let service: Service
    var distance: Double? = nil
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button { onTap?() } label: {
            VStack(alignment: .leading, spacing: RZSpacing.xxs) {
                // Image
                if let photoURL = service.photoURLs.first {
                    AsyncImage(url: photoURL) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        RZSkeletonView(height: 140, radius: 0)
                    }
                    .frame(height: 140)
                    .clipped()
                } else {
                    ZStack {
                        Color.rzInputBackground
                        Image(systemName: "photo")
                            .font(.system(size: 28, weight: .light))
                            .foregroundStyle(.rzTextTertiary)
                    }
                    .frame(height: 140)
                }

                VStack(alignment: .leading, spacing: RZSpacing.xxxs) {
                    Text(service.name)
                        .font(.rzBody)
                        .fontWeight(.semibold)
                        .foregroundStyle(.rzTextPrimary)
                        .lineLimit(1)

                    if let brandName = service.brand?.name ?? service.ownerName {
                        Text(brandName)
                            .font(.rzBodySmall)
                            .foregroundStyle(.rzTextSecondary)
                            .lineLimit(1)
                    }

                    if let stats = service.ratingStats {
                        RZRatingRow(rating: stats.avgRating, reviewCount: stats.reviewCount, size: 11)
                    }

                    HStack {
                        if let price = service.formattedPrice {
                            Text(price)
                                .font(.rzLabel)
                                .foregroundStyle(.rzTextPrimary)
                        }
                        Spacer()
                        if let distance {
                            Text(formatDistance(distance))
                                .font(.rzCaption)
                                .foregroundStyle(.rzTextTertiary)
                        }
                    }
                }
                .padding(.horizontal, RZSpacing.xs)
                .padding(.bottom, RZSpacing.xs)
            }
            .background(Color.rzSurface)
            .clipShape(RoundedRectangle(cornerRadius: RZRadius.card))
            .rzShadow(RZShadow.sm)
        }
        .buttonStyle(.plain)
    }

    private func formatDistance(_ km: Double) -> String {
        if km < 1 { return "\(Int(km * 1000))m" }
        return String(format: "%.1f km", km)
    }
}
