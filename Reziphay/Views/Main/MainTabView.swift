// MainTabView.swift
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import SwiftUI

struct MainTabView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        TabView {
            ExploreView()
                .tabItem {
                    Label("Explore", systemImage: "magnifyingglass")
                }

            ReservationsPlaceholderView()
                .tabItem {
                    Label("Reservations", systemImage: "calendar")
                }

            NotificationsPlaceholderView()
                .tabItem {
                    Label("Notifications", systemImage: "bell")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
        }
        .tint(Color.reziphayPrimary)
    }
}

// MARK: - Placeholder Views (Phase 2+)

struct ExploreView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.reziphayPrimary.opacity(0.4))
                Text("Explore")
                    .font(.title2.bold())
                Text("Coming in Phase 2")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Explore")
        }
    }
}

struct ReservationsPlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "calendar")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.reziphayPrimary.opacity(0.4))
                Text("Reservations")
                    .font(.title2.bold())
                Text("Coming in Phase 3")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Reservations")
        }
    }
}

struct NotificationsPlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "bell")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.reziphayPrimary.opacity(0.4))
                Text("Notifications")
                    .font(.title2.bold())
                Text("Coming in Phase 6")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Notifications")
        }
    }
}

// MARK: - Profile View

struct ProfileView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.reziphayPrimary.opacity(0.15))
                                .frame(width: 56, height: 56)
                            Text(initials)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(Color.reziphayPrimary)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(appState.currentUser?.displayName ?? "User")
                                .font(.system(size: 17, weight: .semibold))
                            Text(appState.currentUser?.phone ?? "")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Account") {
                    Label("Edit Profile", systemImage: "person.crop.circle.badge.pencil")
                    Label("Notifications", systemImage: "bell")
                    Label("Privacy", systemImage: "lock.shield")
                }

                Section {
                    Button(role: .destructive) {
                        Task { await appState.signOut() }
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }

    private var initials: String {
        guard let name = appState.currentUser?.fullName else { return "U" }
        let parts = name.components(separatedBy: " ")
        return parts.prefix(2).compactMap { $0.first }.map { String($0) }.joined()
    }
}
