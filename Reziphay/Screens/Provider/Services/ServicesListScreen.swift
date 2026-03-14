import SwiftUI

// MARK: - ViewModel

@Observable
@MainActor
final class ServicesListViewModel {
    var services: [Service] = []
    var isLoading: Bool = false
    var filterActive: Bool = false

    var filteredServices: [Service] {
        if filterActive {
            return services.filter { $0.isActive }
        }
        return services
    }

    func load(apiClient: APIClient, ownerUserId: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            services = try await apiClient.get(
                APIEndpoints.services,
                query: ["ownerUserId": ownerUserId]
            )
        } catch {
            services = []
        }
    }
}

// MARK: - Screen

struct ServicesListScreen: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = ServicesListViewModel()

    private var currentUserId: String {
        appState.authManager.currentUser?.id ?? ""
    }

    var body: some View {
        VStack(spacing: 0) {
            RZTopBar(title: "My Services") {
                RZIconButton(icon: "chevron.left") { dismiss() }
            } trailing: {
                RZButton(title: "Create", variant: .primary, size: .small) {
                    appState.router.push(.createService, forRole: .uso)
                }
            }

            filterChips
                .padding(.horizontal, RZSpacing.screenHorizontal)
                .padding(.vertical, RZSpacing.xs)

            Divider()

            if viewModel.isLoading {
                skeletonList
            } else if viewModel.filteredServices.isEmpty {
                emptyState
            } else {
                serviceList
            }
        }
        .background(Color.rzBackground)
        .navigationBarHidden(true)
        .task {
            await viewModel.load(apiClient: appState.apiClient, ownerUserId: currentUserId)
        }
        .refreshable {
            await viewModel.load(apiClient: appState.apiClient, ownerUserId: currentUserId)
        }
    }

    // MARK: - Filter Chips

    private var filterChips: some View {
        HStack(spacing: RZSpacing.xxs) {
            filterChip(title: "All", isSelected: !viewModel.filterActive) {
                viewModel.filterActive = false
            }
            filterChip(title: "Active", isSelected: viewModel.filterActive) {
                viewModel.filterActive = true
            }
            Spacer()
        }
    }

    private func filterChip(title: String, isSelected: Bool, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            Text(title)
                .font(.rzBodySmall)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .white : .rzTextSecondary)
                .padding(.horizontal, RZSpacing.sm)
                .padding(.vertical, RZSpacing.xxs)
                .background(isSelected ? Color.rzPrimary : Color.rzSurface)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(isSelected ? Color.clear : Color.rzBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Service List

    private var serviceList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: RZSpacing.xs) {
                ForEach(viewModel.filteredServices) { service in
                    serviceRow(service: service)
                        .padding(.horizontal, RZSpacing.screenHorizontal)
                }
            }
            .padding(.top, RZSpacing.sm)
            .padding(.bottom, RZSpacing.xl)
        }
    }

    private func serviceRow(service: Service) -> some View {
        Button {
            appState.router.push(.editService(id: service.id), forRole: .uso)
        } label: {
            RZCard {
                HStack(spacing: RZSpacing.sm) {
                    VStack(alignment: .leading, spacing: RZSpacing.xxxs) {
                        Text(service.name)
                            .font(.rzBodyLarge)
                            .fontWeight(.semibold)
                            .foregroundStyle(.rzTextPrimary)
                            .lineLimit(1)

                        if let brand = service.brand {
                            HStack(spacing: RZSpacing.xxxs) {
                                Image(systemName: "building.2.fill")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.rzTextTertiary)
                                Text(brand.name)
                                    .font(.rzBodySmall)
                                    .foregroundStyle(.rzTextSecondary)
                            }
                        }

                        HStack(spacing: RZSpacing.xxs) {
                            if let price = service.formattedPrice {
                                RZStatusPill(text: price, color: .rzPrimary)
                            }
                            RZStatusPill(
                                text: service.approvalMode == .manual ? "Manual" : "Auto",
                                color: service.approvalMode == .manual ? .rzWarning : .rzSuccess
                            )
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: RZSpacing.xxs) {
                        RZStatusPill(
                            text: service.isActive ? "Active" : "Inactive",
                            color: service.isActive ? .rzSuccess : .rzTextTertiary
                        )
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.rzTextTertiary)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        RZEmptyState(
            icon: "calendar.badge.plus",
            title: viewModel.filterActive ? "No active services" : "No services yet",
            subtitle: viewModel.filterActive
                ? "None of your services are currently active."
                : "Create your first service to start accepting bookings.",
            actionTitle: viewModel.filterActive ? nil : "Create Service"
        ) {
            appState.router.push(.createService, forRole: .uso)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Skeleton

    private var skeletonList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: RZSpacing.xs) {
                ForEach(0..<5, id: \.self) { _ in
                    RZSkeletonView(height: 80, radius: RZRadius.card)
                        .padding(.horizontal, RZSpacing.screenHorizontal)
                }
            }
            .padding(.top, RZSpacing.sm)
        }
        .allowsHitTesting(false)
    }
}
