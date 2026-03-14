import Foundation

@Observable
final class APIClient {
    static let storageBaseURL = "http://localhost:3000"

    private let session: URLSession
    private let baseURL: URL
    private let decoder: JSONDecoder
    private var keychainService: KeychainService

    private var isRefreshing = false
    private var refreshContinuations: [CheckedContinuation<Void, Error>] = []

    init(
        baseURL: URL = URL(string: "http://localhost:3000/api/v1")!,
        keychainService: KeychainService = .shared
    ) {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
        self.baseURL = baseURL
        self.keychainService = keychainService

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = iso.date(from: string) { return date }
            iso.formatOptions = [.withInternetDateTime]
            if let date = iso.date(from: string) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(string)")
        }
        self.decoder = decoder
    }

    // MARK: - Public API

    func get<T: Decodable>(_ path: String, query: [String: String]? = nil) async throws -> T {
        let request = try buildRequest(path: path, method: "GET", query: query)
        return try await execute(request)
    }

    func post<T: Decodable>(_ path: String, body: Encodable? = nil) async throws -> T {
        let request = try buildRequest(path: path, method: "POST", body: body)
        return try await execute(request)
    }

    func patch<T: Decodable>(_ path: String, body: Encodable? = nil) async throws -> T {
        let request = try buildRequest(path: path, method: "PATCH", body: body)
        return try await execute(request)
    }

    func put<T: Decodable>(_ path: String, body: Encodable? = nil) async throws -> T {
        let request = try buildRequest(path: path, method: "PUT", body: body)
        return try await execute(request)
    }

    func delete<T: Decodable>(_ path: String) async throws -> T {
        let request = try buildRequest(path: path, method: "DELETE")
        return try await execute(request)
    }

    func postVoid(_ path: String, body: Encodable? = nil) async throws {
        let request = try buildRequest(path: path, method: "POST", body: body)
        let _: EmptyData = try await execute(request)
    }

    func patchVoid(_ path: String, body: Encodable? = nil) async throws {
        let request = try buildRequest(path: path, method: "PATCH", body: body)
        let _: EmptyData = try await execute(request)
    }

    func deleteVoid(_ path: String) async throws {
        let request = try buildRequest(path: path, method: "DELETE")
        let _: EmptyData = try await execute(request)
    }

    func upload<T: Decodable>(_ path: String, fileData: Data, fileName: String, mimeType: String, fieldName: String = "file") async throws -> T {
        let boundary = UUID().uuidString
        var request = try buildRequest(path: path, method: "POST")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        return try await execute(request)
    }

    // MARK: - Internal

    private func buildRequest(path: String, method: String, query: [String: String]? = nil, body: Encodable? = nil) throws -> URLRequest {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if let query, !query.isEmpty {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = components.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let token = keychainService.getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
        }

        return request
    }

    private func execute<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown(statusCode: 0)
        }

        if httpResponse.statusCode == 401 {
            // Attempt token refresh
            try await refreshTokenIfNeeded()
            // Retry with new token
            var retryRequest = request
            if let token = keychainService.getAccessToken() {
                retryRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            let (retryData, retryResponse) = try await session.data(for: retryRequest)
            guard let retryHTTP = retryResponse as? HTTPURLResponse else {
                throw APIError.unknown(statusCode: 0)
            }
            if retryHTTP.statusCode == 401 {
                throw APIError.unauthorized
            }
            return try decodeResponse(data: retryData, statusCode: retryHTTP.statusCode)
        }

        return try decodeResponse(data: data, statusCode: httpResponse.statusCode)
    }

    private func decodeResponse<T: Decodable>(data: Data, statusCode: Int) throws -> T {
        guard (200...299).contains(statusCode) else {
            if let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data) {
                switch statusCode {
                case 403: throw APIError.forbidden
                case 404: throw APIError.notFound
                case 422: throw APIError.validationError(message: errorResponse.message)
                default: throw APIError.serverError(code: errorResponse.code ?? "UNKNOWN", message: errorResponse.message)
                }
            }
            throw APIError.unknown(statusCode: statusCode)
        }

        do {
            let envelope = try decoder.decode(APIResponse<T>.self, from: data)
            return envelope.data
        } catch {
            // Some endpoints might return data directly
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingError(error)
            }
        }
    }

    private func refreshTokenIfNeeded() async throws {
        guard let refreshToken = keychainService.getRefreshToken() else {
            throw APIError.unauthorized
        }

        if isRefreshing {
            try await withCheckedThrowingContinuation { continuation in
                refreshContinuations.append(continuation)
            }
            return
        }

        isRefreshing = true
        defer {
            isRefreshing = false
            refreshContinuations.forEach { $0.resume() }
            refreshContinuations.removeAll()
        }

        let body = ["refreshToken": refreshToken]
        var request = try buildRequest(path: APIEndpoints.refresh, method: "POST", body: body)
        request.setValue("Bearer \(refreshToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            keychainService.clearTokens()
            throw APIError.unauthorized
        }

        let tokens: AuthTokens = try decodeResponse(data: data, statusCode: httpResponse.statusCode)
        keychainService.setAccessToken(tokens.accessToken)
        keychainService.setRefreshToken(tokens.refreshToken)
    }
}

struct EmptyData: Decodable {}
