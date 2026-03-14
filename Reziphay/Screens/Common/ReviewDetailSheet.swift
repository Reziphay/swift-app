import SwiftUI

struct ReviewDetailSheet: View {
    let review: Review
    @Binding var isPresented: Bool

    @Environment(AppState.self) private var appState

    @State private var isReporting: Bool = false
    @State private var showReportConfirm: Bool = false

    var body: some View {
        RZBottomSheet(title: "Review") {
            VStack(spacing: RZSpacing.md) {
                // Author & Date
                HStack(spacing: RZSpacing.xs) {
                    RZAvatarView(name: review.authorName ?? "User", url: nil, size: 40)
                    VStack(alignment: .leading, spacing: RZSpacing.xxxs) {
                        Text(review.authorName ?? "Anonymous")
                            .font(.rzBody)
                            .fontWeight(.semibold)
                            .foregroundStyle(.rzTextPrimary)
                        Text(review.formattedDate)
                            .font(.rzCaption)
                            .foregroundStyle(.rzTextTertiary)
                    }
                    Spacer()
                    // Star rating
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= review.rating ? "star.fill" : "star")
                                .font(.system(size: 13))
                                .foregroundStyle(star <= review.rating ? Color.rzWarning : Color.rzBorder)
                        }
                    }
                }

                Divider()

                // Comment
                if !review.comment.isEmpty {
                    Text(review.comment)
                        .font(.rzBody)
                        .foregroundStyle(.rzTextPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Targets
                if let targets = review.targets, !targets.isEmpty {
                    HStack(spacing: RZSpacing.xxs) {
                        ForEach(targets) { target in
                            RZStatusPill(
                                text: targetLabel(target.targetType),
                                color: .rzPrimary
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Provider reply
                if let reply = review.reply {
                    Divider()

                    VStack(alignment: .leading, spacing: RZSpacing.xxs) {
                        HStack(spacing: RZSpacing.xxs) {
                            Image(systemName: "arrowshape.turn.up.left.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.rzPrimary)
                            Text("Provider Reply")
                                .font(.rzBodySmall)
                                .fontWeight(.semibold)
                                .foregroundStyle(.rzPrimary)

                            Spacer()

                            Text(formatISO(reply.createdAt))
                                .font(.rzCaption)
                                .foregroundStyle(.rzTextTertiary)
                        }

                        Text(reply.comment)
                            .font(.rzBodySmall)
                            .foregroundStyle(.rzTextSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.leading, RZSpacing.sm)
                    }
                    .padding(RZSpacing.sm)
                    .background(Color.rzPrimary.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: RZRadius.card))
                }

                Divider()

                // Report button
                RZButton(
                    title: "Report Review",
                    variant: .ghost,
                    size: .medium,
                    isFullWidth: true,
                    isLoading: isReporting
                ) {
                    showReportConfirm = true
                }
                .foregroundStyle(Color.rzError)
            }
        } onDismiss: {
            isPresented = false
        }
        .confirmationDialog(
            "Report this review?",
            isPresented: $showReportConfirm,
            titleVisibility: .visible
        ) {
            Button("Report as Inappropriate", role: .destructive) {
                handleReport()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will flag the review for our moderation team to review.")
        }
    }

    // MARK: - Helpers

    private func targetLabel(_ type: ReviewTargetType) -> String {
        switch type {
        case .service: return "Service"
        case .serviceOwner: return "Provider"
        case .brand: return "Brand"
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

    private func handleReport() {
        isReporting = true
        Task {
            defer { isReporting = false }
            do {
                struct ReportBody: Encodable {
                    let targetType: String
                    let targetId: String
                    let reason: String
                }
                let body = ReportBody(
                    targetType: "REVIEW",
                    targetId: review.id,
                    reason: "Inappropriate review"
                )
                let _: EmptyData = try await appState.apiClient.post(APIEndpoints.reports, body: body)
                appState.showToast("Review reported. Thank you for your feedback.", type: .success)
                isPresented = false
            } catch {
                appState.showToast(error.localizedDescription, type: .error)
            }
        }
    }
}
