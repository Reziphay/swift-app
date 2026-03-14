import SwiftUI

struct RZTimelineItem: View {
    let title: String
    let subtitle: String?
    let timestamp: String
    var isLast: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: RZSpacing.xs) {
            VStack(spacing: 0) {
                Circle()
                    .fill(Color.rzPrimary)
                    .frame(width: 10, height: 10)
                    .padding(.top, 4)

                if !isLast {
                    Rectangle()
                        .fill(Color.rzBorder)
                        .frame(width: 1)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 10)

            VStack(alignment: .leading, spacing: RZSpacing.xxxs) {
                Text(title)
                    .font(.rzBody)
                    .foregroundStyle(.rzTextPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(.rzBodySmall)
                        .foregroundStyle(.rzTextSecondary)
                }

                Text(timestamp)
                    .font(.rzCaption)
                    .foregroundStyle(.rzTextTertiary)
            }
            .padding(.bottom, isLast ? 0 : RZSpacing.sm)
        }
    }
}
