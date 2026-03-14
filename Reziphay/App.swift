// App.swift
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import SwiftUI

@main
struct ReziphayApp: App {
    @State private var appState       = AppState.shared
    @State private var languageManager = LanguageManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(languageManager)
                .task {
                    await appState.bootstrap()
                }
        }
    }
}
