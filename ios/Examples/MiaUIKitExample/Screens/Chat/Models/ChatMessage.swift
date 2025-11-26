//
//  ChatMessage.swift
//  MiaUIKitExample
//
//  Created on November 4, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Model representing a chat message in the UI with transient display states.
//

import Foundation

// MARK: - UI Chat Message Model

struct ChatMessage {
  let text: String
  let isUser: Bool
  let timestamp: Date
  var isTypingIndicator: Bool = false
  var isStreaming: Bool = false
  var isProcessingAudio: Bool = false
  
  func toStoredMessage() -> StoredChatMessage {
    return StoredChatMessage(
      text: text,
      isUser: isUser,
      timestamp: timestamp
    )
  }
}

// MARK: - Stored Chat Message Model

struct StoredChatMessage: Codable {
  let text: String
  let isUser: Bool
  let timestamp: Date

  func toChatMessage() -> ChatMessage {
    return ChatMessage(
      text: text,
      isUser: isUser,
      timestamp: timestamp
    )
  }
}
