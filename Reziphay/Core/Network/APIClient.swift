// APIClient.swift
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import Foundation

// MARK: - Response Envelope

struct APIEnvelope<T: Decodable>: Decodable {
    let data: T
}

struct APIErrorResponse: Decodable {
    let statusCode: Int?
    let message: String?
    let error: String?
}

// MARK: - API Client

actor APIClient {
    static let shared = APIClient()

    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder

    private init() {
        self.baseURL = URL(string: "http://localhost:3000")!
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - Public Request Methods

    func request<T: Decodable>(_ endpoint: Endpoint, responseType: T.Type) async throws -> T {
        let urlRequest = try await buildRequest(for: endpoint)
        return try await perform(urlRequest, endpoint: endpoint, responseType: responseType)
    }

    func requestEmpty(_ endpoint: Endpoint) async throws {
        let urlRequest = try await buildRequest(for: endpoint)
        let (data, response) = try await execute(urlRequest)
        guard let http = response as? HTTPURLResponse else { throw NetworkError.invalidResponse }
        if http.statusCode == 401 {
            try await handleTokenRefresh()
            let retried = try await buildRequest(for: endpoint)
            let (_, retryResponse) = try await execute(retried)
            guard let retryHTTP = retryResponse as? HTTPURLResponse else { throw NetworkError.invalidResponse }
            guard retryHTTP.statusCode >= 200 && retryHTTP.statusCode < 300 else {
                let apiError = (try? decoder.decode(APIErrorResponse.self, from: data))
                throw NetworkError.serverError(statusCode: retryHTTP.statusCode, message: apiError?.message ?? "Request failed")
            }
        } else {
            guard http.statusCode >= 200 && http.statusCode < 300 else {
                let apiError = (try? decoder.decode(APIErrorResponse.self, from: data))
                throw NetworkError.serverError(statusCode: http.statusCode, message: apiError?.message ?? "Request failed")
            }
        }
    }

    // MARK: - Private

    private func perform<T: Decodable>(_ urlRequest: URLRequest, endpoint: Endpoint, responseType: T.Type) async throws -> T {
        let (data, response) = try await execute(urlRequest)
        guard let http = response as? HTTPURLResponse else { throw NetworkError.invalidResponse }

        if http.statusCode == 401 && endpoint.requiresAuth {
            try await handleTokenRefresh()
            let retried = try await buildRequest(for: endpoint)
            let (retryData, retryResponse) = try await execute(retried)
            guard let retryHTTP = retryResponse as? HTTPURLResponse else { throw NetworkError.invalidResponse }
            return try decode(T.self, from: retryData, statusCode: retryHTTP.statusCode)
        }

        return try decode(T.self, from: data, statusCode: http.statusCode)
    }

    private func execute(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch let error as URLError {
            switch error.code {
            case .notConnectedToInternet, .networkConnectionLost:
                throw NetworkError.noInternetConnection
            case .timedOut:
                throw NetworkError.timeout
            default:
                throw NetworkError.unknown(error)
            }
        }
    }

    private func buildRequest(for endpoint: Endpoint) async throws -> URLRequest {
        var components = URLComponents(url: baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: true)
        if let queryItems = endpoint.queryItems {
            components?.queryItems = queryItems
        }
        guard let url = components?.url else { throw NetworkError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if endpoint.requiresAuth, let token = await KeychainStore.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = endpoint.body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        return request
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data, statusCode: Int) throws -> T {
        guard statusCode >= 200 && statusCode < 300 else {
            let apiError = try? decoder.decode(APIErrorResponse.self, from: data)
            if statusCode == 401 { throw NetworkError.unauthorized }
            if statusCode == 404 { throw NetworkError.notFound }
            throw NetworkError.serverError(statusCode: statusCode, message: apiError?.message ?? "Request failed")
        }

        do {
            if let envelope = try? decoder.decode(APIEnvelope<T>.self, from: data) {
                return envelope.data
            }
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }

    private func handleTokenRefresh() async throws {
        guard let refreshToken = await KeychainStore.shared.refreshToken else {
            await KeychainStore.shared.clearTokens()
            throw NetworkError.unauthorized
        }

        do {
            let endpoint = Endpoint.refreshToken(token: refreshToken)
            var components = URLComponents(url: baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: true)
            components?.queryItems = nil
            guard let url = components?.url else { throw NetworkError.invalidURL }

            var request = URLRequest(url: url)
            request.httpMethod = HTTPMethod.POST.rawValue
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: ["refreshToken": refreshToken])

            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                await KeychainStore.shared.clearTokens()
                throw NetworkError.unauthorized
            }

            let tokens = try decoder.decode(APIEnvelope<AuthTokens>.self, from: data).data
            await KeychainStore.shared.save(accessToken: tokens.accessToken, refreshToken: tokens.refreshToken)
        } catch {
            await KeychainStore.shared.clearTokens()
            throw NetworkError.unauthorized
        }
    }
}

