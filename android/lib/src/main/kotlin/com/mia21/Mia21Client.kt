/**
 * Mia21Client.kt
 * Mia21
 *
 * Created on November 25, 2025.
 * Copyright © 2025 Mia21. All rights reserved.
 *
 * Description:
 * Main client for interacting with the Mia21 API.
 * Provides methods for chat operations, space management,
 * conversation history, text/audio streaming, and speech-to-text transcription.
 *
 * Architecture:
 * This class acts as a facade that coordinates multiple service layers:
 * - APIClient: Networking layer
 * - ChatService: Chat initialization and messaging
 * - SpaceService: Workspace management
 * - ConversationService: Conversation history management
 * - StreamingService: Text and voice streaming with SSE event parsing
 * - TranscriptionService: Speech-to-text
 */

package com.mia21

import com.mia21.models.*
import com.mia21.network.APIClient
import com.mia21.services.*
import kotlinx.coroutines.flow.Flow
import java.util.UUID

/**
 * Main client for the Mia21 SDK
 *
 * Example usage:
 * ```kotlin
 * val client = Mia21Client(
 *     apiKey = "your-api-key",
 *     userId = "user-123"
 * )
 *
 * // Initialize chat session
 * client.initialize()
 *
 * // Send a message
 * val response = client.chat("Hello!")
 * println(response.message)
 * ```
 */
class Mia21Client(
    apiKey: String? = null,
    private val userId: String = UUID.randomUUID().toString(),
    environment: Mia21Environment = Mia21Environment.PRODUCTION,
    timeout: Long = 90,
    private val customerLlmKey: String? = null
) {
    
    // Service layers
    private val apiClient: APIClient
    private val chatService: ChatService
    private val spaceService: SpaceService
    private val conversationService: ConversationService
    private val streamingService: StreamingService
    private val transcriptionService: TranscriptionService
    
    /**
     * Current active space ID
     */
    val currentSpace: String?
        get() = chatService.currentSpace
    
    init {
        val baseURL = environment.baseURL
        
        // Initialize networking layer
        apiClient = APIClient(
            baseURL = baseURL,
            apiKey = apiKey,
            timeout = timeout
        )
        
        // Initialize service layers
        chatService = ChatService(apiClient)
        spaceService = SpaceService(apiClient)
        conversationService = ConversationService(apiClient)
        streamingService = StreamingService(apiClient)
        transcriptionService = TranscriptionService(
            baseURL = baseURL,
            apiKey = apiKey,
            timeout = timeout
        )
    }


    /**
     * List all available spaces
     * @return List of Space objects
     * @throws Mia21Exception if the request fails
     */
    suspend fun listSpaces(): List<Space> {
        return spaceService.listSpaces()
    }
    
    /**
     * List all bots for the current customer
     * @return List of Bot objects
     * @throws Mia21Exception if the request fails
     */
    suspend fun listBots(): List<Bot> {
        return spaceService.listBots()
    }
    

    /**
     * Initialize a chat session
     * @param options Configuration options for chat initialization
     * @return InitializeResponse containing app ID and welcome message
     * @throws Mia21Exception if initialization fails
     */
    suspend fun initialize(options: InitializeOptions = InitializeOptions()): InitializeResponse {
        return chatService.initialize(
            userId = userId,
            options = options,
            customerLlmKey = customerLlmKey
        )
    }
    
    /**
     * Send a chat message (non-streaming)
     * @param message User message to send
     * @param options Optional chat configuration
     * @return ChatResponse containing the AI's response
     * @throws Mia21Exception if the request fails or chat not initialized
     */
    suspend fun chat(
        message: String,
        options: ChatOptions = ChatOptions()
    ): ChatResponse {
        return chatService.sendMessage(
            userId = userId,
            message = message,
            options = options,
            customerLlmKey = customerLlmKey,
            currentSpace = chatService.currentSpace
        )
    }
    
    /**
     * Close a chat session
     * @param spaceId Optional space ID to close (defaults to current space)
     * @throws Mia21Exception if the request fails
     */
    suspend fun close(spaceId: String? = null) {
        chatService.close(userId = userId, spaceId = spaceId)
    }
    
    // OpenAI-Compatible Completions
    
    /**
     * Send a completion request using the OpenAI-compatible endpoint.
     * No bot/space pre-configuration required - include system message in the messages list.
     * @param messages List of messages including system prompt (role = MessageRole.SYSTEM)
     * @param options Completion configuration (model, temperature, etc.)
     * @return CompletionResponse containing the AI's response in OpenAI format
     * @throws Mia21Exception if the request fails
     */
    suspend fun complete(
        messages: List<ChatMessage>,
        options: CompletionOptions = CompletionOptions()
    ): CompletionResponse {
        return chatService.complete(
            userId = userId,
            messages = messages,
            options = options
        )
    }
    
    /**
     * Stream a completion using the OpenAI-compatible endpoint.
     * No bot/space pre-configuration required - include system message in the messages list.
     * @param messages List of messages including system prompt (role = MessageRole.SYSTEM)
     * @param options Completion configuration (model, temperature, etc.)
     * @return Flow of text chunks
     * @throws Mia21Exception if the request fails
     */
    fun streamComplete(
        messages: List<ChatMessage>,
        options: CompletionOptions = CompletionOptions()
    ): Flow<String> {
        return streamingService.streamComplete(
            userId = userId,
            messages = messages,
            options = options
        )
    }


    /**
     * Stream chat messages (text only) with full conversation history
     * @param messages List of conversation history messages (including the new user message)
     * @param options Optional chat configuration
     * @return Flow of text chunks
     * @throws Mia21Exception if the request fails or chat not initialized
     */
    fun streamChat(
        messages: List<ChatMessage>,
        options: ChatOptions = ChatOptions()
    ): Flow<String> {
        return streamingService.streamChat(
            userId = userId,
            messages = messages,
            options = options,
            customerLlmKey = customerLlmKey,
            currentSpace = chatService.currentSpace
        )
    }
    
    /**
     * Stream chat messages with voice synthesis support
     * @param messages List of conversation history messages (including the new user message)
     * @param options Optional chat configuration
     * @param voiceConfig Voice synthesis configuration (null for text-only streaming)
     * @return Flow of StreamEvent (text chunks, audio chunks, completion, errors)
     * @throws Mia21Exception if the request fails or chat not initialized
     */
    fun streamChatWithVoice(
        messages: List<ChatMessage>,
        options: ChatOptions = ChatOptions(),
        voiceConfig: VoiceConfig? = null
    ): Flow<StreamEvent> {
        return streamingService.streamChatWithVoice(
            userId = userId,
            messages = messages,
            options = options,
            voiceConfig = voiceConfig,
            customerLlmKey = customerLlmKey,
            currentSpace = chatService.currentSpace
        )
    }
    

    /**
     * List conversations for the current user
     * @param spaceId Optional space ID to filter conversations
     * @param limit Maximum number of conversations to return (1-100, default: 50)
     * @return List of ConversationSummary objects
     * @throws Mia21Exception if the request fails
     */
    suspend fun listConversations(spaceId: String? = null, limit: Int = 50): List<ConversationSummary> {
        return conversationService.listConversations(
            userId = userId,
            spaceId = spaceId,
            limit = limit
        )
    }
    
    /**
     * Get a specific conversation with all messages
     * @param conversationId The conversation ID to retrieve
     * @return ConversationDetail with messages
     * @throws Mia21Exception if the request fails or conversation not found
     */
    suspend fun getConversation(conversationId: String): ConversationDetail {
        return conversationService.getConversation(conversationId = conversationId)
    }
    
    /**
     * Delete a conversation and all its messages
     * @param conversationId The conversation ID to delete
     * @return DeleteConversationResponse with success status
     * @throws Mia21Exception if the request fails or conversation not found
     */
    suspend fun deleteConversation(conversationId: String): DeleteConversationResponse {
        return conversationService.deleteConversation(conversationId = conversationId)
    }
    
    /**
     * Rename a conversation (update its title)
     * @param conversationId The conversation ID to rename
     * @param title New title for the conversation (empty string to clear)
     * @return RenameConversationResponse with success status and new title
     * @throws Mia21Exception if the request fails or conversation not found
     */
    suspend fun renameConversation(conversationId: String, title: String): RenameConversationResponse {
        return conversationService.renameConversation(conversationId = conversationId, title = title)
    }
    
    /**
     * Delete ALL data for a specific end-user (GDPR compliance)
     * ⚠️ This permanently deletes all conversations, messages, memories, and RAG/vector data.
     * This action cannot be undone.
     * @param userId The end-user ID whose data should be deleted
     * @return DeleteUserDataResponse with counts of deleted items
     * @throws Mia21Exception if the request fails
     */
    suspend fun deleteUserData(userId: String): DeleteUserDataResponse {
        return conversationService.deleteUserData(userId = userId)
    }

    /**
     * Transcribe audio data to text
     * @param audioData Audio data to transcribe (supports various formats)
     * @param language Optional language code (e.g., "en", "es")
     * @return TranscriptionResponse containing transcribed text
     * @throws Mia21Exception if transcription fails
     */
    suspend fun transcribeAudio(audioData: ByteArray, language: String? = null): TranscriptionResponse {
        return transcriptionService.transcribeAudio(audioData = audioData, language = language)
    }
    
    companion object {
        /**
         * Set the minimum log level for SDK logging
         * @param level Minimum log level (default: INFO)
         * Note: Set to NONE to disable all logging, DEBUG for verbose logging
         */
        fun setLogLevel(level: LogLevel) {
            com.mia21.utils.Logger.setLogLevel(level)
        }
    }
}

/**
 * Log levels for SDK logging
 */
enum class LogLevel {
    DEBUG,
    INFO,
    ERROR,
    NONE
}
