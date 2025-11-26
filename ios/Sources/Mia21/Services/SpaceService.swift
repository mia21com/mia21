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
}
