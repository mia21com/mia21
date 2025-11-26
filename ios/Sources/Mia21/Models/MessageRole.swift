//
//  MessageRole.swift
//  Mia21
//
//  Created on November 4, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Type-safe enumeration for chat message roles.
//

import Foundation

// MARK: - Message Role

public enum MessageRole: String, Codable {
  case user = "user"
  case assistant = "assistant"
  case system = "system"
}
