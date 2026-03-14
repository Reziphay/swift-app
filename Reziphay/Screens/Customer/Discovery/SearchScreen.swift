import SwiftUI

// MARK: - ViewModel

@Observable
@MainActor
final class SearchViewModel {
    var query: String = ""
    var serviceResults: [ServiceSearchResult] = []
    var brandResults: [BrandSearchResult] = []
    var providerResults: [ProviderSearchResult] = []
    var isLoading: Bool = false
    var selectedTabIndex: Int = 0

    var sortMode: SearchSortMode = .relevance

    // Filters
    var minRating: Double? = nil
    var maxPrice: Double? = nil
    var categoryId: String? = nil
    var onlyAvailable: Bool = false

    var hasActiveFilters: Bool {
        minRating != nil || maxPrice != nil || categoryId != nil || onlyAvailable
    }

    var activeFilterChips: [String] {
        var chips: [String] = []
        if let rating = minRating { chips.append("★ \(String(format: "%.0f", rating))+") }
        if let price = maxPrice { chips.append("Under \(String(format: "%.0f", price))") }
        if onlyAvailable { chips.append("Available") }
        return chips
    }

    private var searchTask: Task<Void, Never>?
    private var cursor: String? = nil
    var hasMore: Bool = false

    func search(apiClient: APIClient) async {
        searchTask?.cancel()
        cursor = nil
        isLoading = true
        defer { isLoading = false }
        await performSearch(apiClient: apiClient, reset: true)
    }

    func loadMore(apiClient: APIClient) async {
        guard hasMore, !isLoading, let cursor else { return }
        await performSearch(apiClient: apiClient, reset: false)
    }

    private func performSearch(apiClient: APIClient, reset: Bool) async {
        var queryParams: [String: String] = [:]

        if !query.isEmpty { queryParams["q"] = query }
        queryParams["sort"] = sortMode.rawValue
        if let rating = minRating { queryParams["minRating"] = String(rating) }
        if let price = maxPrice { queryParams["maxPrice"] = String(price) }
        if let catId = categoryId { queryParams["categoryId"] = catId }
        if onlyAvailable { queryParams["available"] = "true" }
        if !reset, let c = cursor { queryParams["cursor"] = c }
        queryParams["limit"] = "20"

        do {
            let result: SearchResponse = try await apiClient.get(APIEndpoints.search, query: queryParams)
            if reset {
                serviceResults = result.services ?? []
                brandResults = result.brands ?? []
                providerResults = result.providers ?? []
            } else {
                serviceResults.append(contentsOf: result.services ?? [])
                brandResults.append(contentsOf: result.brands ?? [])
                providerResults.append(contentsOf: result.providers ?? [])
            }
            cursor = result.pageInfo?.cursor
            hasMore = result.pageInfo?.hasMore ?? false
        } catch {
            // errors handled by caller via toast
        }
    }

    func applyFilters(
        minRating: Double?,
        maxPrice: Double?,
        categoryId: String?,
        onlyAvailable: Bool,
        apiClient: APIClient
    ) async {
        self.minRating = minRating
        self.maxPrice = maxPrice
        self.categoryId = categoryId
        self.onlyAvailable = onlyAvailable
        await search(apiClient: apiClient)
    }

    func clearFilters(apiClient: APIClient) async {
        minRating = nil
        maxPrice = nil
        categoryId = nil
        onlyAvailable = false
        await search(apiClient: apiClient)
    }

    var selectedTabName: String {
        ["Services", "Brands", "Providers"][selectedTabIndex]
    }
}

// MARK: - Screen

struct SearchScreen: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = SearchViewModel()
    @State private var showSortSheet = false
    @State private var showFilterSheet = false
    @FocusState private var searchFocused: Bool

    var initialQuery: String?

    var body: some View {
        VStack(spacing: 0) {
            // Top bar: search + sort
            searchBar
                .padding(.horizontal, RZSpacing.screenHorizontal)
                .padding(.top, RZSpacing.xs)
                .padding(.bottom, RZSpacing.xxs)

            // Active filter chips
            if viewModel.hasActiveFilters {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: RZSpacing.xxs) {
                        ForEach(viewModel.activeFilterChips, id: \.self) { chip in
                            RZStatusPill(text: chip, color: .rzPrimary)
                        }
                        Button {
                            Task { await viewModel.clearFilters(apiClient: appState.apiClient) }
                        } label: {
                            Text("Clear")
                                .font(.rzCaption)
                                .foregroundStyle(.rzError)
                        }
                    }
                    .padding(.horizontal, RZSpacing.screenHorizontal)
                }
                .padding(.bottom, RZSpacing.xxs)
            }

            // Segment control
            RZSegmentedControl(
                items: ["Services", "Brands", "Providers"],
                selected: $viewModel.selectedTabIndex
            )
            .padding(.horizontal, RZSpacing.screenHorizontal)
            .padding(.bottom, RZSpacing.xs)

            Divider()

            // Content
            resultContent
        }
        .background(Color.rzBackground)
        .navigationBarHidden(true)
        .task {
            if let q = initialQuery {
                viewModel.query = q
            }
            searchFocused = initialQuery == nil
            if !viewModel.query.isEmpty {
                await viewModel.search(apiClient: appState.apiClient)
            }
        }
        .sheet(isPresented: $showSortSheet) {
            sortSheet
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showFilterSheet) {
            SearchFilterSheet(viewModel: viewModel, isPresented: $showFilterSheet)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: RZSpacing.xs) {
            // Back button
            Button {
                appState.router.customerPath.removeLast()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.rzTextPrimary)
                    .frame(width: 36, height: 36)
                    .background(Color.rzInputBackground)
                    .clipShape(Circle())
            }

            // Search field
            HStack(spacing: RZSpacing.xxs) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.rzTextTertiary)

                TextField("Search services, brands…", text: $viewModel.query)
                    .font(.rzBody)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($searchFocused)
                    .onSubmit {
                        Task { await viewModel.search(apiClient: appState.apiClient) }
                    }
                    .submitLabel(.search)

                if !viewModel.query.isEmpty {
                    Button { viewModel.query = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.rzTextTertiary)
                    }
                }
            }
            .padding(.horizontal, RZSpacing.xs)
            .frame(height: 40)
            .background(Color.rzInputBackground)
            .clipShape(RoundedRectangle(cornerRadius: RZRadius.input))

            // Filter button
            Button {
                showFilterSheet = true
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "line.3.horizontal.decrease")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.rzTextPrimary)
                        .frame(width: 36, height: 36)
                        .background(Color.rzInputBackground)
                        .clipShape(RoundedRectangle(cornerRadius: RZRadius.sm))
                    if viewModel.hasActiveFilters {
                        Circle()
                            .fill(Color.rzPrimary)
                            .frame(width: 8, height: 8)
                            .offset(x: 2, y: -2)
                    }
                }
            }

            // Sort button
            Button {
                showSortSheet = true
            } label: {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.rzTextPrimary)
                    .frame(width: 36, height: 36)
                    .background(Color.rzInputBackground)
                    .clipShape(RoundedRectangle(cornerRadius: RZRadius.sm))
            }
        }
    }

    // MARK: - Result Content

    @ViewBuilder
    private var resultContent: some View {
        if viewModel.isLoading && viewModel.serviceResults.isEmpty && viewModel.brandResults.isEmpty {
            skeletonList
        } else {
            switch viewModel.selectedTabIndex {
            case 0: servicesTab
            case 1: brandsTab
            default: providersTab
            }
        }
    }

    private var servicesTab: some View {
        Group {
            if viewModel.serviceResults.isEmpty && !viewModel.isLoading {
                emptyState
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: RZSpacing.xs) {
                        ForEach(viewModel.serviceResults) { result in
                            ServiceCard(service: result.service, distance: result.distance) {
                                appState.router.push(.serviceDetail(id: result.service.id), forRole: .ucr)
                            }
                            .padding(.horizontal, RZSpacing.screenHorizontal)
                            .onAppear {
                                if result.id == viewModel.serviceResults.last?.id {
                                    Task { await viewModel.loadMore(apiClient: appState.apiClient) }
                                }
                            }
                        }
                        if viewModel.isLoading {
                            RZLoadingIndicator()
                                .padding(.vertical, RZSpacing.sm)
                        }
                    }
                    .padding(.top, RZSpacing.xs)
                    .padding(.bottom, RZSpacing.xxl)
                }
            }
        }
    }

    private var brandsTab: some View {
        Group {
            if viewModel.brandResults.isEmpty && !viewModel.isLoading {
                emptyState
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: RZSpacing.xs) {
                        ForEach(viewModel.brandResults) { result in
                            BrandCard(brand: result.brand) {
                                appState.router.push(.brandDetail(id: result.brand.id), forRole: .ucr)
                            }
                            .padding(.horizontal, RZSpacing.screenHorizontal)
                            .onAppear {
                                if result.id == viewModel.brandResults.last?.id {
                                    Task { await viewModel.loadMore(apiClient: appState.apiClient) }
                                }
                            }
                        }
                        if viewModel.isLoading {
                            RZLoadingIndicator()
                                .padding(.vertical, RZSpacing.sm)
                        }
                    }
                    .padding(.top, RZSpacing.xs)
                    .padding(.bottom, RZSpacing.xxl)
                }
            }
        }
    }

    private var providersTab: some View {
        Group {
            if viewModel.providerResults.isEmpty && !viewModel.isLoading {
                emptyState
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: RZSpacing.xs) {
                        ForEach(viewModel.providerResults) { result in
                            ProviderCard(provider: result.provider) {
                                appState.router.push(.providerDetail(id: result.provider.id), forRole: .ucr)
                            }
                            .padding(.horizontal, RZSpacing.screenHorizontal)
                            .onAppear {
                                if result.id == viewModel.providerResults.last?.id {
                                    Task { await viewModel.loadMore(apiClient: appState.apiClient) }
                                }
                            }
                        }
                        if viewModel.isLoading {
                            RZLoadingIndicator()
                                .padding(.vertical, RZSpacing.sm)
                        }
                    }
                    .padding(.top, RZSpacing.xs)
                    .padding(.bottom, RZSpacing.xxl)
                }
            }
        }
    }

    private var emptyState: some View {
        RZEmptyState(
            icon: "magnifyingglass",
            title: "No results",
            subtitle: viewModel.query.isEmpty
                ? "Type something to search"
                : "Nothing found for \"\(viewModel.query)\""
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var skeletonList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: RZSpacing.xs) {
                ForEach(0..<5, id: \.self) { _ in
                    RZSkeletonListRow()
                        .padding(.horizontal, RZSpacing.screenHorizontal)
                }
            }
            .padding(.top, RZSpacing.xs)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Sort Sheet

    private var sortSheet: some View {
        RZBottomSheet(title: "Sort by", onDismiss: { showSortSheet = false }) {
            VStack(spacing: 0) {
                ForEach(SearchSortMode.allCases, id: \.self) { mode in
                    Button {
                        viewModel.sortMode = mode
                        showSortSheet = false
                        Task { await viewModel.search(apiClient: appState.apiClient) }
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
}
