//
//  DynamicPromptService.swift
//  Mia21
//
//  Created on January 21, 2026.
//  Copyright © 2026 Mia21. All rights reserved.
//
//  Description:
//  Service layer for dynamic prompting via OpenAI-compatible endpoint.
//  Allows runtime AI configuration without pre-configuration.
//

import Foundation

// MARK: - Dynamic Prompt Service Protocol

protocol DynamicPromptServiceProtocol {
  func complete(
    messages: [ChatMessage],
    options: DynamicPromptOptions
  ) async throws -> DynamicPromptResponse
  
  func streamComplete(
    messages: [ChatMessage],
    options: DynamicPromptOptions,
    onChunk: @escaping (String) -> Void
  ) async throws
}

// MARK: - Dynamic Prompt Service Implementation

final class DynamicPromptService: DynamicPromptServiceProtocol {
  
  // MARK: - Properties
  
  private let apiClient: APIClientProtocol
  private let defaultUserId: String
  
  // MARK: - Initialization
  
  init(apiClient: APIClientProtocol, defaultUserId: String) {
    self.apiClient = apiClient
    self.defaultUserId = defaultUserId
  }
  
  // MARK: - Public Methods
  
  /// Send a completion request using the OpenAI-compatible endpoint
  /// - Parameters:
  ///   - messages: Array of messages including system prompt
  ///   - options: Configuration options for the request
  /// - Returns: The completion response
  func complete(
    messages: [ChatMessage],
    options: DynamicPromptOptions
  ) async throws -> DynamicPromptResponse {
    logInfo("Dynamic prompt completion with model: \(options.model)")
    
    // Build messages array for API
    let messagesArray = messages.map { msg -> [String: String] in
      ["role": msg.role.rawValue, "content": msg.content]
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
    
    // Build custom headers for user/space context
    var headers: [String: String] = [:]
    if let spaceId = options.spaceId {
      headers["X-Space-Id"] = spaceId
    }
    let userId = options.userId ?? defaultUserId
    headers["X-User-Id"] = userId
    
    let endpoint = APIEndpoint(
      path: "/v1/chat/completions",
      method: .post,
      body: body,
      headers: headers
    )
    
    let response: DynamicPromptResponse = try await apiClient.performRequest(endpoint)
    
    logInfo("Dynamic prompt completed. Model: \(response.model)")
    if let usage = response.usage {
      logDebug("  Tokens - Prompt: \(usage.promptTokens), Completion: \(usage.completionTokens), Total: \(usage.totalTokens)")
    }
    
    return response
  }
  
  /// Stream a completion request using the OpenAI-compatible endpoint
  /// - Parameters:
  ///   - messages: Array of messages including system prompt
  ///   - options: Configuration options for the request
  ///   - onChunk: Callback invoked for each text chunk
  func streamComplete(
    messages: [ChatMessage],
    options: DynamicPromptOptions,
    onChunk: @escaping (String) -> Void
  ) async throws {
    logInfo("Streaming dynamic prompt with model: \(options.model)")
    
    // Build messages array for API
    let messagesArray = messages.map { msg -> [String: String] in
      ["role": msg.role.rawValue, "content": msg.content]
    }
    
    var body: [String: Any] = [
      "model": options.model,
      "messages": messagesArray,
      "stream": true
    ]
    
    if let temperature = options.temperature {
      body["temperature"] = temperature
    }
    if let maxTokens = options.maxTokens {
      body["max_tokens"] = maxTokens
    }
    
    // Build custom headers for user/space context
    var headers: [String: String] = [:]
    if let spaceId = options.spaceId {
      headers["X-Space-Id"] = spaceId
    }
    let userId = options.userId ?? defaultUserId
    headers["X-User-Id"] = userId
    
    let endpoint = APIEndpoint(
      path: "/v1/chat/completions",
      method: .post,
      body: body,
      headers: headers
    )
    
    let stream = try await apiClient.performStreamRequest(endpoint)
    
    for try await data in stream {
      if let line = String(data: data, encoding: .utf8) {
        processStreamLine(line, onChunk: onChunk)
      }
    }
    
    logInfo("Dynamic prompt stream completed")
  }
  
  // MARK: - Private Methods
  
  private func processStreamLine(_ line: String, onChunk: @escaping (String) -> Void) {
    let trimmed = line.trimmingCharacters(in: .whitespaces)
    
    // Skip empty lines
    if trimmed.isEmpty {
      return
    }
    
    // Check for SSE data prefix
    if line.hasPrefix("data: ") {
      let dataContent = String(line.dropFirst(6))
      
      // Check for stream end marker
      if dataContent == "[DONE]" {
        return
      }
      
      // Parse the JSON chunk
      if let data = dataContent.data(using: .utf8),
         let chunk = try? JSONDecoder().decode(DynamicPromptStreamChunk.self, from: data) {
        // Extract content from the delta
        if let content = chunk.choices.first?.delta.content, !content.isEmpty {
          onChunk(content)
        }
      }
    }
  }
}

