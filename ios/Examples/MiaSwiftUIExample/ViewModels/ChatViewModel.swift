//
//  ChatViewModel.swift
//  MiaSwiftUIExample
//
//  Created on November 7, 2025.
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
  @Published private(set) var errorMessage: String?
  @Published var isVoiceEnabled: Bool = false
  @Published var isHandsFreeModeEnabled: Bool = false
  @Published var isHandsFreeListening: Bool = false
  @Published var isHandsFreeVoiceActive: Bool = false
  @Published var isTranscribing: Bool = false

  private let client: Mia21Client
  private let audioManager: AudioPlaybackManager
  private let handsFreeManager = HandsFreeAudioManager.shared
  var currentSpaceId: String
  var currentBotId: String?
  var currentConversationId: String?
  var isLoadingConversation = false
  
  private var currentSessionId = UUID()
  private var conversationHistory: [Mia21.ChatMessage] = []
  private let chunkDelay: TimeInterval = 0.02
  var onConversationCreated: (() -> Void)?

  init(client: Mia21Client, audioManager: AudioPlaybackManager, spaceId: String = "default_space", botId: String? = nil) {
    self.client = client
    self.audioManager = audioManager
    self.currentSpaceId = spaceId
    self.currentBotId = botId
    audioManager.isEnabled = isVoiceEnabled
    
    setupHandsFreeMode()
    setupAudioManagerCallbacks()
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

  func initializeChat() async {
    let sessionId = UUID()
    currentSessionId = sessionId
    
    do {
      let response = try await client.initialize(
        options: InitializeOptions(
          spaceId: currentSpaceId,
          botId: currentBotId,
          generateFirstMessage: true
        )
      )
      
      guard sessionId == currentSessionId else { return }
      
      currentConversationId = nil

      if let welcomeMessage = response.message {
        addMessage(text: welcomeMessage, isUser: false)
        conversationHistory.append(Mia21.ChatMessage(role: .assistant, content: welcomeMessage))
      }
      
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
      
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
        self?.isLoadingConversation = false
      }
    } catch {
      isLoadingConversation = false
      showError("Failed to load conversation: \(error.localizedDescription)")
    }
  }

  func setInitialData(spaceId: String, botId: String?) {
    currentSpaceId = spaceId
    currentBotId = botId
  }

  func sendMessage(_ text: String) async {
    guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !isLoading else { return }

    addMessage(text: text, isUser: true)
    conversationHistory.append(Mia21.ChatMessage(role: .user, content: text))
    setLoading(true)

    do {
      let typingIndicatorIndex = messages.count
      messages.append(ChatMessage(text: "", isUser: false, timestamp: Date(), isTypingIndicator: true))
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
    messages.removeAll()
    conversationHistory.removeAll()
    currentConversationId = nil
    audioManager.stopAll()
    
    if isHandsFreeModeEnabled {
      handsFreeManager.stopHandsFreeMode()
      isHandsFreeModeEnabled = false
    }

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

    let options = ChatOptions(
      spaceId: currentSpaceId,
      botId: currentBotId,
      conversationId: currentConversationId
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
                      isStreaming: false
                    )
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

    while displayedText.count < aiResponse.count {
      try? await Task.sleep(nanoseconds: 100_000_000)
    }

    try? await Task.sleep(nanoseconds: 200_000_000)
    animationTask?.cancel()

    if typingIndicatorIndex < messages.count {
      conversationHistory.append(Mia21.ChatMessage(role: .assistant, content: aiResponse))
    }
  }

  private func sendMessageWithVoice(_ text: String, typingIndicatorIndex: Int) async throws {
    var aiResponse = ""
    var displayedText = ""
    var isFirstChunk = true
    var animationTask: Task<Void, Never>?
    var streamComplete = false

    let voiceConfig = VoiceConfig(
      enabled: true,
      voiceId: "21m00Tcm4TlvDq8ikWAM",
      elevenlabsApiKey: nil,
      stability: 0.5,
      similarityBoost: 0.75
    )

    let options = ChatOptions(
      spaceId: currentSpaceId,
      botId: currentBotId,
      conversationId: currentConversationId
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
                    isStreaming: false
                  )
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

          while displayedText.count < aiResponse.count {
            try? await Task.sleep(nanoseconds: 100_000_000)
          }

          try? await Task.sleep(nanoseconds: 200_000_000)
          animationTask?.cancel()

          if typingIndicatorIndex < self.messages.count {
            self.conversationHistory.append(Mia21.ChatMessage(role: .assistant, content: aiResponse))
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
  }

  private func setLoading(_ loading: Bool) {
    isLoading = loading
  }

  private func showError(_ message: String) {
    errorMessage = message
  }
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
      
      Task {
        setLoading(true)
        
        do {
          let typingIndicatorIndex = messages.count
          messages.append(ChatMessage(text: "", isUser: false, timestamp: Date(), isTypingIndicator: true))
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
  }
  
  func hideAudioProcessingIndicator() {
    if let lastIndex = messages.lastIndex(where: { $0.isProcessingAudio }) {
      messages.remove(at: lastIndex)
    }
  }
  
  func replaceAudioProcessingWithMessage(_ text: String) {
    if let lastIndex = messages.lastIndex(where: { $0.isProcessingAudio }) {
      messages[lastIndex] = ChatMessage(text: text, isUser: true, timestamp: Date())
      conversationHistory.append(Mia21.ChatMessage(role: .user, content: text))
    }
  }
  
  func sendMessageAfterTranscription(_ text: String) async {
    guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !isLoading else { return }
    setLoading(true)

    do {
      let typingIndicatorIndex = messages.count
      messages.append(ChatMessage(text: "", isUser: false, timestamp: Date(), isTypingIndicator: true))
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
