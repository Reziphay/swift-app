import SwiftUI

enum RZShadow {
    static let sm = ShadowStyle(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    static let md = ShadowStyle(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    static let lg = ShadowStyle(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
}

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

extension View {
    func rzShadow(_ style: ShadowStyle) -> some View {
        self.shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}
