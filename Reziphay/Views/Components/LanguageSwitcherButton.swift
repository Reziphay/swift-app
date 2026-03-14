// LanguageSwitcherButton.swift
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import SwiftUI

// MARK: - Language Switcher Button

struct LanguageSwitcherButton: View {

    @Environment(LanguageManager.self) private var languageManager
    @State private var showPicker = false

    var body: some View {
        Button { showPicker = true } label: { label }
            .confirmationDialog(
                "Select Language",
                isPresented: $showPicker,
                titleVisibility: .visible
            ) {
                ForEach(AppLanguage.allCases) { language in
                    Button("\(language.flag)  \(language.displayName)") {
                        languageManager.currentLanguage = language
                    }
                }
            }
    }

    // MARK: - Label

    private var label: some View {
        HStack(spacing: 5) {
            Text(languageManager.currentLanguage.flag)
                .font(.system(size: 15))

            Text(languageManager.currentLanguage.rawValue.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))

            Image(systemName: "chevron.down")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white.opacity(0.45))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(.white.opacity(0.08))
                .overlay(Capsule().stroke(.white.opacity(0.12), lineWidth: 1))
        )
    }
}
