// LanguageManager.swift
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import SwiftUI

// MARK: - Supported Language

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    // Future languages — uncomment when Localizable.strings are added:
    // case azerbaijani = "az"
    // case russian    = "ru"
    // case turkish    = "tr"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: return "English"
        }
    }

    var flag: String {
        switch self {
        case .english: return "🇬🇧"
        }
    }
}

// MARK: - Language Manager

@MainActor
@Observable
final class LanguageManager {

    static let shared = LanguageManager()

    private let storageKey = "reziphay_app_language"

    var currentLanguage: AppLanguage {
        didSet {
            guard oldValue != currentLanguage else { return }
            persist()
            applyToSystem()
        }
    }

    private init() {
        let saved  = UserDefaults.standard.string(forKey: "reziphay_app_language") ?? "en"
        currentLanguage = AppLanguage(rawValue: saved) ?? .english
        applyToSystem()
    }

    // MARK: - Private

    private func persist() {
        UserDefaults.standard.set(currentLanguage.rawValue, forKey: storageKey)
    }

    /// Tells the system which language to use for bundle lookups.
    /// Takes effect after the next app cold-start (standard iOS behaviour).
    private func applyToSystem() {
        UserDefaults.standard.set([currentLanguage.rawValue], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
    }
}
