import SwiftUI

struct RZAvatarView: View {
    var name: String
    var imageURL: URL? = nil
    var size: CGFloat = 48

    var body: some View {
        Group {
            if let imageURL {
                AsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    initialsView
                }
            } else {
                initialsView
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var initialsView: some View {
        ZStack {
            Color.rzPrimary.opacity(0.15)
            Text(initials)
                .font(.system(size: size * 0.36, weight: .semibold))
                .foregroundStyle(.rzPrimary)
        }
    }

    private var initials: String {
        let parts = name.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last = parts.count > 1 ? parts.last!.prefix(1) : ""
        return "\(first)\(last)".uppercased()
    }
}
