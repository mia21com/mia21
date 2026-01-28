/**
 * SpaceModels.kt
 * Mia21
 *
 * Created on November 25, 2025.
 * Copyright © 2025 Mia21. All rights reserved.
 *
 * Description:
 * Space-related data models.
 * Includes space information and configuration.
 */

package com.mia21.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Represents a workspace/space
 */
@Serializable
data class Space(
    @SerialName("space_id")
    val spaceId: String,
    val name: String,
    val prompt: String,
    val description: String,
    @SerialName("generate_first_message")
    val generateFirstMessage: Boolean,
    val bots: List<Bot>,
    @SerialName("is_active")
    val isActive: Boolean,
    @SerialName("usage_count")
    val usageCount: Int,
    @SerialName("created_at")
    val createdAt: String,
    @SerialName("updated_at")
    val updatedAt: String,
    val type: String
)

/**
 * Configuration for a space
 */
@Serializable
data class SpaceConfig(
    @SerialName("space_id")
    val spaceId: String,
    val prompt: String,
    val description: String? = null,
    @SerialName("llm_identifier")
    val llmIdentifier: String,
    val temperature: Double = 0.7,
    @SerialName("max_tokens")
    val maxTokens: Int = 1024,
    @SerialName("frequency_penalty")
    val frequencyPenalty: Double? = null,
    @SerialName("presence_penalty")
    val presencePenalty: Double? = null
)

/**
 * Conversation status filter options
 */
enum class ConversationStatus(val value: String) {
    ACTIVE("active"),
    CLOSED("closed"),
    ARCHIVED("archived")
}

/**
 * Options for listing conversations within a space
 */
data class SpaceConversationsOptions(
    /** Filter by specific user ID */
    val userId: String? = null,
    /** Filter by bot ID */
    val botId: String? = null,
    /** Filter by conversation status */
    val status: ConversationStatus? = null,
    /** Maximum number of conversations to return (1-500, default: 100) */
    val limit: Int = 100,
    /** Offset for pagination */
    val offset: Int = 0
)

/**
 * Response containing conversations within a space
 */
@Serializable
data class SpaceConversationsResponse(
    /** The space ID */
    @SerialName("space_id")
    val spaceId: String,
    /** Total count of conversations matching the filter */
    @SerialName("total_count")
    val totalCount: Int,
    /** List of conversations */
    val conversations: List<SpaceConversation>,
    /** Limit used for the query */
    val limit: Int,
    /** Offset used for the query */
    val offset: Int
)

/**
 * A conversation within a space
 */
@Serializable
data class SpaceConversation(
    /** Unique conversation identifier */
    val id: String,
    /** User ID who owns this conversation */
    @SerialName("user_id")
    val userId: String,
    /** Space ID this conversation belongs to */
    @SerialName("space_id")
    val spaceId: String,
    /** Bot ID used in this conversation */
    @SerialName("bot_id")
    val botId: String? = null,
    /** Conversation title */
    val title: String? = null,
    /** User's timezone */
    val timezone: String? = null,
    /** Conversation status */
    val status: String,
    /** Creation timestamp */
    @SerialName("created_at")
    val createdAt: String,
    /** Last update timestamp */
    @SerialName("updated_at")
    val updatedAt: String,
    /** Timestamp when conversation was closed */
    @SerialName("closed_at")
    val closedAt: String? = null,
    /** Number of messages in the conversation */
    @SerialName("message_count")
    val messageCount: Int
)

