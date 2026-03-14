import SwiftUI

struct RZOTPField: View {
    @Binding var code: String
    let length: Int
    var error: String? = nil

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: RZSpacing.xs) {
            HStack(spacing: RZSpacing.xxs) {
                ForEach(0..<length, id: \.self) { index in
                    let char = index < code.count
                        ? String(code[code.index(code.startIndex, offsetBy: index)])
                        : ""

                    Text(char)
                        .font(.rzH2)
                        .foregroundStyle(.rzTextPrimary)
                        .frame(width: 48, height: 56)
                        .background(Color.rzInputBackground)
                        .clipShape(RoundedRectangle(cornerRadius: RZRadius.sm))
                        .overlay {
                            RoundedRectangle(cornerRadius: RZRadius.sm)
                                .strokeBorder(
                                    index == code.count && isFocused ? Color.rzPrimary :
                                    error != nil ? Color.rzError : Color.clear,
                                    lineWidth: 1.5
                                )
                        }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { isFocused = true }
            .background {
                TextField("", text: $code)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .focused($isFocused)
                    .opacity(0)
                    .onChange(of: code) { _, newValue in
                        code = String(newValue.prefix(length)).filter(\.isNumber)
                    }
            }

            if let error {
                Text(error)
                    .font(.rzCaption)
                    .foregroundStyle(.rzError)
            }
        }
    }
}
