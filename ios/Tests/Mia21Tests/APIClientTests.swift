//
//  APIClientTests.swift
//  Mia21Tests
//
//  Created on November 7, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Unit tests for APIClient networking layer.

import XCTest
@testable import Mia21

final class APIClientTests: XCTestCase {
  
  var apiClient: APIClient!
  var mockSession: URLSession!
  
  override func setUp() {
    super.setUp()
    apiClient = APIClient(
      baseURL: "https://api.mia21.com",
      apiKey: "test-api-key",
      timeout: 30.0
    )
  }
  
  override func tearDown() {
    apiClient = nil
    super.tearDown()
  }
  
  // MARK: - Initialization Tests
  
  func testAPIClientInitialization() {
    XCTAssertNotNil(apiClient)
  }
  
  // MARK: - Request Building Tests
  
  func testBuildRequestWithGET() throws {
    let endpoint = APIEndpoint(
      path: "/test",
      method: .get,
      body: nil
    )
    
    // Access private method via reflection or test through public API
    // For now, we'll test through integration
    XCTAssertEqual(endpoint.method, .get)
    XCTAssertEqual(endpoint.path, "/test")
  }
  
  func testBuildRequestWithPOST() throws {
    let endpoint = APIEndpoint(
      path: "/test",
      method: .post,
      body: ["key": "value"]
    )
    
    XCTAssertEqual(endpoint.method, .post)
    XCTAssertNotNil(endpoint.body)
  }
  
  func testBuildRequestWithHeaders() throws {
    let endpoint = APIEndpoint(
      path: "/test",
      method: .get,
      body: nil,
      headers: ["Custom-Header": "value"]
    )
    
    XCTAssertNotNil(endpoint.headers)
    XCTAssertEqual(endpoint.headers?["Custom-Header"], "value")
  }
  
  // MARK: - HTTP Method Tests
  
  func testHTTPMethodRawValues() {
    XCTAssertEqual(APIEndpoint.HTTPMethod.get.rawValue, "GET")
    XCTAssertEqual(APIEndpoint.HTTPMethod.post.rawValue, "POST")
    XCTAssertEqual(APIEndpoint.HTTPMethod.put.rawValue, "PUT")
    XCTAssertEqual(APIEndpoint.HTTPMethod.delete.rawValue, "DELETE")
  }
}
