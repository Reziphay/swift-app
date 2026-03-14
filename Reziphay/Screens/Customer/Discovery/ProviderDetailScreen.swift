import SwiftUI

// MARK: - ViewModel

@Observable
@MainActor
final class ProviderDetailViewModel {
    var provider: ProviderProfile? = nil
    var services: [Service] = []
    var reviews: [Review] = []
    var isLoading: Bool = false

    func load(id: String, apiClient: APIClient) async {
        isLoading = true
        defer { isLoading = false }
        async let providerFetch: ProviderProfile = apiClient.get("\(APIEndpoints.serviceOwners)/\(id)")
        async let servicesFetch: [Service] = (try? apiClient.get(
            APIEndpoints.services,
            query: ["ownerUserId": id, "limit": "20"]
        )) ?? []
        async let reviewsFetch: [Review] = (try? apiClient.get(
            APIEndpoints.reviews,
            query: ["ownerId": id, "targetType": "SERVICE_OWNER", "limit": "10"]
        )) ?? []

        do {
            let (p, s, r) = try await (providerFetch, servicesFetch, reviewsFetch)
            provider = p
            services = s
            reviews = r
        } catch {
            // provider fetch failed
        }
    }
}

// MARK: - Screen

struct ProviderDetailScreen: View {
    let providerId: String

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ProviderDetailViewModel()
    @State private var showReportSheet = false

    var body: some View {
        VStack(spacing: 0) {
            // Top bar
            RZTopBar(title: viewModel.provider?.fullName ?? "Provider") {
                RZIconButton(icon: "chevron.left") { dismiss() }
            }

            Divider()

            if viewModel.isLoading {
                providerDetailSkeleton
            } else if let provider = viewModel.provider {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: RZSpacing.sectionVertical) {
                        // Provider header
                        providerHeader(provider: provider)
                            .padding(.horizontal, RZSpacing.screenHorizontal)

                        // Stats row
                        statsRow(provider: provider)
                            .padding(.horizontal, RZSpacing.screenHorizontal)

                        // Associated brands
                        if let brandNames = provider.brandNames, !brandNames.isEmpty {
                            brandsSection(brandNames: brandNames)
                        }

                        // Services section
                        if !viewModel.services.isEmpty {
                            servicesSection
                        }

                        // Reviews section
                        reviewsSection
                            .padding(.horizontal, RZSpacing.screenHorizontal)

                        // Report action
                        Button {
                            showReportSheet = true
                        } label: {
                            Text("Report this provider")
                                .font(.rzCaption)
                                .foregroundStyle(.rzTextTertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, RZSpacing.screenHorizontal)
                        .padding(.bottom, RZSpacing.xxl)
                    }
                    .padding(.top, RZSpacing.sm)
                }
            } else {
                RZEmptyState(
                    icon: "person.slash",
                    title: "Provider not found",
                    subtitle: "This provider profile could not be loaded.",
                    actionTitle: "Go Back",
                    action: { dismiss() }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.rzBackground)
        .navigationBarHidden(true)
        .task {
            await viewModel.load(id: providerId, apiClient: appState.apiClient)
        }
        .sheet(isPresented: $showReportSheet) {
            ProviderReportSheet(providerId: providerId, isPresented: $showReportSheet)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Provider Header

    private func providerHeader(provider: ProviderProfile) -> some View {
        VStack(spacing: RZSpacing.xs) {
            RZAvatarView(name: provider.fullName, size: 80)

            VStack(spacing: RZSpacing.xxxs) {
                Text(provider.fullName)
                    .font(.rzH2)
                    .foregroundStyle(.rzTextPrimary)
                    .multilineTextAlignment(.center)

                if let brandNames = provider.brandNames, !brandNames.isEmpty {
                    Text(brandNames.joined(separator: " · "))
                        .font(.rzBodySmall)
                        .foregroundStyle(.rzTextSecondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Stats Row

    private func statsRow(provider: ProviderProfile) -> some View {
        HStack(spacing: 0) {
            statItem(
                value: provider.ratingStats.map { String(format: "%.1f", $0.avgRating) } ?? "—",
                label: "Rating"
            )
            Divider().frame(height: 40)
            statItem(
                value: provider.ratingStats.map { "\($0.reviewCount)" } ?? "0",
                label: "Reviews"
            )
            Divider().frame(height: 40)
            statItem(
                value: "\(viewModel.services.count)",
                label: "Services"
            )
        }
        .padding(.vertical, RZSpacing.sm)
        .background(Color.rzSurface)
        .clipShape(RoundedRectangle(cornerRadius: RZRadius.card))
        .rzShadow(RZShadow.sm)
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: RZSpacing.xxxs) {
            Text(value)
                .font(.rzH3)
                .fontWeight(.bold)
                .foregroundStyle(.rzTextPrimary)
            Text(label)
                .font(.rzCaption)
                .foregroundStyle(.rzTextTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Brands Section

    private func brandsSection(brandNames: [String]) -> some View {
        VStack(alignment: .leading, spacing: RZSpacing.xs) {
            RZSectionHeader(title: "Associated Brands")
                .padding(.horizontal, RZSpacing.screenHorizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: RZSpacing.xs) {
                    ForEach(brandNames, id: \.self) { brandName in
                        HStack(spacing: RZSpacing.xxs) {
                            RZAvatarView(name: brandName, size: 36)
                            Text(brandName)
                                .font(.rzBodySmall)
                                .fontWeight(.medium)
                                .foregroundStyle(.rzTextPrimary)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, RZSpacing.xs)
                        .padding(.vertical, RZSpacing.xxs)
                        .background(Color.rzSurface)
                        .clipShape(RoundedRectangle(cornerRadius: RZRadius.card))
                        .rzShadow(RZShadow.sm)
                    }
                }
                .padding(.horizontal, RZSpacing.screenHorizontal)
            }
        }
    }

    // MARK: - Services Section

    private var servicesSection: some View {
        VStack(alignment: .leading, spacing: RZSpacing.xs) {
            RZSectionHeader(title: "Services")
                .padding(.horizontal, RZSpacing.screenHorizontal)

            LazyVStack(spacing: RZSpacing.xs) {
                ForEach(viewModel.services) { service in
                    ServiceCard(service: service) {
                        appState.router.push(.serviceDetail(id: service.id), forRole: .ucr)
                    }
                    .padding(.horizontal, RZSpacing.screenHorizontal)
                }
            }
        }
    }

    // MARK: - Reviews Section

    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: RZSpacing.xs) {
            RZSectionHeader(title: "Reviews")

            if viewModel.reviews.isEmpty {
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

    private var providerDetailSkeleton: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: RZSpacing.sm) {
                // Header skeleton
                VStack(spacing: RZSpacing.xs) {
                    RZSkeletonView(width: 80, height: 80, radius: 40)
                    RZSkeletonView(width: 200, height: 22)
                    RZSkeletonView(width: 140, height: 16)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, RZSpacing.screenHorizontal)

                // Stats skeleton
                RZSkeletonView(height: 72, radius: RZRadius.card)
                    .padding(.horizontal, RZSpacing.screenHorizontal)

                // Services skeleton
                ForEach(0..<4, id: \.self) { _ in
                    RZSkeletonCard()
                        .padding(.horizontal, RZSpacing.screenHorizontal)
                }
            }
            .padding(.top, RZSpacing.sm)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Provider Report Sheet

private struct ProviderReportSheet: View {
    let providerId: String
    @Binding var isPresented: Bool
    @Environment(AppState.self) private var appState

    @State private var reason = ""
    @State private var isSubmitting = false

    var body: some View {
        RZBottomSheet(title: "Report Provider", onDismiss: { isPresented = false }) {
            VStack(spacing: RZSpacing.sm) {
                Text("Describe the issue with this provider.")
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
                                "targetType": ReportTargetType.user.rawValue,
                                "targetId": providerId,
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
