//
//  SpaceModels.swift
//  Mia21
//
//  Created on November 4, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Space-related data models.
//  Includes space information and configuration.
//

import Foundation

// MARK: - Space

public struct Space: Codable {
  public let spaceId: String
  public let name: String
  public let prompt: String
  public let description: String
  public let generateFirstMessage: Bool
  public let bots: [Bot]
  public let isActive: Bool
  public let usageCount: Int
  public let createdAt: String
  public let updatedAt: String
  public let type: String
  
  // Note: No custom CodingKeys needed - APIClient uses .convertFromSnakeCase
  // snake_case from API (e.g., "space_id") automatically maps to camelCase (e.g., spaceId)
}

// MARK: - Space Configuration

public struct SpaceConfig: Codable {
  public let spaceId: String
  public let prompt: String
  public let description: String?
  public let llmIdentifier: String
  public let temperature: Double
  public let maxTokens: Int
  public let frequencyPenalty: Double?
  public let presencePenalty: Double?
  
  // Note: No custom CodingKeys needed - APIClient uses .convertFromSnakeCase

  public init(
    spaceId: String,
    prompt: String,
    description: String? = nil,
    llmIdentifier: String,
    temperature: Double = 0.7,
    maxTokens: Int = 1024,
    frequencyPenalty: Double? = nil,
    presencePenalty: Double? = nil
  ) {
    self.spaceId = spaceId
    self.prompt = prompt
    self.description = description
    self.llmIdentifier = llmIdentifier
    self.temperature = temperature
    self.maxTokens = maxTokens
    self.frequencyPenalty = frequencyPenalty
    self.presencePenalty = presencePenalty
  }
}
