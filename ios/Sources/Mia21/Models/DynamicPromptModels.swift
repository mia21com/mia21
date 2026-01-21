//
//  DynamicPromptModels.swift
//  Mia21
//
//  Created on January 21, 2026.
//  Copyright © 2026 Mia21. All rights reserved.
//
//  Description:
//  Models for Dynamic Prompting feature.
//  OpenAI-compatible endpoint for runtime AI configuration.
//

import Foundation

// MARK: - Dynamic Prompt Options

/// Options for dynamic prompting via OpenAI-compatible endpoint
public struct DynamicPromptOptions {
  /// The model to use (e.g., "gpt-4o", "gpt-4o-mini", "claude-3-opus")
  public var model: String
  /// Space ID for conversation context separation
  public var spaceId: String?
  /// User ID for personalization and memory
  public var userId: String?
  /// Temperature for response randomness (0.0-2.0)
  public var temperature: Double?
  /// Maximum tokens in the response
  public var maxTokens: Int?
  /// Whether to stream the response
  public var stream: Bool
  
  public init(
    model: String = "gpt-4o",
    spaceId: String? = nil,
    userId: String? = nil,
    temperature: Double? = nil,
    maxTokens: Int? = nil,
    stream: Bool = false
  ) {
    self.model = model
    self.spaceId = spaceId
    self.userId = userId
    self.temperature = temperature
    self.maxTokens = maxTokens
    self.stream = stream
  }
}

// MARK: - Dynamic Prompt Response

/// Response from the OpenAI-compatible chat completions endpoint
public struct DynamicPromptResponse: Codable {
  public let id: String
  public let object: String
  public let created: Int
  public let model: String
  public let choices: [DynamicPromptChoice]
  public let usage: DynamicPromptUsage?
}

/// A single choice in the dynamic prompt response
public struct DynamicPromptChoice: Codable {
  public let index: Int
  public let message: DynamicPromptMessage
  public let finishReason: String?
  
  enum CodingKeys: String, CodingKey {
    case index
    case message
    case finishReason = "finish_reason"
  }
}

/// A message in the OpenAI-compatible format
public struct DynamicPromptMessage: Codable {
  public let role: String
  public let content: String
}

/// Token usage information
public struct DynamicPromptUsage: Codable {
  public let promptTokens: Int
  public let completionTokens: Int
  public let totalTokens: Int
  
  enum CodingKeys: String, CodingKey {
    case promptTokens = "prompt_tokens"
    case completionTokens = "completion_tokens"
    case totalTokens = "total_tokens"
  }
}

// MARK: - Stream Chunk Response

/// A chunk from the streaming response
public struct DynamicPromptStreamChunk: Codable {
  public let id: String
  public let object: String
  public let created: Int
  public let model: String
  public let choices: [DynamicPromptStreamChoice]
}

/// A single choice in a streaming chunk
public struct DynamicPromptStreamChoice: Codable {
  public let index: Int
  public let delta: DynamicPromptDelta
  public let finishReason: String?
  
  enum CodingKeys: String, CodingKey {
    case index
    case delta
    case finishReason = "finish_reason"
  }
}

/// Delta content in a streaming chunk
public struct DynamicPromptDelta: Codable {
  public let role: String?
  public let content: String?
}

