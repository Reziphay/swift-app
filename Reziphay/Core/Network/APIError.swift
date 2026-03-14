import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(code: String, message: String)
    case unauthorized
    case forbidden
    case notFound
    case validationError(message: String)
    case unknown(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL: "Invalid URL"
        case .networkError(let error): error.localizedDescription
        case .decodingError: "Failed to process server response"
        case .serverError(_, let message): message
        case .unauthorized: "Session expired. Please log in again."
        case .forbidden: "You don't have permission to do this."
        case .notFound: "Not found"
        case .validationError(let message): message
        case .unknown(let code): "Something went wrong (code: \(code))"
        }
    }
}
