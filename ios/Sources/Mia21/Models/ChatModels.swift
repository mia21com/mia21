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
  /// Dynamic system prompt - configure AI behavior at runtime.
  /// When provided, this will be prepended as a system message to the conversation.
  public var systemPrompt: String?

  public init(
    spaceId: String? = nil,
    botId: String? = nil,
    conversationId: String? = nil,
    temperature: Double? = nil,
    maxTokens: Int? = nil,
    customerLlmKey: String? = nil,
    spaceConfig: SpaceConfig? = nil,
    llmType: LLMType? = nil,
    voiceId: String? = nil,
    systemPrompt: String? = nil
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
    self.systemPrompt = systemPrompt
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
