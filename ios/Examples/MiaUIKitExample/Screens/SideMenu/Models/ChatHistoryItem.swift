//
//  ChatHistoryItem.swift
//  MiaUIKitExample
//
//  Created on November 20, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Model representing a chat history item with messages.
//

import Foundation

// MARK: - Chat History Item

struct ChatHistoryItem: Codable, Identifiable {
  let id: String
  let title: String
  let botId: String?
  var messages: [StoredChatMessage]
  let createdAt: Date
  let updatedAt: Date

  var messageCount: Int {
    messages.count
  }

  enum CodingKeys: String, CodingKey {
    case id, title
    case botId = "bot_id"
    case messages
    case createdAt = "created_at"
    case updatedAt = "updated_at"
  }
}
