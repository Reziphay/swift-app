// OnboardingView.swift
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedRole: UserRole?
    @State private var navigateToAuth = false

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient

                VStack(spacing: 0) {
                    Spacer()
                    heroSection
                    Spacer()
                    roleCardsSection
                        .padding(.bottom, 48)
                }
                .padding(.horizontal, 24)
            }
            .ignoresSafeArea()
            .navigationDestination(isPresented: $navigateToAuth) {
                if let role = selectedRole {
                    PhoneEntryView(role: role)
                }
            }
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.06, green: 0.04, blue: 0.15),
                Color(red: 0.10, green: 0.06, blue: 0.22)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.reziphayPrimary.opacity(0.15))
                    .frame(width: 96, height: 96)
                Image(systemName: "calendar.badge.checkmark")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(Color.reziphayPrimaryLight)
            }

            VStack(spacing: 8) {
                Text("Reziphay")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Book smarter, live better")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }

    // MARK: - Role Cards

    private var roleCardsSection: some View {
        VStack(spacing: 16) {
            Text("How would you like to continue?")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
                .padding(.bottom, 4)

            RoleCard(
                icon: "person.crop.circle",
                title: "I'm a Customer",
                subtitle: "Discover and book services near you",
                color: Color(red: 0.29, green: 0.56, blue: 1.0)
            ) {
                selectRole(.ucr)
            }

            RoleCard(
                icon: "briefcase.circle",
                title: "I'm a Service Provider",
                subtitle: "Manage your services and bookings",
                color: Color.reziphayPrimary
            ) {
                selectRole(.uso)
            }
        }
    }

    private func selectRole(_ role: UserRole) {
        selectedRole = role
        appState.selectedRole = role
        navigateToAuth = true
    }
}

// MARK: - Role Card

private struct RoleCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 52, height: 52)
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(.white.opacity(0.55))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(.white.opacity(0.10), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(PressedButtonStyle(isPressed: $isPressed))
    }
}

// MARK: - Pressed Button Style

private struct PressedButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, newValue in
                isPressed = newValue
            }
    }
}
