//
//  StreamingService.swift
//  Mia21
//
//  Created on November 4, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Service layer for streaming operations.
//  Handles text and voice streaming with SSE event parsing.
//

import Foundation

// MARK: - Streaming Service Protocol

protocol StreamingServiceProtocol {
  func streamChat(
    userId: String,
    messages: [ChatMessage],
    options: ChatOptions,
    customerLlmKey: String?,
    currentSpace: String?,
    onChunk: @escaping (String) -> Void
  ) async throws

  func streamChatWithVoice(
    userId: String,
    messages: [ChatMessage],
    options: ChatOptions,
    voiceConfig: VoiceConfig?,
    customerLlmKey: String?,
    currentSpace: String?,
    onEvent: @escaping (StreamEvent) -> Void
  ) async throws
  
  func streamComplete(
    userId: String,
    messages: [ChatMessage],
    options: CompletionOptions,
    onChunk: @escaping (String) -> Void
  ) async throws
}

// MARK: - Streaming Service Implementation

final class StreamingService: StreamingServiceProtocol {

  // MARK: - Properties

  private let apiClient: APIClientProtocol

  // MARK: - Initialization

  init(apiClient: APIClientProtocol) {
    self.apiClient = apiClient
  }

  // MARK: - Public Methods

  func streamChat(
    userId: String,
    messages: [ChatMessage],
    options: ChatOptions,
    customerLlmKey: String?,
    currentSpace: String?,
    onChunk: @escaping (String) -> Void
  ) async throws {
    guard currentSpace != nil || options.spaceId != nil else {
      throw Mia21Error.chatNotInitialized
    }

    let messagesDictArray = messages.map { ["role": $0.role.rawValue, "content": $0.content] }

    var body: [String: Any] = [
      "user_id": userId,
      "space_id": options.spaceId ?? currentSpace ?? "default_space",
      "messages": messagesDictArray,
      "llm_type": (options.llmType ?? .openai).rawValue,
      "stream": true
    ]

    if let conversationId = options.conversationId {
      body["conversation_id"] = conversationId
    }

    addCommonOptions(to: &body, options: options, customerLlmKey: customerLlmKey)

    let endpoint = APIEndpoint(path: "/chat/stream", method: .post, body: body)
    let stream = try await apiClient.performStreamRequest(endpoint)

    for try await data in stream {
      if let line = String(data: data, encoding: .utf8) {
        processTextStreamLine(line, onChunk: onChunk)
      }
    }
  }

  func streamChatWithVoice(
    userId: String,
    messages: [ChatMessage],
    options: ChatOptions,
    voiceConfig: VoiceConfig?,
    customerLlmKey: String?,
    currentSpace: String?,
    onEvent: @escaping (StreamEvent) -> Void
  ) async throws {
    guard currentSpace != nil || options.spaceId != nil else {
      throw Mia21Error.chatNotInitialized
    }

    let messagesDictArray = messages.map { ["role": $0.role.rawValue, "content": $0.content] }

    var body: [String: Any] = [
      "user_id": userId,
      "space_id": options.spaceId ?? currentSpace ?? "default_space",
      "messages": messagesDictArray,
      "llm_type": (options.llmType ?? .openai).rawValue
    ]

    // Configure response mode based on voice settings
    if let voiceConfig = voiceConfig, voiceConfig.enabled {
      body["response_mode"] = "stream_voice"
      body["voice_config"] = buildVoiceConfig(voiceConfig)
    } else {
      body["response_mode"] = "stream_text"
    }

    if let conversationId = options.conversationId {
      body["conversation_id"] = conversationId
    }

    addCommonOptions(to: &body, options: options, customerLlmKey: customerLlmKey)

    let endpoint = APIEndpoint(path: "/chat/stream", method: .post, body: body)
    let stream = try await apiClient.performStreamRequest(endpoint)

    var parser = SSEParser()

    for try await data in stream {
      if let line = String(data: data, encoding: .utf8) {
        parser.parse(line: line) { event in
          onEvent(event)
        }
      }
    }

    // Send final done event
    onEvent(.done(nil))
  }
  
  // MARK: - OpenAI-Compatible Streaming Completions
  
  func streamComplete(
    userId: String,
    messages: [ChatMessage],
    options: CompletionOptions,
    onChunk: @escaping (String) -> Void
  ) async throws {
    logInfo("Starting streaming completion with \(messages.count) messages")
    
    // Build OpenAI-compatible messages array
    let messagesArray = messages.map { msg -> [String: String] in
      return ["role": msg.role.rawValue, "content": msg.content]
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
    let stream = try await apiClient.performStreamRequest(endpoint)
    
    for try await data in stream {
      if let line = String(data: data, encoding: .utf8) {
        processOpenAIStreamLine(line, onChunk: onChunk)
      }
    }
  }

  // MARK: - Private Methods
  
  /// Simplified: Accept only text/audio content, filter out all objects/structured data
  /// Returns the text content to display, or nil if it should be skipped
  static func extractTextContent(from content: String) -> String? {
    // Skip truly empty content or [DONE] marker
    // Note: We keep whitespace-only content (like " ") as it may be valid text between words
    if content.isEmpty || content == "[DONE]" {
      return nil
    }
    
    let trimmed = content.trimmingCharacters(in: .whitespaces)
    
    // Skip [DONE] marker even with surrounding whitespace
    if trimmed == "[DONE]" {
      return nil
    }
    
    // If it's JSON, only extract "content" field (actual text)
    if trimmed.hasPrefix("{") || trimmed.hasPrefix("[") {
      if let data = trimmed.data(using: .utf8),
         let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
         let textContent = json["content"] as? String, !textContent.isEmpty {
        return textContent
      }
      // All other JSON (function calls, objects, etc.) - skip
      return nil
    }
    
    // If it contains function call patterns (Python dict or JSON style) - skip
    if trimmed.contains("'type': 'function_call'") ||
       trimmed.contains("\"type\": \"function_call\"") ||
       trimmed.contains("'function_call'") ||
       trimmed.contains("\"function_call\"") {
      return nil
    }
    
    // Otherwise, it's plain text - accept it
    return content
  }

  private func addCommonOptions(to body: inout [String: Any], options: ChatOptions, customerLlmKey: String?) {
    if let temperature = options.temperature {
      body["temperature"] = temperature
    }
    if let maxTokens = options.maxTokens {
      body["max_tokens"] = maxTokens
    }
    if let botId = options.botId {
      body["bot_id"] = botId
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
  }

  private func buildVoiceConfig(_ config: VoiceConfig) -> [String: Any] {
    var voiceDict: [String: Any] = ["enabled": true]

    if let voiceId = config.voiceId {
      voiceDict["voice_id"] = voiceId
    }
    if let apiKey = config.elevenlabsApiKey {
      voiceDict["elevenlabs_api_key"] = apiKey
    }
    if let stability = config.stability {
      voiceDict["stability"] = stability
    }
    if let similarityBoost = config.similarityBoost {
      voiceDict["similarity_boost"] = similarityBoost
    }

    return voiceDict
  }

  private func processTextStreamLine(_ line: String, onChunk: @escaping (String) -> Void) {
    // Only trim to check if empty, but preserve original content with newlines
    let trimmedForCheck = line.trimmingCharacters(in: .whitespaces)

    // Skip completely empty lines (blank lines between SSE events)
    if trimmedForCheck.isEmpty {
      return
    }

    // Check if line has "data: " prefix (SSE format)
    if line.hasPrefix("data: ") {
      let content = String(line.dropFirst(6)) // Remove "data: " prefix
      
      // Empty data line means a newline in the content
      // (SSE sends "data: " with no content to represent line breaks)
      if content.isEmpty {
        onChunk("\n")
        return
      }
      
      // Use general text extraction - only show actual messages
      if let textContent = StreamingService.extractTextContent(from: content) {
        onChunk(textContent)
      }
      // If extractTextContent returns nil, it's structured data - skip it silently
    } else if trimmedForCheck != "[DONE]" {
      // If no prefix, check if it's actual text content
      if let textContent = StreamingService.extractTextContent(from: line) {
        onChunk(textContent)
      }
    }
  }
  
  private func processOpenAIStreamLine(_ line: String, onChunk: @escaping (String) -> Void) {
    let trimmed = line.trimmingCharacters(in: .whitespaces)
    
    // Skip empty lines
    if trimmed.isEmpty {
      return
    }
    
    // Check for SSE data prefix
    guard line.hasPrefix("data: ") else {
      return
    }
    
    let content = String(line.dropFirst(6))
    
    // Check for [DONE] marker
    if content == "[DONE]" {
      return
    }
    
    // Parse OpenAI streaming format
    guard let data = content.data(using: .utf8),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let choices = json["choices"] as? [[String: Any]],
          let firstChoice = choices.first,
          let delta = firstChoice["delta"] as? [String: Any],
          let textContent = delta["content"] as? String else {
      return
    }
    
    onChunk(textContent)
  }
}

// MARK: - SSE Parser

private struct SSEParser {
  private var currentEvent: String?
  private var chunkCount = 0
  private var audioChunkCount = 0

  mutating func parse(line: String, onEvent: (StreamEvent) -> Void) {
    // Only trim to check if truly empty, preserve original for content extraction
    let trimmedForCheck = line.trimmingCharacters(in: .whitespaces)

    if trimmedForCheck.isEmpty {
      return
    }

    // Parse event type - use original line to preserve spacing
    if line.hasPrefix("event: ") {
      currentEvent = String(line.dropFirst(7)).trimmingCharacters(in: .whitespaces)
      logDebug("Event type: \(currentEvent ?? "nil")")
      return
    }

    // Parse data - use original line to preserve content with spaces
    if line.hasPrefix("data: ") {
      let dataString = String(line.dropFirst(6))

      // Check for [DONE] marker
      if dataString == "[DONE]" {
        logInfo("Stream completed. Text: \(chunkCount), Audio: \(audioChunkCount)")
        return
      }
      
      // Empty data line means a newline in the content
      if dataString.isEmpty {
        chunkCount += 1
        onEvent(.text("\n"))
        return
      }

      // Simplified: Only accept text/audio content, filter out all objects
      
      // Try to parse as JSON
      if let data = dataString.data(using: .utf8),
         let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
        
        // Only handle "content" (text) or "audio" fields - skip everything else
        if let textContent = json["content"] as? String, !textContent.isEmpty {
          chunkCount += 1
          logDebug("Text Chunk #\(chunkCount): \(textContent)")
          onEvent(.text(textContent))
        }
        
        if let audioBase64 = json["audio"] as? String,
           let audioData = Data(base64Encoded: audioBase64) {
          audioChunkCount += 1
          logDebug("Audio Chunk #\(audioChunkCount): \(audioData.count) bytes")
          onEvent(.audio(audioData))
        }
        
        // All other JSON fields (function_call, tool_call, error, etc.) - skip silently
        return
      }
      
      // Not JSON - use text extraction to filter structured data
      if let textContent = StreamingService.extractTextContent(from: dataString) {
        switch currentEvent {
        case "text_complete":
          onEvent(.textComplete)
        case "error":
          onEvent(.error(Mia21Error.streamingError(dataString)))
        default:
          chunkCount += 1
          onEvent(.text(textContent))
        }
      }
      // If extractTextContent returns nil, it's structured data - skip silently

      currentEvent = nil
    }
  }
}


