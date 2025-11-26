//
//  ChatView.swift
//  MiaSwiftUIExample
//
//  Created on November 7, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Main chat interface matching UIKit version functionality exactly.

import SwiftUI
import Mia21

struct ChatView: View {
  @StateObject private var viewModel: ChatViewModel
  @StateObject private var sideMenuViewModel: SideMenuViewModel
  @State private var isSideMenuVisible = false
  @State private var inputText = ""
  @FocusState private var isInputFocused: Bool
  @State private var isUserScrolling = false
  @State private var shouldAutoScroll = true
  private let autoScrollThreshold: CGFloat = 50
  @State private var previousMessageCount = 0
  @State private var hasAppeared = false
  private let client: Mia21Client
  private let appId: String
  @Environment(\.scenePhase) private var scenePhase

  init(
    client: Mia21Client,
    audioManager: AudioPlaybackManager,
    appId: String,
    spaces: [Space],
    selectedSpace: Space?,
    bots: [Bot],
    selectedBot: Bot?
  ) {
    self.client = client
    self.appId = appId
    let spaceId = selectedSpace?.spaceId ?? "default-space"
    let botId = selectedBot?.botId
    
    // Create ViewModels
    let vm = ChatViewModel(client: client, audioManager: audioManager, spaceId: spaceId, botId: botId)
    let smvm = SideMenuViewModel(client: client, appId: appId)
    smvm.setInitialData(spaces: spaces, selectedSpace: selectedSpace, bots: bots, selectedBot: selectedBot)
    
    // Connect callback: when conversation is created, reload the side menu list
    vm.onConversationCreated = { [weak smvm] in
      smvm?.reloadConversationsAfterCreation()
    }
    
    _viewModel = StateObject(wrappedValue: vm)
    _sideMenuViewModel = StateObject(wrappedValue: smvm)
  }

  var body: some View {
    ZStack(alignment: .leading) {
      // Main navigation stack with content
      NavigationStack {
        chatContentView
          .navigationTitle("Mia")
          .navigationBarTitleDisplayMode(.inline)
          .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
              Button {
                isInputFocused = false
                withAnimation(isSideMenuVisible ? .easeIn(duration: 0.25) : .easeOut(duration: 0.3)) {
                  isSideMenuVisible.toggle()
                }
              } label: {
                Image(systemName: isSideMenuVisible ? "chevron.left" : "line.3.horizontal")
                  .foregroundColor(.primary)
                  .animation(.none, value: isSideMenuVisible)
              }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
              Button {
                viewModel.toggleVoice()
              } label: {
                Image(systemName: viewModel.isVoiceEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                  .foregroundColor(viewModel.isVoiceEnabled ? .green : .gray)
                  .animation(.none, value: viewModel.isVoiceEnabled)
              }
              .disabled(viewModel.isHandsFreeModeEnabled)
            }
          }
          .onAppear {
            hasAppeared = true
          }
          .task {
            await viewModel.initializeChat()
          }
          .onChange(of: scenePhase) { _ in
            if scenePhase == .background {
              Task {
                do {
                  try await client.close(spaceId: nil)
                  print("✅ Chat session closed when entering background")
                } catch {
                  print("⚠️ Failed to close chat session: \(error.localizedDescription)")
                }
              }
            }
          }
      }
      .offset(x: isSideMenuVisible ? 280 : 0)
      
      // Side menu - always rendered, positioned offscreen when hidden
      sideMenuContent
        .zIndex(10)
    }
  }
  
  private var chatContentView: some View {
    messagesScrollView
      .safeAreaInset(edge: .bottom) {
        inputContainerView
      }
      .opacity(isSideMenuVisible ? 0.3 : 1.0)
      .overlay(
        Group {
          if isSideMenuVisible {
            Color.clear
              .contentShape(Rectangle())
              .onTapGesture {
                withAnimation(.easeIn(duration: 0.25)) {
                  isSideMenuVisible = false
                }
              }
          }
        }
      )
  }

  private var messagesScrollView: some View {
    ScrollViewReader { proxy in
      ScrollView {
        LazyVStack(alignment: .leading, spacing: 12) {
          ForEach(viewModel.messages) { message in
            MessageBubble(message: message)
              .id(message.id)
          }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
          GeometryReader { geometry in
            Color.clear
              .preference(
                key: ScrollOffsetPreferenceKey.self,
                value: geometry.frame(in: .named("scroll")).minY
              )
          }
        )
      }
      .coordinateSpace(name: "scroll")
      .scrollDismissesKeyboard(.immediately)
      .contentShape(Rectangle())
      .onTapGesture {
        isInputFocused = false
      }
      .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
        checkScrollPosition(proxy: proxy, offset: offset)
      }
      .onChange(of: viewModel.messages.count) { newCount in
        updateMessages(proxy: proxy, newCount: newCount)
      }
      .onChange(of: viewModel.messages.last?.text ?? "") { _ in
        // Only update if not actively scrolling
        if !isUserScrolling && shouldAutoScroll && !viewModel.messages.isEmpty {
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            if let lastMessage = self.viewModel.messages.last {
              withAnimation(nil) {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
              }
            }
          }
        }
      }
      .onChange(of: isInputFocused) { focused in
        if focused && shouldAutoScroll {
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let lastMessage = viewModel.messages.last {
              withAnimation {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
              }
            }
          }
        }
      }
      .simultaneousGesture(
        DragGesture()
          .onChanged { _ in
            isUserScrolling = true
          }
          .onEnded { _ in
            isUserScrolling = false
            checkScrollPosition(proxy: proxy, offset: 0)
          }
      )
    }
  }

  private var inputContainerView: some View {
    ChatInputView(
      inputText: $inputText,
      isInputFocused: $isInputFocused,
      isLoading: viewModel.isLoading,
      canSend: canSend,
      isRecording: false,
      isHandsFreeModeEnabled: viewModel.isHandsFreeModeEnabled,
      isRecordingState: false,
      isTranscribingState: viewModel.isTranscribing,
      onSend: sendMessage,
      onRecord: {
        // Recording logic moved to View layer - TODO: implement
      },
      onHandsFreeTapped: {
        viewModel.toggleHandsFreeMode()
      }
    )
  }

  private var sideMenuContent: some View {
    ZStack(alignment: .leading) {
      // Dimming overlay - catches taps outside menu
      if isSideMenuVisible {
        Color.black
          .opacity(0.0)
          .ignoresSafeArea()
          .onTapGesture {
            withAnimation(.easeIn(duration: 0.25)) {
              isSideMenuVisible = false
            }
          }
      }
      
      // Side menu view
      SideMenuView(
        isVisible: $isSideMenuVisible,
        viewModel: sideMenuViewModel,
        onSpaceChanged: { space, bot in
          viewModel.currentSpaceId = space.spaceId
          viewModel.currentBotId = bot?.botId
          viewModel.clearChat()
          withAnimation(.easeIn(duration: 0.25)) {
            isSideMenuVisible = false
          }
        },
        onBotChanged: { bot in
          viewModel.currentBotId = bot.botId
          viewModel.clearChat()
          withAnimation(.easeIn(duration: 0.25)) {
            isSideMenuVisible = false
          }
        },
        onNewChat: {
          viewModel.clearChat()
          withAnimation(.easeIn(duration: 0.25)) {
            isSideMenuVisible = false
          }
        },
        onSelectChat: { conversationId in
          Task {
            await viewModel.loadConversation(conversationId)
          }
          withAnimation(.easeIn(duration: 0.25)) {
            isSideMenuVisible = false
          }
        }
      )
      .offset(x: isSideMenuVisible ? 0 : -280)
      .animation(isSideMenuVisible ? .easeOut(duration: 0.3) : .easeIn(duration: 0.25), value: isSideMenuVisible)
      .ignoresSafeArea(edges: .top)
    }
  }

  // MARK: - Computed Properties

  private var canSend: Bool {
    !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.isLoading
  }

  // MARK: - Actions

  private func sendMessage() {
    let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !text.isEmpty else { return }

    let messageText = text
    shouldAutoScroll = true
    
    // Clear input immediately
    inputText = ""
    
    // Keep focus on input
    isInputFocused = true

    Task {
      await viewModel.sendMessage(messageText)
      await MainActor.run {
        isInputFocused = true
      }
    }
  }

  // MARK: - Message Updates

  private func updateMessages(proxy: ScrollViewProxy, newCount: Int) {
    let currentCount = newCount
    let previousCount = previousMessageCount

    if currentCount > previousCount {
      shouldAutoScroll = true
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        scrollToBottom(proxy: proxy, animated: true)
      }
    } else if currentCount == previousCount && currentCount > 0 {
      if shouldAutoScroll {
        scrollToBottom(proxy: proxy, animated: false)
      }
    } else {
      shouldAutoScroll = true
      scrollToBottom(proxy: proxy, animated: false)
    }

    previousMessageCount = currentCount
  }

  // MARK: - Smart Auto-Scroll Helpers

  private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool) {
    guard !viewModel.messages.isEmpty else { return }
    guard shouldAutoScroll else { return }

    if let lastMessage = viewModel.messages.last {
      if animated {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
          guard self.shouldAutoScroll else { return }
          withAnimation(.easeOut(duration: 0.3)) {
            proxy.scrollTo(lastMessage.id, anchor: .bottom)
          }
        }
      } else {
        withAnimation(nil) {
          proxy.scrollTo(lastMessage.id, anchor: .bottom)
        }
      }
    }
  }

  private func checkScrollPosition(proxy: ScrollViewProxy, offset: CGFloat) {
    if isUserScrolling {
      shouldAutoScroll = abs(offset) < autoScrollThreshold
    }
  }
}

