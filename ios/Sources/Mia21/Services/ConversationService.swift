//
//  ConversationService.swift
//  Mia21
//
//  Created on November 17, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Service layer for conversation history operations.
//  Handles listing, retrieving, and deleting conversations.
//

import Foundation

// MARK: - Conversation Service Protocol

protocol ConversationServiceProtocol {
  func listConversations(userId: String, spaceId: String?, limit: Int) async throws -> [ConversationSummary]
  func getConversation(conversationId: String) async throws -> ConversationDetail
  func deleteConversation(conversationId: String) async throws -> DeleteConversationResponse
}

// MARK: - Conversation Service Implementation

final class ConversationService: ConversationServiceProtocol {

  // MARK: - Properties

  private let apiClient: APIClientProtocol

  // MARK: - Initialization

  init(apiClient: APIClientProtocol) {
    self.apiClient = apiClient
  }

  // MARK: - Public Methods

  func listConversations(userId: String, spaceId: String?, limit: Int) async throws -> [ConversationSummary] {
    logInfo("Listing conversations for user: \(userId), space: \(spaceId ?? "all"), limit: \(limit)")

    var queryParams: [String: String] = [
      "user_id": userId,
      "limit": String(limit)
    ]

    if let spaceId = spaceId {
      queryParams["space_id"] = spaceId
    }

    // Build query string
    let queryString = queryParams
      .map { "\($0.key)=\($0.value)" }
      .joined(separator: "&")

    let endpoint = APIEndpoint(
      path: "/conversations?\(queryString)",
      method: .get
    )

    let conversations: [ConversationSummary] = try await apiClient.performRequest(endpoint)

    logInfo("Retrieved \(conversations.count) conversations")
    
    // Log conversation details
    for (index, conv) in conversations.prefix(5).enumerated() {
      logDebug("  [\(index)] ID: \(conv.id), Space: \(conv.spaceId), Bot: \(conv.botId ?? "nil"), Messages: \(conv.messageCount), Title: \(conv.title ?? "nil")")
    }
    if conversations.count > 5 {
      logDebug("  ... and \(conversations.count - 5) more conversations")
    }
    
    return conversations
  }

  func getConversation(conversationId: String) async throws -> ConversationDetail {
    logInfo("Getting conversation: \(conversationId)")

    let endpoint = APIEndpoint(
      path: "/conversations/\(conversationId)",
      method: .get
    )

    let conversation: ConversationDetail = try await apiClient.performRequest(endpoint)

    logInfo("Retrieved conversation with \(conversation.messages.count) messages")
    logDebug("  Conversation ID: \(conversation.id)")
    logDebug("  Space: \(conversation.spaceId), Bot: \(conversation.botId ?? "nil")")
    logDebug("  Status: \(conversation.status)")
    logDebug("  Created: \(conversation.createdAt), Updated: \(conversation.updatedAt)")
    logDebug("  Message count: \(conversation.messages.count)")
    
    // Log first few messages
    for (index, message) in conversation.messages.prefix(3).enumerated() {
      let preview = message.content.prefix(50)
      logDebug("    [\(index)] \(message.role): \(preview)\(message.content.count > 50 ? "..." : "")")
    }
    if conversation.messages.count > 3 {
      logDebug("    ... and \(conversation.messages.count - 3) more messages")
    }
    
    return conversation
  }

  func deleteConversation(conversationId: String) async throws -> DeleteConversationResponse {
    logInfo("Deleting conversation: \(conversationId)")

    let endpoint = APIEndpoint(
      path: "/conversations/\(conversationId)",
      method: .delete
    )

    let response: DeleteConversationResponse = try await apiClient.performRequest(endpoint)

    logInfo("Successfully deleted conversation: \(conversationId)")
    logDebug("  Response: \(response.message)")
    
    return response
  }
}



