import SwiftUI

// MARK: - ViewModel

@Observable
@MainActor
final class PenaltySummaryViewModel {
    var summary: PenaltySummary?
    var isLoading: Bool = false
    var error: String? = nil

    private var appState: AppState?

    func setup(appState: AppState) {
        self.appState = appState
    }

    func load() async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            summary = try await appState?.apiClient.get(APIEndpoints.penaltiesMe)
        } catch {
            self.error = error.localizedDescription
            appState?.showToast("Failed to load penalty information.", type: .error)
        }
    }

    var activePoints: Int {
        summary?.activePointsTotal ?? 0
    }

    var suspensionThreshold: Int { 5 }
    var permanentThreshold: Int { 10 }

    var progressFraction: Double {
        min(Double(activePoints) / Double(permanentThreshold), 1.0)
    }

    var riskLevel: RiskLevel {
        if activePoints >= permanentThreshold { return .permanent }
        if activePoints >= suspensionThreshold { return .suspension }
        if activePoints >= 3 { return .warning }
        return .safe
    }

    enum RiskLevel {
        case safe, warning, suspension, permanent
    }
}

// MARK: - Screen

struct PenaltySummaryScreen: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = PenaltySummaryViewModel()

    var body: some View {
        ZStack {
            Color.rzBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                RZTopBar(title: "Penalty Points") {
                    RZIconButton(icon: "chevron.left") { dismiss() }
                }

                if viewModel.isLoading && viewModel.summary == nil {
                    loadingSkeleton
                } else if let summary = viewModel.summary {
                    ScrollView {
                        VStack(spacing: RZSpacing.sectionVertical) {
                            summaryCard(summary: summary)
                            progressBar
                            penaltyList(points: summary.points)
                            activeActions(actions: summary.actions)
                            policySection
                        }
                        .padding(.horizontal, RZSpacing.screenHorizontal)
                        .padding(.vertical, RZSpacing.sm)
                    }
                    .refreshable {
                        await viewModel.load()
                    }
                } else {
                    RZEmptyState(
                        icon: "checkmark.shield.fill",
                        title: "No Penalties",
                        subtitle: "You have a clean record. Keep it up!",
                        actionTitle: nil,
                        action: nil
                    )
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            viewModel.setup(appState: appState)
            await viewModel.load()
        }
    }

    // MARK: - Summary Card

    private func summaryCard(summary: PenaltySummary) -> some View {
        RZCard {
            VStack(spacing: RZSpacing.sm) {
                HStack {
                    VStack(alignment: .leading, spacing: RZSpacing.xxxs) {
                        Text("Current Penalty Points")
                            .font(.rzBodySmall)
                            .foregroundStyle(.rzTextSecondary)
                        HStack(alignment: .firstTextBaseline, spacing: RZSpacing.xxxs) {
                            Text("\(viewModel.activePoints)")
                                .font(.system(size: 42, weight: .bold))
                                .foregroundStyle(pointsColor)
                            Text("/ \(viewModel.permanentThreshold)")
                                .font(.rzBody)
                                .foregroundStyle(.rzTextTertiary)
                        }
                    }
                    Spacer()
                    Image(systemName: pointsIcon)
                        .font(.system(size: 44))
                        .foregroundStyle(pointsColor.opacity(0.8))
                }

                if viewModel.activePoints > 0 {
                    HStack(spacing: RZSpacing.xxs) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(pointsColor)
                        Text(riskMessage)
                            .font(.rzCaption)
                            .foregroundStyle(pointsColor)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var pointsColor: Color {
        switch viewModel.riskLevel {
        case .safe: return .rzSuccess
        case .warning: return .rzWarning
        case .suspension: return .rzError
        case .permanent: return .rzError
        }
    }

    private var pointsIcon: String {
        switch viewModel.riskLevel {
        case .safe: return "checkmark.shield.fill"
        case .warning: return "exclamationmark.shield.fill"
        case .suspension: return "xmark.shield.fill"
        case .permanent: return "xmark.shield.fill"
        }
    }

    private var riskMessage: String {
        switch viewModel.riskLevel {
        case .safe: return "Your account is in good standing."
        case .warning: return "You're approaching the suspension threshold. Please note-show cancellations."
        case .suspension: return "You have reached the suspension threshold. Reaching 10 points will result in a permanent ban."
        case .permanent: return "Your account has reached the maximum penalty limit."
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        RZCard {
            VStack(alignment: .leading, spacing: RZSpacing.xs) {
                HStack {
                    Text("Penalty Progress")
                        .font(.rzBodySmall)
                        .fontWeight(.semibold)
                        .foregroundStyle(.rzTextPrimary)
                    Spacer()
                    Text("\(viewModel.activePoints) / \(viewModel.permanentThreshold) pts")
                        .font(.rzCaption)
                        .foregroundStyle(.rzTextSecondary)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.rzBorder)
                            .frame(height: 12)

                        RoundedRectangle(cornerRadius: 6)
                            .fill(progressGradient)
                            .frame(width: geo.size.width * viewModel.progressFraction, height: 12)
                            .animation(.easeInOut(duration: 0.5), value: viewModel.progressFraction)
                    }
                }
                .frame(height: 12)

                // Threshold markers
                HStack {
                    Text("0")
                        .font(.rzCaption)
                        .foregroundStyle(.rzTextTertiary)
                    Spacer()
                    VStack(spacing: 0) {
                        Text("⚠️")
                            .font(.system(size: 10))
                        Text("\(viewModel.suspensionThreshold)")
                            .font(.rzCaption)
                            .foregroundStyle(.rzWarning)
                    }
                    Spacer()
                    VStack(spacing: 0) {
                        Text("🚫")
                            .font(.system(size: 10))
                        Text("\(viewModel.permanentThreshold)")
                            .font(.rzCaption)
                            .foregroundStyle(.rzError)
                    }
                }
            }
        }
    }

    private var progressGradient: LinearGradient {
        LinearGradient(
            colors: [Color.rzWarning, Color.rzError],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    // MARK: - Penalty List

    private func penaltyList(points: [PenaltyPoint]) -> some View {
        Group {
            if !points.isEmpty {
                VStack(alignment: .leading, spacing: RZSpacing.xs) {
                    Text("Penalty History")
                        .font(.rzH4)
                        .foregroundStyle(.rzTextPrimary)

                    ForEach(points) { penalty in
                        penaltyRow(penalty: penalty)
                    }
                }
            }
        }
    }

    private func penaltyRow(penalty: PenaltyPoint) -> some View {
        RZCard {
            HStack(spacing: RZSpacing.xs) {
                VStack(alignment: .leading, spacing: RZSpacing.xxxs) {
                    Text(penaltyReasonLabel(penalty.reason))
                        .font(.rzBodySmall)
                        .fontWeight(.semibold)
                        .foregroundStyle(.rzTextPrimary)

                    Text(formatISO(penalty.createdAt))
                        .font(.rzCaption)
                        .foregroundStyle(.rzTextTertiary)

                    HStack(spacing: RZSpacing.xxxs) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 11))
                            .foregroundStyle(.rzTextTertiary)
                        Text("Expires: \(formatISO(penalty.expiresAt))")
                            .font(.rzCaption)
                            .foregroundStyle(.rzTextTertiary)
                    }
                }

                Spacer()

                VStack(spacing: RZSpacing.xxxs) {
                    Text("+\(penalty.points)")
                        .font(.rzH3)
                        .fontWeight(.bold)
                        .foregroundStyle(.rzError)
                    Text(penalty.isActive ? "Active" : "Expired")
                        .font(.rzCaption)
                        .foregroundStyle(penalty.isActive ? .rzError : .rzTextTertiary)
                }
            }
        }
    }

    // MARK: - Active Actions

    private func activeActions(actions: [PenaltyAction]) -> some View {
        Group {
            if !actions.filter({ $0.isActive }).isEmpty {
                VStack(alignment: .leading, spacing: RZSpacing.xs) {
                    Text("Active Restrictions")
                        .font(.rzH4)
                        .foregroundStyle(.rzTextPrimary)

                    ForEach(actions.filter { $0.isActive }) { action in
                        HStack(spacing: RZSpacing.xs) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.rzError)
                            VStack(alignment: .leading, spacing: RZSpacing.xxxs) {
                                Text(actionLabel(action.action))
                                    .font(.rzBodySmall)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.rzError)
                                if let endsAt = action.endsAt {
                                    Text("Until: \(formatISO(endsAt))")
                                        .font(.rzCaption)
                                        .foregroundStyle(.rzTextSecondary)
                                }
                            }
                        }
                        .padding(RZSpacing.sm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.rzError.opacity(0.07))
                        .clipShape(RoundedRectangle(cornerRadius: RZRadius.card))
                        .overlay(
                            RoundedRectangle(cornerRadius: RZRadius.card)
                                .strokeBorder(Color.rzError.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
            }
        }
    }

    // MARK: - Policy Section

    private var policySection: some View {
        RZCard {
            VStack(alignment: .leading, spacing: RZSpacing.sm) {
                HStack(spacing: RZSpacing.xxs) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.rzPrimary)
                    Text("Penalty Policy")
                        .font(.rzH4)
                        .foregroundStyle(.rzTextPrimary)
                }

                policyItem(
                    icon: "plus.circle.fill",
                    color: .rzError,
                    title: "How points are added",
                    description: "1 point is added for each no-show reservation. A no-show occurs when you don't appear for your confirmed reservation without cancelling."
                )

                policyItem(
                    icon: "clock.arrow.circlepath",
                    color: .rzWarning,
                    title: "Point expiration",
                    description: "Penalty points automatically expire after 3 months from the date they were issued."
                )

                policyItem(
                    icon: "exclamationmark.triangle.fill",
                    color: .rzWarning,
                    title: "5 points — Temporary suspension",
                    description: "Reaching 5 active points results in a 1-month account suspension. You won't be able to make new reservations."
                )

                policyItem(
                    icon: "xmark.circle.fill",
                    color: .rzError,
                    title: "10 points — Permanent ban",
                    description: "Reaching 10 active points results in a permanent account closure. This cannot be reversed."
                )

                policyItem(
                    icon: "person.fill.checkmark",
                    color: .rzSuccess,
                    title: "Submit an objection",
                    description: "If you believe a no-show was incorrectly assigned, you can submit an objection within 48 hours from the reservation detail screen."
                )
            }
        }
    }

    private func policyItem(icon: String, color: Color, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: RZSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
                .frame(width: 20)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: RZSpacing.xxxs) {
                Text(title)
                    .font(.rzBodySmall)
                    .fontWeight(.semibold)
                    .foregroundStyle(.rzTextPrimary)
                Text(description)
                    .font(.rzCaption)
                    .foregroundStyle(.rzTextSecondary)
            }
        }
    }

    // MARK: - Loading Skeleton

    private var loadingSkeleton: some View {
        ScrollView {
            VStack(spacing: RZSpacing.sm) {
                ForEach(0..<3, id: \.self) { _ in
                    RZCard {
                        VStack(alignment: .leading, spacing: RZSpacing.xxs) {
                            RZSkeletonView(height: 20, radius: 6)
                            RZSkeletonView(height: 14, radius: 4).frame(width: 180)
                        }
                    }
                }
            }
            .padding(.horizontal, RZSpacing.screenHorizontal)
            .padding(.top, RZSpacing.xs)
        }
        .disabled(true)
    }

    // MARK: - Helpers

    private func penaltyReasonLabel(_ reason: PenaltyReason) -> String {
        switch reason {
        case .noShow: return "No-Show"
        }
    }

    private func actionLabel(_ action: PenaltyActionType) -> String {
        switch action {
        case .suspend1Month: return "Account Suspended (1 month)"
        case .closeIndefinitely: return "Account Permanently Closed"
        }
    }

    private func formatISO(_ iso: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: iso) else { return iso }
        let display = DateFormatter()
        display.dateFormat = "MMM d, yyyy"
        return display.string(from: date)
    }
}
