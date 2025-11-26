//
//  BotModels.swift
//  Mia21
//
//  Created on November 4, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Bot-related data models.
//  Includes bot information and creation requests.
//

import Foundation

// MARK: - Bot

public struct Bot: Codable, Identifiable {
  public let botId: String
  public let name: String
  public let prompt: String
  public let llmIdentifier: String
  public let temperature: Double
  public let maxTokens: Int
  public let language: String
  public let voiceId: String?
  public let isDefault: Bool
  public let customerId: String
  public let createdAt: String?
  public let updatedAt: String?
  
  // Computed property for Identifiable conformance
  public var id: String {
    return botId
  }
  
  // Note: No custom CodingKeys needed - APIClient uses .convertFromSnakeCase
  // snake_case from API (e.g., "bot_id") automatically maps to camelCase (e.g., botId)
}

// MARK: - Bots Response

public struct BotsResponse: Codable {
  public let bots: [Bot]
  public let count: Int
  
  // Note: No custom CodingKeys needed - APIClient uses .convertFromSnakeCase
}

// MARK: - Bot Create Request

public struct BotCreateRequest {
  public let botId: String
  public let name: String
  public let voiceId: String
  public let additionalPrompt: String?
  public let isDefault: Bool?

  public init(
    botId: String,
    name: String,
    voiceId: String,
    additionalPrompt: String? = nil,
    isDefault: Bool? = false
  ) {
    self.botId = botId
    self.name = name
    self.voiceId = voiceId
    self.additionalPrompt = additionalPrompt
    self.isDefault = isDefault
  }
}
