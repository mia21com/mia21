//
//  ConversationModels.swift
//  Mia21
//
//  Created on November 17, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Conversation-related data models.
//  Includes conversation summaries, details, and message history.
//

import Foundation

// MARK: - Conversation Summary

public struct ConversationSummary: Codable, Identifiable {
  public let id: String
  public let userId: String
  public let spaceId: String
  public let botId: String?
  public let status: String
  public let createdAt: String
  public let updatedAt: String
  public let closedAt: String?
  public let messageCount: Int
  public let firstMessage: String?
  public let title: String?
  
  /// Get display title for the conversation
  /// - Returns: The conversation title, or "New Chat" if no title
  public var displayTitle: String {
    if let title = title, !title.isEmpty {
      return title
    }
    return "New Chat"
  }
  
  // Note: No custom CodingKeys needed - APIClient uses .convertFromSnakeCase
}

// MARK: - Conversation Detail

public struct ConversationDetail: Codable {
  public let id: String
  public let userId: String
  public let spaceId: String
  public let botId: String?
  public let status: String
  public let createdAt: String
  public let updatedAt: String
  public let closedAt: String?
  public let messages: [ConversationMessage]
  
  // Note: No custom CodingKeys needed - APIClient uses .convertFromSnakeCase
}

// MARK: - Conversation Message

public struct ConversationMessage: Codable, Identifiable {
  public let id: String
  public let role: String
  public let content: String
  public let createdAt: String
  public let modelUsed: String?
  public let tokensUsed: Int?
  
  // Note: No custom CodingKeys needed - APIClient uses .convertFromSnakeCase
}

// MARK: - Delete Response

public struct DeleteConversationResponse: Codable {
  public let success: Bool
  public let message: String
  public let conversationId: String
  
  // Note: No custom CodingKeys needed - APIClient uses .convertFromSnakeCase
}

// MARK: - Rename Response

public struct RenameConversationResponse: Codable {
  public let success: Bool
  public let conversationId: String
  public let title: String?
  
  // Note: No custom CodingKeys needed - APIClient uses .convertFromSnakeCase
}

// MARK: - Delete User Data Response (GDPR)

/// Response from deleting all user data (GDPR compliance)
/// ⚠️ This permanently deletes all conversations, messages, memories, and RAG/vector data
public struct DeleteUserDataResponse: Codable {
  public let success: Bool
  public let userId: String
  public let deleted: DeletedDataCounts
  public let ragDeleted: Bool
  
  // Note: No custom CodingKeys needed - APIClient uses .convertFromSnakeCase
}

/// Counts of deleted data items
public struct DeletedDataCounts: Codable {
  public let conversations: Int
  public let messages: Int
  public let memories: Int
}
