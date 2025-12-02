package com.mia21.example.ui

/**
 * MiaApp.kt
 * Root composable that manages app-level state and navigation.
 * Handles loading screen, environment switching, and coordinates
 * between LoadingView and ChatView based on data loading state.
 */

import android.content.Intent
import androidx.activity.ComponentActivity
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.lifecycle.viewmodel.compose.viewModel
import com.mia21.Mia21Client
import com.mia21.example.MainActivity
import com.mia21.example.utils.EnvironmentPreferences
import com.mia21.example.viewmodels.LoadingViewModel
import com.mia21.models.Bot
import com.mia21.models.Space

@Composable
fun MiaApp(client: Mia21Client, userId: String, context: android.content.Context) {
    // Get current environment from preferences (client is already created with correct environment)
    var currentEnvironment by remember {
        mutableStateOf(EnvironmentPreferences.getEnvironment(context))
    }
    var isLoading by remember { mutableStateOf(true) }
    var spaces by remember { mutableStateOf<List<Space>>(emptyList()) }
    var selectedSpace by remember { mutableStateOf<Space?>(null) }
    var bots by remember { mutableStateOf<List<Bot>>(emptyList()) }
    var selectedBot by remember { mutableStateOf<Bot?>(null) }

    // Keep LoadingViewModel reference to observe background updates
    val loadingViewModel: LoadingViewModel = viewModel { LoadingViewModel(client) }
    val loadingResult by loadingViewModel.result.collectAsState()

    // Observe background loading updates even after ChatView is shown
    LaunchedEffect(loadingResult) {
        loadingResult?.let { result ->
            spaces = result.spaces
            selectedSpace = result.selectedSpace
            bots = result.bots
            selectedBot = result.selectedBot
        }
    }

    if (isLoading) {
        LoadingView(
            client = client,
            viewModel = loadingViewModel,
            onLoadComplete = { result ->
                spaces = result.spaces
                selectedSpace = result.selectedSpace
                bots = result.bots
                selectedBot = result.selectedBot
                isLoading = false
            }
        )
    } else {
        ChatView(
            client = client,
            spaces = spaces,
            selectedSpace = selectedSpace,
            bots = bots,
            selectedBot = selectedBot,
            currentEnvironment = currentEnvironment,
            onEnvironmentChanged = { newEnvironment ->
                // Save the new environment
                EnvironmentPreferences.setEnvironment(context, newEnvironment)
                // Restart the app to use the new environment
                val activity = context as? ComponentActivity
                if (activity != null) {
                    val intent = Intent(activity, MainActivity::class.java)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
                    activity.startActivity(intent)
                    activity.finish()
                }
            }
        )
    }
}
