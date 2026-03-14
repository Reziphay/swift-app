import Foundation

struct Service: Codable, Identifiable, Hashable {
    let id: String
    let ownerUserId: String
    let brandId: String?
    let categoryId: String?
    let addressId: String?
    let name: String
    let description: String?
    let priceAmount: Double?
    let priceCurrency: String?
    let waitingTimeMinutes: Int
    let minAdvanceMinutes: Int?
    let maxAdvanceMinutes: Int?
    let serviceType: ServiceType
    let approvalMode: ApprovalMode
    let freeCancellationDeadlineMinutes: Int?
    let isActive: Bool
    let brand: BrandSummary?
    let category: ServiceCategorySummary?
    let address: ServiceAddress?
    let photos: [ServicePhoto]?
    let availabilityRules: [AvailabilityRule]?
    let availabilityExceptions: [AvailabilityException]?
    let manualBlocks: [ManualBlock]?
    let ratingStats: RatingStats?
    let popularityStats: PopularityStats?
    let visibilityLabels: [VisibilityLabelAssignment]?
    let ownerName: String?
    let createdAt: String
    let updatedAt: String

    var formattedPrice: String? {
        guard let amount = priceAmount else { return nil }
        let currency = priceCurrency ?? "USD"
        return "\(currency) \(String(format: "%.2f", amount))"
    }

    var photoURLs: [URL] {
        photos?.compactMap { photo in
            guard let key = photo.file?.objectKey else { return nil }
            return URL(string: "\(APIClient.storageBaseURL)/\(key)")
        } ?? []
    }
}

struct BrandSummary: Codable, Hashable {
    let id: String
    let name: String
}

struct ServiceCategorySummary: Codable, Hashable {
    let id: String
    let name: String
}

struct ServiceAddress: Codable, Hashable {
    let id: String?
    let label: String?
    let fullAddress: String
    let country: String
    let city: String
    let lat: Double?
    let lng: Double?
    let placeId: String?
}

struct ServicePhoto: Codable, Identifiable, Hashable {
    let id: String
    let fileId: String
    let sortOrder: Int
    let file: FileObject?
}

struct FileObject: Codable, Hashable {
    let id: String
    let bucket: String?
    let objectKey: String
    let originalFilename: String?
    let mimeType: String?
    let sizeBytes: Int?
}

struct AvailabilityRule: Codable, Identifiable, Hashable {
    let id: String?
    let dayOfWeek: DayOfWeek
    let startTime: String
    let endTime: String
    let isActive: Bool
}

struct AvailabilityException: Codable, Identifiable, Hashable {
    let id: String?
    let date: String
    let startTime: String?
    let endTime: String?
    let isClosedAllDay: Bool
    let note: String?
}

struct ManualBlock: Codable, Identifiable, Hashable {
    let id: String?
    let startsAt: String
    let endsAt: String
    let reason: String?
}
