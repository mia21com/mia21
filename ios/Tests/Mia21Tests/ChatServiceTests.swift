//
//  ChatServiceTests.swift
//  Mia21Tests
//
//  Created on November 7, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Unit tests for ChatService.

import XCTest
@testable import Mia21

final class ChatServiceTests: XCTestCase {

  var chatService: ChatService!
  var mockAPIClient: MockAPIClient!

  override func setUp() {
    super.setUp()
    mockAPIClient = MockAPIClient()
    chatService = ChatService(apiClient: mockAPIClient)
  }

  override func tearDown() {
    chatService = nil
    mockAPIClient = nil
    super.tearDown()
  }

  // MARK: - Initialization Tests

  func testChatServiceInitialization() {
    XCTAssertNotNil(chatService)
    XCTAssertNil(chatService.currentSpace)
  }

  // MARK: - Initialize Tests

  func testInitializeChat() async throws {
    // Setup mock response
    let mockResponse = InitializeResponse(
      status: "initialized",
      userId: "test-user-id",
      message: "Hello! How can I help?",
      spaceId: "test-space",
      isNewUser: true
    )

    mockAPIClient.performRequestHandler = { endpoint in
      XCTAssertEqual(endpoint.path, "/initialize_chat")
      XCTAssertEqual(endpoint.method, .post)
      return mockResponse
    }

    let options = InitializeOptions(
      spaceId: "test-space",
      llmType: .openai,
      generateFirstMessage: true
    )

    let response = try await chatService.initialize(
      userId: "test-user",
      options: options,
      customerLlmKey: nil
    )

    XCTAssertEqual(response.spaceId, "test-space")
    XCTAssertEqual(response.message, "Hello! How can I help?")
    XCTAssertEqual(chatService.currentSpace, "test-space")
  }

  func testInitializeChatWithBotId() async throws {
    let mockResponse = InitializeResponse(
      status: "initialized",
      userId: "test-user-id",
      message: "Hello!",
      spaceId: "test-space",
      isNewUser: false
    )

    mockAPIClient.performRequestHandler = { endpoint in
      guard let body = endpoint.body else {
        XCTFail("Body should not be nil")
        throw NSError(domain: "Test", code: -1)
      }

      // Verify bot_id is in the body
      XCTAssertNotNil(body["bot_id"] as? String)
      XCTAssertEqual(body["bot_id"] as? String, "test-bot")

      return mockResponse
    }

    var options = InitializeOptions(spaceId: "test-space")
    options.botId = "test-bot"

    let response = try await chatService.initialize(
      userId: "test-user",
      options: options,
      customerLlmKey: nil
    )

    XCTAssertNotNil(response)
  }

  // MARK: - Send Message Tests

  func testSendMessage() async throws {
    let mockResponse = ChatResponse(
      message: "This is a test response",
      userId: "test-user-id",
      toolCalls: nil
    )

    mockAPIClient.performRequestHandler = { endpoint in
      XCTAssertEqual(endpoint.path, "/chat")
      XCTAssertEqual(endpoint.method, .post)
      return mockResponse
    }

    let options = ChatOptions(spaceId: "test-space")
    let response = try await chatService.sendMessage(
      userId: "test-user",
      message: "Hello",
      options: options,
      customerLlmKey: nil,
      currentSpace: "test-space"
    )

    XCTAssertEqual(response.message, "This is a test response")
  }

  func testSendMessageWithBotId() async throws {
    let mockResponse = ChatResponse(
      message: "Response with bot",
      userId: "test-user-id",
      toolCalls: nil
    )

    mockAPIClient.performRequestHandler = { endpoint in
      guard let body = endpoint.body else {
        XCTFail("Body should not be nil")
        throw NSError(domain: "Test", code: -1)
      }

      XCTAssertNotNil(body["bot_id"] as? String)
      return mockResponse
    }

    var options = ChatOptions(spaceId: "test-space")
    options.botId = "test-bot"

    let response = try await chatService.sendMessage(
      userId: "test-user",
      message: "Hello",
      options: options,
      customerLlmKey: nil,
      currentSpace: "test-space"
    )

    XCTAssertNotNil(response)
  }

  // MARK: - Close Chat Tests

  func testCloseChat() async throws {
    mockAPIClient.performRequestHandler = { endpoint in
      XCTAssertEqual(endpoint.path, "/close_chat")
      XCTAssertEqual(endpoint.method, .post)
      return [String: String]() // Empty response
    }

    try await chatService.close(
      userId: "test-user",
      spaceId: "test-space"
    )

    XCTAssertEqual(mockAPIClient.requestCount, 1)
  }
}
