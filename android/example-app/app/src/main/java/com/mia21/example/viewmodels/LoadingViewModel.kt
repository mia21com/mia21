package com.mia21.example.viewmodels

/**
 * LoadingViewModel.kt
 * ViewModel for the loading/splash screen.
 * Loads spaces and bots from the API during app initialization.
 * Provides loading state and error handling.
 */

import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.mia21.Mia21Client
import com.mia21.example.utils.Constants
import com.mia21.models.Bot
import com.mia21.models.Space
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeout
import kotlinx.coroutines.TimeoutCancellationException
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope

data class LoadingResult(
    val spaces: List<Space>,
    val selectedSpace: Space?,
    val bots: List<Bot>,
    val selectedBot: Bot?
)

class LoadingViewModel(private val client: Mia21Client) : ViewModel() {
    private val _isLoading = MutableStateFlow(true)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()
    
    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage: StateFlow<String?> = _errorMessage.asStateFlow()
    
    private val _result = MutableStateFlow<LoadingResult?>(null)
    val result: StateFlow<LoadingResult?> = _result.asStateFlow()
    
    fun loadData() {
        viewModelScope.launch {
            try {
                _isLoading.value = true
                _errorMessage.value = null
                
                Log.d(Constants.TAG, "Loading spaces and bots...")
                
                val spaces = try {
                    withTimeout(10_000L) {
                        client.listSpaces()
                    }
                } catch (e: TimeoutCancellationException) {
                    Log.w(Constants.TAG, "Loading spaces timed out after 10s, continuing in background")
                    launch {
                        try {
                            val bgSpaces = client.listSpaces()
                            val bgSelectedSpace = bgSpaces.firstOrNull()
                            _result.value = (_result.value ?: LoadingResult(
                                emptyList(), null, emptyList(), null
                            )).copy(
                                spaces = bgSpaces,
                                selectedSpace = bgSelectedSpace
                            )
                            Log.d(Constants.TAG, "Background loaded ${bgSpaces.size} spaces")
                        } catch (e: Exception) {
                            Log.e(Constants.TAG, "Background loading spaces failed", e)
                        }
                    }
                    emptyList()
                }
                
                val bots = try {
                    withTimeout(10_000L) {
                        client.listBots()
                    }
                } catch (e: TimeoutCancellationException) {
                    Log.w(Constants.TAG, "Loading bots timed out after 10s, continuing in background")
                    launch {
                        try {
                            val bgBots = client.listBots()
                            val bgSelectedBot = bgBots.firstOrNull { it.isDefault } ?: bgBots.firstOrNull()
                            _result.value = (_result.value ?: LoadingResult(
                                emptyList(), null, emptyList(), null
                            )).copy(
                                bots = bgBots,
                                selectedBot = bgSelectedBot
                            )
                            Log.d(Constants.TAG, "Background loaded ${bgBots.size} bots")
                        } catch (e: Exception) {
                            Log.e(Constants.TAG, "Background loading bots failed", e)
                        }
                    }
                    emptyList()
                }
                
                val selectedSpace = spaces.firstOrNull()
                val selectedBot = bots.firstOrNull { it.isDefault } ?: bots.firstOrNull()
                
                Log.d(Constants.TAG, "Loaded ${spaces.size} spaces and ${bots.size} bots")
                
                _result.value = LoadingResult(
                    spaces = spaces,
                    selectedSpace = selectedSpace,
                    bots = bots,
                    selectedBot = selectedBot
                )
            } catch (e: Exception) {
                Log.e(Constants.TAG, "Failed to load data", e)
                _errorMessage.value = "Failed to load: ${e.message}"
                
                _result.value = LoadingResult(
                    spaces = emptyList(),
                    selectedSpace = null,
                    bots = emptyList(),
                    selectedBot = null
                )
            } finally {
                _isLoading.value = false
            }
        }
    }
}

