import SwiftUI

// MARK: - ViewModel

@Observable
@MainActor
final class BrandDetailViewModel {
    var brand: Brand? = nil
    var members: [BrandMembership] = []
    var services: [Service] = []
    var reviews: [Review] = []
    var isLoading: Bool = false

    func load(id: String, apiClient: APIClient) async {
        isLoading = true
        defer { isLoading = false }
        async let brandFetch: Brand = apiClient.get(APIEndpoints.brand(id))
        async let membersFetch: [BrandMembership] = (try? apiClient.get(APIEndpoints.brandMembers(id))) ?? []
        async let servicesFetch: [Service] = (try? apiClient.get(APIEndpoints.services, query: ["brandId": id, "limit": "20"])) ?? []
        async let reviewsFetch: [Review] = (try? apiClient.get(APIEndpoints.reviews, query: ["brandId": id, "targetType": "BRAND", "limit": "10"])) ?? []

        do {
            let (b, m, s, r) = try await (brandFetch, membersFetch, servicesFetch, reviewsFetch)
            brand = b
            members = m
            services = s
            reviews = r
        } catch {
            // brand fetch failed
        }
    }
}

// MARK: - Screen

struct BrandDetailScreen: View {
    let brandId: String

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = BrandDetailViewModel()
    @State private var showReportSheet = false

    var body: some View {
        VStack(spacing: 0) {
            // Top bar
            RZTopBar(title: viewModel.brand?.name ?? "Brand") {
                RZIconButton(icon: "chevron.left") { dismiss() }
            } trailing: {
                Button {
                    guard let name = viewModel.brand?.name,
                          let url = URL(string: "reziphay://brand/\(brandId)") else { return }
                    let activity = UIActivityViewController(activityItems: [name, url], applicationActivities: nil)
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let root = windowScene.windows.first?.rootViewController {
                        root.present(activity, animated: true)
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.rzTextPrimary)
                        .frame(width: 44, height: 44)
                }
            }

            Divider()

            if viewModel.isLoading {
                brandDetailSkeleton
            } else if let brand = viewModel.brand {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: RZSpacing.sectionVertical) {
                        // Brand header
                        brandHeader(brand: brand)
                            .padding(.horizontal, RZSpacing.screenHorizontal)

                        // Stats row
                        statsRow(brand: brand)
                            .padding(.horizontal, RZSpacing.screenHorizontal)

                        // Description
                        if let desc = brand.description, !desc.isEmpty {
                            descriptionSection(desc: desc)
                                .padding(.horizontal, RZSpacing.screenHorizontal)
                        }

                        // Services section
                        if !viewModel.services.isEmpty {
                            servicesSection
                        }

                        // Team section
                        if !viewModel.members.isEmpty {
                            teamSection
                        }

                        // Reviews section
                        reviewsSection
                            .padding(.horizontal, RZSpacing.screenHorizontal)

                        // Report action
                        Button {
                            showReportSheet = true
                        } label: {
                            Text("Report this brand")
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
                    icon: "exclamationmark.triangle",
                    title: "Brand not found",
                    subtitle: "This brand may have been removed.",
                    actionTitle: "Go Back",
                    action: { dismiss() }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.rzBackground)
        .navigationBarHidden(true)
        .task {
            await viewModel.load(id: brandId, apiClient: appState.apiClient)
        }
        .sheet(isPresented: $showReportSheet) {
            BrandReportSheet(brandId: brandId, isPresented: $showReportSheet)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Brand Header

    private func brandHeader(brand: Brand) -> some View {
        HStack(spacing: RZSpacing.md) {
            if let logoURL = brand.logoURL {
                AsyncImage(url: logoURL) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    RZSkeletonView(width: 72, height: 72, radius: RZRadius.card)
                }
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: RZRadius.card))
                .rzShadow(RZShadow.sm)
            } else {
                RZAvatarView(name: brand.name, size: 72)
            }

            VStack(alignment: .leading, spacing: RZSpacing.xxs) {
                Text(brand.name)
                    .font(.rzH2)
                    .foregroundStyle(.rzTextPrimary)

                if let address = brand.primaryAddress {
                    HStack(spacing: RZSpacing.xxxs) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 11))
                            .foregroundStyle(.rzTextTertiary)
                        Text(address.city)
                            .font(.rzBodySmall)
                            .foregroundStyle(.rzTextSecondary)
                    }
                }

                RZStatusPill(
                    text: brand.status == .active ? "Active" : brand.status.rawValue.capitalized,
                    color: brand.status == .active ? .rzSuccess : .rzWarning
                )
            }

            Spacer()
        }
    }

    // MARK: - Stats Row

    private func statsRow(brand: Brand) -> some View {
        HStack(spacing: 0) {
            statItem(
                value: brand.ratingStats.map { String(format: "%.1f", $0.avgRating) } ?? "—",
                label: "Rating"
            )
            Divider().frame(height: 40)
            statItem(
                value: brand.ratingStats.map { "\($0.reviewCount)" } ?? "0",
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

    // MARK: - Team Section

    private var teamSection: some View {
        VStack(alignment: .leading, spacing: RZSpacing.xs) {
            RZSectionHeader(title: "Team")
                .padding(.horizontal, RZSpacing.screenHorizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: RZSpacing.xs) {
                    ForEach(viewModel.members) { member in
                        if let user = member.user {
                            Button {
                                appState.router.push(.providerDetail(id: user.id), forRole: .ucr)
                            } label: {
                                VStack(spacing: RZSpacing.xxs) {
                                    RZAvatarView(name: user.fullName, size: 52)
                                    Text(user.fullName.components(separatedBy: " ").first ?? user.fullName)
                                        .font(.rzCaption)
                                        .foregroundStyle(.rzTextSecondary)
                                        .lineLimit(1)
                                    RZStatusPill(
                                        text: member.membershipRole == .owner ? "Owner" : "Member",
                                        color: member.membershipRole == .owner ? .rzPrimary : .rzTextTertiary
                                    )
                                }
                                .frame(width: 72)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, RZSpacing.screenHorizontal)
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

    private var brandDetailSkeleton: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: RZSpacing.sm) {
                HStack(spacing: RZSpacing.md) {
                    RZSkeletonView(width: 72, height: 72, radius: RZRadius.card)
                    VStack(alignment: .leading, spacing: RZSpacing.xxs) {
                        RZSkeletonView(width: 180, height: 22)
                        RZSkeletonView(width: 100, height: 14)
                    }
                }
                .padding(.horizontal, RZSpacing.screenHorizontal)

                RZSkeletonView(height: 72, radius: RZRadius.card)
                    .padding(.horizontal, RZSpacing.screenHorizontal)

                RZSkeletonView(height: 80, radius: RZRadius.card)
                    .padding(.horizontal, RZSpacing.screenHorizontal)

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

// MARK: - Brand Report Sheet

private struct BrandReportSheet: View {
    let brandId: String
    @Binding var isPresented: Bool
    @Environment(AppState.self) private var appState

    @State private var reason = ""
    @State private var isSubmitting = false

    var body: some View {
        RZBottomSheet(title: "Report Brand", onDismiss: { isPresented = false }) {
            VStack(spacing: RZSpacing.sm) {
                Text("Describe the issue with this brand.")
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
                                "targetType": ReportTargetType.brand.rawValue,
                                "targetId": brandId,
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
