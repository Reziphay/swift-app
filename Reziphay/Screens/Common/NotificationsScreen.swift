import SwiftUI

// MARK: - ViewModel

@Observable
final class NotificationsViewModel {
    var notifications: [AppNotification] = []
    var isLoading = false
    var errorMessage: String? = nil

    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchNotifications() async {
        isLoading = true
        errorMessage = nil
        do {
            let result: [AppNotification] = try await apiClient.get(APIEndpoints.notifications)
            notifications = result
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    var unread: [AppNotification] {
        notifications.filter { !$0.isRead }
    }

    func markAsRead(_ id: String) async {
        guard let index = notifications.firstIndex(where: { $0.id == id }) else { return }
        _ = notifications[index] // capture before mark
        do {
            try await apiClient.postVoid(APIEndpoints.notificationRead(id))
        } catch {}
        // Optimistically update local state
        notifications = notifications.map { n in
            if n.id == id {
                return AppNotification(
                    id: n.id,
                    userId: n.userId,
                    type: n.type,
                    title: n.title,
                    body: n.body,
                    dataJson: n.dataJson,
                    isRead: true,
                    readAt: ISO8601DateFormatter().string(from: Date()),
                    createdAt: n.createdAt
                )
            }
            return n
        }
    }

    func markAllRead() async {
        do {
            try await apiClient.postVoid(APIEndpoints.notificationsReadAll)
        } catch {}
        notifications = notifications.map { n in
            AppNotification(
                id: n.id,
                userId: n.userId,
                type: n.type,
                title: n.title,
                body: n.body,
                dataJson: n.dataJson,
                isRead: true,
                readAt: ISO8601DateFormatter().string(from: Date()),
                createdAt: n.createdAt
            )
        }
    }
}

// MARK: - Screen

struct NotificationsScreen: View {
    @Environment(AppState.self) private var appState

    @State private var viewModel: NotificationsViewModel? = nil
    @State private var selectedSegment: Int = 0 // 0 = All, 1 = Unread

    var body: some View {
        ZStack {
            Color.rzBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                RZTopBar(title: "Notifications") {
                    EmptyView()
                } trailing: {
                    if let vm = viewModel, !vm.notifications.isEmpty {
                        RZIconButton(icon: "checkmark.circle", color: .rzTextSecondary) {
                            Task { await vm.markAllRead() }
                        }
                    }
                }

                // Segment
                RZSegmentedControl(items: ["All", "Unread"], selected: $selectedSegment)
                    .padding(.horizontal, RZSpacing.screenHorizontal)
                    .padding(.vertical, RZSpacing.xxs)

                Divider()

                // Content
                if let vm = viewModel {
                    notificationContent(vm: vm)
                } else {
                    skeletonView
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            if viewModel == nil {
                viewModel = NotificationsViewModel(apiClient: appState.apiClient)
            }
            await viewModel?.fetchNotifications()
        }
    }

    // MARK: - Content states

    @ViewBuilder
    private func notificationContent(vm: NotificationsViewModel) -> some View {
        if vm.isLoading && vm.notifications.isEmpty {
            skeletonView
        } else if let error = vm.errorMessage {
            RZEmptyState(
                icon: "exclamationmark.triangle.fill",
                title: "Failed to load",
                subtitle: error,
                actionTitle: "Retry"
            ) {
                Task { await vm.fetchNotifications() }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            let items = selectedSegment == 1 ? vm.unread : vm.notifications
            if items.isEmpty {
                RZEmptyState(
                    icon: "bell.slash.fill",
                    title: selectedSegment == 1 ? "No unread notifications" : "No notifications",
                    subtitle: selectedSegment == 1 ? "You're all caught up." : "You'll see updates here."
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(items) { notification in
                            NotificationRow(notification: notification) {
                                handleTap(notification: notification, vm: vm)
                            }
                            Divider()
                                .padding(.leading, RZSpacing.screenHorizontal + 44 + RZSpacing.sm)
                        }
                    }
                }
            }
        }
    }

    private var skeletonView: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(0..<8, id: \.self) { _ in
                    NotificationSkeletonRow()
                    Divider()
                        .padding(.leading, RZSpacing.screenHorizontal)
                }
            }
        }
    }

    // MARK: - Actions

    private func handleTap(notification: AppNotification, vm: NotificationsViewModel) {
        if !notification.isRead {
            Task { await vm.markAsRead(notification.id) }
        }
        navigateForNotification(notification)
    }

    private func navigateForNotification(_ notification: AppNotification) {
        let role = appState.activeRole
        switch notification.type {
        case .reservationReceived, .reservationConfirmed, .reservationRejected,
             .reservationCancelled, .reservationChangeRequested, .reservationDelayUpdated,
             .reservationReminder, .reservationCompleted, .reservationExpired, .reservationNoShow:
            if let id = notification.dataJson?.reservationId {
                appState.router.push(.reservationDetail(id: id), forRole: role)
            }
        case .reviewReceived:
            if let id = notification.dataJson?.serviceId {
                appState.router.push(.serviceDetail(id: id), forRole: role)
            }
        case .penaltyApplied, .objectionReceived:
            appState.router.push(.penaltySummary, forRole: role)
        case .reportReceived, .reviewReported:
            break // No specific destination; stay on notifications
        }
    }
}

// MARK: - Row

private struct NotificationRow: View {
    let notification: AppNotification
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: RZSpacing.sm) {
                // Icon
                ZStack {
                    Circle()
                        .fill(iconBackground)
                        .frame(width: 40, height: 40)
                    Image(systemName: iconName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(iconColor)
                }

                // Content
                VStack(alignment: .leading, spacing: RZSpacing.xxxs) {
                    HStack {
                        Text(notification.title)
                            .font(.rzBody)
                            .fontWeight(notification.isRead ? .regular : .semibold)
                            .foregroundStyle(.rzTextPrimary)
                            .lineLimit(1)
                        Spacer()
                        Text(notification.formattedDate)
                            .font(.rzCaption)
                            .foregroundStyle(.rzTextTertiary)
                    }

                    Text(notification.body)
                        .font(.rzBodySmall)
                        .foregroundStyle(.rzTextSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                // Unread dot
                if !notification.isRead {
                    Circle()
                        .fill(Color.rzPrimary)
                        .frame(width: 8, height: 8)
                        .padding(.top, 6)
                }
            }
            .padding(.horizontal, RZSpacing.screenHorizontal)
            .padding(.vertical, RZSpacing.sm)
            .background(notification.isRead ? Color.rzBackground : Color.rzPrimary.opacity(0.03))
        }
    }

    private var iconName: String {
        switch notification.type {
        case .reservationReceived, .reservationConfirmed: "calendar.badge.checkmark"
        case .reservationRejected, .reservationCancelled: "calendar.badge.minus"
        case .reservationChangeRequested: "calendar.badge.exclamationmark"
        case .reservationDelayUpdated: "clock.badge.exclamationmark"
        case .reservationReminder: "alarm.fill"
        case .reservationCompleted: "checkmark.seal.fill"
        case .reservationExpired, .reservationNoShow: "clock.badge.xmark"
        case .penaltyApplied: "exclamationmark.triangle.fill"
        case .reviewReceived: "star.fill"
        case .reportReceived, .reviewReported: "flag.fill"
        case .objectionReceived: "person.badge.key.fill"
        }
    }

    private var iconColor: Color {
        switch notification.type {
        case .reservationConfirmed, .reservationCompleted: .rzSuccess
        case .reservationRejected, .reservationCancelled, .penaltyApplied,
             .reservationExpired, .reservationNoShow: .rzError
        case .reservationChangeRequested, .reservationDelayUpdated: .rzWarning
        case .reviewReceived: .rzWarning
        default: .rzPrimary
        }
    }

    private var iconBackground: Color {
        iconColor.opacity(0.12)
    }
}

// MARK: - Skeleton row

private struct NotificationSkeletonRow: View {
    var body: some View {
        HStack(alignment: .top, spacing: RZSpacing.sm) {
            RZSkeletonView(width: 40, height: 40, radius: 20)
            VStack(alignment: .leading, spacing: RZSpacing.xxs) {
                RZSkeletonView(height: 14, radius: RZRadius.sm)
                    .frame(maxWidth: 180)
                RZSkeletonView(height: 12, radius: RZRadius.sm)
                    .frame(maxWidth: .infinity)
                RZSkeletonView(height: 12, radius: RZRadius.sm)
                    .frame(maxWidth: 120)
            }
        }
        .padding(.horizontal, RZSpacing.screenHorizontal)
        .padding(.vertical, RZSpacing.sm)
    }
}
