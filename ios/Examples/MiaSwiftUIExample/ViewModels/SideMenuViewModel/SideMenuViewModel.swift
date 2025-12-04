//
//  SideMenuViewModel.swift
//  MiaSwiftUIExample
//
//  Created on November 21, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  ViewModel managing side menu business logic, including space selection,
//  bot selection, and conversation history.
//

import Foundation
import Mia21

@MainActor
final class SideMenuViewModel: ObservableObject {

  @Published private(set) var spaces: [Space] = []
  @Published private(set) var bots: [Bot] = []
  @Published private(set) var conversations: [ConversationSummary] = []
  @Published private(set) var selectedSpace: Space?
  @Published private(set) var selectedBot: Bot?
  @Published private(set) var selectedConversationId: String?
  @Published private(set) var isLoading: Bool = false
  @Published var currentError: AppError?

  private let client: Mia21Client
  private let appId: String

  init(client: Mia21Client, appId: String) {
    self.client = client
    self.appId = appId
  }

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
    if spaces.isEmpty {
      await loadSpaces()
    }
    
    if conversations.isEmpty {
      await loadConversations()
    }
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
      currentError = AppError(message: "Failed to load spaces: \(error.localizedDescription)")
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
      currentError = AppError(message: "Failed to load bots: \(error.localizedDescription)")
    }
  }

  func loadConversations() async {
    do {
      conversations = try await client.listConversations(
        spaceId: nil,
        limit: 50
      )
    } catch {
      currentError = AppError(message: "Failed to load conversations: \(error.localizedDescription)")
    }
  }

  func reloadConversationsAfterCreation() {
    Task {
      try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
      
      await loadConversations()
      
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
      currentError = AppError(message: "Failed to delete conversation: \(error.localizedDescription)")
      return false
    }
  }

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
