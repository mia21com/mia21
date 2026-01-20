//
//  ChatViewModel+Audio.swift
//  MiaSwiftUIExample
//
//  Created on November 27, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Audio recording, transcription, and voice streaming extension for ChatViewModel.
//

import Foundation
import AVFoundation
import Mia21

// MARK: - Audio Recording

extension ChatViewModel {
  
  func setupAudioRecorder() {
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
        self.showError("Recording failed: \(error.localizedDescription)")
      }
    }
    
    audioRecorder.onPermissionDenied = { [weak self] in
      Task { @MainActor [weak self] in
        self?.showError("Please enable microphone access in Settings to record voice messages.")
      }
    }
  }
  
  func checkMicrophonePermission() -> AVAudioSession.RecordPermission {
    return audioRecorder.checkPermission()
  }
  
  func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
    audioRecorder.requestPermission(completion: completion)
  }
  
  func startRecording(currentText: String, keyboardWasVisible: Bool) {
    let permission = checkMicrophonePermission()
    
    switch permission {
    case .undetermined:
      requestMicrophonePermission { [weak self] granted in
        if granted {
          self?.startRecording(currentText: currentText, keyboardWasVisible: keyboardWasVisible)
        }
      }
      return
      
    case .denied:
      showError("Please enable microphone access in Settings to record voice messages.")
      return
      
    case .granted:
      break
      
    @unknown default:
      break
    }
    
    textBeforeRecording = currentText
    wasKeyboardVisible = keyboardWasVisible
    audioRecorder.startRecordingDirectly()
    isRecording = true
    isTranscribing = false
  }
  
  func stopRecording() {
    audioRecorder.stopRecording()
    isRecording = false
    isTranscribing = true
  }
  
  var isRecordingOrTranscribing: Bool {
    return isRecording || isTranscribing
  }
  
  func handleRecordingFinished(audioData: Data) async {
    do {
      let response = try await client.transcribeAudio(audioData: audioData)
      
      isRecording = false
      isTranscribing = false
      
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
      
      transcriptionResult = TranscriptionResult(text: resultText, restoreKeyboard: wasKeyboardVisible)
      resetRecordingState()
      
    } catch {
      isRecording = false
      isTranscribing = false
      showError("Transcription failed: \(error.localizedDescription)")
      transcriptionResult = TranscriptionResult(text: textBeforeRecording, restoreKeyboard: false)
      resetRecordingState()
    }
  }
  
  func resetRecordingState() {
    textBeforeRecording = ""
    wasKeyboardVisible = false
  }
}

// MARK: - Voice Streaming

extension ChatViewModel {
  
  func sendMessageTextOnly(_ text: String, typingIndicatorIndex: Int) async throws {
    var aiResponse = ""
    var displayedText = ""
    var isFirstChunk = true
    var animationTask: Task<Void, Never>?
    var streamComplete = false
    
    let llmType: LLMType = .gemini
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
                    self.updateMessage(at: typingIndicatorIndex, with: ChatMessage(
                      text: displayedText,
                      isUser: false,
                      timestamp: Date(),
                      isTypingIndicator: false,
                      isStreaming: true,
                      collapseDoubleNewlines: collapseDoubleNewlines
                    ))
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
      self.updateMessage(at: typingIndicatorIndex, with: ChatMessage(
        text: finalText,
        isUser: false,
        timestamp: Date(),
        isTypingIndicator: false,
        isStreaming: false,
        collapseDoubleNewlines: collapseDoubleNewlines
      ))
      conversationHistory.append(Mia21.ChatMessage(role: .assistant, content: finalText))
    }
  }

  func sendMessageWithVoice(_ text: String, typingIndicatorIndex: Int) async throws {
    var aiResponse = ""
    var displayedText = ""
    var isFirstChunk = true
    var animationTask: Task<Void, Never>?
    var streamComplete = false
    
    let llmType: LLMType = .gemini
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
        self.updateMessage(at: typingIndicatorIndex, with: ChatMessage(
          text: "",
          isUser: false,
          timestamp: Date(),
          isTypingIndicator: false,
          isStreaming: false
        ))
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
                  self.updateMessage(at: typingIndicatorIndex, with: ChatMessage(
                    text: displayedText,
                    isUser: false,
                    timestamp: Date(),
                    isTypingIndicator: false,
                    isStreaming: true,
                    collapseDoubleNewlines: collapseDoubleNewlines
                  ))
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
            self.updateMessage(at: typingIndicatorIndex, with: ChatMessage(
              text: finalText,
              isUser: false,
              timestamp: Date(),
              isTypingIndicator: false,
              isStreaming: false,
              collapseDoubleNewlines: collapseDoubleNewlines
            ))
            self.conversationHistory.append(Mia21.ChatMessage(role: .assistant, content: finalText))
          }

        case .error(let error):
          throw Mia21Error.streamingError(error.localizedDescription)

        default:
          break
        }
      }
    }
  }
}

