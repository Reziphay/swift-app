import SwiftUI

struct RZSearchField: View {
    @Binding var text: String
    var placeholder: String = "Search"
    var onSubmit: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: RZSpacing.xxs) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.rzTextTertiary)

            TextField(placeholder, text: $text)
                .font(.rzBody)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onSubmit { onSubmit?() }

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.rzTextTertiary)
                }
            }
        }
        .padding(.horizontal, RZSpacing.xs)
        .frame(height: 40)
        .background(Color.rzInputBackground)
        .clipShape(RoundedRectangle(cornerRadius: RZRadius.md))
    }
}
