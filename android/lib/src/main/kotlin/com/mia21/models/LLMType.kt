package com.mia21.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Enum representing different Large Language Model providers
 */
@Serializable
enum class LLMType(val value: String) {
    @SerialName("openai")
    OPENAI("openai"),
    
    @SerialName("gemini")
    GEMINI("gemini");
    
    override fun toString(): String = value
}
