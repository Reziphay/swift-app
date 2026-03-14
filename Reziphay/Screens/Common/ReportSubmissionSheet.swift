import SwiftUI

// MARK: - Reason model

private struct ReportReason: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
}

private let reportReasons: [ReportReason] = [
    ReportReason(id: "FAKE_SPAM",          title: "Fake or spam",           subtitle: "Misleading, duplicate, or automated content"),
    ReportReason(id: "INAPPROPRIATE",      title: "Inappropriate content",  subtitle: "Offensive, harmful, or adult content"),
    ReportReason(id: "INCORRECT_INFO",     title: "Incorrect information",  subtitle: "Wrong details, location, or pricing"),
    ReportReason(id: "OTHER",              title: "Other",                  subtitle: "Something else not listed above"),
]

// MARK: - Request body

private struct CreateReportBody: Encodable {
    let targetType: String
    let targetId: String
    let reason: String
    let detail: String?
}

// MARK: - Sheet

struct ReportSubmissionSheet: View {
    let targetType: ReportTargetType
    let targetId: String
    @Binding var isPresented: Bool

    @Environment(AppState.self) private var appState

    @State private var selectedReasonId: String? = nil
    @State private var detail: String = ""
    @State private var isSubmitting = false
    @State private var isSuccess = false

    var body: some View {
        RZBottomSheet(title: "Report", onDismiss: { isPresented = false }) {
            if isSuccess {
                successView
            } else {
                formView
            }
        }
    }

    // MARK: - Form

    private var formView: some View {
        VStack(spacing: RZSpacing.md) {
            // Target summary
            HStack(spacing: RZSpacing.xxs) {
                Image(systemName: targetIcon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.rzTextSecondary)
                Text(targetLabel)
                    .font(.rzBodySmall)
                    .foregroundStyle(.rzTextSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Reason selection
            VStack(spacing: RZSpacing.xxs) {
                Text("Reason")
                    .font(.rzLabel)
                    .fontWeight(.semibold)
                    .foregroundStyle(.rzTextTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 0) {
                    ForEach(reportReasons) { reason in
                        reasonRow(reason: reason)
                        if reason.id != reportReasons.last?.id {
                            Divider()
                                .padding(.leading, RZSpacing.md + 24)
                        }
                    }
                }
                .background(Color.rzSurface)
                .clipShape(RoundedRectangle(cornerRadius: RZRadius.card))
                .overlay {
                    RoundedRectangle(cornerRadius: RZRadius.card)
                        .strokeBorder(Color.rzBorder, lineWidth: 0.5)
                }
            }

            // Optional detail
            RZTextArea(
                label: "Additional details (optional)",
                text: $detail,
                placeholder: "Describe the issue in more detail…"
            )

            // Submit button
            RZButton(
                title: "Submit Report",
                variant: .primary,
                size: .large,
                isFullWidth: true,
                isLoading: isSubmitting,
                isDisabled: selectedReasonId == nil
            ) {
                handleSubmit()
            }
        }
    }

    private func reasonRow(_ reason: ReportReason) -> some View {
        let isSelected = selectedReasonId == reason.id

        return Button {
            withAnimation(.easeInOut(duration: RZDuration.smallTransition)) {
                selectedReasonId = isSelected ? nil : reason.id
            }
        } label: {
            HStack(spacing: RZSpacing.sm) {
                // Radio indicator
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? Color.rzPrimary : Color.rzBorder, lineWidth: 2)
                        .frame(width: 20, height: 20)
                    if isSelected {
                        Circle()
                            .fill(Color.rzPrimary)
                            .frame(width: 10, height: 10)
                    }
                }

                VStack(alignment: .leading, spacing: RZSpacing.xxxs) {
                    Text(reason.title)
                        .font(.rzBody)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundStyle(.rzTextPrimary)
                    Text(reason.subtitle)
                        .font(.rzCaption)
                        .foregroundStyle(.rzTextTertiary)
                }

                Spacer()
            }
            .padding(.horizontal, RZSpacing.sm)
            .padding(.vertical, RZSpacing.sm)
        }
    }

    // MARK: - Success

    private var successView: some View {
        VStack(spacing: RZSpacing.lg) {
            Spacer()
                .frame(height: RZSpacing.md)

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56, weight: .semibold))
                .foregroundStyle(.rzSuccess)

            VStack(spacing: RZSpacing.xxs) {
                Text("Report Submitted")
                    .font(.rzH3)
                    .foregroundStyle(.rzTextPrimary)
                Text("Thank you for helping keep Reziphay safe. Our team will review your report.")
                    .font(.rzBody)
                    .foregroundStyle(.rzTextSecondary)
                    .multilineTextAlignment(.center)
            }

            RZButton(title: "Done", variant: .primary, size: .large, isFullWidth: true) {
                isPresented = false
            }
            .padding(.top, RZSpacing.sm)
        }
    }

    // MARK: - Computed

    private var targetLabel: String {
        switch targetType {
        case .user:    "Reporting a user"
        case .brand:   "Reporting a brand"
        case .service: "Reporting a service"
        case .review:  "Reporting a review"
        }
    }

    private var targetIcon: String {
        switch targetType {
        case .user:    "person.fill"
        case .brand:   "building.2.fill"
        case .service: "scissors"
        case .review:  "star.fill"
        }
    }

    // MARK: - Submit

    private func handleSubmit() {
        guard let reasonId = selectedReasonId else { return }
        isSubmitting = true
        Task {
            defer { isSubmitting = false }
            do {
                let body = CreateReportBody(
                    targetType: targetType.rawValue,
                    targetId: targetId,
                    reason: reasonId,
                    detail: detail.isEmpty ? nil : detail
                )
                try await appState.apiClient.postVoid(APIEndpoints.reports, body: body)
                withAnimation(.easeInOut(duration: RZDuration.smallTransition)) {
                    isSuccess = true
                }
            } catch {
                appState.showToast(error.localizedDescription, type: .error)
            }
        }
    }
}
