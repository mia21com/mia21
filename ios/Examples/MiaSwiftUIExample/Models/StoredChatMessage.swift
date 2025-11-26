//
//  StoredChatMessage.swift
//  MiaSwiftUIExample
//
//  Created on November 21, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Model representing a persisted chat message for storage and history.
//

import Foundation

// MARK: - Stored Chat Message Model

struct StoredChatMessage: Codable {
  let text: String
  let isUser: Bool
  let timestamp: Date
  
  // Convert to UI message for display
  func toChatMessage() -> ChatMessage {
    return ChatMessage(
      text: text,
      isUser: isUser,
      timestamp: timestamp
    )
  }
}

