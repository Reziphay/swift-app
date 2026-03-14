import SwiftUI

// MARK: - Model

struct NotificationSettingsData: Codable {
    var pushReservationUpdates: Bool
    var pushReminders: Bool
    var pushReviews: Bool
    var pushMarketing: Bool
    var reminderEnabled: Bool
    var reminderMinutesBefore: Int

    init() {
        pushReservationUpdates = true
        pushReminders = true
        pushReviews = true
        pushMarketing = false
        reminderEnabled = true
        reminderMinutesBefore = 30
    }
}

// MARK: - ViewModel

@Observable
final class SettingsViewModel {
    var settings = NotificationSettingsData()
    var isLoading = false
    var isSaving = false
    var errorMessage: String? = nil

    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchSettings() async {
        isLoading = true
        do {
            let data: NotificationSettingsData = try await apiClient.get(APIEndpoints.notificationSettings)
            settings = data
        } catch {
            // If fetch fails, keep defaults — don't block the user
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func saveSettings() async {
        isSaving = true
        do {
            try await apiClient.patchVoid(APIEndpoints.notificationSettings, body: settings)
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}

// MARK: - Screen

struct SettingsScreen: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: SettingsViewModel? = nil

    private let reminderOptions: [(String, Int)] = [
        ("15 minutes", 15),
        ("30 minutes", 30),
        ("1 hour", 60),
        ("2 hours", 120),
        ("1 day", 1440),
    ]

    var body: some View {
        ZStack {
            Color.rzBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                RZTopBar(title: "Settings") {
                    RZIconButton(icon: "chevron.left") {
                        dismiss()
                    }
                }

                if let vm = viewModel {
                    ScrollView {
                        VStack(spacing: RZSpacing.sectionVertical) {
                            // Notification preferences
                            settingsSection(title: "Push Notifications") {
                                toggleRow(
                                    icon: "calendar",
                                    title: "Reservation Updates",
                                    subtitle: "Confirmations, rejections, cancellations",
                                    isOn: Binding(
                                        get: { vm.settings.pushReservationUpdates },
                                        set: { vm.settings.pushReservationUpdates = $0; saveDebounced(vm) }
                                    )
                                )

                                Divider().padding(.leading, RZSpacing.screenHorizontal)

                                toggleRow(
                                    icon: "bell.badge",
                                    title: "Reminders",
                                    subtitle: "Appointment reminders before your booking",
                                    isOn: Binding(
                                        get: { vm.settings.pushReminders },
                                        set: { vm.settings.pushReminders = $0; saveDebounced(vm) }
                                    )
                                )

                                Divider().padding(.leading, RZSpacing.screenHorizontal)

                                toggleRow(
                                    icon: "star",
                                    title: "Reviews",
                                    subtitle: "When someone leaves a review",
                                    isOn: Binding(
                                        get: { vm.settings.pushReviews },
                                        set: { vm.settings.pushReviews = $0; saveDebounced(vm) }
                                    )
                                )

                                Divider().padding(.leading, RZSpacing.screenHorizontal)

                                toggleRow(
                                    icon: "megaphone",
                                    title: "Promotions",
                                    subtitle: "Offers and product updates",
                                    isOn: Binding(
                                        get: { vm.settings.pushMarketing },
                                        set: { vm.settings.pushMarketing = $0; saveDebounced(vm) }
                                    )
                                )
                            }

                            // Reminder settings
                            settingsSection(title: "Appointment Reminders") {
                                toggleRow(
                                    icon: "alarm",
                                    title: "Enable Reminders",
                                    subtitle: "Receive a push notification before appointments",
                                    isOn: Binding(
                                        get: { vm.settings.reminderEnabled },
                                        set: { vm.settings.reminderEnabled = $0; saveDebounced(vm) }
                                    )
                                )

                                if vm.settings.reminderEnabled {
                                    Divider().padding(.leading, RZSpacing.screenHorizontal)

                                    VStack(alignment: .leading, spacing: RZSpacing.xxs) {
                                        Text("Remind me")
                                            .font(.rzBody)
                                            .foregroundStyle(.rzTextPrimary)
                                            .padding(.horizontal, RZSpacing.screenHorizontal)
                                            .padding(.top, RZSpacing.xs)

                                        ForEach(reminderOptions, id: \.1) { option in
                                            Button {
                                                vm.settings.reminderMinutesBefore = option.1
                                                saveDebounced(vm)
                                            } label: {
                                                HStack {
                                                    Text(option.0)
                                                        .font(.rzBody)
                                                        .foregroundStyle(.rzTextPrimary)
                                                    Spacer()
                                                    if vm.settings.reminderMinutesBefore == option.1 {
                                                        Image(systemName: "checkmark")
                                                            .font(.system(size: 13, weight: .semibold))
                                                            .foregroundStyle(.rzPrimary)
                                                    }
                                                }
                                                .padding(.horizontal, RZSpacing.screenHorizontal)
                                                .padding(.vertical, RZSpacing.xs)
                                            }
                                            if option.1 != reminderOptions.last?.1 {
                                                Divider().padding(.leading, RZSpacing.screenHorizontal)
                                            }
                                        }
                                    }
                                }
                            }

                            // App
                            settingsSection(title: "App") {
                                infoRow(icon: "tag", title: "Version", value: appVersion)
                            }

                            // Support
                            settingsSection(title: "Support") {
                                tappableRow(icon: "envelope", title: "Contact Support") {}
                                Divider().padding(.leading, RZSpacing.screenHorizontal)
                                tappableRow(icon: "doc.text", title: "Terms of Service") {}
                                Divider().padding(.leading, RZSpacing.screenHorizontal)
                                tappableRow(icon: "hand.raised", title: "Privacy Policy") {}
                            }
                        }
                        .padding(.vertical, RZSpacing.sm)
                        .padding(.bottom, RZSpacing.xxl)
                    }

                    if vm.isSaving {
                        HStack(spacing: RZSpacing.xxs) {
                            ProgressView()
                                .tint(.rzPrimary)
                                .scaleEffect(0.8)
                            Text("Saving…")
                                .font(.rzCaption)
                                .foregroundStyle(.rzTextSecondary)
                        }
                        .padding(.vertical, RZSpacing.xxs)
                    }
                } else {
                    skeletonView
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            if viewModel == nil {
                viewModel = SettingsViewModel(apiClient: appState.apiClient)
            }
            await viewModel?.fetchSettings()
        }
    }

    // MARK: - Subviews

    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.rzLabel)
                .fontWeight(.semibold)
                .foregroundStyle(.rzTextTertiary)
                .padding(.horizontal, RZSpacing.screenHorizontal)
                .padding(.bottom, RZSpacing.xxs)

            VStack(spacing: 0) {
                content()
            }
            .background(Color.rzSurface)
            .clipShape(RoundedRectangle(cornerRadius: RZRadius.card))
            .overlay {
                RoundedRectangle(cornerRadius: RZRadius.card)
                    .strokeBorder(Color.rzBorder, lineWidth: 0.5)
            }
            .padding(.horizontal, RZSpacing.screenHorizontal)
        }
    }

    private func toggleRow(icon: String, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: RZSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.rzPrimary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: RZSpacing.xxxs) {
                Text(title)
                    .font(.rzBody)
                    .foregroundStyle(.rzTextPrimary)
                Text(subtitle)
                    .font(.rzCaption)
                    .foregroundStyle(.rzTextTertiary)
                    .lineLimit(2)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(.rzPrimary)
        }
        .padding(.horizontal, RZSpacing.screenHorizontal)
        .padding(.vertical, RZSpacing.sm)
    }

    private func infoRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: RZSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.rzTextSecondary)
                .frame(width: 28)

            Text(title)
                .font(.rzBody)
                .foregroundStyle(.rzTextPrimary)

            Spacer()

            Text(value)
                .font(.rzBody)
                .foregroundStyle(.rzTextTertiary)
        }
        .padding(.horizontal, RZSpacing.screenHorizontal)
        .padding(.vertical, RZSpacing.sm)
    }

    private func tappableRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: RZSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.rzTextSecondary)
                    .frame(width: 28)

                Text(title)
                    .font(.rzBody)
                    .foregroundStyle(.rzTextPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.rzTextTertiary)
            }
            .padding(.horizontal, RZSpacing.screenHorizontal)
            .padding(.vertical, RZSpacing.sm)
        }
    }

    private var skeletonView: some View {
        ScrollView {
            VStack(spacing: RZSpacing.sectionVertical) {
                ForEach(0..<3, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: RZSpacing.xxs) {
                        RZSkeletonView(height: 12, radius: RZRadius.sm)
                            .frame(maxWidth: 100)
                            .padding(.horizontal, RZSpacing.screenHorizontal)
                        RZSkeletonView(height: 130, radius: RZRadius.card)
                            .padding(.horizontal, RZSpacing.screenHorizontal)
                    }
                }
            }
            .padding(.vertical, RZSpacing.sm)
        }
    }

    // MARK: - Helpers

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    private func saveDebounced(_ vm: SettingsViewModel) {
        Task {
            await vm.saveSettings()
        }
    }
}
