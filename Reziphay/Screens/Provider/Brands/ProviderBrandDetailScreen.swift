import SwiftUI

// MARK: - ViewModel

@Observable
@MainActor
final class ProviderBrandDetailViewModel {
    var brand: Brand?
    var members: [BrandMembership] = []
    var pendingRequests: [BrandJoinRequest] = []
    var services: [Service] = []
    var isLoading: Bool = false

    func load(id: String, apiClient: APIClient) async {
        isLoading = true
        defer { isLoading = false }

        await withTaskGroup(of: Void.self) { group in
            group.addTask { [weak self] in
                guard let self else { return }
                do {
                    let b: Brand = try await apiClient.get(APIEndpoints.brand(id))
                    await MainActor.run { self.brand = b }
                } catch { }
            }
            group.addTask { [weak self] in
                guard let self else { return }
                do {
                    let m: [BrandMembership] = try await apiClient.get(APIEndpoints.brandMembers(id))
                    await MainActor.run { self.members = m }
                } catch { }
            }
            group.addTask { [weak self] in
                guard let self else { return }
                do {
                    let r: [BrandJoinRequest] = try await apiClient.get(
                        APIEndpoints.brandJoinRequests(id),
                        query: ["status": "PENDING"]
                    )
                    await MainActor.run { self.pendingRequests = r }
                } catch { }
            }
            group.addTask { [weak self] in
                guard let self else { return }
                do {
                    let s: [Service] = try await apiClient.get(
                        APIEndpoints.services,
                        query: ["brandId": id]
                    )
                    await MainActor.run { self.services = s }
                } catch { }
            }
        }
    }
}

// MARK: - Screen

struct ProviderBrandDetailScreen: View {
    let brandId: String

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = ProviderBrandDetailViewModel()

    var body: some View {
        VStack(spacing: 0) {
            RZTopBar(title: viewModel.brand?.name ?? "Brand") {
                RZIconButton(icon: "chevron.left") { dismiss() }
            } trailing: {
                RZIconButton(icon: "pencil") {
                    appState.router.push(.editBrand(id: brandId), forRole: .uso)
                }
            }

            if viewModel.isLoading {
                skeletonContent
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: RZSpacing.sectionVertical) {
                        if let brand = viewModel.brand {
                            brandSummaryCard(brand: brand)
                        }

                        statsRow

                        membersSection

                        if !viewModel.pendingRequests.isEmpty {
                            joinRequestsBanner
                        }

                        servicesSection

                        addServiceButton
                            .padding(.horizontal, RZSpacing.screenHorizontal)
                    }
                    .padding(.top, RZSpacing.sm)
                    .padding(.bottom, RZSpacing.xl)
                }
                .refreshable {
                    await viewModel.load(id: brandId, apiClient: appState.apiClient)
                }
            }
        }
        .background(Color.rzBackground)
        .navigationBarHidden(true)
        .task {
            await viewModel.load(id: brandId, apiClient: appState.apiClient)
        }
    }

    // MARK: - Brand Summary Card

    private func brandSummaryCard(brand: Brand) -> some View {
        RZCard {
            VStack(alignment: .leading, spacing: RZSpacing.xs) {
                HStack(spacing: RZSpacing.sm) {
                    if let logoURL = brand.logoURL {
                        AsyncImage(url: logoURL) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: RZRadius.button))
                        } placeholder: {
                            brandLogoPlaceholder(name: brand.name, size: 60)
                        }
                    } else {
                        brandLogoPlaceholder(name: brand.name, size: 60)
                    }

                    VStack(alignment: .leading, spacing: RZSpacing.xxxs) {
                        Text(brand.name)
                            .font(.rzH3)
                            .foregroundStyle(.rzTextPrimary)
                        if let address = brand.primaryAddress {
                            HStack(spacing: RZSpacing.xxxs) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.rzTextTertiary)
                                Text([address.city, address.country].compactMap { $0 }.joined(separator: ", "))
                                    .font(.rzBodySmall)
                                    .foregroundStyle(.rzTextSecondary)
                            }
                        }
                        if let rating = brand.ratingStats {
                            RZRatingRow(rating: rating.averageRating, reviewCount: rating.totalReviews, size: .small)
                        }
                    }
                }

                if let description = brand.description, !description.isEmpty {
                    Text(description)
                        .font(.rzBody)
                        .foregroundStyle(.rzTextSecondary)
                        .lineLimit(3)
                }

                RZStatusPill(
                    text: brand.status == .active ? "Active" : "Inactive",
                    color: brand.status == .active ? .rzSuccess : .rzTextTertiary
                )
            }
        }
        .padding(.horizontal, RZSpacing.screenHorizontal)
    }

    private func brandLogoPlaceholder(name: String, size: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: RZRadius.button)
                .fill(Color.rzPrimary.opacity(0.1))
                .frame(width: size, height: size)
            Text(name.prefix(1).uppercased())
                .font(.rzH3)
                .foregroundStyle(.rzPrimary)
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: RZSpacing.xs) {
            brandStatCard(
                icon: "person.2.fill",
                value: "\(viewModel.members.count)",
                label: "Members"
            )
            brandStatCard(
                icon: "calendar",
                value: "\(viewModel.services.count)",
                label: "Services"
            )
            brandStatCard(
                icon: "star.fill",
                value: viewModel.brand?.ratingStats.map { String(format: "%.1f", $0.averageRating) } ?? "—",
                label: "Rating"
            )
        }
        .padding(.horizontal, RZSpacing.screenHorizontal)
    }

    private func brandStatCard(icon: String, value: String, label: String) -> some View {
        RZCard {
            VStack(spacing: RZSpacing.xxxs) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(.rzPrimary)
                Text(value)
                    .font(.rzH4)
                    .foregroundStyle(.rzTextPrimary)
                Text(label)
                    .font(.rzCaption)
                    .foregroundStyle(.rzTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, RZSpacing.xxs)
        }
    }

    // MARK: - Members Section

    private var membersSection: some View {
        VStack(alignment: .leading, spacing: RZSpacing.xs) {
            RZSectionHeader(title: "Members")
                .padding(.horizontal, RZSpacing.screenHorizontal)

            if viewModel.members.isEmpty {
                Text("No members yet.")
                    .font(.rzBody)
                    .foregroundStyle(.rzTextTertiary)
                    .padding(.horizontal, RZSpacing.screenHorizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: RZSpacing.sm) {
                        ForEach(viewModel.members) { membership in
                            memberAvatar(membership: membership)
                        }
                    }
                    .padding(.horizontal, RZSpacing.screenHorizontal)
                }
            }
        }
    }

    private func memberAvatar(membership: BrandMembership) -> some View {
        VStack(spacing: RZSpacing.xxxs) {
            RZAvatarView(
                name: membership.user?.fullName ?? "?",
                size: 48
            )
            Text(membership.user?.fullName.components(separatedBy: " ").first ?? "Member")
                .font(.rzCaption)
                .foregroundStyle(.rzTextSecondary)
                .lineLimit(1)
            if membership.membershipRole == .owner {
                RZStatusPill(text: "Owner", color: .rzPrimary)
            }
        }
        .frame(width: 64)
    }

    // MARK: - Join Requests Banner

    private var joinRequestsBanner: some View {
        Button {
            appState.router.push(.brandJoinRequests(id: brandId), forRole: .uso)
        } label: {
            HStack(spacing: RZSpacing.xs) {
                Image(systemName: "person.badge.clock.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.rzWarning)
                VStack(alignment: .leading, spacing: RZSpacing.xxxs) {
                    Text("Pending Join Requests")
                        .font(.rzBodySmall)
                        .fontWeight(.semibold)
                        .foregroundStyle(.rzTextPrimary)
                    Text("\(viewModel.pendingRequests.count) request\(viewModel.pendingRequests.count == 1 ? "" : "s") waiting for review")
                        .font(.rzCaption)
                        .foregroundStyle(.rzTextSecondary)
                }
                Spacer()
                HStack(spacing: RZSpacing.xxxs) {
                    RZStatusPill(text: "\(viewModel.pendingRequests.count)", color: .rzWarning)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.rzTextTertiary)
                }
            }
            .padding(RZSpacing.sm)
            .background(Color.rzWarning.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: RZRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: RZRadius.card)
                    .strokeBorder(Color.rzWarning.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, RZSpacing.screenHorizontal)
    }

    // MARK: - Services Section

    private var servicesSection: some View {
        VStack(alignment: .leading, spacing: RZSpacing.xs) {
            RZSectionHeader(
                title: "Services",
                actionTitle: "Add Service"
            ) {
                appState.router.push(.createService, forRole: .uso)
            }
            .padding(.horizontal, RZSpacing.screenHorizontal)

            if viewModel.services.isEmpty {
                VStack(spacing: RZSpacing.xxs) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 32))
                        .foregroundStyle(.rzTextTertiary)
                    Text("No services yet")
                        .font(.rzBody)
                        .foregroundStyle(.rzTextTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, RZSpacing.md)
            } else {
                VStack(spacing: RZSpacing.xs) {
                    ForEach(viewModel.services) { service in
                        ServiceCard(service: service) {
                            appState.router.push(.editService(id: service.id), forRole: .uso)
                        }
                        .padding(.horizontal, RZSpacing.screenHorizontal)
                    }
                }
            }
        }
    }

    // MARK: - Add Service Button

    private var addServiceButton: some View {
        RZButton(
            title: "Add New Service",
            variant: .secondary,
            isFullWidth: true
        ) {
            appState.router.push(.createService, forRole: .uso)
        }
    }

    // MARK: - Skeleton

    private var skeletonContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: RZSpacing.sectionVertical) {
                RZSkeletonView(height: 140, radius: RZRadius.card)
                    .padding(.horizontal, RZSpacing.screenHorizontal)
                HStack(spacing: RZSpacing.xs) {
                    ForEach(0..<3, id: \.self) { _ in
                        RZSkeletonView(height: 80, radius: RZRadius.card)
                    }
                }
                .padding(.horizontal, RZSpacing.screenHorizontal)
                ForEach(0..<3, id: \.self) { _ in
                    RZSkeletonView(height: 72, radius: RZRadius.card)
                        .padding(.horizontal, RZSpacing.screenHorizontal)
                }
            }
            .padding(.top, RZSpacing.sm)
        }
        .allowsHitTesting(false)
    }
}
