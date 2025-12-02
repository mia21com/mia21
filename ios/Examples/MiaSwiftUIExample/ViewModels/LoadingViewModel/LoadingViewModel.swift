//
//  LoadingViewModel.swift
//  MiaSwiftUIExample
//
//  Created on November 21, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  ViewModel managing loading screen state and initial data fetching.
//

import Foundation
import Mia21

enum LoadingState {
  case loading
  case success([Space], Space?, [Bot], Bot?)
  case error(String)
}

@MainActor
final class LoadingViewModel: ObservableObject {

  @Published private(set) var state: LoadingState = .loading

  private let client: Mia21Client
  private let appId: String

  init(client: Mia21Client, appId: String) {
    self.client = client
    self.appId = appId
  }

  func load() async {
    state = .loading

    do {
      let spaces = try await client.listSpaces()
      let firstSpace = spaces.first

      let bots = try await client.listBots()
      let selectedBot = bots.first(where: { $0.isDefault }) ?? bots.first

      try await Task.sleep(nanoseconds: 500_000_000)

      state = .success(spaces, firstSpace, bots, selectedBot)

    } catch {
      state = .error("Failed to load: \(error.localizedDescription)")
    }
  }

  func retry() async {
    await load()
  }
}
