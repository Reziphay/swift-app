import Foundation

struct APIResponse<T: Decodable>: Decodable {
    let success: Bool
    let data: T
    let requestId: String?
    let timestamp: String?
}

struct APIErrorResponse: Decodable {
    let success: Bool
    let code: String?
    let message: String
    let requestId: String?
}
