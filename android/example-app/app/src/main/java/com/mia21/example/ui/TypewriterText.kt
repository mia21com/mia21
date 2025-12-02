package com.mia21.example.ui

/**
 * TypewriterText.kt
 * Composable that animates text character-by-character (typewriter effect).
 * Used to animate bot messages as they appear, creating a typing effect.
 */

import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import kotlinx.coroutines.delay

@Composable
fun TypewriterText(
    text: String,
    speed: Int = 30,
    onComplete: (() -> Unit)? = null,
    content: @Composable (String) -> Unit
) {
    key(text) {
        var displayedText by remember { mutableIntStateOf(0) }

        
        LaunchedEffect(Unit) {
            displayedText = 0
            for (i in 0..text.length) {
                displayedText = i
                delay(speed.toLong())
            }
            onComplete?.invoke()
        }
        
        val currentText = text.take(displayedText)
        content(currentText)
    }
}

