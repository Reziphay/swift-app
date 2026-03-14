import SwiftUI

struct RZSegmentedControl: View {
    let items: [String]
    @Binding var selected: Int

    var body: some View {
        HStack(spacing: RZSpacing.xxxs) {
            ForEach(items.indices, id: \.self) { index in
                Button {
                    withAnimation(.easeInOut(duration: RZDuration.smallTransition)) {
                        selected = index
                    }
                } label: {
                    Text(items[index])
                        .font(.rzLabel)
                        .fontWeight(selected == index ? .semibold : .regular)
                        .foregroundStyle(selected == index ? .rzPrimary : .rzTextSecondary)
                        .padding(.horizontal, RZSpacing.xs)
                        .padding(.vertical, RZSpacing.xxs)
                        .frame(maxWidth: .infinity)
                        .background(
                            selected == index
                                ? Color.rzPrimary.opacity(0.1)
                                : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: RZRadius.sm))
                }
            }
        }
        .padding(RZSpacing.xxxs)
        .background(Color.rzInputBackground)
        .clipShape(RoundedRectangle(cornerRadius: RZRadius.md))
    }
}
