import SwiftUI

struct RZFilterChip: View {
    let title: String
    var isSelected: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.rzLabel)
                .foregroundStyle(isSelected ? .white : .rzTextSecondary)
                .padding(.horizontal, RZSpacing.xs)
                .padding(.vertical, RZSpacing.xxs)
                .background(isSelected ? Color.rzPrimary : Color.rzInputBackground)
                .clipShape(Capsule())
        }
    }
}

struct RZFilterChipRow: View {
    let chips: [String]
    @Binding var selectedIndex: Int?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: RZSpacing.xxs) {
                ForEach(chips.indices, id: \.self) { index in
                    RZFilterChip(
                        title: chips[index],
                        isSelected: selectedIndex == index
                    ) {
                        if selectedIndex == index {
                            selectedIndex = nil
                        } else {
                            selectedIndex = index
                        }
                    }
                }
            }
            .padding(.horizontal, RZSpacing.screenHorizontal)
        }
    }
}
