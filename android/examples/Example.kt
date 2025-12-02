/**
 * Example.kt
 * 
 * Simple example demonstrating how to use the Mia21 Android SDK
 */

package com.mia21.examples

import com.mia21.Mia21Client
import com.mia21.models.*
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.runBlocking

fun main() = runBlocking {
    // Initialize the client
    val client = Mia21Client(
        apiKey = "your-api-key",
        userId = "user-123"
    )
    
    // Enable debug logging
    Mia21Client.setLogLevel(LogLevel.DEBUG)
    
    // Initialize chat session
    val initResponse = client.initialize(
        options = InitializeOptions(
            generateFirstMessage = true,
            spaceId = "default_space"
        )
    )
    
    println("Bot: ${initResponse.message}")
    
    // Send a message
    val response = client.chat("Hello! Tell me about yourself.")
    println("Bot: ${response.message}")
    
    // Stream a response
    val messages = listOf(
        ChatMessage(role = MessageRole.USER, content = "Write a haiku about coding")
    )
    
    print("Bot (streaming): ")
    client.streamChat(messages).collect { chunk ->
        print(chunk)
    }
    println()
    
    // List conversations
    val conversations = client.listConversations(limit = 5)
    println("\nRecent conversations:")
    conversations.forEach { conv ->
        println("- ${conv.displayTitle("Default Space", "Bot")} (${conv.messageCount} messages)")
    }
    
    // Close session
    client.close()
    println("\nSession closed")
}

