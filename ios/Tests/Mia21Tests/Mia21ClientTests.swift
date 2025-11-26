//
//  Mia21ClientTests.swift
//  Mia21Tests
//
//  Created on November 4, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Basic unit tests for Mia21Client initialization and model creation.

import XCTest
@testable import Mia21

final class Mia21ClientTests: XCTestCase {

  var client: Mia21Client!

  override func setUp() {
    super.setUp()
    // Use test API key or mock
    client = Mia21Client(
      apiKey: "test-api-key",
      environment: .production
    )
  }

  override func tearDown() {
    client = nil
    super.tearDown()
  }

  // MARK: - Initialization Tests

  func testClientInitialization() {
    XCTAssertNotNil(client)
  }

  func testClientInitializationWithCustomUserId() {
    let customClient = Mia21Client(
      apiKey: "test-key",
      userId: "custom-user-123"
    )
    XCTAssertNotNil(customClient)
  }

  func testClientInitializationWithBYOK() {
    let byokClient = Mia21Client(
      customerLlmKey: "test-openai-key"
    )
    XCTAssertNotNil(byokClient)
  }

  func testClientInitializationWithEnvironment() {
    let stagingClient = Mia21Client(
      apiKey: "test-key",
      environment: .staging
    )
    XCTAssertNotNil(stagingClient)
  }

  func testClientInitializationWithTimeout() {
    let customClient = Mia21Client(
      apiKey: "test-key",
      userId: "custom-user",
      timeout: 120.0
    )
    XCTAssertNotNil(customClient)
  }

  // MARK: - Model Tests

  func testChatMessageCreation() {
    let message = ChatMessage(role: .user, content: "Hello")
    XCTAssertEqual(message.role, .user)
    XCTAssertEqual(message.content, "Hello")
  }

  func testInitializeOptionsDefaults() {
    let options = InitializeOptions()
    XCTAssertNil(options.spaceId)
    XCTAssertEqual(options.llmType, .openai)
    XCTAssertTrue(options.generateFirstMessage)
    XCTAssertFalse(options.incognitoMode)
  }

  func testInitializeOptionsCustomization() {
    let options = InitializeOptions(
      spaceId: "test-space",
      llmType: .gemini,
      userName: "Test User",
      generateFirstMessage: false
    )

    XCTAssertEqual(options.spaceId, "test-space")
    XCTAssertEqual(options.llmType, .gemini)
    XCTAssertEqual(options.userName, "Test User")
    XCTAssertFalse(options.generateFirstMessage)
  }

  func testChatOptionsDefaults() {
    let options = ChatOptions()
    XCTAssertNil(options.spaceId)
    XCTAssertNil(options.temperature)
    XCTAssertNil(options.maxTokens)
  }

  func testSpaceConfigCreation() {
    let config = SpaceConfig(
      spaceId: "custom-bot",
      prompt: "You are a helpful assistant",
      llmIdentifier: "gpt-4o",
      temperature: 0.8,
      maxTokens: 2048
    )

    XCTAssertEqual(config.spaceId, "custom-bot")
    XCTAssertEqual(config.temperature, 0.8)
    XCTAssertEqual(config.maxTokens, 2048)
  }

  func testBotCreateRequest() {
    let request = BotCreateRequest(
      botId: "sales-bot",
      name: "Sales Assistant",
      voiceId: "voice-123",
      additionalPrompt: "Be professional"
    )

    XCTAssertEqual(request.botId, "sales-bot")
    XCTAssertEqual(request.name, "Sales Assistant")
    XCTAssertEqual(request.voiceId, "voice-123")
    XCTAssertEqual(request.additionalPrompt, "Be professional")
  }

  // MARK: - Error Tests

  func testMia21ErrorDescriptions() {
    let notInitialized = Mia21Error.chatNotInitialized
    XCTAssertTrue(notInitialized.errorDescription?.contains("not initialized") ?? false)

    let apiError = Mia21Error.apiError("Test error")
    XCTAssertTrue(apiError.errorDescription?.contains("Test error") ?? false)

    let invalidResponse = Mia21Error.invalidResponse
    XCTAssertNotNil(invalidResponse.errorDescription)
  }

  // MARK: - Response Mode Tests

  func testResponseModeRawValues() {
    XCTAssertEqual(ResponseMode.text.rawValue, "text")
    XCTAssertEqual(ResponseMode.streamText.rawValue, "stream_text")
    XCTAssertEqual(ResponseMode.streamVoice.rawValue, "stream_voice")
    XCTAssertEqual(ResponseMode.streamVoiceOnly.rawValue, "stream_voice_only")
  }

  // MARK: - Voice Config Tests

  func testVoiceConfigCreation() {
    let config = VoiceConfig(
      enabled: true,
      voiceId: "voice-123",
      stability: 0.5,
      similarityBoost: 0.75
    )

    XCTAssertTrue(config.enabled)
    XCTAssertEqual(config.voiceId, "voice-123")
    XCTAssertEqual(config.stability, 0.5)
    XCTAssertEqual(config.similarityBoost, 0.75)
  }
}
