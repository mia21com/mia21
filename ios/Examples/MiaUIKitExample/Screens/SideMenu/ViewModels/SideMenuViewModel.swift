//
//  SideMenuViewModel.swift
//  MiaUIKitExample
//
//  Created on November 20, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  ViewModel managing side menu business logic, including space selection,
//  bot selection, and conversation history.
//

import UIKit
import Mia21

// MARK: - Side Menu ViewModel

@MainActor
final class SideMenuViewModel {

  // MARK: - Published State

  private(set) var spaces: [Space] = [] {
    didSet { onSpacesChanged?() }
  }

  private(set) var bots: [Bot] = [] {
    didSet { onBotsChanged?() }
  }

  private(set) var conversations: [ConversationSummary] = [] {
    didSet { onConversationsChanged?() }
  }

  private(set) var selectedSpace: Space? {
    didSet { onSelectedSpaceChanged?() }
  }

  private(set) var selectedBot: Bot? {
    didSet { onSelectedBotChanged?() }
  }

  private(set) var selectedConversationId: String? {
    didSet { onSelectedConversationChanged?() }
  }

  private(set) var isLoading: Bool = false {
    didSet { onLoadingStateChanged?() }
  }

  // MARK: - Callbacks

  var onSpacesChanged: (() -> Void)?
  var onBotsChanged: (() -> Void)?
  var onConversationsChanged: (() -> Void)?
  var onSelectedSpaceChanged: (() -> Void)?
  var onSelectedBotChanged: (() -> Void)?
  var onSelectedConversationChanged: (() -> Void)?
  var onLoadingStateChanged: (() -> Void)?
  var onError: ((String) -> Void)?

  // MARK: - Dependencies

  private let client: Mia21Client
  private let appId: String

  // MARK: - Initialization

  init(client: Mia21Client, appId: String) {
    self.client = client
    self.appId = appId
  }

  // MARK: - Public Methods

  func setInitialData(
    spaces: [Space],
    selectedSpace: Space?,
    bots: [Bot],
    selectedBot: Bot?
  ) {
    self.spaces = spaces
    self.selectedSpace = selectedSpace
    self.bots = bots
    self.selectedBot = selectedBot
  }

  func loadInitialDataIfNeeded() async {
    guard spaces.isEmpty else { return }

    await loadSpaces()
    await loadConversations()
  }

  func loadSpaces() async {
    isLoading = true

    do {
      spaces = try await client.listSpaces()

      if selectedSpace == nil, let firstSpace = spaces.first {
        selectedSpace = firstSpace
      }

      await loadBots()
    } catch {
      onError?("Failed to load spaces: \(error.localizedDescription)")
    }

    isLoading = false
  }

  func loadBots() async {
    do {
      bots = try await client.listBots()

      if selectedBot == nil {
        if let defaultBot = bots.first(where: { $0.isDefault }) {
          selectedBot = defaultBot
        } else if let firstBot = bots.first {
          selectedBot = firstBot
        }
      }
    } catch {
      bots = []
      selectedBot = nil
      onError?("Failed to load bots: \(error.localizedDescription)")
    }
  }

  func loadConversations() async {
    do {
      conversations = try await client.listConversations(
        spaceId: nil,
        limit: 50
      )

      print("✅ Loaded \(conversations.count) conversations")
    } catch {
      onError?("Failed to load conversations: \(error.localizedDescription)")
      print("❌ Error loading conversations: \(error)")
    }
  }

  func reloadConversationsAfterCreation() {
    Task {
      // Wait briefly for backend to propagate the new conversation
      try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s

      let previousCount = conversations.count
      await loadConversations()

      if conversations.count > previousCount {
        print("✅ New conversation detected in history")
      }
    }
  }

  func selectSpace(_ space: Space) {
    selectedSpace = space

    Task {
      await loadBots()
    }
  }

  func selectBot(_ bot: Bot) {
    selectedBot = bot
  }

  func selectConversation(_ conversationId: String) {
    selectedConversationId = conversationId
  }

  func clearConversationSelection() {
    selectedConversationId = nil
  }

  func deleteConversation(at index: Int) async -> Bool {
    guard index < conversations.count else { return false }

    let conversation = conversations[index]
    let wasSelected = conversation.id == selectedConversationId

    do {
      _ = try await client.deleteConversation(conversationId: conversation.id)
      conversations.remove(at: index)
      
      if wasSelected {
        selectedConversationId = nil
      }
      
      return true
    } catch {
      onError?("Failed to delete conversation: \(error.localizedDescription)")
      print("❌ Error deleting conversation: \(error)")
      return false
    }
  }

  // MARK: - Computed Properties

  var spaceDisplayName: String {
    selectedSpace?.name ?? "Select Space"
  }

  var spaceAvatarLetter: String {
    if let spaceName = selectedSpace?.name, !spaceName.isEmpty {
      return String(spaceName.prefix(1)).uppercased()
    }
    return "S"
  }

  var botDisplayName: String {
    if bots.isEmpty {
      return "No Bots Available"
    }
    return selectedBot?.name ?? "Select Bot"
  }

  var hasSpaces: Bool {
    !spaces.isEmpty
  }

  var hasBots: Bool {
    !bots.isEmpty
  }
  
  // MARK: - Table View Data
  
  var numberOfConversations: Int {
    conversations.count
  }
  
  func conversation(at index: Int) -> ConversationSummary? {
    guard index < conversations.count else { return nil }
    return conversations[index]
  }
  
  func isConversationSelected(at index: Int) -> Bool {
    guard let conversation = conversation(at: index) else { return false }
    return conversation.id == selectedConversationId
  }
  
  func selectConversation(at index: Int) {
    guard let conversation = conversation(at: index) else { return }
    selectConversation(conversation.id)
  }
}
