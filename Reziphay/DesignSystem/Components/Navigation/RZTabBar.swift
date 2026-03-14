import SwiftUI

struct RZTabItem: Identifiable, Hashable {
    let id: String
    let title: String
    let icon: String
    let activeIcon: String

    init(id: String, title: String, icon: String, activeIcon: String? = nil) {
        self.id = id
        self.title = title
        self.icon = icon
        self.activeIcon = activeIcon ?? icon
    }
}

struct RZTabBar: View {
    let tabs: [RZTabItem]
    @Binding var selected: String

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs) { tab in
                Button {
                    withAnimation(.easeInOut(duration: RZDuration.tap)) {
                        selected = tab.id
                    }
                } label: {
                    VStack(spacing: RZSpacing.xxxs) {
                        Image(systemName: selected == tab.id ? tab.activeIcon : tab.icon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(selected == tab.id ? .rzPrimary : .rzTextTertiary)

                        Text(tab.title)
                            .font(.rzCaption)
                            .foregroundStyle(selected == tab.id ? .rzPrimary : .rzTextTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, RZSpacing.xxs)
                    .padding(.bottom, RZSpacing.xxxs)
                }
            }
        }
        .background {
            Rectangle()
                .fill(Color.rzSurface)
                .shadow(color: .black.opacity(0.04), radius: 8, y: -2)
                .ignoresSafeArea(edges: .bottom)
        }
    }
}
