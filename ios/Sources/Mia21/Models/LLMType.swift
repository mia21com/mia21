//
//  LLMType.swift
//  Mia21
//
//  Created on November 4, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Type-safe enumeration for LLM providers.
//

import Foundation

// MARK: - LLM Type

public enum LLMType: String, Codable {
  case openai = "openai"
  case gemini = "gemini"
}
