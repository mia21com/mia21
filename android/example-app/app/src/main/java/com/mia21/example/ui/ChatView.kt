package com.mia21.example.ui

/**
 * ChatView.kt
 * Main chat interface composable.
 * Displays messages, handles streaming responses, manages side menu,
 * text input, voice recording, hands-free mode, and TTS audio reading.
 * Coordinates between ChatViewModel and SideMenuViewModel.
 */

import android.Manifest
import android.util.Log
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.gestures.scrollBy
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.VolumeOff
import androidx.compose.material.icons.automirrored.filled.VolumeUp
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.zIndex
import androidx.lifecycle.viewmodel.compose.viewModel
import com.mia21.Mia21Client
import com.mia21.example.R
import com.mia21.example.theme.MiaColors
import com.mia21.example.utils.AudioPlaybackManager
import com.mia21.example.utils.AudioRecorderManager
import com.mia21.example.utils.Constants
import com.mia21.example.utils.EnvironmentType
import com.mia21.example.utils.HandsFreeAudioManager
import com.mia21.example.utils.HandsFreeAudioManagerDelegate
import com.mia21.example.viewmodels.ChatViewModel
import com.mia21.example.viewmodels.SideMenuViewModel
import com.mia21.models.Bot
import com.mia21.models.MessageRole
import com.mia21.models.Mia21Environment
import com.mia21.models.Space
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ChatView(
    client: Mia21Client,
    spaces: List<Space>,
    selectedSpace: Space?,
    bots: List<Bot>,
    selectedBot: Bot?,
    currentEnvironment: EnvironmentType? = null,
    onEnvironmentChanged: ((EnvironmentType) -> Unit)? = null
) {
    val spaceId = selectedSpace?.spaceId ?: Constants.DEFAULT_SPACE_ID
    val botId = selectedBot?.botId
    val context = LocalContext.current

    var isSideMenuVisible by remember { mutableStateOf(false) }
    var inputText by remember { mutableStateOf("") }
    val listState = rememberLazyListState()
    val scope = rememberCoroutineScope()

    val isHandsFreeModeEnabled = remember { mutableStateOf(false) }
    var isAudioReaderEnabled by remember { mutableStateOf(false) }

    // Initialize hands-free audio manager first
    val handsFreeManager = remember {
        HandsFreeAudioManager(context, client)
    }
    
    // Initialize audio playback manager for voice streaming
    val audioPlaybackManager = remember { 
        AudioPlaybackManager(context).apply {
            // Connect to hands-free manager for coordination
            onBotDidStartSpeaking = {
                handsFreeManager.botDidStartSpeaking()
            }
            onBotDidStopSpeaking = {
                handsFreeManager.botDidStopSpeaking()
            }
        }
    }
    
    // Update hands-free active state in audio playback manager
    LaunchedEffect(isHandsFreeModeEnabled.value) {
        audioPlaybackManager.isHandsFreeActive = isHandsFreeModeEnabled.value
    }
    
    // Enable/disable audio playback based on user preference
    LaunchedEffect(isAudioReaderEnabled) {
        audioPlaybackManager.isEnabled = isAudioReaderEnabled
        if (!isAudioReaderEnabled) {
            audioPlaybackManager.stopAll()
        }
    }
    
    // Create chatViewModel after audioPlaybackManager is initialized
    val chatViewModel: ChatViewModel = viewModel(
        factory = object : androidx.lifecycle.ViewModelProvider.Factory {
            override fun <T : androidx.lifecycle.ViewModel> create(modelClass: Class<T>): T {
                return ChatViewModel(
                    context.applicationContext as android.app.Application,
                    client,
                    spaceId,
                    botId,
                    audioPlaybackManager
                ) as T
            }
        }
    )

    val sideMenuViewModel: SideMenuViewModel = viewModel(
        factory = object : androidx.lifecycle.ViewModelProvider.Factory {
            override fun <T : androidx.lifecycle.ViewModel> create(modelClass: Class<T>): T {
                return SideMenuViewModel(client).apply {
                    setInitialData(spaces, selectedSpace, bots, selectedBot)
                } as T
            }
        }
    )

    chatViewModel.onConversationCreated = {
        scope.launch {
            val currentConvId = chatViewModel.currentConversationId.value
            
            if (currentConvId != null) {
                sideMenuViewModel.selectConversation(currentConvId)
            }
            
            sideMenuViewModel.reloadConversationsAfterCreation()
        }
    }

    val messages by chatViewModel.messages.collectAsState()
    val isLoading by chatViewModel.isLoading.collectAsState()
    val isStreaming by chatViewModel.isStreaming.collectAsState()
    val isInitialized by chatViewModel.isInitialized.collectAsState()
    val currentConversationId by chatViewModel.currentConversationId.collectAsState()
    val errorMessage by chatViewModel.errorMessage.collectAsState()
    var localErrorMessage by remember { mutableStateOf<String?>(null) }
    
    // Update hands-free delegate to use chatViewModel
    LaunchedEffect(chatViewModel) {
        handsFreeManager.delegate = object : HandsFreeAudioManagerDelegate {
            override fun onSpeechDetected(text: String) {
                scope.launch {
                    if (text.trim().isNotEmpty()) {
                        chatViewModel.sendMessage(text.trim(), enableVoice = isAudioReaderEnabled)
                    }
                }
            }
            
            override fun onListeningStateChanged(isListening: Boolean) {
                // State is already tracked in handsFreeManager.isListening StateFlow
            }
            
            override fun onVoiceActivityChanged(isActive: Boolean) {
                // State is already tracked in handsFreeManager.isVoiceActive StateFlow
            }
            
            override fun onError(error: Exception) {
                scope.launch {
                    localErrorMessage = context.getString(
                        R.string.error_transcription_failed,
                        error.message ?: ""
                    )
                }
            }
            
            override fun onPermissionDenied() {
                scope.launch {
                    localErrorMessage = context.getString(R.string.error_microphone_permission_required)
                }
            }
        }
    }
    
    // Observe hands-free state
    val isHandsFreeListening by handsFreeManager.isListening.collectAsState()
    val isHandsFreeVoiceActive by handsFreeManager.isVoiceActive.collectAsState()
    
    
    // Start/stop hands-free mode
    LaunchedEffect(isHandsFreeModeEnabled.value) {
        if (isHandsFreeModeEnabled.value) {
            handsFreeManager.startHandsFreeMode()
        } else {
            handsFreeManager.stopHandsFreeMode()
        }
    }

    // Initialize audio recorder
    val audioRecorder = remember { AudioRecorderManager(context) }
    var isRecording by remember { mutableStateOf(false) }
    var isTranscribing by remember { mutableStateOf(false) }
    
    // Helper function to cleanup all audio/voice related state
    fun cleanupAudioAndVoice() {
        // Stop any recording
        if (isRecording) {
            audioRecorder.stopRecording()
            isRecording = false
        }
        isTranscribing = false
        
        // Stop audio playback
        audioPlaybackManager.stopAll()
        
        // Stop hands-free mode
        if (isHandsFreeModeEnabled.value) {
            handsFreeManager.stopHandsFreeMode()
            isHandsFreeModeEnabled.value = false
        }
        
        // Disable audio reader
        isAudioReaderEnabled = false
        
        Log.d(Constants.TAG, "Audio and voice state cleaned up")
    }

    // Keyboard controller and focus requester
    val keyboardController = LocalSoftwareKeyboardController.current
    val focusManager = LocalFocusManager.current
    val inputFocusRequester = remember { FocusRequester() }

    // Permission launcher for microphone
    val requestPermissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission()
    ) { isGranted: Boolean ->
        if (isGranted) {
            // Permission granted
            Log.d(Constants.TAG, "Microphone permission granted")
            
            if (isHandsFreeModeEnabled.value) {
                handsFreeManager.startHandsFreeMode()
                isAudioReaderEnabled = true
            } else if (!isRecording) {
            keyboardController?.hide()
            if (audioRecorder.startRecording()) {
                isRecording = true
                Log.d(Constants.TAG, "Recording started after permission grant")
            } else {
                localErrorMessage = context.getString(R.string.error_failed_to_start_recording)
                }
            }
        } else {
            // Permission denied
            Log.d(Constants.TAG, "Microphone permission denied")
            localErrorMessage = context.getString(R.string.error_microphone_permission_required)
            if (isHandsFreeModeEnabled.value) {
                isHandsFreeModeEnabled.value = false
            }
        }
    }

    // Track which message contents have been animated
    var animatedMessageHashes by remember { mutableStateOf<Set<Int>>(emptySet()) }

    // Track messages that were seen during streaming
    var messagesSeenDuringStreaming by remember { mutableStateOf<Set<Int>>(emptySet()) }

    var streamedMessageIndices by remember { mutableStateOf<Set<Int>>(emptySet()) }

    // Track messages seen during streaming
    LaunchedEffect(messages.size, isStreaming) {
        if (isStreaming && messages.isNotEmpty()) {
            val lastMessage = messages.last()
            if (lastMessage.role == MessageRole.ASSISTANT) {
                messagesSeenDuringStreaming =
                    messagesSeenDuringStreaming + lastMessage.content.hashCode()
            }
        }
    }

    // Reset when messages are cleared
    LaunchedEffect(messages.isEmpty()) {
        if (messages.isEmpty()) {
            animatedMessageHashes = emptySet()
            messagesSeenDuringStreaming = emptySet()
            streamedMessageIndices = emptySet()
        }
    }

    // Cleanup audio playback and hands-free manager on dispose
    DisposableEffect(Unit) {
        onDispose {
            audioPlaybackManager.cleanup()
            handsFreeManager.cleanup()
        }
    }

    // Load conversations and initialize chat when entering ChatView
    LaunchedEffect(Unit) {
        sideMenuViewModel.loadConversations()
        chatViewModel.initializeChat()
    }


    // Track user scrolling state
    var isUserScrolling by remember { mutableStateOf(false) }

    // Track previous streaming state to detect when streaming finishes
    var previousIsStreaming by remember { mutableStateOf(false) }

    // Flag to prevent scrolling when streaming just finished
    var justFinishedStreaming by remember { mutableStateOf(false) }

    LaunchedEffect(messages.size) {
        if (messages.isNotEmpty() && !isUserScrolling && !isStreaming && !justFinishedStreaming) {
            delay(100)
            val lastIndex = messages.size - 1
            scope.launch {
                listState.animateScrollToItem(lastIndex)
            }
        }
    }
    
    // Continuous auto-scroll during streaming to keep bottom visible
    LaunchedEffect(Unit) {
        while (true) {
            delay(16)
            
            if (isStreaming && messages.isNotEmpty() && !isUserScrolling) {
                val lastMessage = messages.lastOrNull()
                if (lastMessage != null && lastMessage.role == MessageRole.ASSISTANT) {
                    try {
                        val layoutInfo = listState.layoutInfo
                        if (layoutInfo.totalItemsCount == 0) continue
                        
                        val lastItemIndex = layoutInfo.totalItemsCount - 1
                        val lastVisibleItem = layoutInfo.visibleItemsInfo.lastOrNull()
                        
                        // Check if last item is visible
                        if (lastVisibleItem != null && lastVisibleItem.index == lastItemIndex) {
                            val itemBottom = lastVisibleItem.offset + lastVisibleItem.size
                            val viewportBottom = layoutInfo.viewportEndOffset
                            val scrollNeeded = itemBottom - viewportBottom
                            
                            if (scrollNeeded > 0) {
                                listState.scrollBy(scrollNeeded.toFloat())
                            }
                        } else if (lastVisibleItem == null || lastVisibleItem.index < lastItemIndex) {
                            listState.scrollToItem(lastItemIndex)
                        }
                    } catch (e: Exception) {
                        // Ignore scroll failures
                    }
                }
            }
        }
    }
    
    LaunchedEffect(isStreaming) {
        if (previousIsStreaming && !isStreaming && messages.isNotEmpty()) {
            justFinishedStreaming = true
            
            delay(200)
            if (!isUserScrolling) {
                scope.launch {
                    try {
                        val layoutInfo = listState.layoutInfo
                        val lastItem = layoutInfo.visibleItemsInfo.lastOrNull()
                        val lastIndex = messages.size - 1
                        
                        if (lastItem != null && lastItem.index == lastIndex) {
                            val itemBottom = lastItem.offset + lastItem.size
                            val viewportBottom = layoutInfo.viewportEndOffset
                            val scrollNeeded = itemBottom - viewportBottom
                            
                            if (scrollNeeded > 0) {
                                listState.scrollBy(scrollNeeded.toFloat())
                            }
                        }
                    } catch (e: Exception) {
                        // Ignore scroll failures
                    }
                    
                    // Clear the flag after a delay
                    delay(500)
                    justFinishedStreaming = false
                }
            }
        }
        previousIsStreaming = isStreaming
    }
    
    // Track last message index during streaming to maintain stable key
    LaunchedEffect(isStreaming, messages.size) {
        if (isStreaming && messages.isNotEmpty()) {
            val lastIndex = messages.size - 1
            if (!streamedMessageIndices.contains(lastIndex)) {
                streamedMessageIndices = streamedMessageIndices + lastIndex
            }
        }
    }
    
    // Track scroll state changes to detect user scrolling
    LaunchedEffect(listState.isScrollInProgress) {
        isUserScrolling = listState.isScrollInProgress
        if (!listState.isScrollInProgress) {
            delay(100)
        }
    }

    // Hide keyboard and unfocus input when side menu opens
    LaunchedEffect(isSideMenuVisible) {
        if (isSideMenuVisible) {
            keyboardController?.hide()
            focusManager.clearFocus()
        }
    }

    // Main chat content - shifts right when menu is open
    Box(modifier = Modifier.fillMaxSize()) {
        // Dimming overlay - clickable to close menu
        if (isSideMenuVisible) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(MiaColors.OverlayDim)
                    .clickable { isSideMenuVisible = false }
            )
        }

        // Side menu - slides in from left
        if (isSideMenuVisible) {
            SideMenuView(
                modifier = Modifier
                    .fillMaxHeight()
                    .zIndex(2f),
                isVisible = isSideMenuVisible,
                viewModel = sideMenuViewModel,
                onSpaceChanged = { space, bot ->
                    cleanupAudioAndVoice()
                    chatViewModel.currentSpaceId = space.spaceId
                    chatViewModel.currentBotId = bot?.botId
                    chatViewModel.clearChat()
                    isSideMenuVisible = false
                },
                onBotChanged = { bot ->
                    cleanupAudioAndVoice()
                    chatViewModel.currentBotId = bot.botId
                    chatViewModel.clearChat()
                    isSideMenuVisible = false
                },
                onNewChat = {
                    cleanupAudioAndVoice()
                    chatViewModel.clearChat()
                    isSideMenuVisible = false
                },
                onSelectChat = { conversationId ->
                    cleanupAudioAndVoice()
                    sideMenuViewModel.selectConversation(conversationId)
                    scope.launch {
                        chatViewModel.loadConversation(conversationId)
                    }
                    isSideMenuVisible = false
                },
                onDeleteCurrentChat = {
                    cleanupAudioAndVoice()
                    sideMenuViewModel.clearConversationSelection()
                    chatViewModel.clearChat()
                    isSideMenuVisible = false
                },
                currentConversationId = currentConversationId,
                onEnvironmentChanged = onEnvironmentChanged?.let { callback ->
                    { env ->
                        val newEnv = when (env) {
                            Mia21Environment.PRODUCTION -> EnvironmentType.Production()
                            Mia21Environment.STAGING -> EnvironmentType.Staging()
                        }
                        callback(newEnv)
                    }
                },
                currentEnvironment = currentEnvironment?.let {
                    when (it) {
                        is EnvironmentType.Production -> Mia21Environment.PRODUCTION
                        is EnvironmentType.Staging -> Mia21Environment.STAGING
                    }
                }
            )
        }

        // Main content - on top
        val density = LocalDensity.current
        var sidebarDragOffset by remember { mutableFloatStateOf(0f) }

        Scaffold(
            modifier = Modifier
                .fillMaxSize()
                .graphicsLayer {
                    val menuWidthPx = with(density) { 280.dp.toPx() }
                    translationX = if (isSideMenuVisible) {
                        (menuWidthPx + sidebarDragOffset).coerceAtMost(menuWidthPx)
                    } else {
                        0f
                    }
                }
                .pointerInput(isSideMenuVisible) {
                    if (isSideMenuVisible) {
                        detectHorizontalDragGestures(
                            onDragEnd = {
                                // If swiped left enough, close sidebar
                                if (sidebarDragOffset < -100) {
                                    isSideMenuVisible = false
                                }
                                sidebarDragOffset = 0f
                            }
                        ) { change, dragAmount ->
                            // Swiping left when sidebar is open
                            if (dragAmount < 0) {
                                sidebarDragOffset =
                                    (sidebarDragOffset + dragAmount).coerceAtLeast(-280f)
                            } else if (sidebarDragOffset < 0) {
                                // Swiping right to close the swipe
                                sidebarDragOffset =
                                    (sidebarDragOffset + dragAmount).coerceAtMost(0f)
                            }
                        }
                    }
                },
            topBar = {
                TopAppBar(
                    title = {
                        Text(
                            modifier = Modifier.fillMaxWidth(),
                            text = stringResource(R.string.app_title),
                            textAlign = TextAlign.Center
                        )
                    },
                    navigationIcon = {
                        IconButton(onClick = {
                            isSideMenuVisible = !isSideMenuVisible
                        }) {
                            Icon(
                                imageVector = Icons.Default.Menu,
                                contentDescription = stringResource(R.string.content_description_menu)
                            )
                        }
                    },
                    actions = {
                        IconButton(onClick = {
                            isAudioReaderEnabled = !isAudioReaderEnabled
                        }) {
                            if (isAudioReaderEnabled) {
                                Icon(
                                    imageVector = Icons.AutoMirrored.Filled.VolumeUp,
                                    contentDescription = stringResource(R.string.content_description_audio_reader),
                                    tint = MiaColors.AudioEnabled
                                )
                            } else {
                                Icon(
                                    imageVector = Icons.AutoMirrored.Filled.VolumeOff,
                                    contentDescription = stringResource(R.string.content_description_audio_reader),
                                    tint = MiaColors.OnSurface
                                )
                            }
                        }
                    },
                    colors = TopAppBarDefaults.topAppBarColors(
                        containerColor = MiaColors.SidebarBackground,
                        titleContentColor = MiaColors.OnSurface,
                        navigationIconContentColor = MiaColors.OnSurface,
                        actionIconContentColor = MiaColors.OnSurface
                    )
                )
            }
        ) { paddingValues ->
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues)
            ) {
                // Error message - auto-hide after 3 seconds
                (errorMessage ?: localErrorMessage)?.let { error ->
                    LaunchedEffect(error) {
                        delay(Constants.ERROR_AUTO_HIDE_DELAY_MS)
                        localErrorMessage = null
                        if (errorMessage != null) {
                            chatViewModel.clearError()
                        }
                    }

                    Surface(
                        color = MaterialTheme.colorScheme.errorContainer,
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable {
                                localErrorMessage = null
                                chatViewModel.clearError()
                            }
                    ) {
                        Text(
                            text = error,
                            color = MaterialTheme.colorScheme.onErrorContainer,
                            modifier = Modifier.padding(16.dp),
                            style = MaterialTheme.typography.bodyMedium
                        )
                    }
                }

                LazyColumn(
                    state = listState,
                    modifier = Modifier
                        .weight(1f)
                        .background(MiaColors.Surface)
                        .fillMaxWidth(),
                    contentPadding = PaddingValues(
                        horizontal = 16.dp, 
                        vertical = 8.dp
                    ),
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                    userScrollEnabled = true
                ) {
                    items(
                        count = messages.size,
                        key = { index ->
                            val msg = messages[index]
                            if (msg.role == MessageRole.ASSISTANT) {
                                "assistant_$index"
                            } else {
                            "${msg.role}_${msg.content.hashCode()}_$index"
                            }
                        }
                    ) { index ->
                        val message = messages[index]
                        val messageHash = message.content.hashCode()

                        val shouldAnimate = false

                        LaunchedEffect(shouldAnimate, messageHash) {
                            if (shouldAnimate) {
                                animatedMessageHashes = animatedMessageHashes + messageHash
                            }
                        }

                        MessageBubble(
                            message = message,
                            enableTypewriter = shouldAnimate
                        )
                    }
                }

                // Input area
                Surface(
                    modifier = Modifier
                        .fillMaxWidth()
                        .imePadding(),
                    shadowElevation = 8.dp,
                    color = MaterialTheme.colorScheme.surface
                ) {
                    ChatInputView(
                        inputText = inputText,
                        onInputTextChange = { inputText = it },
                        isLoading = isLoading || isTranscribing,
                        canSend = inputText.trim().isNotEmpty() && !isLoading && !isTranscribing && isInitialized,
                        isHandsFreeModeEnabled = isHandsFreeModeEnabled.value,
                        isHandsFreeListening = isHandsFreeListening,
                        isHandsFreeVoiceActive = isHandsFreeVoiceActive,
                        onSend = {
                            if (inputText.trim().isNotEmpty()) {
                                scope.launch {
                                    chatViewModel.sendMessage(inputText.trim(), enableVoice = isAudioReaderEnabled)
                                    inputText = ""
                                }
                            }
                        },
                        onHandsFreeTapped = {
                            val newValue = !isHandsFreeModeEnabled.value
                            // If activating hands-free mode
                            if (newValue) {
                                // Stop any active manual voice recording
                                if (isRecording) {
                                    audioRecorder.stopRecording()
                                    isRecording = false
                                }
                                
                                // Check for microphone permission
                                if (!handsFreeManager.hasPermission()) {
                                    // Request permission
                                    requestPermissionLauncher.launch(Manifest.permission.RECORD_AUDIO)
                                    return@ChatInputView
                                }
                                
                                isAudioReaderEnabled = true
                            }
                            
                            isHandsFreeModeEnabled.value = newValue
                        },
                        isRecording = isRecording,
                        isTranscribing = isTranscribing,
                        focusRequester = inputFocusRequester,
                        onFocusChanged = { isFocused ->
                            // Close side menu when text input is focused
                            if (isFocused && isSideMenuVisible) {
                                isSideMenuVisible = false
                            }
                            if (isFocused) {
                                scope.launch {
                                    delay(500)
                                    if (!isUserScrolling && messages.isNotEmpty()) {
                                        val lastIndex = messages.size - 1
                                        listState.animateScrollToItem(lastIndex)
                                    }
                                }
                            }
                        },
                        onRecordAudio = {
                            if (isRecording) {
                                // Stop recording
                                val audioData = audioRecorder.stopRecording()
                                isRecording = false

                                if (audioData != null && audioData.isNotEmpty()) {
                                    // Transcribe audio
                                    isTranscribing = true
                                    scope.launch {
                                        try {
                                            Log.d(
                                                Constants.TAG,
                                                "Starting transcription, audio size: ${audioData.size} bytes"
                                            )
                                            val response = client.transcribeAudio(audioData)
                                            val transcribedText = response.text.trim()
                                            Log.d(
                                                Constants.TAG,
                                                "Transcription result: '$transcribedText'"
                                            )

                                            if (transcribedText.isNotEmpty()) {
                                                // Append to existing text or set as new text
                                                inputText = if (inputText.isEmpty()) {
                                                    transcribedText
                                                } else {
                                                    "$inputText $transcribedText"
                                                }
                                                // Show keyboard and focus after text is added
                                                delay(Constants.KEYBOARD_DELAY_MS)
                                                inputFocusRequester.requestFocus()
                                                keyboardController?.show()
                                                // Scroll to bottom to ensure messages are visible after keyboard appears
                                                delay(400)
                                                if (messages.isNotEmpty() && !isUserScrolling) {
                                                    val lastIndex = messages.size - 1
                                                    listState.animateScrollToItem(lastIndex)
                                                }
                                            } else {
                                                localErrorMessage =
                                                    context.getString(R.string.error_no_text_detected)
                                            }
                                        } catch (e: Exception) {
                                            Log.e(Constants.TAG, "Transcription failed", e)
                                            localErrorMessage = context.getString(
                                                R.string.error_transcription_failed,
                                                e.message ?: ""
                                            )
                                        } finally {
                                            isTranscribing = false
                                        }
                                    }
                                } else {
                                    localErrorMessage =
                                        context.getString(R.string.error_no_audio_data)
                                }
                            } else {
                                // Start recording - check permission first
                                if (audioRecorder.hasPermission()) {
                                    Log.d(Constants.TAG, "Starting audio recording...")
                                    // Hide keyboard when starting to record
                                    keyboardController?.hide()
                                    if (audioRecorder.startRecording()) {
                                        isRecording = true
                                        Log.d(Constants.TAG, "Recording started successfully")
                                    } else {
                                        localErrorMessage =
                                            context.getString(R.string.error_failed_to_start_recording)
                                    }
                                } else {
                                    // Request permission
                                    Log.d(Constants.TAG, "Requesting microphone permission...")
                                    requestPermissionLauncher.launch(Manifest.permission.RECORD_AUDIO)
                                }
                            }
                        }
                    )
                }
            }
        }
    }
}