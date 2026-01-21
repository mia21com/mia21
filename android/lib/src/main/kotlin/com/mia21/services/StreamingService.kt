/**
 * StreamingService.kt
 * Mia21
 *
 * Created on November 25, 2025.
 * Copyright © 2025 Mia21. All rights reserved.
 *
 * Description:
 * Service layer for streaming chat operations.
 * Handles text and voice streaming with SSE event parsing.
 */

package com.mia21.services

import com.mia21.models.*
import com.mia21.network.APIClient
import com.mia21.network.APIEndpoint
import com.mia21.network.HTTPMethod
import com.mia21.utils.Logger
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.flow.filterIsInstance
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.launch
import org.json.JSONObject
import android.util.Base64
import kotlinx.coroutines.channels.awaitClose

/**
 * Service for streaming operations
 */
class StreamingService(private val apiClient: APIClient) {
    
    /**
     * Stream chat messages (text only)
     * This is a convenience method that uses streamChatWithVoice internally
     * with voiceConfig = null, extracting only text events.
     */
    fun streamChat(
        userId: String,
        messages: List<ChatMessage>,
        options: ChatOptions,
        customerLlmKey: String?,
        currentSpace: String?
    ): Flow<String> {
        return streamChatWithVoice(
            userId = userId,
            messages = messages,
            options = options,
            voiceConfig = null,
            customerLlmKey = customerLlmKey,
            currentSpace = currentSpace
        )
            .filterIsInstance<StreamEvent.Text>()
            .map { it.content }
    }
    
    /**
     * Stream chat messages with voice synthesis support
     * @param userId User identifier
     * @param messages List of conversation history messages
     * @param options Chat configuration options
     * @param voiceConfig Voice synthesis configuration (null for text-only)
     * @param customerLlmKey Optional customer LLM key
     * @param currentSpace Current active space ID
     * @return Flow of StreamEvent (text chunks, audio chunks, completion, errors)
     */
    fun streamChatWithVoice(
        userId: String,
        messages: List<ChatMessage>,
        options: ChatOptions,
        voiceConfig: VoiceConfig?,
        customerLlmKey: String?,
        currentSpace: String?
    ): Flow<StreamEvent> = callbackFlow {
        if (currentSpace == null && options.spaceId == null) {
            close(Mia21Exception.ChatNotInitializedException())
            return@callbackFlow
        }
        
        val messagesList = messages.map { mapOf("role" to it.role.name.lowercase(), "content" to it.content) }
        
        val body = mutableMapOf<String, Any?>(
            "user_id" to userId,
            "space_id" to (options.spaceId ?: currentSpace ?: "default_space"),
            "messages" to messagesList,
            "llm_type" to (options.llmType ?: LLMType.OPENAI).value
        )
        
        if (voiceConfig != null && voiceConfig.enabled) {
            body["response_mode"] = "stream_voice"
            body["voice_config"] = buildVoiceConfig(voiceConfig)
        } else {
            body["response_mode"] = "stream_text"
        }
        
        options.temperature?.let { body["temperature"] = it }
        options.maxTokens?.let { body["max_tokens"] = it }
        options.botId?.let { body["bot_id"] = it }
        options.conversationId?.let { body["conversation_id"] = it }
        options.voiceId?.let { body["voice_id"] = it }
        (options.customerLlmKey ?: customerLlmKey)?.let { body["customer_llm_key"] = it }
        
        val endpoint = APIEndpoint(
            path = "/chat/stream",
            method = HTTPMethod.POST,
            body = body
        )
        
        var textChunkCount = 0
        var audioChunkCount = 0
        
        val job = launch {
            try {
                apiClient.performStreamRequest(endpoint).collect { data ->
                    processStreamData(data) { event ->
                        when (event) {
                            is StreamEvent.Text -> {
                                textChunkCount++
                                Logger.debug("Text Chunk #$textChunkCount: ${event.content}")
                                trySend(event)
                            }
                            is StreamEvent.Audio -> {
                                audioChunkCount++
                                Logger.debug("Audio Chunk #$audioChunkCount: ${event.audioData.size} bytes")
                                trySend(event)
                            }
                            is StreamEvent.TextComplete -> {
                                trySend(event)
                            }
                            is StreamEvent.Done -> {
                                Logger.info("Stream completed. Text: $textChunkCount, Audio: $audioChunkCount")
                                trySend(event)
                                close()
                            }
                            is StreamEvent.Error -> {
                                Logger.error("Stream error: ${event.exception.message}")
                                trySend(event)
                                close(event.exception)
                            }
                        }
                    }
                }
                
                trySend(StreamEvent.Done(null))
            } catch (e: Exception) {
                Logger.error("Stream failed: ${e.message}")
                trySend(StreamEvent.Error(e))
                close(e)
            }
        }
        
        awaitClose {
            job.cancel()
        }
    }
    
    /**
     * Stream completion using the OpenAI-compatible endpoint.
     * No bot/space pre-configuration required - include system message in the messages list.
     */
    fun streamComplete(
        userId: String,
        messages: List<ChatMessage>,
        options: CompletionOptions
    ): Flow<String> = callbackFlow {
        Logger.debug("Starting streaming completion with ${messages.size} messages")
        
        // Build OpenAI-compatible messages array
        val messagesList = messages.map { msg ->
            mapOf("role" to msg.role.name.lowercase(), "content" to msg.content)
        }
        
        val body = mutableMapOf<String, Any?>(
            "model" to options.model,
            "messages" to messagesList,
            "stream" to true
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
        
        val job = launch {
            try {
                apiClient.performStreamRequest(endpoint).collect { data ->
                    processOpenAIStreamData(data) { content ->
                        trySend(content)
                    }
                }
            } catch (e: Exception) {
                Logger.error("Streaming completion failed: ${e.message}")
                close(e)
            }
        }
        
        awaitClose {
            job.cancel()
        }
    }
    
    /**
     * Process OpenAI-style streaming data
     */
    private fun processOpenAIStreamData(data: String, onChunk: (String) -> Unit) {
        val trimmed = data.trim()
        
        if (trimmed.isEmpty() || trimmed == "[DONE]") {
            return
        }
        
        try {
            val json = JSONObject(trimmed)
            val choices = json.optJSONArray("choices") ?: return
            if (choices.length() == 0) return
            
            val firstChoice = choices.getJSONObject(0)
            val delta = firstChoice.optJSONObject("delta") ?: return
            val content = delta.optString("content", "")
            
            if (content.isNotEmpty()) {
                onChunk(content)
            }
        } catch (e: Exception) {
            // Not valid OpenAI format, skip
        }
    }
    
    /**
     * Build voice configuration dictionary for API request
     */
    private fun buildVoiceConfig(config: VoiceConfig): Map<String, Any?> {
        val voiceDict = mutableMapOf<String, Any?>(
            "enabled" to true
        )
        
        config.voiceId?.let { voiceDict["voice_id"] = it }
        config.elevenlabsApiKey?.let { voiceDict["elevenlabs_api_key"] = it }
        config.stability?.let { voiceDict["stability"] = it }
        config.similarityBoost?.let { voiceDict["similarity_boost"] = it }
        
        return voiceDict
    }
    
    /**
     * Process stream data (performStreamRequest already extracts data from SSE)
     */
    private fun processStreamData(data: String, onEvent: (StreamEvent) -> Unit) {
        val trimmedForCheck = data.trim()
        
        if (trimmedForCheck.isEmpty()) {
            return
        }
        
        if (trimmedForCheck.equals("[DONE]", ignoreCase = true)) {
            Logger.info("Received [DONE] marker")
            return
        }
        
        try {
            val json = JSONObject(data.trim())
            
            if (json.has("content")) {
                val textContent = json.getString("content")
                if (textContent.isNotEmpty()) {
                    onEvent(StreamEvent.Text(textContent))
                }
            }
            
            if (json.has("audio")) {
                val audioBase64 = json.getString("audio")
                try {
                    val audioData = Base64.decode(audioBase64, Base64.DEFAULT)
                    onEvent(StreamEvent.Audio(audioData))
                } catch (e: IllegalArgumentException) {
                    Logger.error("Failed to decode audio Base64: ${e.message}")
                }
            }
            
            return
        } catch (e: Exception) {
            val textContent = extractTextContent(data)
            if (textContent != null) {
                onEvent(StreamEvent.Text(textContent))
            }
        }
    }
    
    /**
     * Extract text content from data string, filtering out structured data
     * Preserves all spaces in the original content
     */
    private fun extractTextContent(content: String): String? {
        val trimmedForCheck = content.trim()
        
        if (trimmedForCheck.isEmpty() || trimmedForCheck.equals("[DONE]", ignoreCase = true)) {
            return null
        }
        
        if (trimmedForCheck.startsWith("{") || trimmedForCheck.startsWith("[")) {
            try {
                val json = JSONObject(trimmedForCheck)
                if (json.has("content")) {
                    val textContent = json.getString("content")
                    if (textContent.isNotEmpty()) {
                        return textContent
                    }
                }
                return null
            } catch (e: Exception) {
                // Not valid JSON, continue to check for function calls
            }
        }
        
        if (trimmedForCheck.contains("'type': 'function_call'") ||
            trimmedForCheck.contains("\"type\": \"function_call\"") ||
            trimmedForCheck.contains("'function_call'") ||
            trimmedForCheck.contains("\"function_call\"")) {
            return null
        }
        
        return content
    }
}

