import SwiftUI

struct ObjectionSubmissionScreen: View {
    let reservationId: String

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var reservation: Reservation?
    @State private var isLoadingReservation: Bool = false
    @State private var selectedObjectionType: ReservationObjectionType = .noShowDispute
    @State private var reason: String = ""
    @State private var reasonError: String? = nil
    @State private var isSubmitting: Bool = false

    private let objectionOptions: [(ReservationObjectionType, String, String)] = [
        (.noShowDispute, "I was present but marked as no-show", "person.fill.checkmark"),
        (.other, "Other", "ellipsis.circle")
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.rzBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                RZTopBar(title: "Submit Objection") {
                    RZIconButton(icon: "chevron.left") { dismiss() }
                }

                ScrollView {
                    VStack(spacing: RZSpacing.sectionVertical) {
                        if isLoadingReservation {
                            reservationSkeleton
                        } else if let reservation {
                            reservationSummaryCard(reservation: reservation)
                        }

                        objectionTypeSection

                        reasonSection

                        // Info note
                        HStack(alignment: .top, spacing: RZSpacing.xxs) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(.rzPrimary)
                            Text("Objections are reviewed by our team within 24–48 hours. Providing accurate information helps us resolve your case faster.")
                                .font(.rzCaption)
                                .foregroundStyle(.rzTextSecondary)
                        }
                        .padding(RZSpacing.xs)
                        .background(Color.rzPrimary.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: RZRadius.card))
                    }
                    .padding(.horizontal, RZSpacing.screenHorizontal)
                    .padding(.top, RZSpacing.sm)
                    .padding(.bottom, 100)
                }
            }

            // Sticky button
            VStack(spacing: 0) {
                Divider()
                RZButton(
                    title: "Submit Objection",
                    variant: .primary,
                    size: .large,
                    isFullWidth: true,
                    isLoading: isSubmitting
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
            await loadReservation()
        }
    }

    // MARK: - Reservation Summary

    private func reservationSummaryCard(reservation: Reservation) -> some View {
        RZCard {
            HStack(spacing: RZSpacing.xs) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.rzError)
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
                RZStatusPill(text: "No-Show", color: .rzError)
            }
        }
    }

    private var reservationSkeleton: some View {
        RZCard {
            VStack(alignment: .leading, spacing: RZSpacing.xxs) {
                RZSkeletonView(height: 18, radius: 6)
                RZSkeletonView(height: 14, radius: 4).frame(width: 160)
            }
        }
    }

    // MARK: - Objection Type

    private var objectionTypeSection: some View {
        VStack(alignment: .leading, spacing: RZSpacing.xs) {
            Text("Objection Type")
                .font(.rzH4)
                .foregroundStyle(.rzTextPrimary)

            VStack(spacing: RZSpacing.xs) {
                ForEach(objectionOptions, id: \.0) { (type, label, icon) in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedObjectionType = type
                        }
                    } label: {
                        HStack(spacing: RZSpacing.xs) {
                            Image(systemName: icon)
                                .font(.system(size: 18))
                                .foregroundStyle(selectedObjectionType == type ? .rzPrimary : .rzTextTertiary)
                                .frame(width: 24)

                            Text(label)
                                .font(.rzBody)
                                .foregroundStyle(.rzTextPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Image(systemName: selectedObjectionType == type ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 20))
                                .foregroundStyle(selectedObjectionType == type ? Color.rzPrimary : Color.rzBorder)
                        }
                        .padding(RZSpacing.sm)
                        .background(
                            selectedObjectionType == type
                            ? Color.rzPrimary.opacity(0.06)
                            : Color.rzSurface
                        )
                        .clipShape(RoundedRectangle(cornerRadius: RZRadius.card))
                        .overlay(
                            RoundedRectangle(cornerRadius: RZRadius.card)
                                .strokeBorder(
                                    selectedObjectionType == type ? Color.rzPrimary.opacity(0.3) : Color.rzBorder,
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Reason Section

    private var reasonSection: some View {
        RZTextArea(
            label: "Reason",
            text: $reason,
            placeholder: "Describe the situation in detail. Include any evidence you may have (e.g., arrival time, messages with the provider)...",
            error: reasonError
        )
    }

    // MARK: - Actions

    private func loadReservation() async {
        isLoadingReservation = true
        defer { isLoadingReservation = false }
        do {
            reservation = try await appState.apiClient.get(APIEndpoints.reservation(reservationId))
        } catch {
            // Non-critical — just show the form without summary
        }
    }

    private func handleSubmit() {
        reasonError = nil
        let trimmed = reason.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            reasonError = "Reason is required."
            return
        }
        guard trimmed.count >= 20 else {
            reasonError = "Please provide a more detailed explanation (at least 20 characters)."
            return
        }

        isSubmitting = true
        Task {
            defer { isSubmitting = false }
            do {
                struct ObjectionBody: Encodable {
                    let objectionType: String
                    let reason: String
                }
                let body = ObjectionBody(
                    objectionType: selectedObjectionType.rawValue,
                    reason: trimmed
                )
                let _: ReservationObjection = try await appState.apiClient.post(
                    APIEndpoints.reservationObjections(reservationId),
                    body: body
                )
                appState.showToast("Objection submitted. We'll review it within 24–48 hours.", type: .success)
                dismiss()
            } catch {
                appState.showToast(error.localizedDescription, type: .error)
            }
        }
    }
}
