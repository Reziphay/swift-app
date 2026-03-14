import Foundation

struct SearchResponse: Codable {
    let services: [ServiceSearchResult]?
    let brands: [BrandSearchResult]?
    let providers: [ProviderSearchResult]?
    let pageInfo: PageInfo?
}

struct ServiceSearchResult: Codable, Identifiable, Hashable {
    let id: String
    let service: Service
    let distance: Double?
    let availability: AvailabilitySnapshot?
}

struct BrandSearchResult: Codable, Identifiable, Hashable {
    let id: String
    let brand: Brand
    let distance: Double?
}

struct ProviderSearchResult: Codable, Identifiable, Hashable {
    let id: String
    let provider: ProviderProfile
    let distance: Double?
}

struct ProviderProfile: Codable, Identifiable, Hashable {
    let id: String
    let fullName: String
    let brandNames: [String]?
    let serviceCount: Int?
    let ratingStats: RatingStats?
    let popularityStats: PopularityStats?
}

struct AvailabilitySnapshot: Codable, Hashable {
    let isAvailable: Bool?
    let reason: String?
}

struct PageInfo: Codable {
    let cursor: String?
    let hasMore: Bool
}

struct PaginatedResponse<T: Codable>: Codable {
    let items: [T]
    let pageInfo: PageInfo?
}
