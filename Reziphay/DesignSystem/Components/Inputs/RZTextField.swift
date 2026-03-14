import SwiftUI

struct RZTextField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var helper: String? = nil
    var error: String? = nil
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    var isDisabled: Bool = false
    var autocapitalization: TextInputAutocapitalization = .sentences

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: RZSpacing.xxxs) {
            Text(label)
                .font(.rzLabel)
                .foregroundStyle(.rzTextSecondary)

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .textInputAutocapitalization(autocapitalization)
                }
            }
            .font(.rzBodyLarge)
            .padding(.horizontal, RZSpacing.sm)
            .frame(height: 48)
            .background(Color.rzInputBackground)
            .clipShape(RoundedRectangle(cornerRadius: RZRadius.input))
            .overlay {
                RoundedRectangle(cornerRadius: RZRadius.input)
                    .strokeBorder(borderColor, lineWidth: 1)
            }
            .focused($isFocused)
            .disabled(isDisabled)

            if let error {
                Text(error)
                    .font(.rzCaption)
                    .foregroundStyle(.rzError)
            } else if let helper {
                Text(helper)
                    .font(.rzCaption)
                    .foregroundStyle(.rzTextTertiary)
            }
        }
    }

    private var borderColor: Color {
        if error != nil { return .rzError }
        if isFocused { return .rzPrimary }
        return .clear
    }
}
