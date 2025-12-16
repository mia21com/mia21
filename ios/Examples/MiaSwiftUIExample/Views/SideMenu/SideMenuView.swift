//
//  SideMenuView.swift
//  MiaSwiftUIExample
//
//  Created on November 8, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Side menu view for chat interface with space and bot selection.
//  Displays "New Chat" button, recent chats section, and space/bot selectors.
//  Matches UIKit version functionality and design.
//

import SwiftUI
import Mia21

// MARK: - Side Menu View

struct SideMenuView: View {
  @Binding var isVisible: Bool
  @ObservedObject var viewModel: SideMenuViewModel
  let onSpaceChanged: (Space, Bot?) -> Void
  let onBotChanged: (Bot) -> Void
  let onNewChat: () -> Void
  let onSelectChat: (String) -> Void

  @State private var showingSpaceSelector = false
  @State private var showingBotSelector = false

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      // Top spacing for safe area + extra padding
      Color.clear
        .frame(height: max(0, safeAreaTopInset + 10))
      
      Button {
        viewModel.clearConversationSelection()
        onNewChat()
      } label: {
        HStack(spacing: 8) {
          Image(systemName: "plus")
            .font(.system(size: 16, weight: .medium))
          Text("New Chat")
            .font(.system(size: 15, weight: .medium))
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .background(
          LinearGradient.appGradient
        )
        .cornerRadius(10)
      }
      .buttonStyle(.plain)
      .padding(.horizontal, 12)

      Text("RECENTS")
        .font(.system(size: 11, weight: .semibold))
        .foregroundColor(Color(.secondaryLabel))
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .padding(.bottom, 8)

      // Conversation list
      List {
        ForEach(Array(viewModel.conversations.enumerated()), id: \.element.id) { index, conversation in
          Button {
            viewModel.selectConversation(conversation.id)
            onSelectChat(conversation.id)
          } label: {
            Text(conversation.displayTitle)
              .font(.system(size: 14, weight: .regular))
              .foregroundColor(.primary)
              .lineLimit(1)
              .frame(maxWidth: .infinity, alignment: .leading)
          }
          .listRowBackground(
            conversation.id == viewModel.selectedConversationId
              ? Color(UIColor.tertiarySystemFill)
              : Color.clear
          )
          .listRowSeparator(.hidden)
          .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 12))
          .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
              Task {
                _ = await viewModel.deleteConversation(at: index)
              }
            } label: {
              Label("Delete", systemImage: "trash")
            }
          }
        }
      }
      .listStyle(.plain)
      .scrollContentBackground(.hidden)

      Spacer()

      Divider()
        .padding(.horizontal, 12)

      VStack(spacing: 8) {
        // Space selector
        Button {
          showingSpaceSelector = true
        } label: {
          HStack(spacing: 12) {
            ZStack {
              LinearGradient.appGradient
                .frame(width: 36, height: 36)
                .clipShape(Circle())
              
              Text(viewModel.spaceAvatarLetter)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            }

            Text(viewModel.spaceDisplayName)
              .font(.system(size: 15, weight: .medium))
              .foregroundColor(.primary)

            Spacer()

            Image(systemName: "chevron.down")
              .font(.system(size: 10))
              .foregroundColor(Color(.secondaryLabel))
          }
          .padding(.horizontal, 12)
          .frame(height: 52)
          .background(Color.selectorButtonBackground)
          .cornerRadius(10)
          .overlay(
            RoundedRectangle(cornerRadius: 10)
              .stroke(Color.selectorButtonBorder, lineWidth: 1)
          )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .confirmationDialog("Select Space", isPresented: $showingSpaceSelector, titleVisibility: .hidden) {
          ForEach(viewModel.spaces, id: \.spaceId) { space in
            Button(space.spaceId == viewModel.selectedSpace?.spaceId ? "\(space.name) ✓" : space.name) {
              viewModel.selectSpace(space)
              onSpaceChanged(space, viewModel.selectedBot)
            }
          }
          Button("Cancel", role: .cancel) {}
        }

        // Bot selector
        Button {
          showingBotSelector = true
        } label: {
          HStack(spacing: 12) {
            ZStack {
              LinearGradient.appGradient
                .frame(width: 36, height: 36)
                .clipShape(Circle())
              
              Text("✨")
                .font(.system(size: 20))
            }

            Text(viewModel.botDisplayName)
              .font(.system(size: 15, weight: .medium))
              .foregroundColor(.primary)

            Spacer()

            Image(systemName: "chevron.down")
              .font(.system(size: 10))
              .foregroundColor(Color(.secondaryLabel))
          }
          .padding(.horizontal, 12)
          .frame(height: 52)
          .background(Color.selectorButtonBackground)
          .cornerRadius(10)
          .overlay(
            RoundedRectangle(cornerRadius: 10)
              .stroke(Color.selectorButtonBorder, lineWidth: 1)
          )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .confirmationDialog("Select Bot", isPresented: $showingBotSelector, titleVisibility: .hidden) {
          ForEach(viewModel.bots, id: \.botId) { bot in
            Button(bot.botId == viewModel.selectedBot?.botId ? "\(bot.name) ✓" : bot.name) {
              viewModel.selectBot(bot)
              onBotChanged(bot)
            }
          }
          Button("Cancel", role: .cancel) {}
        }
      }
      .padding(.top, 12)
      .padding(.bottom, 12)
    }
    .frame(width: 280)
    .background(Color.sideMenuBackgroundLight)
    .task {
      await viewModel.loadInitialDataIfNeeded()
    }
    .alert(item: $viewModel.currentError) { error in
      Alert(
        title: Text(error.title),
        message: Text(error.message),
        dismissButton: .default(Text("OK"))
      )
    }
  }
  
  private var safeAreaTopInset: CGFloat {
    (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.safeAreaInsets.top ?? 0
  }
  
  func reloadConversationsAfterCreation() {
    viewModel.reloadConversationsAfterCreation()
  }
  
  func selectConversation(_ conversationId: String) {
    viewModel.selectConversation(conversationId)
  }
}
