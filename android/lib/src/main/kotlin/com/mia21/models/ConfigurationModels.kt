/**
 * ConfigurationModels.kt
 * Mia21
 *
 * Created on November 25, 2025.
 * Copyright © 2025 Mia21. All rights reserved.
 *
 * Description:
 * Configuration and initialization models.
 * Includes response modes, initialization options, voice configuration,
 * and initialization responses.
 */

package com.mia21.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * API environment configuration
 */
enum class Mia21Environment(val baseURL: String, val environmentName: String) {
    PRODUCTION("https://api.mia21.com", "Production"),
    STAGING("https://api-staging.mia21.com", "Staging");
}

/**
 * Response mode for API requests
 */
@Serializable
enum class ResponseMode {
    @SerialName("text")
    TEXT,
    
    @SerialName("stream_text")
    STREAM_TEXT,
    
    @SerialName("stream_voice")
    STREAM_VOICE,
    
    @SerialName("stream_voice_only")
    STREAM_VOICE_ONLY
}

/**
 * Options for initializing a chat session
 */
data class InitializeOptions(
    val spaceId: String? = null,
    val botId: String? = null,
    val llmType: LLMType? = LLMType.OPENAI,
    val userName: String? = null,
    val language: String? = null,
    val generateFirstMessage: Boolean = true,
    val incognitoMode: Boolean = false,
    val customerLlmKey: String? = null,
    val spaceConfig: SpaceConfig? = null
)

/**
 * Response from chat initialization
 */
@Serializable
data class InitializeResponse(
    val status: String,
    @SerialName("user_id")
    val userId: String,
    @SerialName("conversation_id")
    val conversationId: String,
    val message: String? = null,
    @SerialName("space_id")
    val spaceId: String? = null,
    @SerialName("is_new_user")
    val isNewUser: Boolean? = null
)

/**
 * Voice synthesis configuration
 */
@Serializable
data class VoiceConfig(
    val enabled: Boolean,
    @SerialName("voice_id")
    val voiceId: String? = null,
    @SerialName("elevenlabs_api_key")
    val elevenlabsApiKey: String? = null,
    val stability: Double? = null,
    @SerialName("similarity_boost")
    val similarityBoost: Double? = null
)

