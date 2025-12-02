package com.mia21.example

/**
 * MainActivity.kt
 * Main entry point for the Mia Example App.
 * Initializes the Mia21Client with user ID and environment preferences,
 * sets up the theme, and displays the main app composable.
 */

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import com.mia21.Mia21Client
import com.mia21.example.theme.MiaExampleTheme
import com.mia21.example.ui.MiaApp
import com.mia21.example.utils.Constants
import com.mia21.example.utils.EnvironmentPreferences
import com.mia21.example.utils.UserPreferences


class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Set log level
        Mia21Client.setLogLevel(com.mia21.LogLevel.DEBUG)

        // Get or create user ID
        val userId = UserPreferences.getOrCreateUserId(this)

        // Get environment from preferences
        val environment = EnvironmentPreferences.getEnvironment(this)

        // Create client with the correct environment
        val client = Mia21Client(
            apiKey = Constants.API_KEY,
            userId = userId,
            environment = environment.toMia21Environment()
        )

        setContent {
            MiaExampleTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    MiaApp(client = client, userId = userId, context = this)
                }
            }
        }
    }
}
