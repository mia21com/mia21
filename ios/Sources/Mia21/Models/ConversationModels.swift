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
  
  /// Generate title from space and bot names with conversation title
  /// - Parameters:
  ///   - spaceName: Name of the space
  ///   - botName: Name of the bot (optional)
  /// - Returns: Formatted title like "Space · Bot: [title]"
  public func displayTitle(spaceName: String?, botName: String?) -> String {
    let spaceDisplay = spaceName ?? spaceId
    let botDisplay = botName ?? (botId ?? "No Bot")
    
    // If backend provided a title, use format: "Space · Bot: [title]"
    if let title = title, !title.isEmpty {
      return "\(spaceDisplay) · \(botDisplay): \(title)"
    }
    
    // Otherwise just show "Space · Bot"
    return "\(spaceDisplay) · \(botDisplay)"
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
