//
//  TranscriptionModels.swift
//  Mia21
//
//  Created on November 4, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Speech-to-text transcription models.
//  Includes transcription response with text, language, and duration.
//

import Foundation

// MARK: - Transcription Response

public struct TranscriptionResponse: Codable {
  public let text: String
  public let language: String?
  public let duration: Double?
  
  // Note: CodingKeys not needed - all properties match JSON keys exactly
}
