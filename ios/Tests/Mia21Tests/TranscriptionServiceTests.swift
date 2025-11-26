//
//  TranscriptionServiceTests.swift
//  Mia21Tests
//
//  Created on November 7, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Unit tests for TranscriptionService.

import XCTest
@testable import Mia21

final class TranscriptionServiceTests: XCTestCase {

  var transcriptionService: TranscriptionService!

  override func setUp() {
    super.setUp()
    transcriptionService = TranscriptionService(
      baseURL: "https://api.mia21.com",
      apiKey: "test-api-key",
      timeout: 30.0
    )
  }

  override func tearDown() {
    transcriptionService = nil
    super.tearDown()
  }

  // MARK: - Initialization Tests

  func testTranscriptionServiceInitialization() {
    XCTAssertNotNil(transcriptionService)
  }

  // MARK: - Transcribe Audio Tests

  // Note: Full transcription tests require network mocking at URLSession level
  // These are basic structure tests - full integration tests would mock URLSession

  func testTranscriptionServiceStructure() {
    // Verify service is properly initialized
    XCTAssertNotNil(transcriptionService)
  }
}
