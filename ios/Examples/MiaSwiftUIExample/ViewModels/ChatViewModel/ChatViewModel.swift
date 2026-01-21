//
//  ChatViewModel.swift
//  MiaSwiftUIExample
//
//  Created on November 7, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Core ViewModel managing chat business logic, including message handling,
//  chat initialization, and streaming API communication.
//

import Foundation
import Mia21
import AVFoundation
import Combine

struct TranscriptionResult: Equatable {
  let text: String
  let restoreKeyboard: Bool
}

@MainActor
final class ChatViewModel: ObservableObject {

  // MARK: - Published Properties
  
  @Published private(set) var messages: [ChatMessage] = []
  @Published private(set) var isLoading: Bool = false
  @Published private(set) var isChatInitialized: Bool = false
  @Published var currentError: AppError?
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
  @Published var transcriptionResult: TranscriptionResult?

  // MARK: - Internal Properties (accessible by extensions)
  
  let client: Mia21Client
  let audioManager: AudioPlaybackManager
  let handsFreeManager = HandsFreeAudioManager.shared
  lazy var audioRecorder = AudioRecorderManager()
  
  var currentSpaceId: String
  var currentBotId: String?
  private(set) var currentConversationId: String?
  var conversationHistory: [Mia21.ChatMessage] = []
  var textBeforeRecording: String = ""
  var wasKeyboardVisible: Bool = false
  
  // MARK: - Private Properties
  
  private var currentSessionId = UUID()
  private var isLoadingConversation = false
  let chunkDelay: TimeInterval = 0.02
  
  // MARK: - Callbacks
  
  var onConversationCreated: (() -> Void)?

  // MARK: - Initialization
  
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
  
  // MARK: - Setup Methods
  
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

  // MARK: - Chat Initialization
  
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

  // MARK: - Send Message
  
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

  // MARK: - Chat Management
  
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

    Task {
      try? await client.close(spaceId: currentSpaceId)
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

  // MARK: - History Methods
  
  func getMessagesForHistory() -> [StoredChatMessage] {
    return messages.compactMap { msg -> StoredChatMessage? in
      guard !msg.isTypingIndicator else { return nil }
      return msg.toStoredMessage()
    }
  }

  func getChatTitle() -> String {
    return messages.first(where: { $0.isUser })?.text ?? "New Chat"
  }
  
  // MARK: - Dynamic Prompting Example
  
  /// Example of using dynamic prompting - send a message with a custom system prompt
  /// This uses the OpenAI-compatible endpoint for runtime AI configuration
  func sendDynamicPromptMessage(_ text: String, systemPrompt: String) async {
    guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !isLoading else { return }
    
    addMessage(text: text, isUser: true)
    setLoading(true)
    
    do {
      // Build messages with custom system prompt
      let apiMessages = [
        Mia21.ChatMessage(role: .system, content: systemPrompt),
        Mia21.ChatMessage(role: .user, content: text)
      ]
      
      var fullResponse = ""
      
      // Add typing indicator
      messages.append(ChatMessage(text: "", isUser: false, timestamp: Date(), isTypingIndicator: true))
      let responseIndex = messages.count - 1
      
      // Stream the response using dynamic prompting
      try await client.streamComplete(
        messages: apiMessages,
        options: DynamicPromptOptions(
          model: "gpt-4o",
          spaceId: "dynamic-prompt-demo",
          temperature: 0.7
        )
      ) { [weak self] chunk in
        Task { @MainActor [weak self] in
          guard let self = self else { return }
          fullResponse += chunk
          
          // Update the message with streaming content
          if responseIndex < self.messages.count {
            self.messages[responseIndex] = ChatMessage(
              text: fullResponse,
              isUser: false,
              timestamp: Date()
            )
          }
        }
      }
      
    } catch {
      if messages.last?.isTypingIndicator == true || messages.last?.text.isEmpty == true {
        messages.removeLast()
      }
      showError("Dynamic prompt failed: \(error.localizedDescription)")
    }
    
    setLoading(false)
  }

  // MARK: - Internal Helper Methods
  
  func addMessage(text: String, isUser: Bool) {
    messages.append(ChatMessage(text: text, isUser: isUser, timestamp: Date()))
  }

  func setLoading(_ loading: Bool) {
    isLoading = loading
  }

  func showError(_ message: String) {
    currentError = AppError(message: message)
  }
  
  func appendMessage(_ message: ChatMessage) {
    messages.append(message)
  }
  
  func updateMessage(at index: Int, with message: ChatMessage) {
    guard index < messages.count else { return }
    messages[index] = message
  }
  
  func removeLastMessage() {
    messages.removeLast()
  }
  
  func removeMessage(at index: Int) {
    guard index < messages.count else { return }
    messages.remove(at: index)
  }
}
