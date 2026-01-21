/**
 * ChatModels.kt
 * Mia21
 *
 * Created on November 25, 2025.
 * Copyright © 2025 Mia21. All rights reserved.
 *
 * Description:
 * Chat-related data models.
 * Includes chat messages, options, responses, and tool calls.
 */

package com.mia21.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Represents a chat message
 */
@Serializable
data class ChatMessage(
    val role: MessageRole,
    val content: String
)

/**
 * Options for sending chat messages
 */
data class ChatOptions(
    val spaceId: String? = null,
    val botId: String? = null,
    val conversationId: String? = null,
    val temperature: Double? = null,
    val maxTokens: Int? = null,
    val customerLlmKey: String? = null,
    val spaceConfig: SpaceConfig? = null,
    val llmType: LLMType? = null,
    /**
     * Voice ID for per-request voice override (ElevenLabs voice ID).
     * Priority: Request-level voiceId > Bot-level voice_id > Default
     */
    val voiceId: String? = null
)

/**
 * Response from a chat message
 */
@Serializable
data class ChatResponse(
    val message: String,
    @SerialName("user_id")
    val userId: String,
    @SerialName("tool_calls")
    val toolCalls: List<ToolCall>? = null
)

/**
 * Represents a tool call in a chat response
 */
@Serializable
data class ToolCall(
    val name: String? = null,
    val arguments: String? = null
)

/**
 * Options for OpenAI-compatible /v1/chat/completions endpoint.
 * No bot/space pre-configuration required - just pass messages with system prompt.
 */
data class CompletionOptions(
    /** Space ID for context separation (passed via X-Space-Id header) */
    val spaceId: String? = null,
    /** Bot ID for specific bot behavior (passed via X-Bot-Id header) */
    val botId: String? = null,
    /** Model to use (e.g., "gpt-4o", "gpt-4o-mini") */
    val model: String = "gpt-4o",
    /** Temperature for response randomness (0.0 - 2.0) */
    val temperature: Double? = null,
    /** Maximum tokens in response */
    val maxTokens: Int? = null,
    /** Whether to stream the response */
    val stream: Boolean = false
)

/**
 * Response from OpenAI-compatible /v1/chat/completions endpoint
 */
@Serializable
data class CompletionResponse(
    val id: String? = null,
    val `object`: String? = null,
    val created: Int? = null,
    val model: String? = null,
    val choices: List<CompletionChoice>? = null,
    val usage: CompletionUsage? = null
)

@Serializable
data class CompletionChoice(
    val index: Int? = null,
    val message: CompletionMessage? = null,
    val delta: CompletionMessage? = null,
    @SerialName("finish_reason")
    val finishReason: String? = null
)

@Serializable
data class CompletionMessage(
    val role: String? = null,
    val content: String? = null
)

@Serializable
data class CompletionUsage(
    @SerialName("prompt_tokens")
    val promptTokens: Int? = null,
    @SerialName("completion_tokens")
    val completionTokens: Int? = null,
    @SerialName("total_tokens")
    val totalTokens: Int? = null
)

