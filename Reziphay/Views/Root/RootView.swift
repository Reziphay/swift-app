// RootView.swift
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            switch appState.authState {
            case .loading:
                SplashView()

            case .unauthenticated:
                OnboardingView()
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .opacity
                    ))

            case .needsRegistration(let phone):
                NavigationStack {
                    RegisterView(phone: phone)
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .opacity
                ))

            case .authenticated:
                MainTabView()
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .opacity
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: animationKey)
    }

    private var animationKey: String {
        switch appState.authState {
        case .loading: return "loading"
        case .unauthenticated: return "unauth"
        case .needsRegistration: return "register"
        case .authenticated: return "auth"
        }
    }
}

// MARK: - Splash View

private struct SplashView: View {
    @State private var opacity = 0.0
    @State private var scale = 0.85

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.04, blue: 0.15)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.reziphayPrimary.opacity(0.15))
                        .frame(width: 88, height: 88)
                    Image(systemName: "calendar.badge.checkmark")
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(Color.reziphayPrimaryLight)
                }

                Text("Reziphay")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .opacity(opacity)
            .scaleEffect(scale)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                opacity = 1.0
                scale = 1.0
            }
        }
    }
}
