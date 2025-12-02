package com.mia21.example.viewmodels

/**
 * SideMenuViewModel.kt
 * ViewModel for managing side menu state and operations.
 * Handles spaces, bots, and conversations loading, selection,
 * and deletion. Manages loading and error states for UI feedback.
 */

import android.content.Context
import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.mia21.Mia21Client
import com.mia21.example.R
import com.mia21.example.utils.Constants.TAG
import com.mia21.models.Bot
import com.mia21.models.ConversationSummary
import com.mia21.models.Space
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class SideMenuViewModel(private val client: Mia21Client) : ViewModel() {
    private val _spaces = MutableStateFlow<List<Space>>(emptyList())
    val spaces: StateFlow<List<Space>> = _spaces.asStateFlow()
    
    private val _bots = MutableStateFlow<List<Bot>>(emptyList())
    val bots: StateFlow<List<Bot>> = _bots.asStateFlow()
    
    private val _conversations = MutableStateFlow<List<ConversationSummary>>(emptyList())
    val conversations: StateFlow<List<ConversationSummary>> = _conversations.asStateFlow()
    
    private val _selectedSpace = MutableStateFlow<Space?>(null)
    val selectedSpace: StateFlow<Space?> = _selectedSpace.asStateFlow()
    
    private val _selectedBot = MutableStateFlow<Bot?>(null)
    val selectedBot: StateFlow<Bot?> = _selectedBot.asStateFlow()
    
    private val _selectedConversationId = MutableStateFlow<String?>(null)
    val selectedConversationId: StateFlow<String?> = _selectedConversationId.asStateFlow()
    
    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()
    
    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage: StateFlow<String?> = _errorMessage.asStateFlow()
    
    fun setInitialData(
        spaces: List<Space>,
        selectedSpace: Space?,
        bots: List<Bot>,
        selectedBot: Bot?
    ) {
        _spaces.value = spaces
        _selectedSpace.value = selectedSpace
        _bots.value = bots
        _selectedBot.value = selectedBot
    }
    
    fun loadInitialDataIfNeeded() {
        viewModelScope.launch {
            if (_spaces.value.isEmpty()) {
                loadSpaces()
                // Conversations are loaded when entering ChatView
            }
        }
    }
    
    fun loadSpaces() {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                _spaces.value = client.listSpaces()
                
                if (_selectedSpace.value == null && _spaces.value.isNotEmpty()) {
                    _selectedSpace.value = _spaces.value.first()
                }
                
                loadBots()
            } catch (e: Exception) {
                Log.e(TAG, "Failed to load spaces", e)
                _errorMessage.value = "Failed to load spaces: ${e.message}"
            } finally {
                _isLoading.value = false
            }
        }
    }
    
    fun loadBots() {
        viewModelScope.launch {
            try {
                _bots.value = client.listBots()
                
                if (_selectedBot.value == null) {
                    _selectedBot.value = _bots.value.firstOrNull { it.isDefault }
                        ?: _bots.value.firstOrNull()
                }
            } catch (e: Exception) {
                Log.e(TAG, "Failed to load bots", e)
                _bots.value = emptyList()
                _selectedBot.value = null
                _errorMessage.value = "Failed to load bots: ${e.message}"
            }
        }
    }
    
    fun loadConversations() {
        viewModelScope.launch {
            try {
                _conversations.value = client.listConversations(spaceId = null, limit = 50)
                Log.d(TAG, "Loaded ${_conversations.value.size} conversations")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to load conversations", e)
                _errorMessage.value = "Failed to load conversations: ${e.message}"
            }
        }
    }
    
    fun reloadConversationsAfterCreation() {
        viewModelScope.launch {
            delay(500)
            val previousCount = _conversations.value.size
            loadConversations()
            
            if (_conversations.value.size > previousCount) {
                Log.d(TAG, "New conversation detected in history")
            }
        }
    }
    
    fun selectSpace(space: Space) {
        _selectedSpace.value = space
        loadBots()
    }
    
    fun selectBot(bot: Bot) {
        _selectedBot.value = bot
    }
    
    fun selectConversation(conversationId: String) {
        _selectedConversationId.value = conversationId
    }
    
    fun clearConversationSelection() {
        _selectedConversationId.value = null
    }
    
    suspend fun deleteConversation(conversationId: String): Boolean {
        return try {
            client.deleteConversation(conversationId)
            _conversations.value = _conversations.value.filter { it.id != conversationId }
            
            if (_selectedConversationId.value == conversationId) {
                _selectedConversationId.value = null
            }
            
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to delete conversation", e)
            _errorMessage.value = "Failed to delete conversation: ${e.message}"
            false
        }
    }
    
    fun deleteConversationAsync(conversationId: String) {
        viewModelScope.launch {
            try {
                client.deleteConversation(conversationId)
                _conversations.value = _conversations.value.filter { it.id != conversationId }
                
                if (_selectedConversationId.value == conversationId) {
                    _selectedConversationId.value = null
                }
                
            } catch (e: Exception) {
                _errorMessage.value = "Failed to delete conversation: ${e.message}"
            }
        }
    }
    
    fun getSpaceDisplayName(context: Context): String {
        return _selectedSpace.value?.name ?: context.getString(R.string.select_space)
    }
    
    val spaceAvatarLetter: String
        get() = _selectedSpace.value?.name?.take(1)?.uppercase() ?: "S"
    
    fun getBotDisplayName(context: Context): String {
        return when {
            _bots.value.isEmpty() -> context.getString(R.string.no_bots_available)
            else -> _selectedBot.value?.name ?: context.getString(R.string.select_bot)
        }
    }

    fun clearError() {
        _errorMessage.value = null
    }
}

