/**
 * MessageRole.kt
 * Mia21
 *
 * Created on November 25, 2025.
 * Copyright © 2025 Mia21. All rights reserved.
 *
 * Description:
 * Type-safe enumeration for chat message roles.
 */

package com.mia21.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Represents the role of a message in a chat conversation
 */
@Serializable
enum class MessageRole {
    @SerialName("user")
    USER,
    
    @SerialName("assistant")
    ASSISTANT,
    
    @SerialName("system")
    SYSTEM
}

