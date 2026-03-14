import SwiftUI

struct ReviewCard: View {
    let review: Review
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button { onTap?() } label: {
            VStack(alignment: .leading, spacing: RZSpacing.xxs) {
                HStack {
                    RZAvatarView(name: review.authorName ?? "User", size: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(review.authorName ?? "User")
                            .font(.rzBodySmall)
                            .fontWeight(.semibold)
                            .foregroundStyle(.rzTextPrimary)

                        RZRatingRow(rating: Double(review.rating), size: 10)
                    }

                    Spacer()

                    Text(review.formattedDate)
                        .font(.rzCaption)
                        .foregroundStyle(.rzTextTertiary)
                }

                Text(review.comment)
                    .font(.rzBody)
                    .foregroundStyle(.rzTextPrimary)
                    .lineLimit(3)

                if let reply = review.reply {
                    VStack(alignment: .leading, spacing: RZSpacing.xxxs) {
                        Text("Provider reply")
                            .font(.rzCaption)
                            .foregroundStyle(.rzTextTertiary)
                        Text(reply.comment)
                            .font(.rzBodySmall)
                            .foregroundStyle(.rzTextSecondary)
                            .lineLimit(2)
                    }
                    .padding(RZSpacing.xxs)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.rzInputBackground)
                    .clipShape(RoundedRectangle(cornerRadius: RZRadius.sm))
                }
            }
            .padding(RZSpacing.sm)
            .background(Color.rzSurface)
            .clipShape(RoundedRectangle(cornerRadius: RZRadius.card))
            .rzShadow(RZShadow.sm)
        }
        .buttonStyle(.plain)
    }
}
