//
//  Errors.swift
//  Mia21
//
//  Created on November 4, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Custom error types for the Mia21 SDK.
//  Defines specific error cases for API operations,
//  networking, decoding, and chat management.
//

import Foundation

public enum Mia21Error: LocalizedError {
  case chatNotInitialized
  case invalidResponse
  case networkError(Error)
  case apiError(String)
  case decodingError(Error)
  case invalidURL
  case streamingError(String)
  case audioTranscriptionError(String)

  public var errorDescription: String? {
    switch self {
    case .chatNotInitialized:
      return "Chat not initialized. Call initialize() first."
    case .invalidResponse:
      return "Invalid response from server"
    case .networkError(let error):
      return "Network error: \(error.localizedDescription)"
    case .apiError(let message):
      return "API error: \(message)"
    case .decodingError(let error):
      return "Failed to decode response: \(error.localizedDescription)"
    case .invalidURL:
      return "Invalid URL"
    case .streamingError(let message):
      return "Streaming error: \(message)"
    case .audioTranscriptionError(let message):
      return "Audio transcription error: \(message)"
    }
  }
}
