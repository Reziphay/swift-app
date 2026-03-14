import SwiftUI

// MARK: - ViewModel

@Observable
@MainActor
final class ReviewCreateViewModel {
    var reservation: Reservation?
    var isLoadingReservation: Bool = false
    var isSubmitting: Bool = false
    var rating: Int = 0
    var comment: String = ""

    private var appState: AppState?

    func setup(appState: AppState) {
        self.appState = appState
    }

    func loadReservation(id: String) async {
        isLoadingReservation = true
        defer { isLoadingReservation = false }
        do {
            reservation = try await appState?.apiClient.get(APIEndpoints.reservation(id))
        } catch {
            appState?.showToast("Failed to load reservation details.", type: .error)
        }
    }

    func submitReview(reservationId: String) async throws {
        guard let appState else { throw URLError(.unknown) }
        isSubmitting = true
        defer { isSubmitting = false }

        struct ReviewBody: Encodable {
            let reservationId: String
            let rating: Int
            let comment: String
            let targetType: String
        }
        let body = ReviewBody(
            reservationId: reservationId,
            rating: rating,
            comment: comment,
            targetType: "SERVICE"
        )
        let _: Review = try await appState.apiClient.post(APIEndpoints.reviews, body: body)
    }
}

// MARK: - Screen

struct ReviewCreateScreen: View {
    let reservationId: String

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = ReviewCreateViewModel()
    @State private var ratingError: String? = nil

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.rzBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                RZTopBar(title: "Leave a Review") {
                    RZIconButton(icon: "chevron.left") { dismiss() }
                }

                ScrollView {
                    VStack(spacing: RZSpacing.sectionVertical) {
                        if viewModel.isLoadingReservation {
                            reservationSkeleton
                        } else if let reservation = viewModel.reservation {
                            reservationSummaryCard(reservation: reservation)
                        }

                        ratingSection

                        commentSection

                        // Note
                        HStack(spacing: RZSpacing.xxs) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(.rzTextTertiary)
                            Text("Reviews cannot be edited after submission.")
                                .font(.rzCaption)
                                .foregroundStyle(.rzTextTertiary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, RZSpacing.screenHorizontal)
                    .padding(.top, RZSpacing.sm)
                    .padding(.bottom, 100)
                }
            }

            // Sticky submit button
            VStack(spacing: 0) {
                Divider()
                RZButton(
                    title: "Submit Review",
                    variant: .primary,
                    size: .large,
                    isFullWidth: true,
                    isLoading: viewModel.isSubmitting,
                    isDisabled: viewModel.rating == 0
                ) {
                    handleSubmit()
                }
                .padding(.horizontal, RZSpacing.screenHorizontal)
                .padding(.vertical, RZSpacing.sm)
                .background(Color.rzBackground)
            }
        }
        .navigationBarHidden(true)
        .task {
            viewModel.setup(appState: appState)
            await viewModel.loadReservation(id: reservationId)
        }
    }

    // MARK: - Reservation Summary Card

    private func reservationSummaryCard(reservation: Reservation) -> some View {
        RZCard {
            HStack(spacing: RZSpacing.xs) {
                Image(systemName: "calendar.badge.checkmark")
                    .font(.system(size: 24))
                    .foregroundStyle(.rzPrimary)
                VStack(alignment: .leading, spacing: RZSpacing.xxxs) {
                    Text(reservation.serviceName ?? "Service")
                        .font(.rzH4)
                        .foregroundStyle(.rzTextPrimary)
                    if let brand = reservation.brand {
                        Text(brand.name)
                            .font(.rzBodySmall)
                            .foregroundStyle(.rzTextSecondary)
                    }
                    Text(reservation.formattedDateTime)
                        .font(.rzCaption)
                        .foregroundStyle(.rzTextTertiary)
                }
                Spacer()
                RZStatusPill(
                    text: reservation.status.displayLabel,
                    color: reservation.status.displayColor
                )
            }
        }
    }

    private var reservationSkeleton: some View {
        RZCard {
            VStack(alignment: .leading, spacing: RZSpacing.xxs) {
                RZSkeletonView(height: 18, radius: 6)
                RZSkeletonView(height: 14, radius: 4).frame(width: 140)
                RZSkeletonView(height: 12, radius: 4).frame(width: 180)
            }
        }
    }

    // MARK: - Rating Section

    private var ratingSection: some View {
        RZCard {
            VStack(spacing: RZSpacing.sm) {
                Text("Rate your experience")
                    .font(.rzH4)
                    .foregroundStyle(.rzTextPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                RZStarSelector(rating: Binding(
                    get: { viewModel.rating },
                    set: { viewModel.rating = $0; ratingError = nil }
                ))
                .frame(maxWidth: .infinity, alignment: .center)

                if let error = ratingError {
                    Text(error)
                        .font(.rzCaption)
                        .foregroundStyle(.rzError)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if viewModel.rating > 0 {
                    Text(ratingLabel)
                        .font(.rzBodySmall)
                        .fontWeight(.semibold)
                        .foregroundStyle(ratingColor)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                        .animation(.easeInOut(duration: 0.2), value: viewModel.rating)
                }
            }
        }
    }

    private var ratingLabel: String {
        switch viewModel.rating {
        case 1: return "Poor"
        case 2: return "Fair"
        case 3: return "Good"
        case 4: return "Very Good"
        case 5: return "Excellent!"
        default: return ""
        }
    }

    private var ratingColor: Color {
        switch viewModel.rating {
        case 1, 2: return .rzError
        case 3: return .rzWarning
        case 4, 5: return .rzSuccess
        default: return .rzTextSecondary
        }
    }

    // MARK: - Comment Section

    private var commentSection: some View {
        RZTextArea(
            label: "Your Comment (optional)",
            text: Binding(
                get: { viewModel.comment },
                set: { viewModel.comment = $0 }
            ),
            placeholder: "Share your experience with this service. Your feedback helps others make better choices."
        )
    }

    // MARK: - Actions

    private func handleSubmit() {
        ratingError = nil
        guard viewModel.rating > 0 else {
            ratingError = "Please select a rating."
            return
        }
        Task {
            do {
                try await viewModel.submitReview(reservationId: reservationId)
                appState.showToast("Review submitted. Thank you!", type: .success)
                dismiss()
            } catch {
                appState.showToast(error.localizedDescription, type: .error)
            }
        }
    }
}
