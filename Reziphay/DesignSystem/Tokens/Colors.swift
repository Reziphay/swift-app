import SwiftUI

extension Color {
    static let rzPrimary = Color(hex: "9989FF")
    static let rzSecondary = Color(hex: "A89AFE")
    static let rzBlack = Color(hex: "1E1E1E")
    static let rzWhite = Color(hex: "FDFDFD")

    static let rzSuccess = Color(hex: "1FA971")
    static let rzWarning = Color(hex: "E8A317")
    static let rzError = Color(hex: "D84C4C")

    static let rzBackground = Color.rzWhite
    static let rzSurface = Color.white
    static let rzTextPrimary = Color.rzBlack
    static let rzTextSecondary = Color(hex: "6B6B6B")
    static let rzTextTertiary = Color(hex: "9E9E9E")
    static let rzBorder = Color(hex: "E5E5E5")
    static let rzDivider = Color(hex: "F0F0F0")
    static let rzInputBackground = Color(hex: "F7F7F7")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
