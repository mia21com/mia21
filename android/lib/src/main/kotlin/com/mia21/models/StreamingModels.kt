/**
 * StreamingModels.kt
 * Mia21
 *
 * Created on November 25, 2025.
 * Copyright © 2025 Mia21. All rights reserved.
 *
 * Description:
 * Streaming-related data models.
 * Includes stream events for text and audio responses.
 */

package com.mia21.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Events received during streaming
 */
sealed class StreamEvent {
    /**
     * Text chunk received
     */
    data class Text(val content: String) : StreamEvent()
    
    /**
     * Audio chunk received (decoded from Base64)
     */
    data class Audio(val audioData: ByteArray) : StreamEvent() {
        override fun equals(other: Any?): Boolean {
            if (this === other) return true
            if (javaClass != other?.javaClass) return false
            other as Audio
            return audioData.contentEquals(other.audioData)
        }
        
        override fun hashCode(): Int {
            return audioData.contentHashCode()
        }
    }
    
    /**
     * Text streaming completed
     */
    object TextComplete : StreamEvent()
    
    /**
     * Stream completed successfully
     */
    data class Done(val response: ChatResponse? = null) : StreamEvent()
    
    /**
     * Error occurred during streaming
     */
    data class Error(val exception: Throwable) : StreamEvent()
}

/**
 * Server-sent event data
 */
@Serializable
data class StreamChunk(
    val type: String,
    val content: String? = null,
    @SerialName("audio_data")
    val audioData: String? = null,
    val error: String? = null
)

