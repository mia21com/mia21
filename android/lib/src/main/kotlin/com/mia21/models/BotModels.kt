/**
 * BotModels.kt
 * Mia21
 *
 * Created on November 25, 2025.
 * Copyright © 2025 Mia21. All rights reserved.
 *
 * Description:
 * Bot-related data models.
 * Includes bot information and creation requests.
 */

package com.mia21.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Represents an AI bot/assistant
 */
@Serializable
data class Bot(
    @SerialName("bot_id")
    val botId: String,
    val name: String,
    val prompt: String,
    @SerialName("llm_identifier")
    val llmIdentifier: String,
    val temperature: Double,
    @SerialName("max_tokens")
    val maxTokens: Int,
    val language: String,
    @SerialName("voice_id")
    val voiceId: String? = null,
    @SerialName("is_default")
    val isDefault: Boolean,
    @SerialName("customer_id")
    val customerId: String,
    @SerialName("created_at")
    val createdAt: String? = null,
    @SerialName("updated_at")
    val updatedAt: String? = null
)

/**
 * Response containing a list of bots
 */
@Serializable
data class BotsResponse(
    val bots: List<Bot>,
    val count: Int
)

/**
 * Request to create a new bot
 */
data class BotCreateRequest(
    val botId: String,
    val name: String,
    val voiceId: String,
    val additionalPrompt: String? = null,
    val isDefault: Boolean? = false
)

