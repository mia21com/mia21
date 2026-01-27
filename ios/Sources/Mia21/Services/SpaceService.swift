//
//  SpaceService.swift
//  Mia21
//
//  Created on November 4, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Service layer for space management operations.
//  Handles listing and retrieving workspace information.
//

import Foundation

// MARK: - Space Service Protocol

protocol SpaceServiceProtocol {
  func listSpaces() async throws -> [Space]
  func listBots() async throws -> [Bot]
  func listSpaceConversations(spaceId: String, options: SpaceConversationsOptions) async throws -> SpaceConversationsResponse
}

// MARK: - Space Service Implementation

final class SpaceService: SpaceServiceProtocol {

  // MARK: - Properties

  private let apiClient: APIClientProtocol

  // MARK: - Initialization

  init(apiClient: APIClientProtocol) {
    self.apiClient = apiClient
  }

  // MARK: - Public Methods

  func listSpaces() async throws -> [Space] {
    let endpoint = APIEndpoint(
      path: "/spaces",
      method: .get,
      body: nil
    )

    let spaces: [Space] = try await apiClient.performRequest(endpoint)
    return spaces
  }
  
  func listBots() async throws -> [Bot] {
    let endpoint = APIEndpoint(
      path: "/bots",
      method: .get,
      body: nil
    )

    // Response has format: {"bots": [...], "count": X}
    let response: BotsResponse = try await apiClient.performRequest(endpoint)
    return response.bots
  }
  
  func listSpaceConversations(spaceId: String, options: SpaceConversationsOptions) async throws -> SpaceConversationsResponse {
    logInfo("Listing conversations for space: \(spaceId)")
    
    // Build query parameters
    var queryParams: [String] = []
    
    if let userId = options.userId {
      queryParams.append("user_id=\(userId)")
    }
    if let botId = options.botId {
      queryParams.append("bot_id=\(botId)")
    }
    if let status = options.status {
      queryParams.append("status=\(status.rawValue)")
    }
    queryParams.append("limit=\(options.limit)")
    queryParams.append("offset=\(options.offset)")
    
    let queryString = queryParams.isEmpty ? "" : "?\(queryParams.joined(separator: "&"))"
    let path = "/spaces/\(spaceId)/conversations\(queryString)"
    
    let endpoint = APIEndpoint(
      path: path,
      method: .get,
      body: nil
    )
    
    let response: SpaceConversationsResponse = try await apiClient.performRequest(endpoint)
    logDebug("Found \(response.totalCount) conversations in space \(spaceId)")
    return response
  }
}
