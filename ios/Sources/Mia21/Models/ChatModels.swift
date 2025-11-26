//
//  ChatModels.swift
//  Mia21
//
//  Created on November 4, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Chat-related data models.
//  Includes chat messages, options, responses, and tool calls.
//

import Foundation

// MARK: - Chat Message

public struct ChatMessage: Codable {
  public let role: MessageRole
  public let content: String

  public init(role: MessageRole, content: String) {
    self.role = role
    self.content = content
  }
}

// MARK: - Chat Options

public struct ChatOptions {
  public var spaceId: String?
  public var botId: String?
  public var conversationId: String?
  public var temperature: Double?
  public var maxTokens: Int?
  public var customerLlmKey: String?
  public var spaceConfig: SpaceConfig?
  public var llmType: LLMType?

  public init(
    spaceId: String? = nil,
    botId: String? = nil,
    conversationId: String? = nil,
    temperature: Double? = nil,
    maxTokens: Int? = nil,
    customerLlmKey: String? = nil,
    spaceConfig: SpaceConfig? = nil,
    llmType: LLMType? = nil
  ) {
    self.spaceId = spaceId
    self.botId = botId
    self.conversationId = conversationId
    self.temperature = temperature
    self.maxTokens = maxTokens
    self.customerLlmKey = customerLlmKey
    self.spaceConfig = spaceConfig
    self.llmType = llmType
  }
}

// MARK: - Chat Response

public struct ChatResponse: Codable {
  public let message: String
  public let userId: String
  public let toolCalls: [ToolCall]?
  
  // Note: No custom CodingKeys needed - APIClient uses .convertFromSnakeCase
}

// MARK: - Tool Call

public struct ToolCall: Codable {
  public let name: String?
  public let arguments: String?
}
