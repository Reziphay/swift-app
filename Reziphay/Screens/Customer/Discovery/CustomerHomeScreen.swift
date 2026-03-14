import SwiftUI
import CoreLocation

// MARK: - ViewModel

@Observable
@MainActor
final class CustomerHomeViewModel {
    var categories: [ServiceCategory] = []
    var featuredServices: [Service] = []
    var nearbyServices: [Service] = []
    var popularBrands: [Brand] = []

    var isLoadingCategories = false
    var isLoadingFeatured = false
    var isLoadingNearby = false
    var isLoadingBrands = false

    var error: String?

    func loadAll(apiClient: APIClient, location: CLLocationCoordinate2D?) async {
        async let cats: Void = loadCategories(apiClient: apiClient)
        async let featured: Void = loadFeatured(apiClient: apiClient)
        async let nearby: Void = loadNearby(apiClient: apiClient, location: location)
        async let brands: Void = loadBrands(apiClient: apiClient)
        _ = await (cats, featured, nearby, brands)
    }

    private func loadCategories(apiClient: APIClient) async {
        isLoadingCategories = true
        defer { isLoadingCategories = false }
        do {
            let result: [ServiceCategory] = try await apiClient.get(APIEndpoints.categories)
            categories = result
        } catch {
            // silent per-section failure
        }
    }

    private func loadFeatured(apiClient: APIClient) async {
        isLoadingFeatured = true
        defer { isLoadingFeatured = false }
        do {
            let result: [Service] = try await apiClient.get(
                APIEndpoints.services,
                query: ["visibility": "featured", "limit": "10"]
            )
            featuredServices = result
        } catch {
            // silent
        }
    }

    private func loadNearby(apiClient: APIClient, location: CLLocationCoordinate2D?) async {
        isLoadingNearby = true
        defer { isLoadingNearby = false }
        do {
            var query: [String: String] = ["limit": "10"]
            if let loc = location {
                query["lat"] = String(loc.latitude)
                query["lng"] = String(loc.longitude)
            }
            let result: [Service] = try await apiClient.get(APIEndpoints.servicesNearby, query: query)
            nearbyServices = result
        } catch {
            // silent
        }
    }

    private func loadBrands(apiClient: APIClient) async {
        isLoadingBrands = true
        defer { isLoadingBrands = false }
        do {
            let result: [Brand] = try await apiClient.get(
                APIEndpoints.brands,
                query: ["popular": "true", "limit": "10"]
            )
            popularBrands = result
        } catch {
            // silent
        }
    }
}

// MARK: - Screen

struct CustomerHomeScreen: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = CustomerHomeViewModel()
    @State private var locationManager = LocationManager()
    @State private var searchText = ""

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private var userName: String {
        appState.authManager.currentUser?.fullName.components(separatedBy: " ").first ?? "there"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Top header
                headerSection
                    .padding(.horizontal, RZSpacing.screenHorizontal)
                    .padding(.top, RZSpacing.md)
                    .padding(.bottom, RZSpacing.xs)

                // Search bar (tappable, navigates to search)
                searchBarTappable
                    .padding(.horizontal, RZSpacing.screenHorizontal)
                    .padding(.bottom, RZSpacing.sectionVertical)

                // Location permission callout
                if !locationManager.isAuthorized && locationManager.authorizationStatus != .notDetermined {
                    locationPermissionCallout
                        .padding(.horizontal, RZSpacing.screenHorizontal)
                        .padding(.bottom, RZSpacing.sectionVertical)
                }

                // Near Me section
                if locationManager.isAuthorized {
                    nearMeSection
                        .padding(.bottom, RZSpacing.sectionVertical)
                }

                // Featured section
                featuredSection
                    .padding(.bottom, RZSpacing.sectionVertical)

                // Categories section
                categoriesSection
                    .padding(.bottom, RZSpacing.sectionVertical)

                // Popular Brands section
                popularBrandsSection
                    .padding(.bottom, RZSpacing.xxl)
            }
        }
        .background(Color.rzBackground)
        .ignoresSafeArea(edges: .top)
        .task {
            locationManager.requestPermission()
            await viewModel.loadAll(
                apiClient: appState.apiClient,
                location: locationManager.location
            )
        }
        .onChange(of: locationManager.location) { _, newLocation in
            if viewModel.nearbyServices.isEmpty, let _ = newLocation {
                Task {
                    await viewModel.loadAll(
                        apiClient: appState.apiClient,
                        location: newLocation
                    )
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: RZSpacing.xxxs) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.rzPrimary)
                    Text(locationManager.isAuthorized ? "Nearby" : "Everywhere")
                        .font(.rzCaption)
                        .foregroundStyle(.rzTextSecondary)
                }
                Text("\(greeting), \(userName)")
                    .font(.rzH3)
                    .foregroundStyle(.rzTextPrimary)
            }

            Spacer()

            Button {
                appState.router.push(.settings, forRole: .ucr)
            } label: {
                RZAvatarView(
                    name: appState.authManager.currentUser?.fullName ?? "U",
                    size: 40
                )
            }
        }
        .padding(.top, 52) // safe area compensation
    }

    // MARK: - Search Bar

    private var searchBarTappable: some View {
        Button {
            appState.router.push(.searchResults(query: nil), forRole: .ucr)
        } label: {
            HStack(spacing: RZSpacing.xxs) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.rzTextTertiary)
                Text("Search services, brands…")
                    .font(.rzBody)
                    .foregroundStyle(.rzTextTertiary)
                Spacer()
            }
            .padding(.horizontal, RZSpacing.xs)
            .frame(height: 44)
            .background(Color.rzInputBackground)
            .clipShape(RoundedRectangle(cornerRadius: RZRadius.input))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Location Permission Callout

    private var locationPermissionCallout: some View {
        HStack(spacing: RZSpacing.xs) {
            Image(systemName: "location.slash.fill")
                .font(.system(size: 18))
                .foregroundStyle(.rzWarning)

            VStack(alignment: .leading, spacing: 2) {
                Text("Location access needed")
                    .font(.rzBodySmall)
                    .fontWeight(.semibold)
                    .foregroundStyle(.rzTextPrimary)
                Text("Enable location to see services near you")
                    .font(.rzCaption)
                    .foregroundStyle(.rzTextSecondary)
            }

            Spacer()

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Enable")
                    .font(.rzLabel)
                    .fontWeight(.semibold)
                    .foregroundStyle(.rzPrimary)
            }
        }
        .padding(RZSpacing.sm)
        .background(Color.rzSurface)
        .clipShape(RoundedRectangle(cornerRadius: RZRadius.card))
        .rzShadow(RZShadow.sm)
    }

    // MARK: - Near Me Section

    private var nearMeSection: some View {
        VStack(alignment: .leading, spacing: RZSpacing.xs) {
            RZSectionHeader(title: "Near Me", actionTitle: "See map") {
                appState.router.push(.nearbyMap, forRole: .ucr)
            }
            .padding(.horizontal, RZSpacing.screenHorizontal)

            if viewModel.isLoadingNearby {
                horizontalSkeletonCards
            } else if viewModel.nearbyServices.isEmpty {
                Text("No services found nearby")
                    .font(.rzBody)
                    .foregroundStyle(.rzTextTertiary)
                    .padding(.horizontal, RZSpacing.screenHorizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: RZSpacing.xs) {
                        ForEach(viewModel.nearbyServices) { service in
                            ServiceCard(service: service) {
                                appState.router.push(.serviceDetail(id: service.id), forRole: .ucr)
                            }
                            .frame(width: 200)
                        }
                    }
                    .padding(.horizontal, RZSpacing.screenHorizontal)
                }
            }
        }
    }

    // MARK: - Featured Section

    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: RZSpacing.xs) {
            RZSectionHeader(title: "Featured")
                .padding(.horizontal, RZSpacing.screenHorizontal)

            if viewModel.isLoadingFeatured {
                horizontalSkeletonCards
            } else if viewModel.featuredServices.isEmpty {
                Text("No featured services at the moment")
                    .font(.rzBody)
                    .foregroundStyle(.rzTextTertiary)
                    .padding(.horizontal, RZSpacing.screenHorizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: RZSpacing.xs) {
                        ForEach(viewModel.featuredServices) { service in
                            ServiceCard(service: service) {
                                appState.router.push(.serviceDetail(id: service.id), forRole: .ucr)
                            }
                            .frame(width: 200)
                        }
                    }
                    .padding(.horizontal, RZSpacing.screenHorizontal)
                }
            }
        }
    }

    // MARK: - Categories Section

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: RZSpacing.xs) {
            RZSectionHeader(title: "Categories")
                .padding(.horizontal, RZSpacing.screenHorizontal)

            if viewModel.isLoadingCategories {
                categoriesSkeletonGrid
            } else if viewModel.categories.isEmpty {
                EmptyView()
            } else {
                let columns = [GridItem(.flexible()), GridItem(.flexible())]
                LazyVGrid(columns: columns, spacing: RZSpacing.xs) {
                    ForEach(viewModel.categories.prefix(10)) { category in
                        CategoryChipCard(category: category) {
                            appState.router.push(
                                .categoryListing(id: category.id, name: category.name),
                                forRole: .ucr
                            )
                        }
                    }
                }
                .padding(.horizontal, RZSpacing.screenHorizontal)
            }
        }
    }

    // MARK: - Popular Brands Section

    private var popularBrandsSection: some View {
        VStack(alignment: .leading, spacing: RZSpacing.xs) {
            RZSectionHeader(title: "Popular Brands")
                .padding(.horizontal, RZSpacing.screenHorizontal)

            if viewModel.isLoadingBrands {
                VStack(spacing: RZSpacing.xs) {
                    ForEach(0..<3, id: \.self) { _ in
                        RZSkeletonListRow()
                            .padding(.horizontal, RZSpacing.screenHorizontal)
                    }
                }
            } else if viewModel.popularBrands.isEmpty {
                Text("No brands yet")
                    .font(.rzBody)
                    .foregroundStyle(.rzTextTertiary)
                    .padding(.horizontal, RZSpacing.screenHorizontal)
            } else {
                VStack(spacing: RZSpacing.xs) {
                    ForEach(viewModel.popularBrands) { brand in
                        BrandCard(brand: brand) {
                            appState.router.push(.brandDetail(id: brand.id), forRole: .ucr)
                        }
                        .padding(.horizontal, RZSpacing.screenHorizontal)
                    }
                }
            }
        }
    }

    // MARK: - Skeleton Helpers

    private var horizontalSkeletonCards: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: RZSpacing.xs) {
                ForEach(0..<4, id: \.self) { _ in
                    RZSkeletonCard()
                        .frame(width: 200)
                }
            }
            .padding(.horizontal, RZSpacing.screenHorizontal)
        }
        .allowsHitTesting(false)
    }

    private var categoriesSkeletonGrid: some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: columns, spacing: RZSpacing.xs) {
            ForEach(0..<6, id: \.self) { _ in
                RZSkeletonView(height: 52, radius: RZRadius.card)
            }
        }
        .padding(.horizontal, RZSpacing.screenHorizontal)
        .allowsHitTesting(false)
    }
}

// MARK: - Category Chip Card

private struct CategoryChipCard: View {
    let category: ServiceCategory
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: RZSpacing.xxs) {
                Image(systemName: categoryIcon(for: category.slug))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.rzPrimary)
                Text(category.name)
                    .font(.rzBodySmall)
                    .fontWeight(.medium)
                    .foregroundStyle(.rzTextPrimary)
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, RZSpacing.xs)
            .padding(.vertical, RZSpacing.sm)
            .background(Color.rzSurface)
            .clipShape(RoundedRectangle(cornerRadius: RZRadius.card))
            .rzShadow(RZShadow.sm)
        }
        .buttonStyle(.plain)
    }

    private func categoryIcon(for slug: String) -> String {
        switch slug {
        case let s where s.contains("hair"): return "scissors"
        case let s where s.contains("beauty"): return "sparkles"
        case let s where s.contains("nail"): return "hand.point.up.left"
        case let s where s.contains("massage"): return "figure.walk"
        case let s where s.contains("fitness"): return "figure.strengthtraining.traditional"
        case let s where s.contains("dental"): return "cross.case"
        case let s where s.contains("photo"): return "camera"
        case let s where s.contains("clean"): return "bubbles.and.sparkles"
        default: return "tag"
        }
    }
}
