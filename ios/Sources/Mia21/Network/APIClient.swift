//
//  APIClient.swift
//  Mia21
//
//  Created on November 4, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Protocol-based networking layer for API communication.
//  Handles request creation, execution, and response processing.
//

import Foundation

// MARK: - API Client Protocol

protocol APIClientProtocol {
  func performRequest<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T
  func performStreamRequest(_ endpoint: APIEndpoint) async throws -> AsyncThrowingStream<Data, Error>
}

// MARK: - API Endpoint

struct APIEndpoint {
  let path: String
  let method: HTTPMethod
  let body: [String: Any]?
  let headers: [String: String]?

  enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
  }

  init(path: String, method: HTTPMethod, body: [String: Any]? = nil, headers: [String: String]? = nil) {
    self.path = path
    self.method = method
    self.body = body
    self.headers = headers
  }
}

// MARK: - API Client Implementation

final class APIClient: APIClientProtocol {

  // MARK: - Properties

  private let baseURL: String
  private let apiKey: String?
  private let session: URLSession
  private let timeout: TimeInterval

  // MARK: - Initialization

  init(baseURL: String, apiKey: String?, timeout: TimeInterval) {
    self.baseURL = baseURL
    self.apiKey = apiKey
    self.timeout = timeout

    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = timeout
    config.timeoutIntervalForResource = timeout * 2
    self.session = URLSession(configuration: config)
  }

  // MARK: - Public Methods

  func performRequest<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
    let request = try buildRequest(endpoint)

    logRequest(request)

    let (data, response) = try await session.data(for: request)

    try validateResponse(response, data: data)
    logResponse(response, data: data)

    return try decodeResponse(data)
  }

  func performStreamRequest(_ endpoint: APIEndpoint) async throws -> AsyncThrowingStream<Data, Error> {
    let request = try buildRequest(endpoint)

    logRequest(request)

    return AsyncThrowingStream { continuation in
      Task {
        do {
          let (bytes, response) = try await session.bytes(for: request)

          guard let httpResponse = response as? HTTPURLResponse else {
            continuation.finish(throwing: Mia21Error.invalidResponse)
            return
          }

          logDebug("Stream Status: \(httpResponse.statusCode)")

          guard (200...299).contains(httpResponse.statusCode) else {
            logError("Stream error: HTTP \(httpResponse.statusCode)")
            continuation.finish(throwing: Mia21Error.apiError("HTTP \(httpResponse.statusCode)"))
            return
          }

          for try await line in bytes.lines {
            if let data = line.data(using: .utf8) {
              continuation.yield(data)
            }
          }

          continuation.finish()
        } catch {
          continuation.finish(throwing: error)
        }
      }
    }
  }

  // MARK: - Private Methods

  private func buildRequest(_ endpoint: APIEndpoint) throws -> URLRequest {
    let fullURL = "\(baseURL)/api/v1\(endpoint.path)"

    guard let url = URL(string: fullURL) else {
      throw Mia21Error.invalidURL
    }

    var request = URLRequest(url: url)
    request.httpMethod = endpoint.method.rawValue
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    // Add API key if available
    if let apiKey = apiKey {
      request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
    }

    // Add custom headers
    endpoint.headers?.forEach { key, value in
      request.setValue(value, forHTTPHeaderField: key)
    }

    // Add body if provided
    if let body = endpoint.body {
      request.httpBody = try JSONSerialization.data(withJSONObject: body)
    }

    return request
  }

  private func validateResponse(_ response: URLResponse, data: Data) throws {
    guard let httpResponse = response as? HTTPURLResponse else {
      throw Mia21Error.invalidResponse
    }

    guard (200...299).contains(httpResponse.statusCode) else {
      let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
      throw Mia21Error.apiError("HTTP \(httpResponse.statusCode): \(errorMessage)")
    }
  }

  private func decodeResponse<T: Decodable>(_ data: Data) throws -> T {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase

    do {
      return try decoder.decode(T.self, from: data)
    } catch {
      logError("Decoding error: \(error)")
      throw Mia21Error.decodingError(error)
    }
  }

  // MARK: - Logging

  private func logRequest(_ request: URLRequest) {
    logDebug("API Request: \(request.httpMethod ?? "?") \(request.url?.absoluteString ?? "?")")
    if let bodyData = request.httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
      logDebug("Request Body: \(bodyString)")
    }
  }

  private func logResponse(_ response: URLResponse, data: Data) {
    if let httpResponse = response as? HTTPURLResponse {
      logDebug("Response Status: \(httpResponse.statusCode)")
    }
    if let responseString = String(data: data, encoding: .utf8) {
      logDebug("Response Data: \(responseString)")
    }
  }
}
