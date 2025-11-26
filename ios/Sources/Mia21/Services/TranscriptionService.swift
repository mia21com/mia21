//
//  TranscriptionService.swift
//  Mia21
//
//  Created on November 4, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Service layer for speech-to-text transcription.
//  Handles audio file transcription using the STT API.
//

import Foundation

// MARK: - Transcription Service Protocol

protocol TranscriptionServiceProtocol {
  func transcribeAudio(audioData: Data, language: String?) async throws -> TranscriptionResponse
}

// MARK: - Transcription Service Implementation

final class TranscriptionService: TranscriptionServiceProtocol {

  // MARK: - Properties

  private let baseURL: String
  private let apiKey: String?
  private let timeout: TimeInterval
  private let session: URLSession

  // MARK: - Initialization

  init(baseURL: String, apiKey: String?, timeout: TimeInterval) {
    self.baseURL = baseURL
    self.apiKey = apiKey
    self.timeout = timeout

    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = timeout
    config.timeoutIntervalForResource = timeout * 2
    self.session = URLSession(configuration: config)
  }

  // MARK: - Public Methods

  func transcribeAudio(audioData: Data, language: String?) async throws -> TranscriptionResponse {
    let url = URL(string: "\(baseURL)/api/v1/stt/transcribe")!

    var request = URLRequest(url: url)
    request.httpMethod = "POST"

    if let apiKey = apiKey {
      request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
    }

    // Create multipart form data
    let boundary = "Boundary-\(UUID().uuidString)"
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

    var body = Data()

    // Add audio file
    body.append("--\(boundary)\r\n".data(using: .utf8)!)
    body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
    body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
    body.append(audioData)
    body.append("\r\n".data(using: .utf8)!)

    // Add language if provided
    if let language = language {
      body.append("--\(boundary)\r\n".data(using: .utf8)!)
      body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
      body.append("\(language)\r\n".data(using: .utf8)!)
    }

    body.append("--\(boundary)--\r\n".data(using: .utf8)!)
    request.httpBody = body

    logDebug("Transcription Request: POST \(url.absoluteString)")
    logDebug("Audio size: \(audioData.count) bytes")

    let (data, response) = try await session.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw Mia21Error.invalidResponse
    }

    logDebug("Response Status: \(httpResponse.statusCode)")

    guard (200...299).contains(httpResponse.statusCode) else {
      let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
      logError("Transcription error: HTTP \(httpResponse.statusCode): \(errorMessage)")
      throw Mia21Error.apiError("HTTP \(httpResponse.statusCode): \(errorMessage)")
    }

    let decoder = JSONDecoder()
    let transcriptionResponse = try decoder.decode(TranscriptionResponse.self, from: data)

    logInfo("Transcribed: \(transcriptionResponse.text)")
    return transcriptionResponse
  }
}
