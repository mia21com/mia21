/**
 * DynamicPromptModels.kt
 * Mia21
 *
 * Created on January 21, 2026.
 * Copyright © 2026 Mia21. All rights reserved.
 *
 * Description:
 * Models for Dynamic Prompting feature.
 * OpenAI-compatible endpoint for runtime AI configuration.
 */

package com.mia21.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Options for dynamic prompting via OpenAI-compatible endpoint
 */
data class DynamicPromptOptions(
    /**
     * The model to use (e.g., "gpt-4o", "gpt-4o-mini", "claude-3-opus")
     */
    val model: String = "gpt-4o",
    /**
     * Space ID for conversation context separation
     */
    val spaceId: String? = null,
    /**
     * User ID for personalization and memory
     */
    val userId: String? = null,
    /**
     * Temperature for response randomness (0.0-2.0)
     */
    val temperature: Double? = null,
    /**
     * Maximum tokens in the response
     */
    val maxTokens: Int? = null,
    /**
     * Whether to stream the response
     */
    val stream: Boolean = false
)

/**
 * Response from the OpenAI-compatible chat completions endpoint
 */
@Serializable
data class DynamicPromptResponse(
    val id: String,
    val `object`: String,
    val created: Long,
    val model: String,
    val choices: List<DynamicPromptChoice>,
    val usage: DynamicPromptUsage? = null
)

/**
 * A single choice in the dynamic prompt response
 */
@Serializable
data class DynamicPromptChoice(
    val index: Int,
    val message: DynamicPromptMessage,
    @SerialName("finish_reason")
    val finishReason: String? = null
)

/**
 * A message in the OpenAI-compatible format
 */
@Serializable
data class DynamicPromptMessage(
    val role: String,
    val content: String
)

/**
 * Token usage information
 */
@Serializable
data class DynamicPromptUsage(
    @SerialName("prompt_tokens")
    val promptTokens: Int,
    @SerialName("completion_tokens")
    val completionTokens: Int,
    @SerialName("total_tokens")
    val totalTokens: Int
)

/**
 * A chunk from the streaming response
 */
@Serializable
data class DynamicPromptStreamChunk(
    val id: String,
    val `object`: String,
    val created: Long,
    val model: String,
    val choices: List<DynamicPromptStreamChoice>
)

/**
 * A single choice in a streaming chunk
 */
@Serializable
data class DynamicPromptStreamChoice(
    val index: Int,
    val delta: DynamicPromptDelta,
    @SerialName("finish_reason")
    val finishReason: String? = null
)

/**
 * Delta content in a streaming chunk
 */
@Serializable
data class DynamicPromptDelta(
    val role: String? = null,
    val content: String? = null
)

