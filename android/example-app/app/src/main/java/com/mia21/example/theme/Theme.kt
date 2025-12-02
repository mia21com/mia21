package com.mia21.example.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

/**
 * Custom color palette for Mia Example App
 */
object MiaColors {
    // Primary colors
    val Primary = Color(0xFF6200EE)
    val Second = Color(0xFFD1BBF0)
    val Secondary = Color(0xFF03DAC6)
    
    // Background colors
    val Background = Color(0xFFF5F5F5)
    val Surface = Color.White
    val SidebarBackground = Color(0xFFF4F4F9)
    val CardBackground = Color(0xFFFBFAFF)
    val ConversationItemBackground = Color(0xFFE5E4EB)
    
    // Text colors
    val OnPrimary = Color.White
    val OnSecondary = Color.Black
    val OnBackground = Color.Black
    val OnSurface = Color.Black
    
    // Message colors
    val UserMessage = Color(0xFF027BFF)
    val BotMessage = Color(0xFFF4F4F9)
    
    // Status colors
    val AudioEnabled = Color(0xFF36C85A)
    val Recording = Color(0xFFE53935)
    val DeleteButton = Color(0xFFFF3B32)
    val HandsFreeEnabled = Color(0xFF027BFF)
    
    // Overlay colors
    val OverlayDim = Color.Black.copy(alpha = 0.3f)
    
    // Gradient colors (for buttons and avatars)
    val GradientStart = Color(0xFF03DAC6)
    val GradientEnd = Color(0xFF6200EE)
}

/**
 * Light color scheme for the app
 */
private val LightColorScheme = lightColorScheme(
    primary = MiaColors.Primary,
    secondary = MiaColors.Secondary,
    background = MiaColors.Background,
    surface = MiaColors.Surface,
    onPrimary = MiaColors.OnPrimary,
    onSecondary = MiaColors.OnSecondary,
    onBackground = MiaColors.OnBackground,
    onSurface = MiaColors.OnSurface,
)

/**
 * Main theme composable for Mia Example App
 */
@Composable
fun MiaExampleTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = LightColorScheme,
        content = content
    )
}

