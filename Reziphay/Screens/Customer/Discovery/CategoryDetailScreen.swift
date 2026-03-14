import SwiftUI

// MARK: - ViewModel

@Observable
@MainActor
final class CategoryDetailViewModel {
    var services: [Service] = []
    var isLoading: Bool = false
    var error: String? = nil

    var sortMode: SearchSortMode = .relevance
    var selectedSortIndex: Int? = nil

    func load(categoryId: String, apiClient: APIClient) async {
        isLoading = true
        defer { isLoading = false }
        do {
            var query: [String: String] = ["categoryId": categoryId]
            query["sort"] = sortMode.rawValue
            let result: [Service] = try await apiClient.get(APIEndpoints.services, query: query)
            services = result
        } catch {
            self.error = error.localizedDescription
        }
    }

    func reload(categoryId: String, apiClient: APIClient) async {
        services = []
        await load(categoryId: categoryId, apiClient: apiClient)
    }
}

// MARK: - Screen

struct CategoryDetailScreen: View {
    let categoryId: String
    let categoryName: String

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = CategoryDetailViewModel()
    @State private var showSortSheet = false

    private let sortOptions = SearchSortMode.allCases.map { $0.displayName }

    var body: some View {
        VStack(spacing: 0) {
            // Top bar
            RZTopBar(title: categoryName) {
                RZIconButton(icon: "chevron.left") { dismiss() }
            } trailing: {
                RZIconButton(icon: "arrow.up.arrow.down") { showSortSheet = true }
            }

            Divider()

            // Filter chip row (sort modes)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: RZSpacing.xxs) {
                    ForEach(Array(SearchSortMode.allCases.enumerated()), id: \.element) { index, mode in
                        RZFilterChip(
                            title: mode.displayName,
                            isSelected: viewModel.sortMode == mode
                        ) {
                            viewModel.sortMode = mode
                            Task {
                                await viewModel.reload(categoryId: categoryId, apiClient: appState.apiClient)
                            }
                        }
                    }
                }
                .padding(.horizontal, RZSpacing.screenHorizontal)
                .padding(.vertical, RZSpacing.xs)
            }

            Divider()

            // Content
            if viewModel.isLoading {
                skeletonList
            } else if viewModel.services.isEmpty {
                RZEmptyState(
                    icon: "square.3.layers.3d.down.right",
                    title: "No services yet",
                    subtitle: "There are no services in this category yet."
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: RZSpacing.xs) {
                        ForEach(viewModel.services) { service in
                            ServiceCard(service: service) {
                                appState.router.push(.serviceDetail(id: service.id), forRole: .ucr)
                            }
                            .padding(.horizontal, RZSpacing.screenHorizontal)
                        }
                    }
                    .padding(.top, RZSpacing.xs)
                    .padding(.bottom, RZSpacing.xxl)
                }
            }
        }
        .background(Color.rzBackground)
        .navigationBarHidden(true)
        .task {
            await viewModel.load(categoryId: categoryId, apiClient: appState.apiClient)
        }
        .sheet(isPresented: $showSortSheet) {
            sortSheetContent
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Sort Sheet

    private var sortSheetContent: some View {
        RZBottomSheet(title: "Sort by", onDismiss: { showSortSheet = false }) {
            VStack(spacing: 0) {
                ForEach(SearchSortMode.allCases, id: \.self) { mode in
                    Button {
                        viewModel.sortMode = mode
                        showSortSheet = false
                        Task {
                            await viewModel.reload(categoryId: categoryId, apiClient: appState.apiClient)
                        }
                    } label: {
                        HStack {
                            Text(mode.displayName)
                                .font(.rzBody)
                                .foregroundStyle(.rzTextPrimary)
                            Spacer()
                            if viewModel.sortMode == mode {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.rzPrimary)
                            }
                        }
                        .padding(.vertical, RZSpacing.sm)
                    }
                    if mode != SearchSortMode.allCases.last {
                        Divider()
                    }
                }
            }
        }
    }

    // MARK: - Skeleton

    private var skeletonList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: RZSpacing.xs) {
                ForEach(0..<6, id: \.self) { _ in
                    RZSkeletonCard()
                        .padding(.horizontal, RZSpacing.screenHorizontal)
                }
            }
            .padding(.top, RZSpacing.xs)
        }
        .allowsHitTesting(false)
    }
}
