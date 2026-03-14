import SwiftUI

struct RZTopBar<Leading: View, Trailing: View>: View {
    let title: String
    @ViewBuilder var leading: Leading
    @ViewBuilder var trailing: Trailing

    init(
        title: String,
        @ViewBuilder leading: () -> Leading = { EmptyView() },
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.leading = leading()
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: RZSpacing.xs) {
            leading
                .frame(width: 44)

            Spacer()

            Text(title)
                .font(.rzH4)
                .foregroundStyle(.rzTextPrimary)
                .lineLimit(1)

            Spacer()

            trailing
                .frame(width: 44)
        }
        .frame(height: 44)
        .padding(.horizontal, RZSpacing.xs)
    }
}
