import SwiftUI

struct RZSectionHeader: View {
    let title: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.rzH4)
                .foregroundStyle(.rzTextPrimary)

            Spacer()

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.rzLabel)
                        .foregroundStyle(.rzPrimary)
                }
            }
        }
    }
}
