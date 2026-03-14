// View+Extensions.swift
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import SwiftUI

extension View {
    func primaryButtonStyle() -> some View {
        self.modifier(PrimaryButtonModifier())
    }

    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Button Modifier

struct PrimaryButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Color.reziphayPrimary)
            .foregroundStyle(.white)
            .font(.system(size: 16, weight: .semibold))
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Brand Colors

extension Color {
    static let reziphayPrimary = Color(red: 0.42, green: 0.22, blue: 0.93)
    static let reziphayPrimaryLight = Color(red: 0.58, green: 0.44, blue: 0.97)
    static let reziphayBackground = Color(UIColor.systemBackground)
    static let reziphaySecondaryBackground = Color(UIColor.secondarySystemBackground)
}
