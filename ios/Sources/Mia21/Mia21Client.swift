//
//  Mia21Client.swift
//  Mia21
//
//  Created on November 4, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Main client for interacting with the Mia21 API.
//  Provides methods for chat operations, space management,
//  conversation history, text/audio streaming, and speech-to-text transcription.
//
//  Architecture:
//  This class acts as a facade that coordinates multiple service layers:
//  - APIClient: Networking layer
//  - ChatService: Chat initialization and messaging
//  - SpaceService: Workspace management
//  - ConversationService: Conversation history management
//  - StreamingService: Text and voice streaming
//  - TranscriptionService: Speech-to-text
//

import Foundation

// MARK: - Mia21 Client

public final class Mia21Client {

  // MARK: - Properties

  private let userId: String
  private let customerLlmKey: String?

  // Service layers
  private let apiClient: APIClient
  private let chatService: ChatService
  private let spaceService: SpaceService
  private let streamingService: StreamingService
  private let transcriptionService: TranscriptionService
  private let conversationService: ConversationService

  // MARK: - Public Properties

  /// Current active space ID
  public var currentSpace: String? {
    chatService.currentSpace
  }

  // MARK: - Logging Configuration

  /// Set the minimum log level for SDK logging
  /// - Parameter level: Minimum log level (default: .info)
  /// - Note: Set to .none to disable all logging, .debug for verbose logging
  public static func setLogLevel(_ level: LogLevel) {
    LoggerManager.shared.setLogLevel(level)
  }

  // MARK: - Initialization

  /// Initialize the Mia21 SDK client
  /// - Parameters:
  ///   - apiKey: Optional API key for authentication
  ///   - userId: Unique user identifier (default: auto-generated UUID)
  ///   - environment: API environment (default: .production)
  ///   - timeout: Request timeout in seconds (default: 90)
  ///   - customerLlmKey: Optional customer LLM key for BYOK
  public init(
    apiKey: String? = nil,
    userId: String? = nil,
    environment: Mia21Environment = .production,
    timeout: TimeInterval = 90,
    customerLlmKey: String? = nil
  ) {
    self.userId = userId ?? UUID().uuidString
    self.customerLlmKey = customerLlmKey

    let baseURL = environment.baseURL

    // Initialize networking layer
    self.apiClient = APIClient(
      baseURL: baseURL,
      apiKey: apiKey,
      timeout: timeout
    )

    // Initialize service layers
    self.chatService = ChatService(apiClient: apiClient)
    self.spaceService = SpaceService(apiClient: apiClient)
    self.streamingService = StreamingService(apiClient: apiClient)
    self.conversationService = ConversationService(apiClient: apiClient)
    self.transcriptionService = TranscriptionService(
      baseURL: baseURL,
      apiKey: apiKey,
      timeout: timeout
    )
  }

  /// Internal initializer for dependency injection (testing only)
  init(
    userId: String = UUID().uuidString,
    customerLlmKey: String? = nil,
    apiClient: APIClient,
    chatService: ChatService,
    spaceService: SpaceService,
    streamingService: StreamingService,
    conversationService: ConversationService,
    transcriptionService: TranscriptionService
  ) {
    self.userId = userId
    self.customerLlmKey = customerLlmKey
    self.apiClient = apiClient
    self.chatService = chatService
    self.spaceService = spaceService
    self.streamingService = streamingService
    self.conversationService = conversationService
    self.transcriptionService = transcriptionService
  }

  // MARK: - Space Management

  /// List all available spaces
  /// - Returns: Array of Space objects
  /// - Throws: Mia21Error if the request fails
  public func listSpaces() async throws -> [Space] {
    return try await spaceService.listSpaces()
  }

  /// List all bots for the current customer
  /// - Returns: Array of Bot objects
  /// - Throws: Mia21Error if the request fails
  public func listBots() async throws -> [Bot] {
    return try await spaceService.listBots()
  }

  // MARK: - Chat Operations

  /// Initialize a chat session
  /// - Parameter options: Configuration options for chat initialization
  /// - Returns: InitializeResponse containing app ID and welcome message
  /// - Throws: Mia21Error if initialization fails
  public func initialize(options: InitializeOptions = InitializeOptions()) async throws -> InitializeResponse {
    return try await chatService.initialize(
      userId: userId,
      options: options,
      customerLlmKey: customerLlmKey
    )
  }

  /// Send a chat message (non-streaming)
  /// - Parameters:
  ///   - message: User message to send
  ///   - options: Optional chat configuration
  /// - Returns: ChatResponse containing the AI's response
  /// - Throws: Mia21Error if the request fails or chat not initialized
  public func chat(
    message: String,
    options: ChatOptions = ChatOptions()
  ) async throws -> ChatResponse {
    return try await chatService.sendMessage(
      userId: userId,
      message: message,
      options: options,
      customerLlmKey: customerLlmKey,
      currentSpace: chatService.currentSpace
    )
  }

  /// Close a chat session
  /// - Parameter spaceId: Optional space ID to close (defaults to current space)
  /// - Throws: Mia21Error if the request fails
  public func close(spaceId: String? = nil) async throws {
    try await chatService.close(userId: userId, spaceId: spaceId)
  }

  // MARK: - Streaming Operations

  /// Stream chat messages (text only) with full conversation history
  /// - Parameters:
  ///   - messages: Array of conversation history messages (including the new user message)
  ///   - options: Optional chat configuration
  ///   - onChunk: Callback invoked for each text chunk received
  /// - Throws: Mia21Error if the request fails or chat not initialized
  public func streamChat(
    messages: [ChatMessage],
    options: ChatOptions = ChatOptions(),
    onChunk: @escaping (String) -> Void
  ) async throws {
    try await streamingService.streamChat(
      userId: userId,
      messages: messages,
      options: options,
      customerLlmKey: customerLlmKey,
      currentSpace: chatService.currentSpace,
      onChunk: onChunk
    )
  }

  /// Stream chat with voice synthesis and full conversation history
  /// - Parameters:
  ///   - messages: Array of conversation history messages (including the new user message)
  ///   - options: Optional chat configuration
  ///   - voiceConfig: Voice synthesis configuration
  ///   - onEvent: Callback invoked for each stream event (text, audio, done, error)
  /// - Throws: Mia21Error if the request fails or chat not initialized
  public func streamChatWithVoice(
    messages: [ChatMessage],
    options: ChatOptions = ChatOptions(),
    voiceConfig: VoiceConfig? = nil,
    onEvent: @escaping (StreamEvent) -> Void
  ) async throws {
    try await streamingService.streamChatWithVoice(
      userId: userId,
      messages: messages,
      options: options,
      voiceConfig: voiceConfig,
      customerLlmKey: customerLlmKey,
      currentSpace: chatService.currentSpace,
      onEvent: onEvent
    )
  }

  // MARK: - Conversation History

  /// List conversations for the current user
  /// - Parameters:
  ///   - spaceId: Optional space ID to filter conversations
  ///   - limit: Maximum number of conversations to return (1-100, default: 50)
  /// - Returns: Array of ConversationSummary objects
  /// - Throws: Mia21Error if the request fails
  public func listConversations(spaceId: String? = nil, limit: Int = 50) async throws -> [ConversationSummary] {
    return try await conversationService.listConversations(
      userId: userId,
      spaceId: spaceId,
      limit: limit
    )
  }

  /// Get a specific conversation with all messages
  /// - Parameter conversationId: The conversation ID to retrieve
  /// - Returns: ConversationDetail with messages
  /// - Throws: Mia21Error if the request fails or conversation not found
  public func getConversation(conversationId: String) async throws -> ConversationDetail {
    return try await conversationService.getConversation(conversationId: conversationId)
  }

  /// Delete a conversation and all its messages
  /// - Parameter conversationId: The conversation ID to delete
  /// - Returns: DeleteConversationResponse with success status
  /// - Throws: Mia21Error if the request fails or conversation not found
  public func deleteConversation(conversationId: String) async throws -> DeleteConversationResponse {
    return try await conversationService.deleteConversation(conversationId: conversationId)
  }
  
  /// Rename a conversation (update its title)
  /// - Parameters:
  ///   - conversationId: The conversation ID to rename
  ///   - title: New title for the conversation (empty string to clear)
  /// - Returns: RenameConversationResponse with success status and new title
  /// - Throws: Mia21Error if the request fails or conversation not found
  public func renameConversation(conversationId: String, title: String) async throws -> RenameConversationResponse {
    return try await conversationService.renameConversation(conversationId: conversationId, title: title)
  }
  
  /// Delete ALL data for a specific end-user (GDPR compliance)
  /// - Parameter userId: The end-user ID whose data should be deleted
  /// - Returns: DeleteUserDataResponse with counts of deleted items
  /// - Throws: Mia21Error if the request fails
  /// - Warning: ⚠️ This permanently deletes all conversations, messages, memories, and RAG/vector data. This action cannot be undone.
  public func deleteUserData(userId: String) async throws -> DeleteUserDataResponse {
    return try await conversationService.deleteUserData(userId: userId)
  }

  // MARK: - Speech-to-Text

  /// Transcribe audio data to text
  /// - Parameters:
  ///   - audioData: Audio data to transcribe (supports various formats)
  ///   - language: Optional language code (e.g., "en", "es")
  /// - Returns: TranscriptionResponse containing transcribed text
  /// - Throws: Mia21Error if transcription fails
  public func transcribeAudio(audioData: Data, language: String? = nil) async throws -> TranscriptionResponse {
    return try await transcriptionService.transcribeAudio(audioData: audioData, language: language)
  }
}
