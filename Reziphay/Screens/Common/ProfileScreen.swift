import SwiftUI

struct ProfileScreen: View {
    @Environment(AppState.self) private var appState

    @State private var showRoleSwitch = false
    @State private var showLogoutConfirmation = false
    @State private var isLoggingOut = false
    @State private var penaltyCount: Int = 0

    var body: some View {
        ZStack {
            Color.rzBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Avatar & identity
                    identitySection

                    Divider()
                        .padding(.top, RZSpacing.sectionVertical)

                    // Role & switch
                    roleSectionView
                        .padding(.horizontal, RZSpacing.screenHorizontal)
                        .padding(.top, RZSpacing.sectionVertical)

                    Divider()
                        .padding(.top, RZSpacing.sectionVertical)

                    // Navigation rows
                    navigationRows
                        .padding(.top, RZSpacing.sm)

                    // Log out
                    logoutButton
                        .padding(.horizontal, RZSpacing.screenHorizontal)
                        .padding(.top, RZSpacing.lg)
                        .padding(.bottom, RZSpacing.xxl)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showRoleSwitch) {
            RoleSwitchSheet(isPresented: $showRoleSwitch)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showLogoutConfirmation) {
            RZConfirmationDialog(
                title: "Log Out",
                message: "Are you sure you want to log out?",
                confirmTitle: "Log Out",
                confirmVariant: .destructive,
                onConfirm: {
                    showLogoutConfirmation = false
                    handleLogout()
                },
                onCancel: {
                    showLogoutConfirmation = false
                }
            )
            .presentationDetents([.height(260)])
        }
    }

    // MARK: - Identity section

    private var identitySection: some View {
        VStack(spacing: RZSpacing.sm) {
            if let user = appState.authManager.currentUser {
                RZAvatarView(name: user.fullName, size: 80)

                VStack(spacing: RZSpacing.xxxs) {
                    Text(user.fullName)
                        .font(.rzH3)
                        .foregroundStyle(.rzTextPrimary)

                    Text(user.phone)
                        .font(.rzBody)
                        .foregroundStyle(.rzTextSecondary)

                    if let email = user.email {
                        HStack(spacing: RZSpacing.xxxs) {
                            Text(email)
                                .font(.rzBodySmall)
                                .foregroundStyle(.rzTextTertiary)
                            if user.isEmailVerified {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.rzSuccess)
                            }
                        }
                    }
                }
            } else {
                RZSkeletonView(width: 80, height: 80, radius: 40)
                RZSkeletonView(height: 18, radius: RZRadius.sm)
                    .frame(maxWidth: 160)
                RZSkeletonView(height: 14, radius: RZRadius.sm)
                    .frame(maxWidth: 100)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, RZSpacing.lg)
        .padding(.horizontal, RZSpacing.screenHorizontal)
    }

    // MARK: - Role section

    private var roleSectionView: some View {
        HStack {
            VStack(alignment: .leading, spacing: RZSpacing.xxxs) {
                Text("Active Role")
                    .font(.rzBodySmall)
                    .foregroundStyle(.rzTextTertiary)
                HStack(spacing: RZSpacing.xxs) {
                    Image(systemName: appState.isCustomer ? "person.fill" : "briefcase.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.rzPrimary)
                    Text(appState.isCustomer ? "Customer" : "Service Provider")
                        .font(.rzBodyLarge)
                        .fontWeight(.semibold)
                        .foregroundStyle(.rzTextPrimary)
                }
            }

            Spacer()

            Button {
                showRoleSwitch = true
            } label: {
                Text("Switch")
                    .font(.rzLabel)
                    .fontWeight(.semibold)
                    .foregroundStyle(.rzPrimary)
                    .padding(.horizontal, RZSpacing.sm)
                    .padding(.vertical, RZSpacing.xxs)
                    .background(Color.rzPrimary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: RZRadius.button))
            }
        }
    }

    // MARK: - Navigation rows

    private var navigationRows: some View {
        VStack(spacing: 0) {
            if penaltyCount > 0 {
                profileRow(
                    icon: "exclamationmark.triangle.fill",
                    iconColor: .rzWarning,
                    title: "Penalties",
                    badge: "\(penaltyCount)",
                    badgeColor: .rzWarning
                ) {
                    appState.router.push(.penaltySummary, forRole: appState.activeRole)
                }
                Divider().padding(.leading, RZSpacing.screenHorizontal + 44 + RZSpacing.sm)
            }

            profileRow(icon: "gearshape.fill", title: "Settings") {
                appState.router.push(.settings, forRole: appState.activeRole)
            }
            Divider().padding(.leading, RZSpacing.screenHorizontal + 44 + RZSpacing.sm)

            profileRow(icon: "questionmark.circle.fill", title: "Help") {
                // TODO: open help
            }
            Divider().padding(.leading, RZSpacing.screenHorizontal + 44 + RZSpacing.sm)

            profileRow(icon: "info.circle.fill", title: "About") {
                // TODO: open about
            }
        }
    }

    private func profileRow(
        icon: String,
        iconColor: Color = .rzPrimary,
        title: String,
        badge: String? = nil,
        badgeColor: Color = .rzError,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: RZSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.1))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(iconColor)
                }

                Text(title)
                    .font(.rzBodyLarge)
                    .foregroundStyle(.rzTextPrimary)

                Spacer()

                if let badge {
                    Text(badge)
                        .font(.rzCaption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, RZSpacing.xxs)
                        .padding(.vertical, RZSpacing.xxxs)
                        .background(badgeColor)
                        .clipShape(RoundedRectangle(cornerRadius: RZRadius.pill))
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.rzTextTertiary)
            }
            .padding(.horizontal, RZSpacing.screenHorizontal)
            .padding(.vertical, RZSpacing.sm)
        }
    }

    // MARK: - Log out

    private var logoutButton: some View {
        RZButton(
            title: "Log Out",
            variant: .destructive,
            size: .large,
            isFullWidth: true,
            isLoading: isLoggingOut
        ) {
            showLogoutConfirmation = true
        }
    }

    // MARK: - Actions

    private func handleLogout() {
        isLoggingOut = true
        Task {
            defer { isLoggingOut = false }
            await appState.handleLogout()
        }
    }
}


