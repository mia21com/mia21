//
//  ChatViewModel+HandsFree.swift
//  MiaSwiftUIExample
//
//  Created on November 27, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Hands-free mode delegate implementation for ChatViewModel.
//

import Foundation
import Mia21

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
      updateMessage(at: lastIndex, with: ChatMessage(text: text, isUser: true, timestamp: Date()))
      conversationHistory.append(Mia21.ChatMessage(role: .user, content: text))
      
      Task {
        setLoading(true)
        
        do {
          let typingIndicatorIndex = messages.count
          appendMessage(ChatMessage(text: "", isUser: false, timestamp: Date(), isTypingIndicator: true))
          audioManager.reset()
          
          if isVoiceEnabled {
            try await sendMessageWithVoice(text, typingIndicatorIndex: typingIndicatorIndex)
          } else {
            try await sendMessageTextOnly(text, typingIndicatorIndex: typingIndicatorIndex)
          }
        } catch {
          if messages.last?.isTypingIndicator == true {
            removeLastMessage()
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
    appendMessage(ChatMessage(text: "", isUser: true, timestamp: Date(), isProcessingAudio: true))
  }
  
  func hideAudioProcessingIndicator() {
    if let lastIndex = messages.lastIndex(where: { $0.isProcessingAudio }) {
      removeMessage(at: lastIndex)
    }
  }
  
  func replaceAudioProcessingWithMessage(_ text: String) {
    if let lastIndex = messages.lastIndex(where: { $0.isProcessingAudio }) {
      updateMessage(at: lastIndex, with: ChatMessage(text: text, isUser: true, timestamp: Date()))
      conversationHistory.append(Mia21.ChatMessage(role: .user, content: text))
    }
  }
  
  func sendMessageAfterTranscription(_ text: String) async {
    guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !isLoading else { return }
    setLoading(true)

    do {
      let typingIndicatorIndex = messages.count
      appendMessage(ChatMessage(text: "", isUser: false, timestamp: Date(), isTypingIndicator: true))
      audioManager.reset()

      if isVoiceEnabled {
        try await sendMessageWithVoice(text, typingIndicatorIndex: typingIndicatorIndex)
      } else {
        try await sendMessageTextOnly(text, typingIndicatorIndex: typingIndicatorIndex)
      }
    } catch {
      if messages.last?.isTypingIndicator == true {
        removeLastMessage()
      }
      showError("Failed to send message: \(error.localizedDescription)")
    }

    setLoading(false)
  }
}
