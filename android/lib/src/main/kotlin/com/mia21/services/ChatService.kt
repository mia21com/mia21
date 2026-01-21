/**
 * ChatService.kt
 * Mia21
 *
 * Created on November 25, 2025.
 * Copyright © 2025 Mia21. All rights reserved.
 *
 * Description:
 * Service layer for chat operations.
 * Handles chat initialization, sending messages, and session management.
 */

package com.mia21.services

import com.mia21.models.*
import com.mia21.network.APIClient
import com.mia21.network.APIEndpoint
import com.mia21.network.HTTPMethod
import com.mia21.utils.Logger

/**
 * Interface for chat service operations
 */
interface ChatServiceProtocol {
    val currentSpace: String?
    suspend fun initialize(userId: String, options: InitializeOptions, customerLlmKey: String?): InitializeResponse
    suspend fun sendMessage(userId: String, message: String, options: ChatOptions, customerLlmKey: String?, currentSpace: String?): ChatResponse
    suspend fun complete(userId: String, messages: List<ChatMessage>, options: CompletionOptions): CompletionResponse
    suspend fun close(userId: String, spaceId: String?)
}

/**
 * Implementation of chat service
 */
class ChatService(private val apiClient: APIClient) : ChatServiceProtocol {
    
    override var currentSpace: String? = null
        private set
    
    override suspend fun initialize(
        userId: String,
        options: InitializeOptions,
        customerLlmKey: String?
    ): InitializeResponse {
        Logger.debug("Initializing chat with space: ${options.spaceId ?: "default_space"}")
        
        val body = mutableMapOf<String, Any?>(
            "user_id" to userId,
            "space_id" to (options.spaceId ?: "default_space"),
            "llm_type" to (options.llmType ?: LLMType.OPENAI).value,
            "generate_first_message" to options.generateFirstMessage,
            "incognito_mode" to options.incognitoMode
        )
        
        options.userName?.let { body["user_name"] = it }
        options.language?.let { body["language"] = it }
        options.timezone?.let { body["timezone"] = it }
        options.botId?.let { body["bot_id"] = it }
        (options.customerLlmKey ?: customerLlmKey)?.let { body["customer_llm_key"] = it }
        
        val endpoint = APIEndpoint(
            path = "/initialize_chat",
            method = HTTPMethod.POST,
            body = body
        )
        
        val jsonResponse = apiClient.performRequest(endpoint, String::class.java)
        val response = apiClient.json.decodeFromString<InitializeResponse>(jsonResponse)
        currentSpace = options.spaceId ?: "default_space"
        
        Logger.debug("Chat initialized. Current space: $currentSpace")
        return response
    }
    
    override suspend fun sendMessage(
        userId: String,
        message: String,
        options: ChatOptions,
        customerLlmKey: String?,
        currentSpace: String?
    ): ChatResponse {
        if (currentSpace == null && options.spaceId == null) {
            throw Mia21Exception.ChatNotInitializedException()
        }
        
        val messagesList = listOf(mapOf("role" to "user", "content" to message))

        val body = mutableMapOf<String, Any?>(
            "user_id" to userId,
            "space_id" to (options.spaceId ?: currentSpace ?: "default_space"),
            "messages" to messagesList,
            "llm_type" to (options.llmType ?: LLMType.OPENAI).value,
            "stream" to false
        )
        
        options.temperature?.let { body["temperature"] = it }
        options.maxTokens?.let { body["max_tokens"] = it }
        options.botId?.let { body["bot_id"] = it }
        options.conversationId?.let { body["conversation_id"] = it }
        options.voiceId?.let { body["voice_id"] = it }
        (options.customerLlmKey ?: customerLlmKey)?.let { body["customer_llm_key"] = it }
        
        val endpoint = APIEndpoint(
            path = "/chat",
            method = HTTPMethod.POST,
            body = body
        )
        
        val jsonResponse = apiClient.performRequest(endpoint, String::class.java)
        return apiClient.json.decodeFromString<ChatResponse>(jsonResponse)
    }
    
    override suspend fun close(userId: String, spaceId: String?) {
        val body = mapOf(
            "user_id" to userId,
            "space_id" to (spaceId ?: currentSpace ?: "default_space")
        )
        
        val endpoint = APIEndpoint(
            path = "/close_chat",
            method = HTTPMethod.POST,
            body = body
        )
        
        apiClient.performRequest(endpoint, String::class.java)
        currentSpace = null
        Logger.debug("Chat session closed")
    }
    
    /**
     * Send a completion request using the OpenAI-compatible endpoint.
     * No bot/space pre-configuration required - include system message in the messages list.
     */
    override suspend fun complete(
        userId: String,
        messages: List<ChatMessage>,
        options: CompletionOptions
    ): CompletionResponse {
        Logger.debug("Sending completion request with ${messages.size} messages")
        
        // Build OpenAI-compatible messages array
        val messagesList = messages.map { msg ->
            mapOf("role" to msg.role.name.lowercase(), "content" to msg.content)
        }
        
        val body = mutableMapOf<String, Any?>(
            "model" to options.model,
            "messages" to messagesList,
            "stream" to false
        )
        
        options.temperature?.let { body["temperature"] = it }
        options.maxTokens?.let { body["max_tokens"] = it }
        
        // Build headers for OpenAI-compatible endpoint
        val headers = mutableMapOf("X-User-Id" to userId)
        options.spaceId?.let { headers["X-Space-Id"] = it }
        options.botId?.let { headers["X-Bot-Id"] = it }
        
        val endpoint = APIEndpoint(
            path = "/v1/chat/completions",
            method = HTTPMethod.POST,
            body = body,
            headers = headers
        )
        
        val jsonResponse = apiClient.performRequest(endpoint, String::class.java)
        return apiClient.json.decodeFromString<CompletionResponse>(jsonResponse)
    }
}

