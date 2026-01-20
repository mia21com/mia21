/**
 * APIClient.kt
 * Mia21
 *
 * Created on November 25, 2025.
 * Copyright © 2025 Mia21. All rights reserved.
 *
 * Description:
 * Network layer for API communication.
 * Handles request creation, execution, and response processing.
 */

package com.mia21.network

import com.mia21.models.Mia21Exception
import com.mia21.utils.Logger
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import org.json.JSONArray
import org.json.JSONObject
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import okhttp3.Response
import okhttp3.sse.EventSource
import okhttp3.sse.EventSourceListener
import okhttp3.sse.EventSources
import java.io.IOException
import java.util.concurrent.TimeUnit

/**
 * HTTP method types
 */
enum class HTTPMethod {
    GET, POST, PUT, PATCH, DELETE
}

/**
 * API endpoint definition
 */
data class APIEndpoint(
    val path: String,
    val method: HTTPMethod,
    val body: Map<String, Any?>? = null,
    val headers: Map<String, String>? = null
)

/**
 * Interface for API client operations
 */
interface APIClientProtocol {
    suspend fun <T> performRequest(endpoint: APIEndpoint, responseType: Class<T>): T
    fun performStreamRequest(endpoint: APIEndpoint): Flow<String>
}

/**
 * Implementation of API client using OkHttp
 */
class APIClient(
    private val baseURL: String,
    private val apiKey: String?,
    timeout: Long = 90
) : APIClientProtocol {
    
    val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
        coerceInputValues = true
    }
    
    private val client = OkHttpClient.Builder()
        .connectTimeout(timeout, TimeUnit.SECONDS)
        .readTimeout(timeout, TimeUnit.SECONDS)
        .writeTimeout(timeout, TimeUnit.SECONDS)
        .build()
    
    /**
     * Perform a regular HTTP request
     * Returns raw JSON string - caller must deserialize
     */
    @Suppress("UNCHECKED_CAST")
    override suspend fun <T> performRequest(endpoint: APIEndpoint, responseType: Class<T>): T {
        return withContext(Dispatchers.IO) {
            val request = buildRequest(endpoint)
            
            logRequest(request)
            
            try {
                val response = client.newCall(request).execute()
                
                validateResponse(response)
                logResponse(response)
                
                // Return raw JSON string - services will deserialize
                val bodyString = response.body?.string()
                    ?: throw Mia21Exception.InvalidResponseException()
                
                bodyString as T
            } catch (e: IOException) {
                throw Mia21Exception.NetworkException(e)
            }
        }
    }
    
    /**
     * Perform a streaming HTTP request (SSE)
     */
    override fun performStreamRequest(endpoint: APIEndpoint): Flow<String> = callbackFlow {
        val request = buildRequest(endpoint)
            .newBuilder()
            .header("Accept", "text/event-stream")
            .header("Cache-Control", "no-cache")
            .build()
        
        logRequest(request)
        logDebug("Starting SSE stream...")
        
        val eventSource = EventSources.createFactory(client).newEventSource(
            request,
            object : EventSourceListener() {
                override fun onOpen(eventSource: EventSource, response: Response) {
                    logDebug("Stream opened: ${response.code}, content-type: ${response.header("Content-Type")}")
                    
                    if (!response.isSuccessful) {
                        val contentType = response.header("Content-Type")
                        val body = try {
                            response.body.string()
                        } catch (e: Exception) {
                            null
                        }
                        
                        Logger.error("Stream failed with status ${response.code}")
                        logDebug("Response body: $body")
                        
                        val errorMessage = if (contentType?.contains("application/json") == true && body != null) {
                            try {
                                val errorJson = json.parseToJsonElement(body)
                                val errorObj = errorJson.jsonObject
                                errorObj["message"]?.jsonPrimitive?.contentOrNull
                                    ?: errorObj["error"]?.jsonPrimitive?.contentOrNull
                                    ?: errorObj["detail"]?.jsonPrimitive?.contentOrNull
                                    ?: "HTTP ${response.code}: ${body.take(200)}"
                            } catch (e: Exception) {
                                "HTTP ${response.code}: ${body.take(200)}"
                            }
                        } else {
                            "HTTP ${response.code}: ${body?.take(200) ?: "Unknown error"}"
                        }
                        
                        close(Mia21Exception.StreamingException(errorMessage))
                    }
                }
                
                override fun onEvent(
                    eventSource: EventSource,
                    id: String?,
                    type: String?,
                    data: String
                ) {
                    logDebug("Received event - type: $type, data length: ${data.length}")
                    trySend(data).isSuccess
                }
                
                override fun onClosed(eventSource: EventSource) {
                    logDebug("Stream closed normally")
                    close()
                }
                
                override fun onFailure(
                    eventSource: EventSource,
                    t: Throwable?,
                    response: Response?
                ) {
                    val contentType = response?.header("Content-Type")
                    val statusCode = response?.code
                    val body = response?.body?.string()
                    
                    logDebug("Stream failed - Status: $statusCode, Content-Type: $contentType")
                    logDebug("Response body: $body")
                    logDebug("Error: ${t?.message}")
                    
                    val errorMessage = if (contentType?.contains("application/json") == true && body != null) {
                        try {
                            val errorJson = json.parseToJsonElement(body)
                            val errorObj = errorJson.jsonObject
                            errorObj["message"]?.jsonPrimitive?.contentOrNull
                                ?: errorObj["error"]?.jsonPrimitive?.contentOrNull
                                ?: errorObj["detail"]?.jsonPrimitive?.contentOrNull
                                ?: "HTTP $statusCode: ${body.take(200)}"
                        } catch (e: Exception) {
                            "HTTP $statusCode: ${body.take(200)}"
                        }
                    } else {
                        t?.message ?: "Stream failed - HTTP $statusCode"
                    }
                    
                    close(Mia21Exception.StreamingException(errorMessage))
                }
            }
        )
        
        awaitClose {
            logDebug("Closing stream...")
            eventSource.cancel()
        }
    }
    
    /**
     * Build HTTP request from endpoint definition
     */
    private fun buildRequest(endpoint: APIEndpoint): Request {
        val fullURL = "$baseURL/api/v1${endpoint.path}"
        
        val requestBuilder = Request.Builder().url(fullURL)
        
        // Add content type
        requestBuilder.addHeader("Content-Type", "application/json")
        
        // Add API key if available
        apiKey?.let {
            requestBuilder.addHeader("x-api-key", it)
        }
        
        // Add custom headers
        endpoint.headers?.forEach { (key, value) ->
            requestBuilder.addHeader(key, value)
        }
        
        // Add body if provided
        endpoint.body?.let { bodyMap ->
            val jsonObject = mapToJsonObject(bodyMap)
            val jsonBody = jsonObject.toString()
            val body = jsonBody.toRequestBody("application/json".toMediaType())
            
            when (endpoint.method) {
                HTTPMethod.POST -> requestBuilder.post(body)
                HTTPMethod.PUT -> requestBuilder.put(body)
                HTTPMethod.DELETE -> requestBuilder.delete(body)
                HTTPMethod.GET -> {} // GET doesn't have body
            }
        } ?: run {
            when (endpoint.method) {
                HTTPMethod.GET -> requestBuilder.get()
                HTTPMethod.DELETE -> requestBuilder.delete()
                else -> {}
            }
        }
        
        return requestBuilder.build()
    }
    
    /**
     * Convert map to JSONObject (properly handles control character escaping)
     */
    private fun mapToJsonObject(map: Map<String, Any?>): JSONObject {
        val jsonObject = JSONObject()
        map.forEach { (key, value) ->
            when (value) {
                null -> jsonObject.put(key, JSONObject.NULL)
                is String -> jsonObject.put(key, value)
                is Number -> jsonObject.put(key, value)
                is Boolean -> jsonObject.put(key, value)
                is List<*> -> jsonObject.put(key, listToJsonArray(value))
                is Map<*, *> -> jsonObject.put(key, mapToJsonObject(value as Map<String, Any?>))
                else -> jsonObject.put(key, value.toString())
            }
        }
        return jsonObject
    }
    
    private fun listToJsonArray(list: List<*>): JSONArray {
        val jsonArray = JSONArray()
        list.forEach { item ->
            when (item) {
                null -> jsonArray.put(JSONObject.NULL)
                is String -> jsonArray.put(item)
                is Number -> jsonArray.put(item)
                is Boolean -> jsonArray.put(item)
                is Map<*, *> -> jsonArray.put(mapToJsonObject(item as Map<String, Any?>))
                else -> jsonArray.put(item.toString())
            }
        }
        return jsonArray
    }
    
    /**
     * Validate HTTP response
     */
    private fun validateResponse(response: Response) {
        if (!response.isSuccessful) {
            val errorMessage = response.body?.string() ?: "Unknown error"
            throw Mia21Exception.ApiException("HTTP ${response.code}: $errorMessage")
        }
    }
    
    private fun logRequest(request: Request) {
        logDebug("API Request: ${request.method} ${request.url}")
    }
    
    private fun logResponse(response: Response) {
        logDebug("Response Status: ${response.code}")
    }
    
    private fun logDebug(message: String) {
        Logger.debug(message)
    }
}
