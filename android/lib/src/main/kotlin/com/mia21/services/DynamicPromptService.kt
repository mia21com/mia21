/**
 * DynamicPromptService.kt
 * Mia21
 *
 * Created on January 21, 2026.
 * Copyright © 2026 Mia21. All rights reserved.
 *
 * Description:
 * Service layer for dynamic prompting via OpenAI-compatible endpoint.
 * Allows runtime AI configuration without pre-configuration.
 */

package com.mia21.services

import com.mia21.models.*
import com.mia21.network.APIClient
import com.mia21.network.APIEndpoint
import com.mia21.network.HTTPMethod
import com.mia21.utils.Logger
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.channels.awaitClose
import kotlinx.serialization.json.Json

/**
 * Service for dynamic prompting operations
 */
class DynamicPromptService(
    private val apiClient: APIClient,
    private val defaultUserId: String
) {
    
    private val json = Json { ignoreUnknownKeys = true }
    
    /**
     * Send a completion request using the OpenAI-compatible endpoint
     * @param messages Array of messages including system prompt
     * @param options Configuration options for the request
     * @return The completion response
     */
    suspend fun complete(
        messages: List<ChatMessage>,
        options: DynamicPromptOptions
    ): DynamicPromptResponse {
        Logger.info("Dynamic prompt completion with model: ${options.model}")
        
        val messagesArray = messages.map { msg ->
            mapOf("role" to msg.role.name.lowercase(), "content" to msg.content)
        }
        
        val body = mutableMapOf<String, Any?>(
            "model" to options.model,
            "messages" to messagesArray,
            "stream" to false
        )
        
        options.temperature?.let { body["temperature"] = it }
        options.maxTokens?.let { body["max_tokens"] = it }
        
        // Build custom headers for user/space context
        val headers = mutableMapOf<String, String>()
        options.spaceId?.let { headers["X-Space-Id"] = it }
        headers["X-User-Id"] = options.userId ?: defaultUserId
        
        val endpoint = APIEndpoint(
            path = "/v1/chat/completions",
            method = HTTPMethod.POST,
            body = body,
            headers = headers
        )
        
        val jsonResponse = apiClient.performRequest(endpoint, String::class.java)
        val response = json.decodeFromString<DynamicPromptResponse>(jsonResponse)
        
        Logger.info("Dynamic prompt completed. Model: ${response.model}")
        response.usage?.let { usage ->
            Logger.debug("  Tokens - Prompt: ${usage.promptTokens}, Completion: ${usage.completionTokens}, Total: ${usage.totalTokens}")
        }
        
        return response
    }
    
    /**
     * Stream a completion request using the OpenAI-compatible endpoint
     * @param messages Array of messages including system prompt
     * @param options Configuration options for the request
     * @return Flow of text chunks
     */
    fun streamComplete(
        messages: List<ChatMessage>,
        options: DynamicPromptOptions
    ): Flow<String> = callbackFlow {
        Logger.info("Streaming dynamic prompt with model: ${options.model}")
        
        val messagesArray = messages.map { msg ->
            mapOf("role" to msg.role.name.lowercase(), "content" to msg.content)
        }
        
        val body = mutableMapOf<String, Any?>(
            "model" to options.model,
            "messages" to messagesArray,
            "stream" to true
        )
        
        options.temperature?.let { body["temperature"] = it }
        options.maxTokens?.let { body["max_tokens"] = it }
        
        // Build custom headers for user/space context
        val headers = mutableMapOf<String, String>()
        options.spaceId?.let { headers["X-Space-Id"] = it }
        headers["X-User-Id"] = options.userId ?: defaultUserId
        
        val endpoint = APIEndpoint(
            path = "/v1/chat/completions",
            method = HTTPMethod.POST,
            body = body,
            headers = headers
        )
        
        val job = launch {
            try {
                apiClient.performStreamRequest(endpoint).collect { data ->
                    processStreamData(data)?.let { content ->
                        trySend(content)
                    }
                }
                Logger.info("Dynamic prompt stream completed")
            } catch (e: Exception) {
                Logger.error("Stream failed: ${e.message}")
                close(e)
            }
        }
        
        awaitClose {
            job.cancel()
        }
    }
    
    /**
     * Process stream data and extract text content
     */
    private fun processStreamData(data: String): String? {
        val trimmed = data.trim()
        
        if (trimmed.isEmpty() || trimmed == "[DONE]") {
            return null
        }
        
        return try {
            val chunk = json.decodeFromString<DynamicPromptStreamChunk>(trimmed)
            chunk.choices.firstOrNull()?.delta?.content?.takeIf { it.isNotEmpty() }
        } catch (e: Exception) {
            Logger.debug("Failed to parse stream chunk: ${e.message}")
            null
        }
    }
}

