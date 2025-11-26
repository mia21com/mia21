//
//  StreamingServiceTests.swift
//  Mia21Tests
//
//  Created on November 7, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Unit tests for StreamingService.

import XCTest
@testable import Mia21

final class StreamingServiceTests: XCTestCase {

  var streamingService: StreamingService!
  var mockAPIClient: MockAPIClient!

  override func setUp() {
    super.setUp()
    mockAPIClient = MockAPIClient()
    streamingService = StreamingService(apiClient: mockAPIClient)
  }

  override func tearDown() {
    streamingService = nil
    mockAPIClient = nil
    super.tearDown()
  }

  // MARK: - Initialization Tests

  func testStreamingServiceInitialization() {
    XCTAssertNotNil(streamingService)
  }

  // MARK: - Stream Chat Tests

  func testStreamChatTextOnly() async throws {
    let testChunks = [
      "data: Hello",
      "data:  World",
      "data: !",
      "data: [DONE]"
    ]

    mockAPIClient.performStreamRequestHandler = { endpoint in
      XCTAssertEqual(endpoint.path, "/chat/stream")
      XCTAssertEqual(endpoint.method, .post)

      return AsyncThrowingStream { continuation in
        Task {
          for chunk in testChunks {
            if let data = chunk.data(using: .utf8) {
              continuation.yield(data)
            }
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
          }
          continuation.finish()
        }
      }
    }

    var receivedChunks: [String] = []
    let messages = [ChatMessage(role: .user, content: "Hello")]
    let options = ChatOptions(spaceId: "test-space")

    try await streamingService.streamChat(
      userId: "test-user",
      messages: messages,
      options: options,
      customerLlmKey: nil,
      currentSpace: "test-space"
    ) { chunk in
      receivedChunks.append(chunk)
    }

    XCTAssertGreaterThan(receivedChunks.count, 0)
    XCTAssertTrue(receivedChunks.joined().contains("Hello"))
  }

  func testStreamChatWithVoice() async throws {
    var textChunks: [String] = []
    var audioChunks: [Data] = []

    mockAPIClient.performStreamRequestHandler = { endpoint in
      XCTAssertEqual(endpoint.path, "/chat/stream")
      XCTAssertEqual(endpoint.method, .post)

      return AsyncThrowingStream { continuation in
        Task {
          // Simulate text chunk
          let textData = "data: {\"content\": \"Hello\"}".data(using: .utf8)!
          continuation.yield(textData)

          // Simulate audio chunk
          let audioJson = "data: {\"audio\": \"dGVzdCBhdWRpbyBkYXRh\"}".data(using: .utf8)!
          continuation.yield(audioJson)

          continuation.finish()
        }
      }
    }

    let messages = [ChatMessage(role: .user, content: "Hello")]
    let options = ChatOptions(spaceId: "test-space")
    let voiceConfig = VoiceConfig(
      enabled: true,
      voiceId: "test-voice",
      stability: 0.5,
      similarityBoost: 0.75
    )

    try await streamingService.streamChatWithVoice(
      userId: "test-user",
      messages: messages,
      options: options,
      voiceConfig: voiceConfig,
      customerLlmKey: nil,
      currentSpace: "test-space"
    ) { event in
      switch event {
      case .text(let chunk):
        textChunks.append(chunk)
      case .audio(let data):
        audioChunks.append(data)
      default:
        break
      }
    }

    XCTAssertGreaterThan(textChunks.count, 0)
    XCTAssertGreaterThan(audioChunks.count, 0)
  }

  // MARK: - Text Extraction Tests

  func testExtractTextContentFromPlainText() {
    let text = "This is plain text"
    let result = StreamingService.extractTextContent(from: text)
    XCTAssertEqual(result, text)
  }

  func testExtractTextContentFromJSON() {
    let json = "{\"content\": \"Hello from JSON\"}"
    let result = StreamingService.extractTextContent(from: json)
    XCTAssertEqual(result, "Hello from JSON")
  }

  func testExtractTextContentFiltersFunctionCalls() {
    let functionCall = "{'type': 'function_call', 'name': 'test'}"
    let result = StreamingService.extractTextContent(from: functionCall)
    XCTAssertNil(result)
  }

  func testExtractTextContentFiltersDONE() {
    let done = "[DONE]"
    let result = StreamingService.extractTextContent(from: done)
    XCTAssertNil(result)
  }

  func testExtractTextContentFiltersEmpty() {
    let empty = ""
    let result = StreamingService.extractTextContent(from: empty)
    XCTAssertNil(result)
  }
}
