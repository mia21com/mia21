package com.mia21.example.viewmodels

/**
 * ChatViewModel.kt
 * ViewModel for managing chat state and operations.
 * Handles message streaming, chat initialization, conversation loading,
 * and error management. Coordinates with Mia21Client for API calls.
 */

import android.app.Application
import android.util.Log
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.mia21.Mia21Client
import com.mia21.example.R
import com.mia21.example.utils.Constants
import com.mia21.example.utils.Constants.DEFAULT_LANGUAGE
import com.mia21.example.utils.Constants.DEFAULT_USER_NAME
import com.mia21.models.ChatMessage
import com.mia21.models.ChatOptions
import com.mia21.models.InitializeOptions
import com.mia21.models.LLMType
import com.mia21.models.MessageRole
import com.mia21.models.StreamEvent
import com.mia21.models.VoiceConfig
import kotlinx.coroutines.TimeoutCancellationException
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeout
import java.util.UUID

class ChatViewModel(
    application: Application,
    private val client: Mia21Client,
    private var spaceId: String = Constants.DEFAULT_SPACE_ID,
    private var botId: String? = null,
    private val audioPlaybackManager: com.mia21.example.utils.AudioPlaybackManager? = null
) : AndroidViewModel(application) {

    private val _messages = MutableStateFlow<List<ChatMessage>>(emptyList())
    val messages: StateFlow<List<ChatMessage>> = _messages.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _isStreaming = MutableStateFlow(false)
    val isStreaming: StateFlow<Boolean> = _isStreaming.asStateFlow()

    private val _isInitialized = MutableStateFlow(false)
    val isInitialized: StateFlow<Boolean> = _isInitialized.asStateFlow()

    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage: StateFlow<String?> = _errorMessage.asStateFlow()

    private val _currentConversationId = MutableStateFlow<String?>(null)
    val currentConversationId: StateFlow<String?> = _currentConversationId.asStateFlow()

    private var currentSessionId = UUID.randomUUID()
    var isLoadingConversation = false

    var onConversationCreated: (() -> Unit)? = null

    var currentSpaceId: String
        get() = spaceId
        set(value) {
            spaceId = value
        }

    var currentBotId: String?
        get() = botId
        set(value) {
            botId = value
        }

    fun initializeChat() {
        viewModelScope.launch {
            val sessionId = UUID.randomUUID()
            currentSessionId = sessionId

            try {
                Log.d(Constants.TAG, "=== Initializing Mia Chat ===")
                Log.d(Constants.TAG, "Space ID: $spaceId")
                Log.d(Constants.TAG, "Bot ID: $botId")
                _isLoading.value = true
                _errorMessage.value = null

                Log.d(Constants.TAG, "Calling client.initialize() with 30s timeout...")
                val response = try {
                    withTimeout(Constants.INITIALIZE_TIMEOUT_MS) {
                        client.initialize(
                            InitializeOptions(
                                spaceId = spaceId,
                                botId = botId,
                                llmType = LLMType.GEMINI,
                                userName = DEFAULT_USER_NAME,
                                language = DEFAULT_LANGUAGE,
                                generateFirstMessage = true,
                                incognitoMode = false,
                                customerLlmKey = null,
                                spaceConfig = null
                            )
                        )
                    }
                } catch (e: TimeoutCancellationException) {
                    Log.e(Constants.TAG, "Initialize call timed out after 30 seconds", e)
                    val errorMsg = getApplication<Application>().getString(R.string.error_request_timed_out)
                    throw Exception(errorMsg)
                } catch (e: Exception) {
                    Log.e(Constants.TAG, "Exception during initialize call", e)
                    Log.e(Constants.TAG, "Exception stack trace:", e)
                    e.printStackTrace()
                    throw e
                }

                Log.d(Constants.TAG, "Initialize call completed")
                Log.d(Constants.TAG, "Response status: ${response.status}")
                Log.d(Constants.TAG, "Response message: ${response.message}")

                if (sessionId != currentSessionId) {
                    Log.d(Constants.TAG, "Session changed, ignoring response")
                    return@launch
                }

                _currentConversationId.value = response.conversationId

                response.message?.let { welcomeMessage ->
                    Log.d(Constants.TAG, "Adding welcome message: $welcomeMessage")
                    _messages.value = listOf(
                        ChatMessage(role = MessageRole.ASSISTANT, content = welcomeMessage)
                    )
                } ?: run {
                    Log.d(Constants.TAG, "No welcome message in response")
                }

                Log.d(Constants.TAG, "Calling onConversationCreated callback")
                onConversationCreated?.invoke()
                Log.d(Constants.TAG, "Initialization complete")
                _isInitialized.value = true

            } catch (e: Exception) {
                if (sessionId == currentSessionId) {
                    Log.e(Constants.TAG, "Failed to initialize", e)
                    Log.e(Constants.TAG, "Exception type: ${e.javaClass.simpleName}")
                    Log.e(Constants.TAG, "Exception message: ${e.message}")
                    e.printStackTrace()
                    val errorMsg = e.localizedMessage ?: e.message
                        ?: getApplication<Application>().getString(R.string.error_unknown)
                    _errorMessage.value = errorMsg
                } else {
                    Log.d(Constants.TAG, "Session changed, ignoring error")
                }
            } finally {
                Log.d(Constants.TAG, "Setting isLoading to false")
                _isLoading.value = false
            }
        }
    }

    fun loadConversation(conversationId: String) {
        viewModelScope.launch {
            currentSessionId = UUID.randomUUID()
            isLoadingConversation = true
            _isInitialized.value = false

            try {
                val conversation = client.getConversation(conversationId)
                _currentConversationId.value = conversationId

                _messages.value = emptyList()

                val loadedMessages = conversation.messages
                    .filter { it.role != "system" }
                    .map { message ->
                        val isUser = message.role == "user"
                        ChatMessage(
                            role = if (isUser) MessageRole.USER else MessageRole.ASSISTANT,
                            content = message.content
                        )
                    }

                _messages.value = loadedMessages
                spaceId = conversation.spaceId
                botId = conversation.botId
                _isInitialized.value = true

                delay(500)
                isLoadingConversation = false

            } catch (e: Exception) {
                isLoadingConversation = false
                Log.e(Constants.TAG, "Failed to load conversation", e)
                val errorMsg = getApplication<Application>().getString(
                    R.string.error_failed_to_load_conversation,
                    e.localizedMessage ?: e.message ?: ""
                )
                _errorMessage.value = errorMsg
            }
        }
    }

    fun clearChat() {
        currentSessionId = UUID.randomUUID()
        _messages.value = emptyList()
        _currentConversationId.value = null
        _isInitialized.value = false

        viewModelScope.launch {
            try {
                client.close(spaceId = spaceId)
            } catch (e: Exception) {
                Log.w(Constants.TAG, "Warning: Failed to close chat session: ${e.message}")
            }

            initializeChat()
        }
    }

    fun clearError() {
        _errorMessage.value = null
    }

    fun sendMessage(content: String, enableVoice: Boolean = false, voiceConfig: VoiceConfig? = null) {
        viewModelScope.launch {
            try {
                if (content.trim().isEmpty() || _isLoading.value) return@launch

                Log.d(Constants.TAG, "=== Sending message ===")
                _errorMessage.value = null

                // Add user message
                val userMessage = ChatMessage(role = MessageRole.USER, content = content)
                _messages.value = _messages.value + userMessage

                // Start streaming
                _isStreaming.value = true

                // Capture messages before streaming
                val messagesBeforeStream = _messages.value
                var botResponseContent = ""

                val options = ChatOptions(
                    spaceId = spaceId,
                    botId = botId,
                    conversationId = _currentConversationId.value
                )

                val finalVoiceConfig = if (enableVoice) {
                    voiceConfig ?: VoiceConfig(
                        enabled = true,
                        voiceId = "21m00Tcm4TlvDq8ikWAM", // Default voice ID
                        elevenlabsApiKey = null,
                        stability = 0.5,
                        similarityBoost = 0.75
                    )
                } else {
                    null
                }

                client.streamChatWithVoice(messagesBeforeStream, options, finalVoiceConfig)
                    .catch { exception ->
                        Log.e(Constants.TAG, "Stream error", exception)
                        val errorMsg = getApplication<Application>().getString(
                            R.string.error_stream_error,
                            exception.message ?: ""
                        )
                        _errorMessage.value = errorMsg
                        _isStreaming.value = false
                    }
                    .collect { event ->
                        when (event) {
                            is StreamEvent.Text -> {
                                val chunk = event.content
                                if (chunk.isNotEmpty() && !chunk.contains("[DONE]", ignoreCase = true)) {
                                    botResponseContent += chunk
                                    
                                    _messages.value = messagesBeforeStream + ChatMessage(
                                role = MessageRole.ASSISTANT,
                                content = botResponseContent
                            )
                                }
                            }
                            is StreamEvent.Audio -> {
                                audioPlaybackManager?.queueAudioChunk(event.audioData)
                                Log.d(Constants.TAG, "Received audio chunk: ${event.audioData.size} bytes")
                            }
                            is StreamEvent.TextComplete -> {
                                Log.d(Constants.TAG, "Text streaming completed")
                            }
                            is StreamEvent.Done -> {
                                Log.d(Constants.TAG, "Stream complete")
                                _isStreaming.value = false
                            }
                            is StreamEvent.Error -> {
                                Log.e(Constants.TAG, "Stream error event", event.exception)
                                val errorMsg = getApplication<Application>().getString(
                                    R.string.error_stream_error,
                                    event.exception.message ?: ""
                                )
                                _errorMessage.value = errorMsg
                                _isStreaming.value = false
                            }
                        }
                    }

            } catch (e: Exception) {
                Log.e(Constants.TAG, "Failed to send message", e)
                val errorMsg = getApplication<Application>().getString(
                    R.string.error_failed_to_send_message,
                    e.message ?: ""
                )
                _errorMessage.value = errorMsg
            } finally {
                _isStreaming.value = false
            }
        }
    }
}

