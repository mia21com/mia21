/**
 * ConversationModels.kt
 * Mia21
 *
 * Created on November 25, 2025.
 * Copyright © 2025 Mia21. All rights reserved.
 *
 * Description:
 * Conversation-related data models.
 * Includes conversation summaries, details, and message history.
 */

package com.mia21.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Summary of a conversation
 */
@Serializable
data class ConversationSummary(
    val id: String,
    @SerialName("user_id")
    val userId: String,
    @SerialName("space_id")
    val spaceId: String,
    @SerialName("bot_id")
    val botId: String? = null,
    val status: String,
    @SerialName("created_at")
    val createdAt: String,
    @SerialName("updated_at")
    val updatedAt: String,
    @SerialName("closed_at")
    val closedAt: String? = null,
    @SerialName("message_count")
    val messageCount: Int,
    @SerialName("first_message")
    val firstMessage: String? = null,
    val title: String? = null
) {
    /**
     * Generate a display title from space and bot names with conversation title
     * @param spaceName Name of the space
     * @param botName Name of the bot (optional)
     * @return Formatted title like "Space · Bot: [title]"
     */
    fun displayTitle(spaceName: String?, botName: String?): String {
        val spaceDisplay = spaceName ?: spaceId
        val botDisplay = botName ?: (botId ?: "No Bot")
        
        // If backend provided a title, use format: "Space · Bot: [title]"
        return if (!title.isNullOrEmpty()) {
            "$spaceDisplay · $botDisplay: $title"
        } else {
            // Otherwise just show "Space · Bot"
            "$spaceDisplay · $botDisplay"
        }
    }
}

/**
 * Detailed conversation with all messages
 */
@Serializable
data class ConversationDetail(
    val id: String,
    @SerialName("user_id")
    val userId: String,
    @SerialName("space_id")
    val spaceId: String,
    @SerialName("bot_id")
    val botId: String? = null,
    val status: String,
    @SerialName("created_at")
    val createdAt: String,
    @SerialName("updated_at")
    val updatedAt: String,
    @SerialName("closed_at")
    val closedAt: String? = null,
    val messages: List<ConversationMessage>
)

/**
 * A single message in a conversation
 */
@Serializable
data class ConversationMessage(
    val id: String,
    val role: String,
    val content: String,
    @SerialName("created_at")
    val createdAt: String,
    @SerialName("model_used")
    val modelUsed: String? = null,
    @SerialName("tokens_used")
    val tokensUsed: Int? = null
)

/**
 * Response from deleting a conversation
 */
@Serializable
data class DeleteConversationResponse(
    val success: Boolean,
    val message: String,
    @SerialName("conversation_id")
    val conversationId: String
)

/**
 * Response from renaming a conversation
 */
@Serializable
data class RenameConversationResponse(
    val success: Boolean,
    @SerialName("conversation_id")
    val conversationId: String,
    val title: String? = null
)

/**
 * Response from deleting all user data (GDPR compliance)
 * ⚠️ This permanently deletes all conversations, messages, memories, and RAG/vector data
 */
@Serializable
data class DeleteUserDataResponse(
    val success: Boolean,
    @SerialName("user_id")
    val userId: String,
    val deleted: DeletedDataCounts,
    @SerialName("rag_deleted")
    val ragDeleted: Boolean
)

/**
 * Counts of deleted data items
 */
@Serializable
data class DeletedDataCounts(
    val conversations: Int,
    val messages: Int,
    val memories: Int
)

