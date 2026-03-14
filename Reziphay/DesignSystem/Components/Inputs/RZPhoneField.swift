import SwiftUI

struct RZPhoneField: View {
    let label: String
    @Binding var phone: String
    var error: String? = nil

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: RZSpacing.xxxs) {
            Text(label)
                .font(.rzLabel)
                .foregroundStyle(.rzTextSecondary)

            HStack(spacing: RZSpacing.xxs) {
                Image(systemName: "phone.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.rzTextTertiary)
                    .frame(width: 24)

                TextField("Phone number", text: $phone)
                    .keyboardType(.phonePad)
                    .font(.rzBodyLarge)
                    .focused($isFocused)
            }
            .padding(.horizontal, RZSpacing.sm)
            .frame(height: 48)
            .background(Color.rzInputBackground)
            .clipShape(RoundedRectangle(cornerRadius: RZRadius.input))
            .overlay {
                RoundedRectangle(cornerRadius: RZRadius.input)
                    .strokeBorder(borderColor, lineWidth: 1)
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
