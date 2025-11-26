//
//  LoadingViewModel.swift
//  MiaUIKitExample
//
//  Created by Nataliia Kozlovska on 21.11.2025.
//

import UIKit
import Mia21

// MARK: - Loading State

enum LoadingState {
  case loading
  case success([Space], Space?, [Bot], Bot?)
  case error(String)
}

// MARK: - Loading ViewModel

@MainActor
final class LoadingViewModel {

  // MARK: - Properties

  private(set) var state: LoadingState = .loading {
    didSet { onStateChanged?(state) }
  }

  private let client: Mia21Client
  private let appId: String

  // MARK: - Callbacks

  var onStateChanged: ((LoadingState) -> Void)?

  // MARK: - Initialization

  init(client: Mia21Client, appId: String) {
    self.client = client
    self.appId = appId
  }

  // MARK: - Public Methods

  func load() async {
    state = .loading

    do {
      let spaces = try await client.listSpaces()
      let firstSpace = spaces.first

      let bots = try await client.listBots()
      let selectedBot = bots.first(where: { $0.isDefault }) ?? bots.first

      // Small delay for smooth transition
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
