//
//  ChatHistoryItem.swift
//  MiaSwiftUIExample
//
//  Created on November 21, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Model representing a chat conversation entry in the side menu history.
//

import Foundation

struct ChatHistoryItem: Codable, Identifiable {
  let id: String
  let title: String
  let botId: String?
  var messages: [StoredChatMessage]
  let createdAt: Date
  let updatedAt: Date
  
  init(
    id: String = UUID().uuidString,
    title: String,
    botId: String? = nil,
    messages: [StoredChatMessage] = [],
    createdAt: Date = Date(),
    updatedAt: Date = Date()
  ) {
    self.id = id
    self.title = title
    self.botId = botId
    self.messages = messages
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
}

