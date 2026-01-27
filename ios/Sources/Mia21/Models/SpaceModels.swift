//
//  SpaceModels.swift
//  Mia21
//
//  Created on November 4, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Space-related data models.
//  Includes space information and configuration.
//

import Foundation

// MARK: - Space

public struct Space: Codable {
  public let spaceId: String
  public let name: String
  public let prompt: String
  public let description: String
  public let generateFirstMessage: Bool
  public let bots: [Bot]
  public let isActive: Bool
  public let usageCount: Int
  public let createdAt: String
  public let updatedAt: String
  public let type: String
  
  // Note: No custom CodingKeys needed - APIClient uses .convertFromSnakeCase
  // snake_case from API (e.g., "space_id") automatically maps to camelCase (e.g., spaceId)
}

// MARK: - Space Configuration

public struct SpaceConfig: Codable {
  public let spaceId: String
  public let prompt: String
  public let description: String?
  public let llmIdentifier: String
  public let temperature: Double
  public let maxTokens: Int
  public let frequencyPenalty: Double?
  public let presencePenalty: Double?
  
  // Note: No custom CodingKeys needed - APIClient uses .convertFromSnakeCase

  public init(
    spaceId: String,
    prompt: String,
    description: String? = nil,
    llmIdentifier: String,
    temperature: Double = 0.7,
    maxTokens: Int = 1024,
    frequencyPenalty: Double? = nil,
    presencePenalty: Double? = nil
  ) {
    self.spaceId = spaceId
    self.prompt = prompt
    self.description = description
    self.llmIdentifier = llmIdentifier
    self.temperature = temperature
    self.maxTokens = maxTokens
    self.frequencyPenalty = frequencyPenalty
    self.presencePenalty = presencePenalty
  }
}

// MARK: - Space Conversations

/// Conversation status filter options
public enum ConversationStatus: String {
  case active
  case closed
  case archived
}

/// Options for listing conversations within a space
public struct SpaceConversationsOptions {
  /// Filter by specific user ID
  public var userId: String?
  /// Filter by bot ID
  public var botId: String?
  /// Filter by conversation status
  public var status: ConversationStatus?
  /// Maximum number of conversations to return (1-500, default: 100)
  public var limit: Int
  /// Offset for pagination
  public var offset: Int
  
  public init(
    userId: String? = nil,
    botId: String? = nil,
    status: ConversationStatus? = nil,
    limit: Int = 100,
    offset: Int = 0
  ) {
    self.userId = userId
    self.botId = botId
    self.status = status
    self.limit = min(max(limit, 1), 500)
    self.offset = max(offset, 0)
  }
}

/// Response containing conversations within a space
public struct SpaceConversationsResponse: Codable {
  /// The space ID
  public let spaceId: String
  /// Total count of conversations matching the filter
  public let totalCount: Int
  /// List of conversations
  public let conversations: [SpaceConversation]
  /// Limit used for the query
  public let limit: Int
  /// Offset used for the query
  public let offset: Int
}

/// A conversation within a space
public struct SpaceConversation: Codable {
  /// Unique conversation identifier
  public let id: String
  /// User ID who owns this conversation
  public let userId: String
  /// Space ID this conversation belongs to
  public let spaceId: String
  /// Bot ID used in this conversation
  public let botId: String?
  /// Conversation title
  public let title: String?
  /// Conversation status
  public let status: String
  /// Creation timestamp
  public let createdAt: String
  /// Last update timestamp
  public let updatedAt: String
  /// Number of messages in the conversation
  public let messageCount: Int
}
