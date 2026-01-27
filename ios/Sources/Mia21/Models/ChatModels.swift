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
  /// Voice ID for per-request voice override (ElevenLabs voice ID).
  /// Priority: Request-level voiceId > Bot-level voice_id > Default
  public var voiceId: String?

  public init(
    spaceId: String? = nil,
    botId: String? = nil,
    conversationId: String? = nil,
    temperature: Double? = nil,
    maxTokens: Int? = nil,
    customerLlmKey: String? = nil,
    spaceConfig: SpaceConfig? = nil,
    llmType: LLMType? = nil,
    voiceId: String? = nil
  ) {
    self.spaceId = spaceId
    self.botId = botId
    self.conversationId = conversationId
    self.temperature = temperature
    self.maxTokens = maxTokens
    self.customerLlmKey = customerLlmKey
    self.spaceConfig = spaceConfig
    self.llmType = llmType
    self.voiceId = voiceId
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

// MARK: - OpenAI-Compatible Completion Options

/// Options for OpenAI-compatible `/v1/chat/completions` endpoint.
/// No bot/space pre-configuration required - just pass messages with system prompt.
public struct CompletionOptions {
  /// Space ID for context separation (passed via X-Space-Id header)
  public var spaceId: String?
  /// Bot ID for specific bot behavior (passed via X-Bot-Id header)
  public var botId: String?
  /// Model to use (e.g., "gpt-4o", "gpt-4o-mini")
  public var model: String
  /// Temperature for response randomness (0.0 - 2.0)
  public var temperature: Double?
  /// Maximum tokens in response
  public var maxTokens: Int?
  /// Whether to stream the response
  public var stream: Bool
  
  public init(
    spaceId: String? = nil,
    botId: String? = nil,
    model: String = "gpt-4o",
    temperature: Double? = nil,
    maxTokens: Int? = nil,
    stream: Bool = false
  ) {
    self.spaceId = spaceId
    self.botId = botId
    self.model = model
    self.temperature = temperature
    self.maxTokens = maxTokens
    self.stream = stream
  }
}

// MARK: - OpenAI-Compatible Completion Response

/// Response from OpenAI-compatible `/v1/chat/completions` endpoint
public struct CompletionResponse: Codable {
  public let id: String?
  public let object: String?
  public let created: Int?
  public let model: String?
  public let choices: [CompletionChoice]?
  public let usage: CompletionUsage?
}

public struct CompletionChoice: Codable {
  public let index: Int?
  public let message: CompletionMessage?
  public let delta: CompletionMessage?
  public let finishReason: String?
}

public struct CompletionMessage: Codable {
  public let role: String?
  public let content: String?
}

public struct CompletionUsage: Codable {
  public let promptTokens: Int?
  public let completionTokens: Int?
  public let totalTokens: Int?
}

// MARK: - OpenAI-Compatible Chat Initialize

/// Options for OpenAI-compatible `/v1/chat/initialize` endpoint.
/// Generates a personalized greeting based on user's conversation history.
public struct ChatInitializeOptions {
  /// Space ID for context separation (passed via X-Space-Id header)
  public var spaceId: String?
  /// Bot ID for specific bot behavior (passed via X-Bot-Id header)
  public var botId: String?
  /// Model to use for generating the greeting (e.g., "gpt-4o", "gpt-4o-mini")
  public var model: String
  /// Language code for the greeting (e.g., "en", "es", "fr")
  public var language: String?
  /// User's name for personalization
  public var userName: String?
  /// User's timezone for context-aware greetings
  public var timezone: String?
  
  public init(
    spaceId: String? = nil,
    botId: String? = nil,
    model: String = "gpt-4o",
    language: String? = nil,
    userName: String? = nil,
    timezone: String? = nil
  ) {
    self.spaceId = spaceId
    self.botId = botId
    self.model = model
    self.language = language
    self.userName = userName
    self.timezone = timezone
  }
}

/// Response from OpenAI-compatible `/v1/chat/initialize` endpoint
public struct ChatInitializeResponse: Codable {
  /// Unique identifier for the initialization request
  public let id: String?
  /// Object type (e.g., "chat.initialize")
  public let object: String?
  /// Unix timestamp of creation
  public let created: Int?
  /// Model used to generate the greeting
  public let model: String?
  /// Personalized greeting message based on conversation history
  public let greeting: String?
  /// Context about the user derived from history
  public let userContext: ChatUserContext?
}

/// User context derived from conversation history
public struct ChatUserContext: Codable {
  /// Number of previous conversations
  public let conversationCount: Int?
  /// Last interaction timestamp
  public let lastInteraction: String?
  /// Topics the user has discussed
  public let topics: [String]?
  /// Whether this is a returning user
  public let isReturningUser: Bool?
}
