/**
 * SpaceService.kt
 * Mia21
 *
 * Created on November 25, 2025.
 * Copyright © 2025 Mia21. All rights reserved.
 *
 * Description:
 * Service layer for space and bot management operations.
 */

package com.mia21.services

import com.mia21.models.Bot
import com.mia21.models.BotsResponse
import com.mia21.models.Space
import com.mia21.network.APIClient
import com.mia21.network.APIEndpoint
import com.mia21.network.HTTPMethod
import kotlinx.serialization.decodeFromString

/**
 * Service for managing spaces and bots
 */
class SpaceService(private val apiClient: APIClient) {
    
    /**
     * List all available spaces
     */
    suspend fun listSpaces(): List<Space> {
        val endpoint = APIEndpoint(
            path = "/spaces",
            method = HTTPMethod.GET
        )
        
        val jsonResponse = apiClient.performRequest(endpoint, String::class.java)
        return try {
            apiClient.json.decodeFromString<List<Space>>(jsonResponse)
        } catch (e: Exception) {
            emptyList()
        }
    }
    
    /**
     * List all bots for the current customer
     */
    suspend fun listBots(): List<Bot> {
        val endpoint = APIEndpoint(
            path = "/bots",
            method = HTTPMethod.GET
        )
        
        val jsonResponse = apiClient.performRequest(endpoint, String::class.java)
        val response = apiClient.json.decodeFromString<BotsResponse>(jsonResponse)
        return response.bots
    }
}

