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
 * Fully compatible with OpenAI's API - standard OpenAI SDKs work by just changing the base_url.
 * Mia21 extensions are passed via HTTP headers.
 */
data class CompletionOptions(
    // OpenAI Standard Parameters (in request body)
    
    /** Model to use (e.g., "gpt-4o", "gpt-4o-mini") */
    val model: String = "gpt-4o",
    /** Temperature for response randomness (0.0 - 2.0) */
    val temperature: Double? = null,
    /** Maximum tokens in response */
    val maxTokens: Int? = null,
    /** Whether to stream the response */
    val stream: Boolean = false,
    
    // Mia21 Extensions (via HTTP headers)
    
    /** Space ID for memory isolation (X-Space-Id header, default: "default") */
    val spaceId: String? = null,
    /** Agent ID for specific agent behavior (X-Agent-Id header) */
    val agentId: String? = null,
    /** Enable voice output (X-Voice-Enabled header, default: false) */
    val voiceEnabled: Boolean? = null,
    /** ElevenLabs voice ID for TTS (X-Voice-Id header) */
    val voiceId: String? = null,
    /** Disable memory - no history used or saved (X-Incognito header, default: false) */
    val incognito: Boolean? = null,
    /** Customer's own LLM API key for BYOK (X-LLM-API-Key header) */
    val llmApiKey: String? = null,
    /** User's timezone for context (X-Timezone header, e.g., "America/New_York") */
    val timezone: String? = null,
    /** User's name for personalization (X-User-Name header) */
    val userName: String? = null,
    /** Specific conversation ID (X-Conversation-Id header) */
    val conversationId: String? = null,
    /** Custom metadata as JSON string (X-Meta header) */
    val meta: String? = null
) {
    /** Backward compatibility constructor with botId */
    @Deprecated("Use agentId instead of botId", ReplaceWith("CompletionOptions(model, temperature, maxTokens, stream, spaceId, agentId = botId)"))
    constructor(
        spaceId: String?,
        botId: String?,
        model: String = "gpt-4o",
        temperature: Double? = null,
        maxTokens: Int? = null,
        stream: Boolean = false
    ) : this(
        model = model,
        temperature = temperature,
        maxTokens = maxTokens,
        stream = stream,
        spaceId = spaceId,
        agentId = botId  // Map botId to agentId
    )
}

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

/**
 * Options for OpenAI-compatible /v1/chat/initialize endpoint.
 * Generates a personalized greeting based on user's conversation history and memories.
 * All parameters are passed via HTTP headers (no request body).
 */
data class GreetingOptions(
    /** Space ID for context separation (X-Space-Id header) */
    val spaceId: String? = null,
    /** Agent ID for greeting style (X-Agent-Id header) */
    val agentId: String? = null,
    /** Enable voice in response (X-Voice-Enabled header) */
    val voiceEnabled: Boolean? = null,
    /** Voice ID for TTS (X-Voice-Id header) */
    val voiceId: String? = null,
    /** If true, no memory is used or saved (X-Incognito header) */
    val incognito: Boolean? = null,
    /** Customer's own LLM API key for BYOK (X-LLM-API-Key header) */
    val llmApiKey: String? = null,
    /** User's timezone for time-aware greetings (X-Timezone header, e.g., "America/New_York") */
    val timezone: String? = null,
    /** User's name for personalized greetings (X-User-Name header) */
    val userName: String? = null,
    /** Specific conversation ID to continue (X-Conversation-Id header) */
    val conversationId: String? = null,
    /** Custom metadata as JSON string (X-Meta header) */
    val meta: String? = null
)

/** Backward compatibility alias */
@Deprecated("Use GreetingOptions instead", ReplaceWith("GreetingOptions"))
typealias ChatInitializeOptions = GreetingOptions

/**
 * Response from OpenAI-compatible /v1/chat/initialize endpoint
 */
@Serializable
data class GreetingResponse(
    /** Unique identifier for the request */
    val id: String? = null,
    /** Object type (e.g., "chat.initialization") */
    val `object`: String? = null,
    /** Unix timestamp of creation */
    val created: Int? = null,
    /** Model used to generate the greeting */
    val model: String? = null,
    /** Personalized greeting message based on conversation history */
    val greeting: String? = null,
    /** Whether the user has memory/history */
    @SerialName("has_memory")
    val hasMemory: Boolean? = null,
    /** Number of memories for this user */
    @SerialName("memory_count")
    val memoryCount: Int? = null,
    /** Conversation ID for continuing this conversation */
    @SerialName("conversation_id")
    val conversationId: String? = null,
    /** Context about the user derived from history (legacy) */
    @SerialName("user_context")
    val userContext: GreetingUserContext? = null,
    /** Audio data if voice was enabled (base64 encoded) */
    val audio: String? = null
)

/** Backward compatibility alias */
@Deprecated("Use GreetingResponse instead", ReplaceWith("GreetingResponse"))
typealias ChatInitializeResponse = GreetingResponse

/**
 * User context derived from conversation history
 */
@Serializable
data class GreetingUserContext(
    /** Number of previous conversations */
    @SerialName("conversation_count")
    val conversationCount: Int? = null,
    /** Last interaction timestamp */
    @SerialName("last_interaction")
    val lastInteraction: String? = null,
    /** Topics the user has discussed */
    val topics: List<String>? = null,
    /** Whether this is a returning user */
    @SerialName("is_returning_user")
    val isReturningUser: Boolean? = null
)

/** Backward compatibility alias */
@Deprecated("Use GreetingUserContext instead", ReplaceWith("GreetingUserContext"))
typealias ChatUserContext = GreetingUserContext

