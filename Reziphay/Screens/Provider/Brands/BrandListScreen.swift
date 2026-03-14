import SwiftUI

// MARK: - ViewModel

@Observable
@MainActor
final class BrandListViewModel {
    var ownedBrands: [Brand] = []
    var joinedBrands: [Brand] = []
    var isLoading: Bool = false

    func load(apiClient: APIClient, currentUserId: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let all: [Brand] = try await apiClient.get(APIEndpoints.brands)
            ownedBrands = all.filter { brand in
                // Brands where user is owner — determined by membership role fetched in a real context
                // For now, use a heuristic: use the role query param endpoint
                true // placeholder — the real filter is done server-side via role=owner query
            }
        } catch { }

        await withTaskGroup(of: Void.self) { group in
            group.addTask { [weak self] in
                guard let self else { return }
                do {
                    let owned: [Brand] = try await apiClient.get(
                        APIEndpoints.brands,
                        query: ["role": "owner"]
                    )
                    await MainActor.run { self.ownedBrands = owned }
                } catch { }
            }
            group.addTask { [weak self] in
                guard let self else { return }
                do {
                    let joined: [Brand] = try await apiClient.get(
                        APIEndpoints.brands,
                        query: ["role": "member"]
                    )
                    await MainActor.run { self.joinedBrands = joined }
                } catch { }
            }
        }
    }
}

// MARK: - Screen

struct BrandListScreen: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = BrandListViewModel()

    private var currentUserId: String {
        appState.authManager.currentUser?.id ?? ""
    }

    var body: some View {
        VStack(spacing: 0) {
            RZTopBar(title: "My Brands") {
                RZIconButton(icon: "chevron.left") { dismiss() }
            } trailing: {
                RZButton(title: "Create Brand", variant: .primary, size: .small) {
                    appState.router.push(.createBrand, forRole: .uso)
                }
            }

            if viewModel.isLoading {
                skeletonList
            } else if viewModel.ownedBrands.isEmpty && viewModel.joinedBrands.isEmpty {
                emptyState
            } else {
                brandList
            }
        }
        .background(Color.rzBackground)
        .navigationBarHidden(true)
        .task {
            await viewModel.load(apiClient: appState.apiClient, currentUserId: currentUserId)
        }
        .refreshable {
            await viewModel.load(apiClient: appState.apiClient, currentUserId: currentUserId)
        }
    }

    // MARK: - Brand List

    private var brandList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: RZSpacing.sectionVertical, pinnedViews: []) {
                if !viewModel.ownedBrands.isEmpty {
                    Section {
                        ForEach(viewModel.ownedBrands) { brand in
                            BrandCard(brand: brand) {
                                appState.router.push(.brandManage(id: brand.id), forRole: .uso)
                            }
                            .padding(.horizontal, RZSpacing.screenHorizontal)
                        }
                    } header: {
                        RZSectionHeader(title: "My Brands")
                            .padding(.horizontal, RZSpacing.screenHorizontal)
                    }
                }

                if !viewModel.joinedBrands.isEmpty {
                    Section {
                        ForEach(viewModel.joinedBrands) { brand in
                            BrandCard(brand: brand) {
                                appState.router.push(.brandManage(id: brand.id), forRole: .uso)
                            }
                            .padding(.horizontal, RZSpacing.screenHorizontal)
                        }
                    } header: {
                        RZSectionHeader(title: "Joined Brands")
                            .padding(.horizontal, RZSpacing.screenHorizontal)
                    }
                }
            }
            .padding(.top, RZSpacing.sm)
            .padding(.bottom, RZSpacing.xl)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        RZEmptyState(
            icon: "building.2",
            title: "No brands yet",
            subtitle: "Create your first brand to start accepting reservations.",
            actionTitle: "Create Brand"
        ) {
            appState.router.push(.createBrand, forRole: .uso)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Skeleton

    private var skeletonList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: RZSpacing.xs) {
                ForEach(0..<3, id: \.self) { _ in
                    RZSkeletonView(height: 80, radius: RZRadius.card)
                        .padding(.horizontal, RZSpacing.screenHorizontal)
                }
            }
            .padding(.top, RZSpacing.sm)
        }
        .allowsHitTesting(false)
    }
}
