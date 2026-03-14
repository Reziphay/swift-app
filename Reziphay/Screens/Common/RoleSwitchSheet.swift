import SwiftUI

struct RoleSwitchSheet: View {
    @Environment(AppState.self) private var appState
    @Binding var isPresented: Bool

    @State private var isLoading = false

    var body: some View {
        RZBottomSheet(title: "Switch Role", onDismiss: { isPresented = false }) {
            VStack(spacing: RZSpacing.sm) {
                // Role options
                roleRow(
                    title: "Customer",
                    subtitle: "Book and manage appointments",
                    icon: "person.fill",
                    role: .ucr
                )

                if hasProviderRole {
                    roleRow(
                        title: "Service Provider",
                        subtitle: "Manage services and reservations",
                        icon: "briefcase.fill",
                        role: .uso
                    )
                } else {
                    // Activate provider CTA
                    activateProviderRow
                }
            }
        }
    }

    // MARK: - Subviews

    private func roleRow(title: String, subtitle: String, icon: String, role: AppRole) -> some View {
        let isActive = appState.activeRole == role

        return Button {
            guard !isActive else { return }
            switchToRole(role)
        } label: {
            HStack(spacing: RZSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(isActive ? Color.rzPrimary : Color.rzInputBackground)
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(isActive ? .white : .rzTextSecondary)
                }

                VStack(alignment: .leading, spacing: RZSpacing.xxxs) {
                    Text(title)
                        .font(.rzBodyLarge)
                        .fontWeight(.semibold)
                        .foregroundStyle(.rzTextPrimary)
                    Text(subtitle)
                        .font(.rzBodySmall)
                        .foregroundStyle(.rzTextSecondary)
                }

                Spacer()

                if isActive {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.rzPrimary)
                }

                if isLoading && !isActive {
                    ProgressView()
                        .tint(.rzPrimary)
                        .scaleEffect(0.8)
                }
            }
            .padding(RZSpacing.sm)
            .background(isActive ? Color.rzPrimary.opacity(0.06) : Color.rzSurface)
            .clipShape(RoundedRectangle(cornerRadius: RZRadius.card))
            .overlay {
                RoundedRectangle(cornerRadius: RZRadius.card)
                    .strokeBorder(isActive ? Color.rzPrimary.opacity(0.3) : Color.rzBorder, lineWidth: 1)
            }
        }
        .disabled(isLoading)
    }

    private var activateProviderRow: some View {
        VStack(spacing: RZSpacing.xs) {
            HStack(spacing: RZSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(Color.rzInputBackground)
                        .frame(width: 44, height: 44)
                    Image(systemName: "briefcase.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.rzTextTertiary)
                }

                VStack(alignment: .leading, spacing: RZSpacing.xxxs) {
                    Text("Service Provider")
                        .font(.rzBodyLarge)
                        .fontWeight(.semibold)
                        .foregroundStyle(.rzTextSecondary)
                    Text("Not yet activated")
                        .font(.rzBodySmall)
                        .foregroundStyle(.rzTextTertiary)
                }

                Spacer()
            }
            .padding(RZSpacing.sm)
            .background(Color.rzSurface)
            .clipShape(RoundedRectangle(cornerRadius: RZRadius.card))
            .overlay {
                RoundedRectangle(cornerRadius: RZRadius.card)
                    .strokeBorder(Color.rzBorder, lineWidth: 1)
            }

            RZButton(
                title: "Activate Provider Role",
                variant: .primary,
                size: .large,
                isFullWidth: true,
                isLoading: isLoading
            ) {
                activateProvider()
            }
        }
    }

    // MARK: - Computed

    private var hasProviderRole: Bool {
        appState.authManager.currentUser?.roles?.contains(where: { $0.role == .uso }) ?? false
    }

    // MARK: - Actions

    private func switchToRole(_ role: AppRole) {
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                try await appState.handleRoleSwitch(to: role)
                isPresented = false
            } catch {
                appState.showToast(error.localizedDescription, type: .error)
            }
        }
    }

    private func activateProvider() {
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                try await appState.authManager.activateUSO()
                try await appState.handleRoleSwitch(to: .uso)
                isPresented = false
                appState.showToast("Provider role activated.", type: .success)
            } catch {
                appState.showToast(error.localizedDescription, type: .error)
            }
        }
    }
}
