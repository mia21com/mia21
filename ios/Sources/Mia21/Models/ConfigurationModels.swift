//
//  ConfigurationModels.swift
//  Mia21
//
//  Created on November 4, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Configuration and initialization models.
//  Includes response modes, initialization options, voice configuration,
//  and initialization responses.
//

import Foundation

// MARK: - Environment

public enum Mia21Environment {
  case production
  case staging
  case custom(String)
  
  public var baseURL: String {
    switch self {
    case .production:
      return "https://api.mia21.com"
    case .staging:
      return "https://api-staging.mia21.com"
    case .custom(let url):
      return url
    }
  }
}

// MARK: - Response Mode

public enum ResponseMode: String, Codable {
  case text = "text"
  case streamText = "stream_text"
  case streamVoice = "stream_voice"
  case streamVoiceOnly = "stream_voice_only"
}

// MARK: - Initialize Options

public struct InitializeOptions {
  public var spaceId: String?
  public var botId: String?
  public var llmType: LLMType?
  public var userName: String?
  public var language: String?
  public var generateFirstMessage: Bool
  public var incognitoMode: Bool
  public var customerLlmKey: String?
  public var spaceConfig: SpaceConfig?

  public init(
    spaceId: String? = nil,
    botId: String? = nil,
    llmType: LLMType? = .openai,
    userName: String? = nil,
    language: String? = nil,
    generateFirstMessage: Bool = true,
    incognitoMode: Bool = false,
    customerLlmKey: String? = nil,
    spaceConfig: SpaceConfig? = nil
  ) {
    self.spaceId = spaceId
    self.botId = botId
    self.llmType = llmType
    self.userName = userName
    self.language = language
    self.generateFirstMessage = generateFirstMessage
    self.incognitoMode = incognitoMode
    self.customerLlmKey = customerLlmKey
    self.spaceConfig = spaceConfig
  }
}

// MARK: - Initialize Response

public struct InitializeResponse: Codable {
  public let status: String
  public let userId: String
  public let message: String?
  public let spaceId: String?
  public let isNewUser: Bool?
  
  // Note: No custom CodingKeys needed - APIClient uses .convertFromSnakeCase
}

// MARK: - Voice Configuration

public struct VoiceConfig: Codable {
  public let enabled: Bool
  public let voiceId: String?
  public let elevenlabsApiKey: String?
  public let stability: Double?
  public let similarityBoost: Double?
  
  // Note: No custom CodingKeys needed - APIClient uses .convertFromSnakeCase

  public init(
    enabled: Bool,
    voiceId: String? = nil,
    elevenlabsApiKey: String? = nil,
    stability: Double? = nil,
    similarityBoost: Double? = nil
  ) {
    self.enabled = enabled
    self.voiceId = voiceId
    self.elevenlabsApiKey = elevenlabsApiKey
    self.stability = stability
    self.similarityBoost = similarityBoost
  }
}
