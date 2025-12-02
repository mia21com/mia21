package com.mia21.example.ui

/**
 * MessageBubble.kt
 * Composable for displaying individual chat messages.
 * Supports typewriter animation for bot messages and different
 * styling for user vs assistant messages.
 */

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import com.mia21.example.theme.MiaColors
import com.mia21.models.ChatMessage
import com.mia21.models.MessageRole

@Composable
fun MessageBubble(
    message: ChatMessage,
    enableTypewriter: Boolean = false
) {
    val isUser = message.role == MessageRole.USER

    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = if (isUser) Arrangement.End else Arrangement.Start
    ) {
        Surface(
            shape = RoundedCornerShape(
                topStart = 16.dp,
                topEnd = 16.dp,
                bottomStart = if (isUser) 16.dp else 4.dp,
                bottomEnd = if (isUser) 4.dp else 16.dp
            ),
            color = if (isUser) {
                MiaColors.UserMessage
            } else {
                MiaColors.BotMessage
            },
            modifier = Modifier
                .widthIn(max = 280.dp)
                .padding(
                    start = if (isUser) 48.dp else 0.dp,
                    end = if (isUser) 0.dp else 48.dp
                )
        ) {
            if (enableTypewriter && !isUser) {
                androidx.compose.runtime.key("${message.content}_${enableTypewriter}") {
                    TypewriterText(
                        text = message.content,
                        speed = 30
                    ) { displayedText ->
                        MarkdownText(
                            text = displayedText.ifEmpty { "\u200B" },
                            modifier = Modifier.padding(12.dp),
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            style = MaterialTheme.typography.bodyLarge
                        )
                    }
                }
            } else {
                MarkdownText(
                    text = message.content,
                    modifier = Modifier.padding(12.dp),
                    color = if (isUser) {
                        MiaColors.OnPrimary
                    } else {
                        MaterialTheme.colorScheme.onSurfaceVariant
                    },
                    style = MaterialTheme.typography.bodyLarge
                )
            }
        }
    }
}

/**
 * Simple markdown text renderer for basic markdown formatting
 * Supports: **bold**, *italic*, `code`, and line breaks
 */
@Composable
fun MarkdownText(
    text: String,
    modifier: Modifier = Modifier,
    color: androidx.compose.ui.graphics.Color,
    style: androidx.compose.ui.text.TextStyle
) {
    val annotatedString = buildAnnotatedString {
        var i = 0
        while (i < text.length) {
            when {
                // Bold: **text**
                i + 1 < text.length && text[i] == '*' && text[i + 1] == '*' -> {
                    val endIndex = text.indexOf("**", i + 2)
                    if (endIndex != -1) {
                        withStyle(style = SpanStyle(fontWeight = FontWeight.Bold, color = color)) {
                            append(text.substring(i + 2, endIndex))
                        }
                        i = endIndex + 2
                    } else {
                        // No closing **, treat as regular text
                        withStyle(style = SpanStyle(color = color)) {
                            if (i + 2 <= text.length) {
                                append(text.substring(i, i + 2))
                            } else {
                                append(text.substring(i))
                            }
                        }
                        i += 2
                    }
                }
                // Code: `text`
                text[i] == '`' -> {
                    val endIndex = text.indexOf("`", i + 1)
                    if (endIndex != -1) {
                        withStyle(style = SpanStyle(
                            fontFamily = androidx.compose.ui.text.font.FontFamily.Monospace,
                            background = color.copy(alpha = 0.1f),
                            color = color
                        )) {
                            append(text.substring(i + 1, endIndex))
                        }
                        i = endIndex + 1
                    } else {
                        withStyle(style = SpanStyle(color = color)) {
                            append(text[i])
                        }
                        i++
                    }
                }
                // Italic: *text*
                text[i] == '*' && (i + 1 >= text.length || text[i + 1] != '*') -> {
                    val endIndex = text.indexOf("*", i + 1)
                    if (endIndex != -1 && (endIndex + 1 >= text.length || text[endIndex + 1] != '*')) {
                        withStyle(style = SpanStyle(fontStyle = FontStyle.Italic, color = color)) {
                            append(text.substring(i + 1, endIndex))
                        }
                        i = endIndex + 1
                    } else {
                        withStyle(style = SpanStyle(color = color)) {
                            append(text[i])
                        }
                        i++
                    }
                }
                else -> {
                    // Regular text
                    withStyle(style = SpanStyle(color = color)) {
                        append(text[i])
                    }
                    i++
                }
            }
        }
    }
    
    Text(
        text = annotatedString,
        modifier = modifier,
        style = style
    )
}
