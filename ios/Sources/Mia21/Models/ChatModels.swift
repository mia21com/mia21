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
/// Fully compatible with OpenAI's API - standard OpenAI SDKs work by just changing the base_url.
/// Mia21 extensions are passed via HTTP headers.
public struct CompletionOptions {
  // MARK: - OpenAI Standard Parameters (in request body)
  
  /// Model to use (e.g., "gpt-4o", "gpt-4o-mini")
  public var model: String
  /// Temperature for response randomness (0.0 - 2.0)
  public var temperature: Double?
  /// Maximum tokens in response
  public var maxTokens: Int?
  /// Whether to stream the response
  public var stream: Bool
  
  // MARK: - Mia21 Extensions (via HTTP headers)
  
  /// Space ID for memory isolation (X-Space-Id header, default: "default")
  public var spaceId: String?
  /// Agent ID for specific agent behavior (X-Agent-Id header)
  public var agentId: String?
  /// Enable voice output (X-Voice-Enabled header, default: false)
  public var voiceEnabled: Bool?
  /// ElevenLabs voice ID for TTS (X-Voice-Id header)
  public var voiceId: String?
  /// Disable memory - no history used or saved (X-Incognito header, default: false)
  public var incognito: Bool?
  
  public init(
    model: String = "gpt-4o",
    temperature: Double? = nil,
    maxTokens: Int? = nil,
    stream: Bool = false,
    spaceId: String? = nil,
    agentId: String? = nil,
    voiceEnabled: Bool? = nil,
    voiceId: String? = nil,
    incognito: Bool? = nil
  ) {
    self.model = model
    self.temperature = temperature
    self.maxTokens = maxTokens
    self.stream = stream
    self.spaceId = spaceId
    self.agentId = agentId
    self.voiceEnabled = voiceEnabled
    self.voiceId = voiceId
    self.incognito = incognito
  }
  
  /// Backward compatibility initializer with botId
  @available(*, deprecated, message: "Use agentId instead of botId")
  public init(
    spaceId: String? = nil,
    botId: String?,
    model: String = "gpt-4o",
    temperature: Double? = nil,
    maxTokens: Int? = nil,
    stream: Bool = false
  ) {
    self.model = model
    self.temperature = temperature
    self.maxTokens = maxTokens
    self.stream = stream
    self.spaceId = spaceId
    self.agentId = botId  // Map botId to agentId
    self.voiceEnabled = nil
    self.voiceId = nil
    self.incognito = nil
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

// MARK: - OpenAI-Compatible Chat Initialize (Greeting Generation)

/// Options for OpenAI-compatible `/v1/chat/initialize` endpoint.
/// Generates a personalized greeting based on user's conversation history and memories.
/// All parameters are passed via HTTP headers (no request body).
public struct GreetingOptions {
  /// Space ID for context separation (X-Space-Id header)
  public var spaceId: String?
  /// Agent ID for greeting style (X-Agent-Id header)
  public var agentId: String?
  /// Enable voice in response (X-Voice-Enabled header)
  public var voiceEnabled: Bool?
  /// Voice ID for TTS (X-Voice-Id header)
  public var voiceId: String?
  /// If true, no memory is used or saved (X-Incognito header)
  public var incognito: Bool?
  
  public init(
    spaceId: String? = nil,
    agentId: String? = nil,
    voiceEnabled: Bool? = nil,
    voiceId: String? = nil,
    incognito: Bool? = nil
  ) {
    self.spaceId = spaceId
    self.agentId = agentId
    self.voiceEnabled = voiceEnabled
    self.voiceId = voiceId
    self.incognito = incognito
  }
}

/// Backward compatibility alias
@available(*, deprecated, renamed: "GreetingOptions")
public typealias ChatInitializeOptions = GreetingOptions

/// Response from OpenAI-compatible `/v1/chat/initialize` endpoint
public struct GreetingResponse: Codable {
  /// Unique identifier for the request
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
  public let userContext: GreetingUserContext?
  /// Audio data if voice was enabled (base64 encoded)
  public let audio: String?
}

/// User context derived from conversation history
public struct GreetingUserContext: Codable {
  /// Number of previous conversations
  public let conversationCount: Int?
  /// Last interaction timestamp
  public let lastInteraction: String?
  /// Topics the user has discussed
  public let topics: [String]?
  /// Whether this is a returning user
  public let isReturningUser: Bool?
}

/// Backward compatibility aliases
@available(*, deprecated, renamed: "GreetingResponse")
public typealias ChatInitializeResponse = GreetingResponse
@available(*, deprecated, renamed: "GreetingUserContext")
public typealias ChatUserContext = GreetingUserContext
