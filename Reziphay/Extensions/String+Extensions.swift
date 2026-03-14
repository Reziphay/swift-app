import Foundation

extension String {
    var isValidEmail: Bool {
        let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return range(of: pattern, options: .regularExpression) != nil
    }

    var isValidPhone: Bool {
        let digits = filter(\.isNumber)
        return digits.count >= 7 && digits.count <= 15
    }

    var maskedPhone: String {
        guard count > 4 else { return self }
        let visible = suffix(4)
        let masked = String(repeating: "*", count: max(0, count - 4))
        return masked + visible
    }
}
