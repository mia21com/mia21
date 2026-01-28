//
//  ChatViewModel.swift
//  MiaUIKitExample
//
//  Created on November 4, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  ViewModel managing chat business logic, including message handling,
//  chat initialization, and streaming API communication.
//

import Foundation
import Mia21
import AVFoundation

@MainActor
final class ChatViewModel: ObservableObject {

  @Published private(set) var messages: [ChatMessage] = []
  @Published private(set) var isLoading: Bool = false
  @Published private(set) var isChatInitialized: Bool = false
  @Published private(set) var errorMessage: String?
  @Published var isVoiceEnabled: Bool = false
  @Published var isHandsFreeModeEnabled: Bool = false
  /// Voice ID for per-request voice override (ElevenLabs voice ID).
  /// Priority: Request-level voiceId > Bot-level voice_id > Default
  /// Set to a test voice ID to verify it's passed to the API (e.g., "EXAVITQu4vr4xnSDxMaL" for Bella)
  var currentVoiceId: String? = "EXAVITQu4vr4xnSDxMaL"  // Test: Bella voice
  @Published var isHandsFreeListening: Bool = false
  @Published var isHandsFreeVoiceActive: Bool = false
  @Published var isRecording: Bool = false
  @Published var isTranscribing: Bool = false
  @Published var recordingStatusText: String = ""
  @Published var textFieldPlaceholder: String = "Message"

  private let client: Mia21Client
  private let audioManager: AudioPlaybackManager
  private let handsFreeManager = HandsFreeAudioManager.shared
  private lazy var audioRecorder = AudioRecorderManager()
  var currentSpaceId: String
  var currentBotId: String?
  var currentConversationId: String?
  var isLoadingConversation = false
  var textBeforeRecording: String = ""
  var wasKeyboardVisible: Bool = false
  
  private var currentSessionId = UUID()
  private var conversationHistory: [Mia21.ChatMessage] = []
  private let chunkDelay: TimeInterval = 0.02
  var onMessagesUpdated: (() -> Void)?
  var onScrollToBottom: (() -> Void)?
  var onConversationCreated: (() -> Void)?

  init(client: Mia21Client, audioManager: AudioPlaybackManager, spaceId: String = "default_space", botId: String? = nil) {
    self.client = client
    self.audioManager = audioManager
    self.currentSpaceId = spaceId
    self.currentBotId = botId
    audioManager.isEnabled = isVoiceEnabled
    
    setupHandsFreeMode()
    setupAudioManagerCallbacks()
    setupAudioRecorder()
  }
  
  private func setupHandsFreeMode() {
    handsFreeManager.delegate = self
    handsFreeManager.setTranscriptionClient(client)
  }
  
  private func setupAudioManagerCallbacks() {
    audioManager.onBotDidStartSpeaking = { [weak self] in
      Task { @MainActor [weak self] in
        self?.handsFreeManager.botDidStartSpeaking()
      }
    }
    
    audioManager.onBotDidStopSpeaking = { [weak self] in
      Task { @MainActor [weak self] in
        self?.handsFreeManager.botDidStopSpeaking()
      }
    }
  }
  
  private func setupAudioRecorder() {
    audioRecorder.onRecordingFinished = { [weak self] audioData in
      Task { @MainActor [weak self] in
        await self?.handleRecordingFinished(audioData: audioData)
      }
    }
    
    audioRecorder.onRecordingError = { [weak self] error in
      Task { @MainActor [weak self] in
        guard let self = self else { return }
        self.isRecording = false
        self.isTranscribing = false
        self.updateTextFieldState()
        self.showError("Recording failed: \(error.localizedDescription)")
      }
    }
  }

  func initializeChat() async {
    isChatInitialized = false
    let sessionId = UUID()
    currentSessionId = sessionId
    
    do {
      let response = try await client.initialize(
        options: InitializeOptions(
          spaceId: currentSpaceId,
          botId: currentBotId,
          timezone: TimeZone.current.identifier,  // Pass device timezone
          generateFirstMessage: true
        )
      )
      
      guard sessionId == currentSessionId else { return }
      
      currentConversationId = nil

      if let welcomeMessage = response.message {
        addMessage(text: welcomeMessage, isUser: false)
        conversationHistory.append(Mia21.ChatMessage(role: .assistant, content: welcomeMessage))
      }
      
      isChatInitialized = true
      onConversationCreated?()
    } catch {
      if sessionId == currentSessionId {
        showError(error.localizedDescription)
      }
    }
  }
  
  func loadConversation(_ conversationId: String) async {
    currentSessionId = UUID()
    isLoadingConversation = true
    
    do {
      let conversation = try await client.getConversation(conversationId: conversationId)
      currentConversationId = conversationId
      
      messages.removeAll()
      conversationHistory.removeAll()
      
      var loadedMessages: [ChatMessage] = []
      var loadedHistory: [Mia21.ChatMessage] = []
      
      for message in conversation.messages {
        guard message.role != "system" else { continue }
        
        let isUser = message.role == "user"
        loadedMessages.append(ChatMessage(text: message.content, isUser: isUser, timestamp: Date()))
        loadedHistory.append(Mia21.ChatMessage(
          role: isUser ? .user : .assistant,
          content: message.content
        ))
      }
      
      messages = loadedMessages
      conversationHistory = loadedHistory
      currentSpaceId = conversation.spaceId
      currentBotId = conversation.botId
      isChatInitialized = true
      onMessagesUpdated?()
      
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
        self?.isLoadingConversation = false
      }
    } catch {
      isLoadingConversation = false
      showError("Failed to load conversation: \(error.localizedDescription)")
    }
  }

  func sendMessage(_ text: String) async {
    guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !isLoading else { return }

    addMessage(text: text, isUser: true)
    conversationHistory.append(Mia21.ChatMessage(role: .user, content: text))
    setLoading(true)

    do {
      let typingIndicatorIndex = messages.count
      messages.append(ChatMessage(text: "", isUser: false, timestamp: Date(), isTypingIndicator: true))
      onMessagesUpdated?()
      onScrollToBottom?()
      audioManager.reset()

      if isVoiceEnabled {
        try await sendMessageWithVoice(text, typingIndicatorIndex: typingIndicatorIndex)
      } else {
        try await sendMessageTextOnly(text, typingIndicatorIndex: typingIndicatorIndex)
      }
    } catch {
      if messages.last?.isTypingIndicator == true {
        messages.removeLast()
      }
      showError("Failed to send message: \(error.localizedDescription)")
    }

    setLoading(false)
  }

  func clearChat() {
    currentSessionId = UUID()
    isChatInitialized = false
    messages.removeAll()
    conversationHistory.removeAll()
    currentConversationId = nil
    audioManager.stopAll()
    
    if isHandsFreeModeEnabled {
      handsFreeManager.stopHandsFreeMode()
      isHandsFreeModeEnabled = false
    }
    
    onMessagesUpdated?()

    Task {
      do {
        try await client.close(spaceId: currentSpaceId)
      } catch {
        print("Warning: Failed to close chat session: \(error.localizedDescription)")
      }
      
      await initializeChat()
    }
  }

  func toggleVoice() {
    isVoiceEnabled.toggle()
    audioManager.isEnabled = isVoiceEnabled
    if !isVoiceEnabled {
      audioManager.stopAll()
    }
  }
  
  func toggleHandsFreeMode() {
    if isHandsFreeModeEnabled {
      isHandsFreeModeEnabled = false
      handsFreeManager.stopHandsFreeMode()
      isVoiceEnabled = true
      audioManager.isEnabled = true
    } else {
      let permission = AVAudioSession.sharedInstance().recordPermission
      
      switch permission {
      case .granted:
        activateHandsFreeMode()
        
      case .undetermined:
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
          DispatchQueue.main.async {
            if granted {
              self?.activateHandsFreeMode()
            } else {
              self?.showError("Microphone access is required for hands-free mode. Please enable it in Settings.")
            }
          }
        }
        
      case .denied:
        showError("Microphone access is required for hands-free mode. Please enable it in Settings.")
        
      @unknown default:
        showError("Unable to access microphone.")
      }
    }
  }
  
  private func activateHandsFreeMode() {
    if !isVoiceEnabled {
      isVoiceEnabled = true
      audioManager.isEnabled = true
    }
    
    isHandsFreeModeEnabled = true
    handsFreeManager.startHandsFreeMode()
  }

  func getMessagesForHistory() -> [StoredChatMessage] {
    return messages.compactMap { msg -> StoredChatMessage? in
      guard !msg.isTypingIndicator else { return nil }
      return msg.toStoredMessage()
    }
  }

  func getChatTitle() -> String {
    return messages.first(where: { $0.isUser })?.text ?? "New Chat"
  }

  private func sendMessageTextOnly(_ text: String, typingIndicatorIndex: Int) async throws {
    var aiResponse = ""
    var displayedText = ""
    var isFirstChunk = true
    var animationTask: Task<Void, Never>?
    var streamComplete = false
    
    let llmType: LLMType = .openai
    let collapseDoubleNewlines = false

    let options = ChatOptions(
      spaceId: currentSpaceId,
      botId: currentBotId,
      conversationId: currentConversationId,
      llmType: llmType,
      voiceId: currentVoiceId  // Per-request voice override
    )

    try await client.streamChat(messages: conversationHistory, options: options) { [weak self] chunk in
      Task { @MainActor [weak self] in
        guard let self = self else { return }

        if isFirstChunk {
          isFirstChunk = false
          aiResponse = chunk
        } else {
          aiResponse += chunk
        }

        if animationTask == nil && typingIndicatorIndex < self.messages.count {
          animationTask = Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            while !Task.isCancelled {
              if displayedText.count < aiResponse.count {
                let nextIndex = displayedText.endIndex
                if nextIndex < aiResponse.endIndex {
                  let nextChar = String(aiResponse[nextIndex])
                  displayedText += nextChar
                  
                  if typingIndicatorIndex < self.messages.count {
                    self.messages[typingIndicatorIndex] = ChatMessage(
                      text: displayedText,
                      isUser: false,
                      timestamp: Date(),
                      isTypingIndicator: false,
                      isStreaming: true,
                      collapseDoubleNewlines: collapseDoubleNewlines
                    )
                    self.onMessagesUpdated?()
                  }
                  
                  try? await Task.sleep(nanoseconds: UInt64(self.chunkDelay * 1_000_000_000))
                } else {
                  try? await Task.sleep(nanoseconds: UInt64(self.chunkDelay * 1_000_000_000))
                }
              } else {
                if streamComplete {
                  break
                }
                try? await Task.sleep(nanoseconds: UInt64(self.chunkDelay * 1_000_000_000))
              }
            }
          }
        }
      }
    }

    streamComplete = true
    
    var finalText = aiResponse
    if let regex = try? NSRegularExpression(pattern: "\\n{3,}", options: []) {
      finalText = regex.stringByReplacingMatches(in: finalText, options: [], range: NSRange(location: 0, length: finalText.utf16.count), withTemplate: "\n\n")
    }
    if collapseDoubleNewlines {
      if let regex = try? NSRegularExpression(pattern: "\\n{2}", options: []) {
        finalText = regex.stringByReplacingMatches(in: finalText, options: [], range: NSRange(location: 0, length: finalText.utf16.count), withTemplate: "\n")
      }
    }
    
    while displayedText.count < aiResponse.count {
      try? await Task.sleep(nanoseconds: 100_000_000)
    }
    
    try? await Task.sleep(nanoseconds: 200_000_000)
    animationTask?.cancel()

    if typingIndicatorIndex < messages.count {
      messages[typingIndicatorIndex] = ChatMessage(
        text: finalText,
        isUser: false,
        timestamp: Date(),
        isTypingIndicator: false,
        isStreaming: false,
        collapseDoubleNewlines: collapseDoubleNewlines
      )
      conversationHistory.append(Mia21.ChatMessage(role: .assistant, content: finalText))
      onMessagesUpdated?()
    }
  }

  private func sendMessageWithVoice(_ text: String, typingIndicatorIndex: Int) async throws {
    var aiResponse = ""
    var displayedText = ""
    var isFirstChunk = true
    var animationTask: Task<Void, Never>?
    var streamComplete = false
    
    let llmType: LLMType = .openai
    let collapseDoubleNewlines = false

    // Use currentVoiceId if set, otherwise fall back to default voice
    let voiceConfig = VoiceConfig(
      enabled: true,
      voiceId: currentVoiceId ?? "21m00Tcm4TlvDq8ikWAM",
      elevenlabsApiKey: nil,
      stability: 0.5,
      similarityBoost: 0.75
    )

    let options = ChatOptions(
      spaceId: currentSpaceId,
      botId: currentBotId,
      conversationId: currentConversationId,
      llmType: llmType,
      voiceId: currentVoiceId  // Per-request voice override
    )

    audioManager.onFirstAudioStart = { [weak self] in
      guard let self = self else { return }
      
      if typingIndicatorIndex < self.messages.count {
        self.messages[typingIndicatorIndex] = ChatMessage(
          text: "",
          isUser: false,
          timestamp: Date(),
          isTypingIndicator: false,
          isStreaming: false
        )
        self.onMessagesUpdated?()
      }
      
      if animationTask == nil {
        animationTask = Task { @MainActor [weak self] in
          guard let self = self else { return }
          
          while !Task.isCancelled {
            if displayedText.count < aiResponse.count {
              let nextIndex = displayedText.endIndex
              if nextIndex < aiResponse.endIndex {
                let nextChar = String(aiResponse[nextIndex])
                displayedText += nextChar
                
                if typingIndicatorIndex < self.messages.count {
                  self.messages[typingIndicatorIndex] = ChatMessage(
                    text: displayedText,
                    isUser: false,
                    timestamp: Date(),
                    isTypingIndicator: false,
                    isStreaming: true,
                    collapseDoubleNewlines: collapseDoubleNewlines
                  )
                  self.onMessagesUpdated?()
                }
                
                try? await Task.sleep(nanoseconds: UInt64(self.chunkDelay * 1_000_000_000))
              } else {
                try? await Task.sleep(nanoseconds: UInt64(self.chunkDelay * 1_000_000_000))
              }
            } else {
              if streamComplete {
                break
              }
              try? await Task.sleep(nanoseconds: UInt64(self.chunkDelay * 1_000_000_000))
            }
          }
        }
      }
    }

    try await client.streamChatWithVoice(
      messages: conversationHistory,
      options: options,
      voiceConfig: voiceConfig
    ) { [weak self] event in
      Task { @MainActor [weak self] in
        guard let self = self else { return }

        switch event {
        case .text(let chunk):
          if isFirstChunk {
            isFirstChunk = false
            aiResponse = chunk
          } else {
            aiResponse += chunk
          }

        case .audio(let audioData):
          self.audioManager.queueAudioChunk(audioData)

        case .done:
          streamComplete = true
          
          var finalText = aiResponse
          if let regex = try? NSRegularExpression(pattern: "\\n{3,}", options: []) {
            finalText = regex.stringByReplacingMatches(in: finalText, options: [], range: NSRange(location: 0, length: finalText.utf16.count), withTemplate: "\n\n")
          }
          if collapseDoubleNewlines {
            if let regex = try? NSRegularExpression(pattern: "\\n{2}", options: []) {
              finalText = regex.stringByReplacingMatches(in: finalText, options: [], range: NSRange(location: 0, length: finalText.utf16.count), withTemplate: "\n")
            }
          }
          
          while displayedText.count < aiResponse.count {
            try? await Task.sleep(nanoseconds: 100_000_000)
          }
          
          try? await Task.sleep(nanoseconds: 200_000_000)
          animationTask?.cancel()
          
          if typingIndicatorIndex < self.messages.count {
            self.messages[typingIndicatorIndex] = ChatMessage(
              text: finalText,
              isUser: false,
              timestamp: Date(),
              isTypingIndicator: false,
              isStreaming: false,
              collapseDoubleNewlines: collapseDoubleNewlines
            )
            self.conversationHistory.append(Mia21.ChatMessage(role: .assistant, content: finalText))
            self.onMessagesUpdated?()
          }

        case .error(let error):
          throw Mia21Error.streamingError(error.localizedDescription)

        default:
          break
        }
      }
    }
  }

  private func addMessage(text: String, isUser: Bool) {
    messages.append(ChatMessage(text: text, isUser: isUser, timestamp: Date()))
    onMessagesUpdated?()
    onScrollToBottom?()
  }

  private func setLoading(_ loading: Bool) {
    isLoading = loading
  }

  private func showError(_ message: String) {
    errorMessage = message
  }
  
  // MARK: - Audio Recording Methods
  
  func checkMicrophonePermission() -> AVAudioSession.RecordPermission {
    return audioRecorder.checkPermission()
  }
  
  func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
    audioRecorder.requestPermission(completion: completion)
  }
  
  func startRecording(currentText: String, keyboardWasVisible: Bool) {
    textBeforeRecording = currentText
    wasKeyboardVisible = keyboardWasVisible
    audioRecorder.startRecordingDirectly()
    isRecording = true
    isTranscribing = false
    updateTextFieldState()
  }
  
  func stopRecording() {
    audioRecorder.stopRecording()
    isRecording = false
    isTranscribing = true
    updateTextFieldState()
  }
  
  var isRecordingOrTranscribing: Bool {
    return isRecording || isTranscribing
  }
  
  private func updateTextFieldState() {
    if isRecording {
      recordingStatusText = "Listening..."
      textFieldPlaceholder = ""
    } else if isTranscribing {
      recordingStatusText = "Transcribing..."
      textFieldPlaceholder = ""
    } else {
      recordingStatusText = ""
      textFieldPlaceholder = "Message"
    }
  }
  
  private func handleRecordingFinished(audioData: Data) async {
    do {
      let response = try await client.transcribeAudio(audioData: audioData)
      
      isRecording = false
      isTranscribing = false
      updateTextFieldState()
      
      guard !response.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
        resetRecordingState()
        return
      }
      
      let newText = response.text.trimmingCharacters(in: .whitespacesAndNewlines)
      let resultText: String
      if textBeforeRecording.isEmpty {
        resultText = newText
      } else {
        let separator = textBeforeRecording.hasSuffix(" ") ? "" : " "
        resultText = textBeforeRecording + separator + newText
      }
      
      // Notify controller of transcription result
      onTranscriptionCompleted?(resultText, wasKeyboardVisible)
      resetRecordingState()
      
    } catch {
      isRecording = false
      isTranscribing = false
      updateTextFieldState()
      showError("Transcription failed: \(error.localizedDescription)")
      onTranscriptionCompleted?(textBeforeRecording, false)
      resetRecordingState()
    }
  }
  
  private func resetRecordingState() {
    textBeforeRecording = ""
    wasKeyboardVisible = false
  }
  
  // Callbacks for controller
  var onTranscriptionCompleted: ((String, Bool) -> Void)?
}

// MARK: - HandsFreeAudioManagerDelegate

extension ChatViewModel: HandsFreeAudioManagerDelegate {
  func handsFreeDidStartListening() {
    isHandsFreeListening = true
  }
  
  func handsFreeDidStopListening() {
    isHandsFreeListening = false
  }
  
  func handsFreeDidDetectSpeech(_ text: String) {
    if let lastIndex = messages.lastIndex(where: { $0.isProcessingAudio }) {
      messages[lastIndex] = ChatMessage(text: text, isUser: true, timestamp: Date())
      conversationHistory.append(Mia21.ChatMessage(role: .user, content: text))
      onMessagesUpdated?()
      
      Task {
        setLoading(true)
        
        do {
          let typingIndicatorIndex = messages.count
          messages.append(ChatMessage(text: "", isUser: false, timestamp: Date(), isTypingIndicator: true))
          onMessagesUpdated?()
          onScrollToBottom?()
          audioManager.reset()
          
          if isVoiceEnabled {
            try await sendMessageWithVoice(text, typingIndicatorIndex: typingIndicatorIndex)
          } else {
            try await sendMessageTextOnly(text, typingIndicatorIndex: typingIndicatorIndex)
          }
        } catch {
          if messages.last?.isTypingIndicator == true {
            messages.removeLast()
          }
          showError("Failed to send message: \(error.localizedDescription)")
        }
        
        setLoading(false)
      }
    } else {
      Task {
        await sendMessage(text)
      }
    }
  }
  
  func handsFreeDidFailWithError(_ error: Error) {
    showError("Hands-free error: \(error.localizedDescription)")
  }
  
  func handsFreeVoiceActivityChanged(_ isActive: Bool) {
    isHandsFreeVoiceActive = isActive
  }
  
  func handsFreeDidStartRecordingChunk() {}
  
  func handsFreeDidFinishRecordingChunk(duration: TimeInterval) {
    showAudioProcessingIndicator()
  }
  
  func handsFreePermissionDenied() {}
  
  func showAudioProcessingIndicator() {
    if let lastMessage = messages.last, lastMessage.isProcessingAudio {
      return
    }
    
    messages.append(ChatMessage(text: "", isUser: true, timestamp: Date(), isProcessingAudio: true))
    onMessagesUpdated?()
    onScrollToBottom?()
  }
  
  func hideAudioProcessingIndicator() {
    if let lastIndex = messages.lastIndex(where: { $0.isProcessingAudio }) {
      messages.remove(at: lastIndex)
      onMessagesUpdated?()
    }
  }
  
  func replaceAudioProcessingWithMessage(_ text: String) {
    if let lastIndex = messages.lastIndex(where: { $0.isProcessingAudio }) {
      messages[lastIndex] = ChatMessage(text: text, isUser: true, timestamp: Date())
      conversationHistory.append(Mia21.ChatMessage(role: .user, content: text))
      onMessagesUpdated?()
    }
  }
  
  func sendMessageAfterTranscription(_ text: String) async {
    guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !isLoading else { return }
    setLoading(true)

    do {
      let typingIndicatorIndex = messages.count
      messages.append(ChatMessage(text: "", isUser: false, timestamp: Date(), isTypingIndicator: true))
      onMessagesUpdated?()
      onScrollToBottom?()
      audioManager.reset()

      if isVoiceEnabled {
        try await sendMessageWithVoice(text, typingIndicatorIndex: typingIndicatorIndex)
      } else {
        try await sendMessageTextOnly(text, typingIndicatorIndex: typingIndicatorIndex)
      }
    } catch {
      if messages.last?.isTypingIndicator == true {
        messages.removeLast()
      }
      showError("Failed to send message: \(error.localizedDescription)")
    }

    setLoading(false)
  }
}
