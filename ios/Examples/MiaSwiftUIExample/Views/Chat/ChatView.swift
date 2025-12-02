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
  @State private var userHasScrolledUp = false
  @State private var previousMessageCount = 0
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
          .task {
            await viewModel.initializeChat()
          }
          .onChange(of: scenePhase) { _ in
            if scenePhase == .background {
              Task {
                try? await client.close(spaceId: nil)
              }
            }
          }
          .onChange(of: viewModel.transcriptionResult) { result in
            if let result = result {
              inputText = result.text
              if result.restoreKeyboard {
                isInputFocused = true
              }
              // Clear the result after processing
              viewModel.transcriptionResult = nil
            }
          }
      }
      .offset(x: isSideMenuVisible ? 280 : 0)
      .alert(item: $viewModel.currentError) { error in
        Alert(
          title: Text(error.title),
          message: Text(error.message),
          dismissButton: .default(Text("OK"))
        )
      }
      
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
      }
      .scrollDismissesKeyboard(.immediately)
      .contentShape(Rectangle())
      .onTapGesture {
        isInputFocused = false
      }
      .simultaneousGesture(
        DragGesture(minimumDistance: 5)
          .onChanged { _ in
            // User started scrolling - disable auto-scroll
            if !userHasScrolledUp {
              userHasScrolledUp = true
            }
          }
      )
      .onChange(of: viewModel.messages.count) { newCount in
        // New message added - scroll to bottom only if user hasn't scrolled up
        if newCount > previousMessageCount {
          if !userHasScrolledUp {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
              if let lastMessage = viewModel.messages.last {
                withAnimation {
                  proxy.scrollTo(lastMessage.id, anchor: .bottom)
                }
              }
            }
          }
          previousMessageCount = newCount
        }
      }
      .onChange(of: viewModel.messages.last?.text ?? "") { _ in
        // Streaming update - only scroll if user hasn't scrolled up
        guard !userHasScrolledUp else { return }
        
        if let lastMessage = viewModel.messages.last {
          withAnimation(nil) {
            proxy.scrollTo(lastMessage.id, anchor: .bottom)
          }
        }
      }
      .onChange(of: isInputFocused) { focused in
        if focused && !userHasScrolledUp {
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let lastMessage = viewModel.messages.last {
              withAnimation {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
              }
            }
          }
        }
      }
    }
  }

  private var inputContainerView: some View {
    ChatInputView(
      inputText: $inputText,
      isInputFocused: $isInputFocused,
      isLoading: viewModel.isLoading,
      canSend: canSend,
      isRecording: viewModel.isRecording,
      isHandsFreeModeEnabled: viewModel.isHandsFreeModeEnabled,
      isRecordingState: viewModel.isRecording,
      isTranscribingState: viewModel.isTranscribing,
      onSend: sendMessage,
      onRecord: toggleRecording,
      onHandsFreeTapped: {
        // Dismiss keyboard when enabling hands-free mode
        if !viewModel.isHandsFreeModeEnabled {
          isInputFocused = false
        }
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
          userHasScrolledUp = false
          viewModel.clearChat()
          withAnimation(.easeIn(duration: 0.25)) {
            isSideMenuVisible = false
          }
        },
        onBotChanged: { bot in
          viewModel.currentBotId = bot.botId
          userHasScrolledUp = false
          viewModel.clearChat()
          withAnimation(.easeIn(duration: 0.25)) {
            isSideMenuVisible = false
          }
        },
        onNewChat: {
          userHasScrolledUp = false
          viewModel.clearChat()
          withAnimation(.easeIn(duration: 0.25)) {
            isSideMenuVisible = false
          }
        },
        onSelectChat: { conversationId in
          userHasScrolledUp = false
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
    !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.isLoading && viewModel.isChatInitialized
  }

  // MARK: - Actions

  private func sendMessage() {
    let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !text.isEmpty else { return }

    let messageText = text
    
    // Reset scroll state when user sends a message - they want to see the response
    userHasScrolledUp = false
    
    // Clear input immediately
    inputText = ""
    
    // Keep focus on input
    isInputFocused = true

    Task {
      await viewModel.sendMessage(messageText)
    }
  }
  
  private func toggleRecording() {
    if viewModel.isRecording {
      viewModel.stopRecording()
    } else {
      let keyboardWasVisible = isInputFocused
      // Dismiss keyboard when starting recording
      isInputFocused = false
      viewModel.startRecording(currentText: inputText, keyboardWasVisible: keyboardWasVisible)
    }
  }
}

