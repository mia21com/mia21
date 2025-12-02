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

