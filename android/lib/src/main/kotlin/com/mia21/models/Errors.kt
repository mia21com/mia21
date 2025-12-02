/**
 * Errors.kt
 * Mia21
 *
 * Created on November 25, 2025.
 * Copyright © 2025 Mia21. All rights reserved.
 *
 * Description:
 * Custom exception types for the Mia21 SDK.
 * Defines specific exceptions for API operations,
 * networking, decoding, and chat management.
 */

package com.mia21.models

/**
 * Base exception class for all Mia21 SDK errors
 */
sealed class Mia21Exception(message: String, cause: Throwable? = null) : Exception(message, cause) {
    
    /**
     * Chat session not initialized error
     */
    class ChatNotInitializedException : Mia21Exception("Chat not initialized. Call initialize() first.")
    
    /**
     * Invalid response from server
     */
    class InvalidResponseException : Mia21Exception("Invalid response from server")
    
    /**
     * Network connectivity error
     */
    class NetworkException(cause: Throwable) : Mia21Exception("Network error: ${cause.message}", cause)
    
    /**
     * API error with specific message
     */
    class ApiException(message: String) : Mia21Exception("API error: $message")
    
    /**
     * JSON decoding error
     */
    class DecodingException(cause: Throwable) : Mia21Exception("Failed to decode response: ${cause.message}", cause)
    
    /**
     * Invalid URL error
     */
    class InvalidURLException : Mia21Exception("Invalid URL")
    
    /**
     * Streaming error
     */
    class StreamingException(message: String) : Mia21Exception("Streaming error: $message")
    
    /**
     * Audio transcription error
     */
    class AudioTranscriptionException(message: String) : Mia21Exception("Audio transcription error: $message")
}

