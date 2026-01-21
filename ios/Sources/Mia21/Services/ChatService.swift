//
//  ChatService.swift
//  Mia21
//
//  Created on November 4, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Service layer for chat operations.
//  Handles chat initialization, sending messages, and session management.
//

import Foundation

// MARK: - Chat Service Protocol

protocol ChatServiceProtocol {
  var currentSpace: String? { get }
  func initialize(userId: String, options: InitializeOptions, customerLlmKey: String?) async throws -> InitializeResponse
  func sendMessage(userId: String, message: String, options: ChatOptions, customerLlmKey: String?, currentSpace: String?) async throws -> ChatResponse
  func complete(userId: String, messages: [ChatMessage], options: CompletionOptions) async throws -> CompletionResponse
  func close(userId: String, spaceId: String?) async throws
}

// MARK: - Chat Service Implementation

final class ChatService: ChatServiceProtocol {

  // MARK: - Properties

  private let apiClient: APIClientProtocol
  private(set) var currentSpace: String?

  // MARK: - Initialization

  init(apiClient: APIClientProtocol) {
    self.apiClient = apiClient
  }

  // MARK: - Public Methods

  func initialize(userId: String, options: InitializeOptions, customerLlmKey: String?) async throws -> InitializeResponse {
    logInfo("Initializing chat with space: \(options.spaceId ?? "default_space")")

    var body: [String: Any] = [
      "user_id": userId,
      "space_id": options.spaceId ?? "default_space",
      "llm_type": (options.llmType ?? .openai).rawValue,
      "generate_first_message": options.generateFirstMessage,
      "incognito_mode": options.incognitoMode
    ]

    if let userName = options.userName {
      body["user_name"] = userName
    }
    if let language = options.language {
      body["language"] = language
    }
    if let timezone = options.timezone {
      body["timezone"] = timezone
    }
    if let botId = options.botId {
      body["bot_id"] = botId
    }

    let llmKey = options.customerLlmKey ?? customerLlmKey
    if let llmKey = llmKey {
      body["customer_llm_key"] = llmKey
    }

    if let spaceConfig = options.spaceConfig {
      let encoder = JSONEncoder()
      encoder.keyEncodingStrategy = .convertToSnakeCase
      if let configData = try? encoder.encode(spaceConfig),
         let configDict = try? JSONSerialization.jsonObject(with: configData) as? [String: Any] {
        body["space_config"] = configDict
      }
    }

    let endpoint = APIEndpoint(path: "/initialize_chat", method: .post, body: body)
    let response: InitializeResponse = try await apiClient.performRequest(endpoint)

    currentSpace = options.spaceId ?? "default_space"
    logInfo("Chat initialized. Current space: \(currentSpace ?? "nil")")
    logDebug("Welcome message: \(response.message ?? "none")")

    return response
  }

  func sendMessage(userId: String, message: String, options: ChatOptions, customerLlmKey: String?, currentSpace: String?) async throws -> ChatResponse {
    guard currentSpace != nil || options.spaceId != nil else {
      throw Mia21Error.chatNotInitialized
    }

    let messagesArray: [[String: String]] = [
      ["role": MessageRole.user.rawValue, "content": message]
    ]

    var body: [String: Any] = [
      "user_id": userId,
      "space_id": options.spaceId ?? currentSpace ?? "default_space",
      "messages": messagesArray,
      "llm_type": (options.llmType ?? .openai).rawValue,
      "stream": false
    ]

    if let temperature = options.temperature {
      body["temperature"] = temperature
    }
    if let maxTokens = options.maxTokens {
      body["max_tokens"] = maxTokens
    }
    if let botId = options.botId {
      body["bot_id"] = botId
    }
    if let conversationId = options.conversationId {
      body["conversation_id"] = conversationId
    }
    if let voiceId = options.voiceId {
      body["voice_id"] = voiceId
    }

    let llmKey = options.customerLlmKey ?? customerLlmKey
    if let llmKey = llmKey {
      body["customer_llm_key"] = llmKey
    }

    if let spaceConfig = options.spaceConfig {
      let encoder = JSONEncoder()
      encoder.keyEncodingStrategy = .convertToSnakeCase
      if let configData = try? encoder.encode(spaceConfig),
         let configDict = try? JSONSerialization.jsonObject(with: configData) as? [String: Any] {
        body["space_config"] = configDict
      }
    }

    let endpoint = APIEndpoint(path: "/chat", method: .post, body: body)
    return try await apiClient.performRequest(endpoint)
  }

  func close(userId: String, spaceId: String?) async throws {
    let body: [String: Any] = [
      "user_id": userId,
      "space_id": spaceId ?? currentSpace ?? "default_space"
    ]

    let endpoint = APIEndpoint(path: "/close_chat", method: .post, body: body)
    let _: [String: String] = try await apiClient.performRequest(endpoint)

    if spaceId == nil || spaceId == currentSpace {
      currentSpace = nil
    }
  }
  
  // MARK: - OpenAI-Compatible Completions
  
  func complete(userId: String, messages: [ChatMessage], options: CompletionOptions) async throws -> CompletionResponse {
    logInfo("Sending completion request with \(messages.count) messages")
    
    // Build OpenAI-compatible messages array
    let messagesArray = messages.map { msg -> [String: String] in
      return ["role": msg.role.rawValue, "content": msg.content]
    }
    
    var body: [String: Any] = [
      "model": options.model,
      "messages": messagesArray,
      "stream": false
    ]
    
    if let temperature = options.temperature {
      body["temperature"] = temperature
    }
    if let maxTokens = options.maxTokens {
      body["max_tokens"] = maxTokens
    }
    
    // Build headers for OpenAI-compatible endpoint
    var headers: [String: String] = [
      "X-User-Id": userId
    ]
    if let spaceId = options.spaceId {
      headers["X-Space-Id"] = spaceId
    }
    if let botId = options.botId {
      headers["X-Bot-Id"] = botId
    }
    
    let endpoint = APIEndpoint(path: "/v1/chat/completions", method: .post, body: body, headers: headers)
    return try await apiClient.performRequest(endpoint)
  }
}
