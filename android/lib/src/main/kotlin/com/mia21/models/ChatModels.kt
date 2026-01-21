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
    val voiceId: String? = null,
    /**
     * Dynamic system prompt - configure AI behavior at runtime.
     * When provided, this will be prepended as a system message to the conversation.
     */
    val systemPrompt: String? = null
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

