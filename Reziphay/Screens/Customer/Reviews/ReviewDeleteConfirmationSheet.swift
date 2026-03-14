import SwiftUI

struct ReviewDeleteConfirmationSheet: View {
    let review: Review
    @Binding var isPresented: Bool
    let onDeleted: () -> Void

    @Environment(AppState.self) private var appState

    @State private var isDeleting: Bool = false

    var body: some View {
        RZBottomSheet(title: "Delete Review") {
            VStack(spacing: RZSpacing.md) {
                // Warning header
                HStack(spacing: RZSpacing.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.rzError)
                    Text("This action cannot be undone")
                        .font(.rzBodySmall)
                        .fontWeight(.semibold)
                        .foregroundStyle(.rzError)
                    Spacer()
                }

                // Review preview
                RZCard {
                    VStack(alignment: .leading, spacing: RZSpacing.xxs) {
                        // Stars preview
                        HStack(spacing: RZSpacing.xxxs) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= review.rating ? "star.fill" : "star")
                                    .font(.system(size: 14))
                                    .foregroundStyle(star <= review.rating ? Color.rzWarning : Color.rzBorder)
                            }
                        }

                        if !review.comment.isEmpty {
                            Text(review.comment)
                                .font(.rzBodySmall)
                                .foregroundStyle(.rzTextSecondary)
                                .lineLimit(3)
                        }

                        Text(review.formattedDate)
                            .font(.rzCaption)
                            .foregroundStyle(.rzTextTertiary)
                    }
                }

                // Permanent warning
                Text("Deleting this review is permanent and cannot be undone. Once deleted, neither you nor the provider will be able to see it.")
                    .font(.rzBodySmall)
                    .foregroundStyle(.rzTextSecondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Buttons
                RZButton(
                    title: "Delete Review",
                    variant: .destructive,
                    size: .large,
                    isFullWidth: true,
                    isLoading: isDeleting
                ) {
                    handleDelete()
                }

                RZButton(
                    title: "Cancel",
                    variant: .ghost,
                    size: .large,
                    isFullWidth: true
                ) {
                    isPresented = false
                }
            }
        } onDismiss: {
            isPresented = false
        }
    }

    private func handleDelete() {
        isDeleting = true
        Task {
            defer { isDeleting = false }
            do {
                let _: Review = try await appState.apiClient.delete(APIEndpoints.review(review.id))
                appState.showToast("Review deleted.", type: .info)
                isPresented = false
                onDeleted()
            } catch {
                appState.showToast(error.localizedDescription, type: .error)
            }
        }
    }
}
