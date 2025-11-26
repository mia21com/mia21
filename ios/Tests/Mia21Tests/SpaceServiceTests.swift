//
//  SpaceServiceTests.swift
//  Mia21Tests
//
//  Created on November 7, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Unit tests for SpaceService.

import XCTest
@testable import Mia21

final class SpaceServiceTests: XCTestCase {
  
  var spaceService: SpaceService!
  var mockAPIClient: MockAPIClient!
  
  override func setUp() {
    super.setUp()
    mockAPIClient = MockAPIClient()
    spaceService = SpaceService(apiClient: mockAPIClient)
  }
  
  override func tearDown() {
    spaceService = nil
    mockAPIClient = nil
    super.tearDown()
  }
  
  // MARK: - Initialization Tests
  
  func testSpaceServiceInitialization() {
    XCTAssertNotNil(spaceService)
  }
  
  // MARK: - List Spaces Tests
  
  func testListSpaces() async throws {
    // Create mock bots first
    let mockBot1 = Bot(
      botId: "bot-1",
      name: "Bot 1",
      prompt: "Be helpful",
      llmIdentifier: "gpt-4o",
      temperature: 0.7,
      maxTokens: 512,
      language: "en",
      voiceId: "voice-1",
      isDefault: true,
      customerId: "customer-1",
      createdAt: "2025-01-01T00:00:00Z",
      updatedAt: "2025-01-01T00:00:00Z"
    )
    
    let mockBot2 = Bot(
      botId: "bot-2",
      name: "Bot 2",
      prompt: "Be professional",
      llmIdentifier: "gpt-4o",
      temperature: 0.8,
      maxTokens: 1024,
      language: "en",
      voiceId: "voice-2",
      isDefault: false,
      customerId: "customer-1",
      createdAt: "2025-01-01T00:00:00Z",
      updatedAt: "2025-01-01T00:00:00Z"
    )
    
    let mockSpaces: [Space] = [
      Space(
        spaceId: "space-1",
        name: "Test Space 1",
        prompt: "You are a helpful assistant",
        description: "Description 1",
        generateFirstMessage: true,
        bots: [mockBot1],
        isActive: true,
        usageCount: 0,
        createdAt: "2025-01-01T00:00:00Z",
        updatedAt: "2025-01-01T00:00:00Z",
        type: "custom"
      ),
      Space(
        spaceId: "space-2",
        name: "Test Space 2",
        prompt: "You are a professional assistant",
        description: "Description 2",
        generateFirstMessage: false,
        bots: [mockBot2],
        isActive: true,
        usageCount: 5,
        createdAt: "2025-01-02T00:00:00Z",
        updatedAt: "2025-01-02T00:00:00Z",
        type: "preset"
      )
    ]
    
    mockAPIClient.performRequestHandler = { endpoint in
      XCTAssertEqual(endpoint.path, "/spaces")
      XCTAssertEqual(endpoint.method, .get)
      XCTAssertNil(endpoint.body) // GET request should have no body
      return mockSpaces
    }
    
    let spaces = try await spaceService.listSpaces()
    
    XCTAssertEqual(spaces.count, 2)
    XCTAssertEqual(spaces[0].spaceId, "space-1")
    XCTAssertEqual(spaces[1].spaceId, "space-2")
    XCTAssertEqual(spaces[0].name, "Test Space 1")
    XCTAssertEqual(spaces[0].bots.count, 1)
    XCTAssertEqual(spaces[0].bots[0].botId, "bot-1")
  }
  
  // MARK: - List Bots Tests
  
  func testListBots() async throws {
    let mockBots: [Bot] = [
      Bot(
        botId: "bot-1",
        name: "Test Bot 1",
        prompt: "Be helpful",
        llmIdentifier: "gpt-4o",
        temperature: 0.7,
        maxTokens: 512,
        language: "en",
        voiceId: "voice-1",
        isDefault: true,
        customerId: "customer-1",
        createdAt: "2025-01-01T00:00:00Z",
        updatedAt: "2025-01-01T00:00:00Z"
      ),
      Bot(
        botId: "bot-2",
        name: "Test Bot 2",
        prompt: "Be professional",
        llmIdentifier: "gpt-4o",
        temperature: 0.8,
        maxTokens: 1024,
        language: "en",
        voiceId: "voice-2",
        isDefault: false,
        customerId: "customer-1",
        createdAt: "2025-01-02T00:00:00Z",
        updatedAt: "2025-01-02T00:00:00Z"
      )
    ]
    
    // Use the public BotsResponse model
    let mockResponse = BotsResponse(bots: mockBots, count: mockBots.count)
    
    mockAPIClient.performRequestHandler = { endpoint in
      XCTAssertEqual(endpoint.path, "/bots")
      XCTAssertEqual(endpoint.method, .get)
      XCTAssertNil(endpoint.body)
      return mockResponse
    }
    
    let bots = try await spaceService.listBots()
    
    XCTAssertEqual(bots.count, 2)
    XCTAssertEqual(bots[0].botId, "bot-1")
    XCTAssertEqual(bots[1].botId, "bot-2")
    XCTAssertTrue(bots[0].isDefault)
    XCTAssertFalse(bots[1].isDefault)
  }
}
