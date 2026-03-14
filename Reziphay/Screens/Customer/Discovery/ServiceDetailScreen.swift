import SwiftUI

// MARK: - ViewModel

@Observable
@MainActor
final class ServiceDetailViewModel {
    var service: Service? = nil
    var reviews: [Review] = []
    var isLoading: Bool = false
    var isLoadingReviews: Bool = false

    func load(id: String, apiClient: APIClient) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let result: Service = try await apiClient.get(APIEndpoints.service(id))
            service = result
        } catch {
            // error surfaced to screen
            throw error
        }
    }

    func loadReviews(serviceId: String, apiClient: APIClient) async {
        isLoadingReviews = true
        defer { isLoadingReviews = false }
        do {
            let result: [Review] = try await apiClient.get(
                APIEndpoints.reviews,
                query: ["serviceId": serviceId, "targetType": "SERVICE", "limit": "10"]
            )
            reviews = result
        } catch {
            // silent
        }
    }
}

// MARK: - Screen

struct ServiceDetailScreen: View {
    let serviceId: String

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ServiceDetailViewModel()
    @State private var showReportSheet = false
    @State private var showAllReviews = false

    var body: some View {
        ZStack(alignment: .bottom) {
            if viewModel.isLoading {
                serviceDetailSkeleton
            } else if let service = viewModel.service {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Image carousel with floating controls
                        imageHeader(service: service)

                        // Content
                        VStack(alignment: .leading, spacing: RZSpacing.sectionVertical) {
                            // Title + Provider info
                            titleSection(service: service)
                                .padding(.horizontal, RZSpacing.screenHorizontal)

                            // Rating
                            if let stats = service.ratingStats {
                                Button {
                                    showAllReviews = true
                                } label: {
                                    HStack(spacing: RZSpacing.xxs) {
                                        RZRatingRow(
                                            rating: stats.avgRating,
                                            reviewCount: stats.reviewCount
                                        )
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundStyle(.rzTextTertiary)
                                    }
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, RZSpacing.screenHorizontal)
                            }

                            // Key facts
                            keyFactsSection(service: service)
                                .padding(.horizontal, RZSpacing.screenHorizontal)

                            // Availability
                            if let rules = service.availabilityRules, !rules.isEmpty {
                                availabilitySection(rules: rules)
                                    .padding(.horizontal, RZSpacing.screenHorizontal)
                            }

                            // Description
                            if let desc = service.description, !desc.isEmpty {
                                descriptionSection(desc: desc)
                                    .padding(.horizontal, RZSpacing.screenHorizontal)
                            }

                            // Provider mini card
                            providerMiniCard(service: service)
                                .padding(.horizontal, RZSpacing.screenHorizontal)

                            // Brand mini card
                            if let brand = service.brand {
                                brandMiniCard(brand: brand)
                                    .padding(.horizontal, RZSpacing.screenHorizontal)
                            }

                            // Reviews section
                            reviewsSection
                                .padding(.horizontal, RZSpacing.screenHorizontal)

                            // Report action
                            Button {
                                showReportSheet = true
                            } label: {
                                Text("Report this service")
                                    .font(.rzCaption)
                                    .foregroundStyle(.rzTextTertiary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, RZSpacing.screenHorizontal)
                            .padding(.bottom, 100) // space for sticky CTA
                        }
                        .padding(.top, RZSpacing.sm)
                    }
                }

                // Sticky CTA
                VStack(spacing: 0) {
                    Divider()
                    HStack(spacing: RZSpacing.xs) {
                        if let price = service.formattedPrice {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("From")
                                    .font(.rzCaption)
                                    .foregroundStyle(.rzTextTertiary)
                                Text(price)
                                    .font(.rzH3)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.rzTextPrimary)
                            }
                        }
                        RZButton(title: "Reserve") {
                            appState.router.push(.createReservation(serviceId: serviceId), forRole: .ucr)
                        }
                    }
                    .padding(.horizontal, RZSpacing.screenHorizontal)
                    .padding(.vertical, RZSpacing.sm)
                    .background(Color.rzBackground)
                }
            } else {
                // Error or empty
                VStack {
                    RZEmptyState(
                        icon: "exclamationmark.triangle",
                        title: "Service not found",
                        subtitle: "This service may have been removed.",
                        actionTitle: "Go Back",
                        action: { dismiss() }
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarHidden(true)
        .background(Color.rzBackground)
        .task {
            do {
                try await viewModel.load(id: serviceId, apiClient: appState.apiClient)
                await viewModel.loadReviews(serviceId: serviceId, apiClient: appState.apiClient)
            } catch {
                appState.showToast("Failed to load service", type: .error)
                dismiss()
            }
        }
        .sheet(isPresented: $showReportSheet) {
            ReportSheet(
                targetType: .service,
                targetId: serviceId,
                isPresented: $showReportSheet
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Image Header

    private func imageHeader(service: Service) -> some View {
        ZStack(alignment: .topLeading) {
            RZImageCarousel(imageURLs: service.photoURLs, height: 260)

            // Back button overlay
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 36, height: 36)
                        .background(.thinMaterial)
                        .clipShape(Circle())
                }

                Spacer()

                Button {
                    guard let url = URL(string: "reziphay://service/\(serviceId)") else { return }
                    let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let root = windowScene.windows.first?.rootViewController {
                        root.present(activity, animated: true)
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 36, height: 36)
                        .background(.thinMaterial)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, RZSpacing.screenHorizontal)
            .padding(.top, 56) // status bar clearance
        }
    }

    // MARK: - Title Section

    private func titleSection(service: Service) -> some View {
        VStack(alignment: .leading, spacing: RZSpacing.xxs) {
            Text(service.name)
                .font(.rzH2)
                .foregroundStyle(.rzTextPrimary)

            HStack(spacing: RZSpacing.xxs) {
                if let brandName = service.brand?.name {
                    Text(brandName)
                        .font(.rzBodySmall)
                        .foregroundStyle(.rzTextSecondary)
                } else if let ownerName = service.ownerName {
                    Text(ownerName)
                        .font(.rzBodySmall)
                        .foregroundStyle(.rzTextSecondary)
                }
            }
        }
    }

    // MARK: - Key Facts

    private func keyFactsSection(service: Service) -> some View {
        VStack(alignment: .leading, spacing: RZSpacing.xs) {
            // Category
            if let category = service.category {
                factRow(
                    icon: "tag",
                    content: AnyView(
                        RZStatusPill(text: category.name, color: .rzPrimary)
                    )
                )
            }

            // Address
            if let address = service.address {
                factRow(
                    icon: "mappin.and.ellipse",
                    content: AnyView(
                        Text(address.fullAddress)
                            .font(.rzBody)
                            .foregroundStyle(.rzTextPrimary)
                    )
                )
            }

            // Price
            if let price = service.formattedPrice {
                factRow(
                    icon: "banknote",
                    content: AnyView(
                        Text(price)
                            .font(.rzBody)
                            .fontWeight(.semibold)
                            .foregroundStyle(.rzTextPrimary)
                    )
                )
            }

            // Approval mode
            factRow(
                icon: service.approvalMode == .auto ? "bolt.fill" : "clock",
                content: AnyView(
                    Text(service.approvalMode == .auto
                         ? "Auto-confirm"
                         : "Manual approval — ~\(service.waitingTimeMinutes) min response")
                        .font(.rzBody)
                        .foregroundStyle(service.approvalMode == .auto ? .rzSuccess : .rzWarning)
                )
            )
        }
        .padding(RZSpacing.sm)
        .background(Color.rzSurface)
        .clipShape(RoundedRectangle(cornerRadius: RZRadius.card))
        .rzShadow(RZShadow.sm)
    }

    private func factRow(icon: String, content: AnyView) -> some View {
        HStack(alignment: .center, spacing: RZSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.rzPrimary)
                .frame(width: 20)
            content
            Spacer()
        }
    }

    // MARK: - Availability Section

    private func availabilitySection(rules: [AvailabilityRule]) -> some View {
        VStack(alignment: .leading, spacing: RZSpacing.xs) {
            Text("Availability")
                .font(.rzH4)
                .foregroundStyle(.rzTextPrimary)

            VStack(alignment: .leading, spacing: RZSpacing.xxs) {
                ForEach(rules.filter { $0.isActive }, id: \.id) { rule in
                    HStack {
                        Text(rule.dayOfWeek.displayName)
                            .font(.rzBodySmall)
                            .foregroundStyle(.rzTextSecondary)
                            .frame(width: 80, alignment: .leading)
                        Text("\(rule.startTime) – \(rule.endTime)")
                            .font(.rzBodySmall)
                            .foregroundStyle(.rzTextPrimary)
                    }
                }
            }
        }
    }

    // MARK: - Description

    private func descriptionSection(desc: String) -> some View {
        VStack(alignment: .leading, spacing: RZSpacing.xs) {
            Text("About")
                .font(.rzH4)
                .foregroundStyle(.rzTextPrimary)

            Text(desc)
                .font(.rzBody)
                .foregroundStyle(.rzTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Provider Mini Card

    private func providerMiniCard(service: Service) -> some View {
        Button {
            appState.router.push(.providerDetail(id: service.ownerUserId), forRole: .ucr)
        } label: {
            HStack(spacing: RZSpacing.xs) {
                RZAvatarView(name: service.ownerName ?? "Provider", size: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Service provider")
                        .font(.rzCaption)
                        .foregroundStyle(.rzTextTertiary)
                    Text(service.ownerName ?? "Provider")
                        .font(.rzBody)
                        .fontWeight(.semibold)
                        .foregroundStyle(.rzTextPrimary)
                }

                Spacer()

                Text("View Profile")
                    .font(.rzLabel)
                    .foregroundStyle(.rzPrimary)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.rzTextTertiary)
            }
            .padding(RZSpacing.sm)
            .background(Color.rzSurface)
            .clipShape(RoundedRectangle(cornerRadius: RZRadius.card))
            .rzShadow(RZShadow.sm)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Brand Mini Card

    private func brandMiniCard(brand: BrandSummary) -> some View {
        Button {
            appState.router.push(.brandDetail(id: brand.id), forRole: .ucr)
        } label: {
            HStack(spacing: RZSpacing.xs) {
                RZAvatarView(name: brand.name, size: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Brand")
                        .font(.rzCaption)
                        .foregroundStyle(.rzTextTertiary)
                    Text(brand.name)
                        .font(.rzBody)
                        .fontWeight(.semibold)
                        .foregroundStyle(.rzTextPrimary)
                }

                Spacer()

                Text("View Brand")
                    .font(.rzLabel)
                    .foregroundStyle(.rzPrimary)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.rzTextTertiary)
            }
            .padding(RZSpacing.sm)
            .background(Color.rzSurface)
            .clipShape(RoundedRectangle(cornerRadius: RZRadius.card))
            .rzShadow(RZShadow.sm)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Reviews Section

    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: RZSpacing.xs) {
            RZSectionHeader(title: "Reviews", actionTitle: viewModel.reviews.count > 3 ? "See all" : nil) {
                showAllReviews = true
            }

            if viewModel.isLoadingReviews {
                ForEach(0..<3, id: \.self) { _ in
                    RZSkeletonListRow()
                }
            } else if viewModel.reviews.isEmpty {
                Text("No reviews yet")
                    .font(.rzBody)
                    .foregroundStyle(.rzTextTertiary)
            } else {
                VStack(spacing: RZSpacing.xs) {
                    ForEach(viewModel.reviews.prefix(3)) { review in
                        ReviewCard(review: review)
                    }
                }
            }
        }
    }

    // MARK: - Skeleton

    private var serviceDetailSkeleton: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: RZSpacing.sm) {
                RZSkeletonView(height: 260, radius: 0)

                VStack(alignment: .leading, spacing: RZSpacing.xs) {
                    RZSkeletonView(width: 220, height: 24)
                    RZSkeletonView(width: 140, height: 16)
                    RZSkeletonView(height: 100, radius: RZRadius.card)
                    RZSkeletonView(height: 80, radius: RZRadius.card)
                    RZSkeletonView(height: 60, radius: RZRadius.card)
                }
                .padding(.horizontal, RZSpacing.screenHorizontal)
            }
        }
        .ignoresSafeArea(edges: .top)
        .allowsHitTesting(false)
    }
}

// MARK: - DayOfWeek Display Extension

extension DayOfWeek {
    var displayName: String {
        switch self {
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        case .sunday: return "Sunday"
        }
    }
}

// MARK: - Report Sheet (inline minimal)

private struct ReportSheet: View {
    let targetType: ReportTargetType
    let targetId: String
    @Binding var isPresented: Bool
    @Environment(AppState.self) private var appState

    @State private var reason = ""
    @State private var isSubmitting = false

    var body: some View {
        RZBottomSheet(title: "Report", onDismiss: { isPresented = false }) {
            VStack(spacing: RZSpacing.sm) {
                Text("Please describe the issue with this \(targetType == .service ? "service" : "content").")
                    .font(.rzBody)
                    .foregroundStyle(.rzTextSecondary)

                RZTextArea(label: "Details", text: $reason, placeholder: "Describe the issue…")

                RZButton(
                    title: "Submit Report",
                    variant: .primary,
                    isLoading: isSubmitting,
                    isDisabled: reason.trimmingCharacters(in: .whitespaces).isEmpty
                ) {
                    Task {
                        isSubmitting = true
                        defer { isSubmitting = false }
                        do {
                            let body: [String: String] = [
                                "targetType": targetType.rawValue,
                                "targetId": targetId,
                                "reason": reason
                            ]
                            try await appState.apiClient.postVoid(APIEndpoints.reports, body: body)
                            appState.showToast("Report submitted. Thank you.", type: .success)
                            isPresented = false
                        } catch {
                            appState.showToast("Failed to submit report", type: .error)
                        }
                    }
                }
            }
        }
    }
}
