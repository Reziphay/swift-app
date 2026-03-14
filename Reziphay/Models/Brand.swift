import Foundation

struct Brand: Codable, Identifiable, Hashable {
    let id: String
    let ownerUserId: String
    let name: String
    let description: String?
    let status: BrandStatus
    let logoFile: FileObject?
    let primaryAddress: BrandAddress?
    let ratingStats: RatingStats?
    let popularityStats: PopularityStats?
    let visibilityLabels: [VisibilityLabelAssignment]?
    let createdAt: String
    let updatedAt: String

    var logoURL: URL? {
        guard let key = logoFile?.objectKey else { return nil }
        return URL(string: "\(APIClient.storageBaseURL)/\(key)")
    }
}

struct BrandAddress: Codable, Hashable {
    let id: String?
    let label: String?
    let fullAddress: String
    let country: String
    let city: String
    let lat: Double?
    let lng: Double?
    let placeId: String?
    let isPrimary: Bool?
}

struct BrandMembership: Codable, Identifiable, Hashable {
    let id: String
    let brandId: String
    let userId: String
    let membershipRole: BrandMembershipRole
    let user: User?
}

struct BrandJoinRequest: Codable, Identifiable, Hashable {
    let id: String
    let brandId: String
    let requesterUserId: String
    let message: String?
    let status: BrandJoinRequestStatus
    let requester: User?
    let createdAt: String
}

struct VisibilityLabelAssignment: Codable, Hashable {
    let id: String?
    let label: VisibilityLabel?
    let startsAt: String?
    let endsAt: String?
}

struct VisibilityLabel: Codable, Hashable {
    let id: String
    let name: String
    let slug: String
}
