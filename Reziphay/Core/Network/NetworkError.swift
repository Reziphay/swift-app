// NetworkError.swift
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case notFound
    case serverError(statusCode: Int, message: String)
    case decodingError(Error)
    case noInternetConnection
    case timeout
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL."
        case .invalidResponse:
            return "Invalid server response."
        case .unauthorized:
            return "Your session has expired. Please log in again."
        case .notFound:
            return "Resource not found."
        case .serverError(_, let message):
            return message
        case .decodingError:
            return "Failed to process server response."
        case .noInternetConnection:
            return "No internet connection. Please check your network settings."
        case .timeout:
            return "Request timed out. Please try again."
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}
