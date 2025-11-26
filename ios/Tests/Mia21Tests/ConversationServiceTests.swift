//
//  ConversationServiceTests.swift
//  Mia21Tests
//
//  Created on November 17, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Unit tests for ConversationService.

import XCTest
@testable import Mia21

final class ConversationServiceTests: XCTestCase {

  var conversationService: ConversationService!
  var mockAPIClient: MockAPIClient!

  override func setUp() {
    super.setUp()
    mockAPIClient = MockAPIClient()
    conversationService = ConversationService(apiClient: mockAPIClient)
  }

  override func tearDown() {
    conversationService = nil
    mockAPIClient = nil
    super.tearDown()
  }

  // MARK: - List Conversations Tests

  func testListConversations() async throws {
    let mockConversations = [
      ConversationSummary(
        id: "conv-1",
        userId: "user-123",
        spaceId: "space-456",
        botId: "bot-789",
        status: "active",
        createdAt: "2024-01-01T00:00:00Z",
        updatedAt: "2024-01-01T00:00:00Z",
        closedAt: nil,
        messageCount: 10,
        firstMessage: "Hello",
        title: "Test Conversation"
      ),
      ConversationSummary(
        id: "conv-2",
        userId: "user-123",
        spaceId: "space-456",
        botId: nil,
        status: "closed",
        createdAt: "2024-01-02T00:00:00Z",
        updatedAt: "2024-01-02T00:00:00Z",
        closedAt: "2024-01-02T12:00:00Z",
        messageCount: 5,
        firstMessage: "Hi there",
        title: nil
      )
    ]

    mockAPIClient.performRequestHandler = { endpoint in
      XCTAssertTrue(endpoint.path.contains("/conversations"))
      XCTAssertTrue(endpoint.path.contains("user_id=user-123"))
      XCTAssertTrue(endpoint.path.contains("limit=50"))
      XCTAssertEqual(endpoint.method, .get)
      return mockConversations
    }

    let conversations = try await conversationService.listConversations(
      userId: "user-123",
      spaceId: nil,
      limit: 50
    )

    XCTAssertEqual(conversations.count, 2)
    XCTAssertEqual(conversations[0].id, "conv-1")
    XCTAssertEqual(conversations[0].messageCount, 10)
    XCTAssertEqual(conversations[1].status, "closed")
  }

  func testListConversationsWithSpaceFilter() async throws {
    let mockConversations: [ConversationSummary] = []

    mockAPIClient.performRequestHandler = { endpoint in
      XCTAssertTrue(endpoint.path.contains("space_id=test-space"))
      return mockConversations
    }

    let conversations = try await conversationService.listConversations(
      userId: "user-123",
      spaceId: "test-space",
      limit: 20
    )

    XCTAssertEqual(conversations.count, 0)
  }

  // MARK: - Get Conversation Tests

  func testGetConversation() async throws {
    let mockMessages = [
      ConversationMessage(
        id: "msg-1",
        role: "user",
        content: "Hello",
        createdAt: "2024-01-01T00:00:00Z",
        modelUsed: nil,
        tokensUsed: nil
      ),
      ConversationMessage(
        id: "msg-2",
        role: "assistant",
        content: "Hi there!",
        createdAt: "2024-01-01T00:00:01Z",
        modelUsed: "gpt-4",
        tokensUsed: 10
      )
    ]

    let mockConversation = ConversationDetail(
      id: "conv-123",
      userId: "user-123",
      spaceId: "space-456",
      botId: "bot-789",
      status: "active",
      createdAt: "2024-01-01T00:00:00Z",
      updatedAt: "2024-01-01T00:00:01Z",
      closedAt: nil,
      messages: mockMessages
    )

    mockAPIClient.performRequestHandler = { endpoint in
      XCTAssertEqual(endpoint.path, "/conversations/conv-123")
      XCTAssertEqual(endpoint.method, .get)
      return mockConversation
    }

    let conversation = try await conversationService.getConversation(
      conversationId: "conv-123"
    )

    XCTAssertEqual(conversation.id, "conv-123")
    XCTAssertEqual(conversation.messages.count, 2)
    XCTAssertEqual(conversation.messages[0].role, "user")
    XCTAssertEqual(conversation.messages[1].content, "Hi there!")
  }

  // MARK: - Delete Conversation Tests

  func testDeleteConversation() async throws {
    let mockResponse = DeleteConversationResponse(
      success: true,
      message: "Conversation deleted successfully",
      conversationId: "conv-123"
    )

    mockAPIClient.performRequestHandler = { endpoint in
      XCTAssertEqual(endpoint.path, "/conversations/conv-123")
      XCTAssertEqual(endpoint.method, .delete)
      return mockResponse
    }

    let response = try await conversationService.deleteConversation(
      conversationId: "conv-123"
    )

    XCTAssertTrue(response.success)
    XCTAssertEqual(response.conversationId, "conv-123")
  }
}
