//
//  StreamingModels.swift
//  Mia21
//
//  Created on November 4, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Streaming-related data models.
//  Includes stream events for text and audio streaming.
//

import Foundation

// MARK: - Stream Event

public enum StreamEvent {
  case text(String)
  case audio(Data)
  case textComplete
  case done(ChatResponse?)
  case error(Error)
}
