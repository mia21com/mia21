//
//  Mia21ClientIntegrationTests.swift
//  Mia21Tests
//
//  Created on November 7, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Integration tests for Mia21Client facade.
//  Tests the coordination between services.

import XCTest
@testable import Mia21

final class Mia21ClientIntegrationTests: XCTestCase {

  var client: Mia21Client!
  var mockAPIClient: MockAPIClient!

  override func setUp() {
    super.setUp()
    mockAPIClient = MockAPIClient()

    // Create real services with mock API client
    let chatService = ChatService(apiClient: mockAPIClient)
    let spaceService = SpaceService(apiClient: mockAPIClient)
    let streamingService = StreamingService(apiClient: mockAPIClient)
    let conversationService = ConversationService(apiClient: mockAPIClient)

    // TranscriptionService uses its own URLSession, not APIClientProtocol
    // For integration tests, we create it normally
    let transcriptionService = TranscriptionService(
      baseURL: "https://api.mia21.com",
      apiKey: "test-key",
      timeout: 30.0
    )

    // Create a real APIClient for the client (services use mockAPIClient)
    let realAPIClient = APIClient(
      baseURL: "https://api.mia21.com",
      apiKey: "test-key",
      timeout: 30.0
    )

    // Create client with dependency injection
    client = Mia21Client(
      userId: "test-user",
      customerLlmKey: nil,
      apiClient: realAPIClient,
      chatService: chatService,
      spaceService: spaceService,
      streamingService: streamingService,
      conversationService: conversationService,
      transcriptionService: transcriptionService
    )
  }

  override func tearDown() {
    client = nil
    mockAPIClient = nil
    super.tearDown()
  }

  // MARK: - Initialization Tests

  func testClientInitialization() {
    XCTAssertNotNil(client)
  }

  // MARK: - Chat Flow Tests

  func testFullChatFlow() async throws {
    // 1. Initialize chat
    let initResponse = InitializeResponse(
      status: "initialized",
      userId: "test-user",
      message: "Hello!",
      spaceId: "test-space",
      isNewUser: true
    )

    mockAPIClient.performRequestHandler = { endpoint in
      if endpoint.path == "/initialize_chat" {
        return initResponse
      } else if endpoint.path == "/chat" {
        return ChatResponse(message: "Response", userId: "test-user", toolCalls: nil)
      }
      throw NSError(domain: "Test", code: -1)
    }

    let initOptions = InitializeOptions(spaceId: "test-space")
    let response = try await client.initialize(options: initOptions)

    XCTAssertEqual(response.spaceId, "test-space")
    XCTAssertEqual(client.currentSpace, "test-space")

    // 2. Send message
    let chatResponse = try await client.chat(
      message: "Hello",
      options: ChatOptions(spaceId: "test-space")
    )

    XCTAssertNotNil(chatResponse)
  }

  // MARK: - Space Management Tests

  func testListSpaces() async throws {
    let mockBots: [Bot] = [
      Bot(
        botId: "bot-1",
        name: "Bot 1",
        prompt: "Be helpful",
        llmIdentifier: "gpt-4o",
        temperature: 0.7,
        maxTokens: 512,
        language: "en",
        voiceId: "voice-1",
        isDefault: true,
        customerId: "customer-1",
        createdAt: "2025-01-01T00:00:00Z",
        updatedAt: "2025-01-01T00:00:00Z"
      )
    ]
    
    let mockSpaces: [Space] = [
      Space(
        spaceId: "space-1",
        name: "Space 1",
        prompt: "You are a helpful assistant",
        description: "Desc 1",
        generateFirstMessage: true,
        bots: mockBots,
        isActive: true,
        usageCount: 0,
        createdAt: "2025-01-01T00:00:00Z",
        updatedAt: "2025-01-01T00:00:00Z",
        type: "custom"
      )
    ]

    mockAPIClient.performRequestHandler = { _ in
      return mockSpaces
    }

    let spaces = try await client.listSpaces()

    XCTAssertEqual(spaces.count, 1)
    XCTAssertEqual(spaces[0].spaceId, "space-1")
    XCTAssertEqual(spaces[0].name, "Space 1")
    XCTAssertEqual(spaces[0].bots.count, 1)
  }

  func testListBots() async throws {
    let mockBots: [Bot] = [
      Bot(
        botId: "bot-1",
        name: "Bot 1",
        prompt: "Be helpful",
        llmIdentifier: "gpt-4o",
        temperature: 0.7,
        maxTokens: 512,
        language: "en",
        voiceId: "voice-1",
        isDefault: true,
        customerId: "customer-1",
        createdAt: "2025-01-01T00:00:00Z",
        updatedAt: "2025-01-01T00:00:00Z"
      )
    ]

    // Use the public BotsResponse model
    let mockResponse = BotsResponse(bots: mockBots, count: mockBots.count)

    mockAPIClient.performRequestHandler = { _ in
      return mockResponse
    }

    let bots = try await client.listBots()

    XCTAssertEqual(bots.count, 1)
    XCTAssertEqual(bots[0].botId, "bot-1")
    XCTAssertEqual(bots[0].name, "Bot 1")
    XCTAssertTrue(bots[0].isDefault)
  }

  // MARK: - Streaming Tests

  func testStreamChat() async throws {
    var receivedChunks: [String] = []

    mockAPIClient.performStreamRequestHandler = { _ in
      return AsyncThrowingStream { continuation in
        Task {
          let chunks = ["data: Hello", "data:  World", "data: !"]
          for chunk in chunks {
            if let data = chunk.data(using: .utf8) {
              continuation.yield(data)
            }
          }
          continuation.finish()
        }
      }
    }

    let messages = [ChatMessage(role: .user, content: "Hello")]
    try await client.streamChat(
      messages: messages,
      options: ChatOptions(spaceId: "test-space")
    ) { chunk in
      receivedChunks.append(chunk)
    }

    XCTAssertGreaterThan(receivedChunks.count, 0)
  }

  // MARK: - Transcription Tests

  func testTranscribeAudio() async throws {
    // Note: This test would require URLSession mocking for full functionality
    // TranscriptionService uses its own URLSession, not APIClientProtocol
    // For now, we just verify the client has the method available
    XCTAssertNotNil(client)

    // In a full test setup, we would mock URLSession at a lower level
    // or use a protocol-based approach for TranscriptionService
  }
}
