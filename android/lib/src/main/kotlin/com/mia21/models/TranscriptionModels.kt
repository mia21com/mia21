/**
 * TranscriptionModels.kt
 * Mia21
 *
 * Created on November 25, 2025.
 * Copyright © 2025 Mia21. All rights reserved.
 *
 * Description:
 * Speech-to-text transcription models.
 * Includes request and response models for audio transcription.
 */

package com.mia21.models

import kotlinx.serialization.Serializable

/**
 * Response from audio transcription
 */
@Serializable
data class TranscriptionResponse(
    val text: String,
    val language: String? = null,
    val confidence: Double? = null
)

