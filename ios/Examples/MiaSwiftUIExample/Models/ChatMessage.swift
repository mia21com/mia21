//
//  ChatMessage.swift
//  MiaSwiftUIExample
//
//  Created on November 21, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Model representing a chat message in the UI with transient display states.
//

import Foundation

// MARK: - UI Chat Message Model

struct ChatMessage: Identifiable {
  let id = UUID()
  let text: String
  let isUser: Bool
  let timestamp: Date
  var isTypingIndicator: Bool = false
  var isStreaming: Bool = false
  var isProcessingAudio: Bool = false
  var collapseDoubleNewlines: Bool = false

  // Convert to storable format for persistence
  func toStoredMessage() -> StoredChatMessage {
    return StoredChatMessage(
      text: text,
      isUser: isUser,
      timestamp: timestamp
    )
  }
}

