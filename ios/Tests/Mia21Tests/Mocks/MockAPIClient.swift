//
//  MockAPIClient.swift
//  Mia21Tests
//
//  Created on November 7, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Mock implementation of APIClientProtocol for testing.

import Foundation
@testable import Mia21

// MARK: - Mock API Client

final class MockAPIClient: APIClientProtocol {

  // MARK: - Properties

  var performRequestHandler: ((APIEndpoint) throws -> Any)?
  var performStreamRequestHandler: ((APIEndpoint) throws -> AsyncThrowingStream<Data, Error>)?

  var lastRequest: APIEndpoint?
  var requestCount = 0

  // MARK: - APIClientProtocol

  func performRequest<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
    requestCount += 1
    lastRequest = endpoint

    if let handler = performRequestHandler {
      let result = try handler(endpoint)
      guard let typedResult = result as? T else {
        throw NSError(domain: "MockAPIClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Type mismatch"])
      }
      return typedResult
    }

    throw NSError(domain: "MockAPIClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "No handler set"])
  }

  func performStreamRequest(_ endpoint: APIEndpoint) async throws -> AsyncThrowingStream<Data, Error> {
    requestCount += 1
    lastRequest = endpoint

    if let handler = performStreamRequestHandler {
      return try handler(endpoint)
    }

    return AsyncThrowingStream { continuation in
      continuation.finish(throwing: NSError(domain: "MockAPIClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "No handler set"]))
    }
  }

  // MARK: - Helper Methods
  
  func reset() {
    performRequestHandler = nil
    performStreamRequestHandler = nil
    lastRequest = nil
    requestCount = 0
  }
}
