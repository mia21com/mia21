/**
 * ConversationService.kt
 * Mia21
 *
 * Created on November 25, 2025.
 * Copyright © 2025 Mia21. All rights reserved.
 *
 * Description:
 * Service layer for conversation history management.
 */

package com.mia21.services

import com.mia21.models.ConversationDetail
import com.mia21.models.ConversationSummary
import com.mia21.models.DeleteConversationResponse
import com.mia21.network.APIClient
import com.mia21.network.APIEndpoint
import com.mia21.network.HTTPMethod
import kotlinx.serialization.decodeFromString

/**
 * Service for managing conversation history
 */
class ConversationService(private val apiClient: APIClient) {
    
    /**
     * List conversations for a user
     */
    suspend fun listConversations(
        userId: String,
        spaceId: String? = null,
        limit: Int = 50
    ): List<ConversationSummary> {
        val queryParams = mutableMapOf(
            "user_id" to userId,
            "limit" to limit.toString()
        )
        spaceId?.let { queryParams["space_id"] = it }
        
        val path = "/conversations?" + queryParams.map { "${it.key}=${it.value}" }.joinToString("&")
        val endpoint = APIEndpoint(
            path = path,
            method = HTTPMethod.GET
        )
        
        val jsonResponse = apiClient.performRequest(endpoint, String::class.java)
        // Parse JSON response
        return try {
            apiClient.json.decodeFromString<List<ConversationSummary>>(jsonResponse)
        } catch (e: Exception) {
            emptyList()
        }
    }
    
    /**
     * Get a specific conversation
     */
    suspend fun getConversation(conversationId: String): ConversationDetail {
        val endpoint = APIEndpoint(
            path = "/conversations/$conversationId",
            method = HTTPMethod.GET
        )
        
        val jsonResponse = apiClient.performRequest(endpoint, String::class.java)
        return apiClient.json.decodeFromString<ConversationDetail>(jsonResponse)
    }
    
    /**
     * Delete a conversation
     */
    suspend fun deleteConversation(conversationId: String): DeleteConversationResponse {
        val endpoint = APIEndpoint(
            path = "/conversations/$conversationId",
            method = HTTPMethod.DELETE
        )
        
        val jsonResponse = apiClient.performRequest(endpoint, String::class.java)
        return apiClient.json.decodeFromString<DeleteConversationResponse>(jsonResponse)
    }
}

