/**
 * TranscriptionService.kt
 * Mia21
 *
 * Created on November 25, 2025.
 * Copyright © 2025 Mia21. All rights reserved.
 *
 * Description:
 * Service layer for audio transcription (speech-to-text).
 */

package com.mia21.services

import com.mia21.models.Mia21Exception
import com.mia21.models.TranscriptionResponse
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.MultipartBody
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import java.util.concurrent.TimeUnit

/**
 * Service for audio transcription
 */
class TranscriptionService(
    private val baseURL: String,
    private val apiKey: String?,
    timeout: Long = 90
) {
    
    private val client = OkHttpClient.Builder()
        .connectTimeout(timeout, TimeUnit.SECONDS)
        .readTimeout(timeout, TimeUnit.SECONDS)
        .writeTimeout(timeout, TimeUnit.SECONDS)
        .build()
    
    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
    }
    
    /**
     * Transcribe audio data to text
     */
    suspend fun transcribeAudio(audioData: ByteArray, language: String? = null): TranscriptionResponse {
        return withContext(Dispatchers.IO) {
            val requestBody = MultipartBody.Builder()
                .setType(MultipartBody.FORM)
                .addFormDataPart(
                    "audio",
                    "audio.m4a",
                    audioData.toRequestBody("audio/m4a".toMediaType())
                )
                .apply {
                    language?.let { addFormDataPart("language", it) }
                }
                .build()
            
            val request = Request.Builder()
                .url("$baseURL/api/v1/stt/transcribe")
                .apply {
                    apiKey?.let { addHeader("x-api-key", it) }
                }
                .post(requestBody)
                .build()
            
            try {
                val response = client.newCall(request).execute()
                val responseBody = response.body.string()
                
                if (!response.isSuccessful) {
                    val errorMsg = responseBody
                    throw Mia21Exception.AudioTranscriptionException(errorMsg)
                }
                
                if (responseBody.isEmpty()) {
                    throw Mia21Exception.AudioTranscriptionException("Empty response from server")
                }
                
                // Parse JSON response
                try {
                    val transcriptionResponse = json.decodeFromString<TranscriptionResponse>(responseBody)
                    transcriptionResponse
                } catch (e: kotlinx.serialization.SerializationException) {
                    if (responseBody.contains("\"text\"")) {
                        val textMatch = Regex("\"text\"\\s*:\\s*\"([^\"]+)\"").find(responseBody)
                        val extractedText = textMatch?.groupValues?.get(1) ?: ""
                        if (extractedText.isNotEmpty()) {
                            TranscriptionResponse(text = extractedText, language = language)
                        } else {
                            throw Mia21Exception.AudioTranscriptionException("Failed to parse response: ${e.message}")
                        }
                    } else {
                        throw Mia21Exception.AudioTranscriptionException("Failed to parse response: ${e.message}")
                    }
                }
            } catch (e: Mia21Exception.AudioTranscriptionException) {
                throw e
            } catch (e: Exception) {
                throw Mia21Exception.AudioTranscriptionException(e.message ?: "Unknown error")
            }
        }
    }
}

