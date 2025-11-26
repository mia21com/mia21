//
//  Logging.swift
//  Mia21
//
//  Created on November 4, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Simple logging system with log levels.
//  Provides configurable logging for debugging and production use.
//

import Foundation

// MARK: - Log Level

public enum LogLevel: Int, Comparable {
  case none = 0
  case error = 1
  case warning = 2
  case info = 3
  case debug = 4

  public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
    lhs.rawValue < rhs.rawValue
  }
}

// MARK: - Logger

public protocol Logger {
  func log(_ level: LogLevel, _ message: String)
}

// MARK: - Default Logger

final class DefaultLogger: Logger {
  private let minLevel: LogLevel

  init(minLevel: LogLevel = .info) {
    self.minLevel = minLevel
  }

  func log(_ level: LogLevel, _ message: String) {
    guard level <= minLevel else { return }

    let prefix: String
    switch level {
    case .none:
      return
    case .error:
      prefix = "❌"
    case .warning:
      prefix = "⚠️"
    case .info:
      prefix = "ℹ️"
    case .debug:
      prefix = "🔍"
    }

    print("\(prefix) [Mia21] \(message)")
  }
}

// MARK: - Logger Manager

final class LoggerManager {
  static let shared = LoggerManager()

  private var logger: Logger
  private var minLevel: LogLevel

  private init() {
    self.minLevel = .info
    self.logger = DefaultLogger(minLevel: minLevel)
  }

  func setLogger(_ logger: Logger) {
    self.logger = logger
  }

  func setLogLevel(_ level: LogLevel) {
    self.minLevel = level
    if logger is DefaultLogger {
      // Recreate with new level
      self.logger = DefaultLogger(minLevel: level)
    }
  }

  func log(_ level: LogLevel, _ message: String) {
    logger.log(level, message)
  }
}

// MARK: - Logging Helpers

func logError(_ message: String) {
  LoggerManager.shared.log(.error, message)
}

func logWarning(_ message: String) {
  LoggerManager.shared.log(.warning, message)
}

func logInfo(_ message: String) {
  LoggerManager.shared.log(.info, message)
}

func logDebug(_ message: String) {
  LoggerManager.shared.log(.debug, message)
}
