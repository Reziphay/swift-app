import SwiftUI

struct RZTextArea: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var error: String? = nil
    var maxLength: Int? = nil
    var minHeight: CGFloat = 100

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: RZSpacing.xxxs) {
            HStack {
                Text(label)
                    .font(.rzLabel)
                    .foregroundStyle(.rzTextSecondary)
                Spacer()
                if let maxLength {
                    Text("\(text.count)/\(maxLength)")
                        .font(.rzCaption)
                        .foregroundStyle(.rzTextTertiary)
                }
            }

            TextEditor(text: $text)
                .font(.rzBody)
                .frame(minHeight: minHeight)
                .padding(RZSpacing.xxs)
                .scrollContentBackground(.hidden)
                .background(Color.rzInputBackground)
                .clipShape(RoundedRectangle(cornerRadius: RZRadius.input))
                .overlay {
                    RoundedRectangle(cornerRadius: RZRadius.input)
                        .strokeBorder(borderColor, lineWidth: 1)
                }
                .focused($isFocused)
                .overlay(alignment: .topLeading) {
                    if text.isEmpty {
                        Text(placeholder)
                            .font(.rzBody)
                            .foregroundStyle(.rzTextTertiary)
                            .padding(.horizontal, RZSpacing.xs)
                            .padding(.vertical, RZSpacing.xs)
                            .allowsHitTesting(false)
                    }
                }
                .onChange(of: text) { _, newValue in
                    if let maxLength, newValue.count > maxLength {
                        text = String(newValue.prefix(maxLength))
                    }
                }

            if let error {
                Text(error)
                    .font(.rzCaption)
                    .foregroundStyle(.rzError)
            }
        }
    }

    private var borderColor: Color {
        if error != nil { return .rzError }
        if isFocused { return .rzPrimary }
        return .clear
    }
}
