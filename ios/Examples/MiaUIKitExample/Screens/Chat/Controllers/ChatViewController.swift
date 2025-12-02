//
//  ChatViewController.swift
//  MiaUIKitExample
//
//  Created on November 4, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Main chat interface using MVVM architecture with ChatGPT-style design.
//  Handles UI presentation while delegating business logic to ChatViewModel.
//

import UIKit
import Mia21
import AVFoundation
import Combine

// MARK: - Constants

private enum Constants {
  static let sideMenuWidth: CGFloat = 280
  static let autoScrollThreshold: CGFloat = 120
}

// MARK: - Chat View Controller

final class ChatViewController: UIViewController {

  // MARK: - Properties

  private let client: Mia21Client
  private let appId: String

  private lazy var audioManager = AudioPlaybackManager()
  lazy var viewModel: ChatViewModel = {
    let vm = ChatViewModel(client: client, audioManager: audioManager)
    vm.onMessagesUpdated = { [weak self] in
      self?.updateMessages()
    }
    vm.onScrollToBottom = { [weak self] in
      guard let self = self else { return }
      let animated = !self.viewModel.isLoadingConversation
      // Re-enable auto-scroll when explicitly requested (e.g., new message sent)
      self.scrollManager.enableAutoScroll()
      self.scrollToBottom(animated: animated)
    }
    vm.onConversationCreated = { [weak self] in
      self?.sideMenuViewController.reloadConversationsAfterCreation()
    }
    vm.onTranscriptionCompleted = { [weak self] text, shouldRestoreKeyboard in
      self?.handleTranscriptionCompleted(text: text, shouldRestoreKeyboard: shouldRestoreKeyboard)
    }
    return vm
  }()

  // Managers
  private let scrollManager = ScrollManager()
  private lazy var sideMenuManager: SideMenuManager = {
    let manager = SideMenuManager()
    manager.menuButton = menuButton
    manager.dimmingView = dimmingView
    manager.sideMenuView = sideMenuViewController.view
    manager.navigationBar = navigationController?.navigationBar
    manager.tableView = tableView
    manager.inputContainer = chatInputView
    return manager
  }()

  private var previousMessageCount = 0
  private var hasInitializedChat = false
  private lazy var sideMenuViewController = SideMenuViewController(client: client, appId: appId)
  private var menuButton: UIBarButtonItem?
  private var handsFreeUpdateTimer: Timer?
  private var cancellables = Set<AnyCancellable>()
  
  private lazy var dimmingView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .clear
    view.alpha = 0
    view.isUserInteractionEnabled = false
    return view
  }()

  // MARK: - UI Components

  private lazy var tableView: UITableView = {
    let table = UITableView(frame: .zero, style: .plain)
    table.translatesAutoresizingMaskIntoConstraints = false
    table.separatorStyle = .none
    table.backgroundColor = .systemBackground
    table.keyboardDismissMode = .interactive
    table.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
    table.showsVerticalScrollIndicator = false
    table.showsHorizontalScrollIndicator = false
    table.indicatorStyle = .default
    table.dataSource = self
    table.delegate = self
    table.register(ChatMessageCell.self, forCellReuseIdentifier: "ChatMessageCell")
    return table
  }()

  private lazy var chatInputView: ChatInputView = {
    let inputView = ChatInputView()
    inputView.translatesAutoresizingMaskIntoConstraints = false
    inputView.delegate = self
    return inputView
  }()
  
  private var inputContainerBottomConstraint: NSLayoutConstraint!

  // MARK: - Initialization
  
  init(client: Mia21Client, appId: String) {
    self.client = client
    self.appId = appId
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupUI()
    setupNavigation()
    setupKeyboardObservers()
    setupHandsFreeObservers()
    setupBackgroundObserver()
    setupViewModelObservers()

    if !hasInitializedChat {
      hasInitializedChat = true
      Task {
        await viewModel.initializeChat()
      }
    }
    
    DispatchQueue.main.async { [weak self] in
      self?.setupSideMenu()
    }
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    // Layout is handled by ChatInputView
  }

  deinit {
    handsFreeUpdateTimer?.invalidate()
    NotificationCenter.default.removeObserver(self)
    cancellables.removeAll()
  }
  
  // MARK: - Public Methods

  func setInitialData(
    spaces: [Space],
    selectedSpace: Space?,
    bots: [Bot],
    selectedBot: Bot?
  ) {
    sideMenuViewController.setInitialData(
      spaces: spaces,
      selectedSpace: selectedSpace,
      bots: bots,
      selectedBot: selectedBot
    )

    if let selectedSpace = selectedSpace {
      viewModel.currentSpaceId = selectedSpace.spaceId
      viewModel.currentBotId = selectedBot?.botId
    }
    
    if !hasInitializedChat {
      hasInitializedChat = true
      Task {
        await viewModel.initializeChat()
      }
    }
  }
}

// MARK: - Setup

private extension ChatViewController {
  
  func setupUI() {
    view.backgroundColor = .systemBackground

    view.addSubview(tableView)
    view.addSubview(chatInputView)
    view.addSubview(dimmingView)

    inputContainerBottomConstraint = chatInputView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor)

    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.topAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: chatInputView.topAnchor),

      dimmingView.topAnchor.constraint(equalTo: view.topAnchor),
      dimmingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      dimmingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      dimmingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      chatInputView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      chatInputView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      inputContainerBottomConstraint
    ])
  }

  func setupNavigation() {
    navigationController?.navigationBar.prefersLargeTitles = false
    navigationItem.largeTitleDisplayMode = .never
    navigationController?.hidesBarsOnSwipe = false

    let appearance = UINavigationBarAppearance()
    appearance.configureWithDefaultBackground()
    navigationController?.navigationBar.standardAppearance = appearance
    navigationController?.navigationBar.scrollEdgeAppearance = appearance

    let menuBtn = UIBarButtonItem(
      image: UIImage(systemName: "line.3.horizontal"),
      style: .plain,
      target: self,
      action: #selector(toggleSideMenu)
    )
    menuBtn.tintColor = .label
    menuButton = menuBtn

    let titleLabel = UILabel()
    titleLabel.text = "Mia"
    titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
    titleLabel.textColor = .label
    titleLabel.backgroundColor = .clear
    titleLabel.sizeToFit()

    navigationItem.leftBarButtonItems = [menuBtn]
    navigationItem.titleView = titleLabel

    let voiceButton = UIBarButtonItem(
      image: UIImage(systemName: "speaker.slash.fill"),
      style: .plain,
      target: self,
      action: #selector(voiceButtonTapped)
    )
    voiceButton.tintColor = .systemGray
    
    navigationItem.rightBarButtonItems = [voiceButton]
  }

  func setupKeyboardObservers() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(keyboardWillShow),
      name: UIResponder.keyboardWillShowNotification,
      object: nil
    )

    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
    tapGesture.cancelsTouchesInView = false
    tableView.addGestureRecognizer(tapGesture)
  }
  
  func setupHandsFreeObservers() {
    handsFreeUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
      guard let self = self else { return }
      Task { @MainActor in
        self.chatInputView.updateHandsFreeButton(
          isEnabled: self.viewModel.isHandsFreeModeEnabled,
          isListening: self.viewModel.isHandsFreeListening
        )
      }
    }
  }
  
  func setupBackgroundObserver() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleAppDidEnterBackground),
      name: UIApplication.didEnterBackgroundNotification,
      object: nil
    )
  }
  
  @objc private func handleAppDidEnterBackground() {
    Task {
      do {
        try await client.close(spaceId: nil)
        print("✅ Chat session closed when entering background")
      } catch {
        print("⚠️ Failed to close chat session: \(error.localizedDescription)")
      }
    }
  }
  

  func setupSideMenu() {
    addChild(sideMenuViewController)
    view.addSubview(sideMenuViewController.view)
    sideMenuViewController.didMove(toParent: self)

    sideMenuViewController.view.frame = CGRect(
      x: -Constants.sideMenuWidth,
      y: 0,
      width: Constants.sideMenuWidth,
      height: view.bounds.height
    )

    sideMenuViewController.onNewChat = { [weak self] in
      self?.handleNewChat()
    }

    sideMenuViewController.onSelectChat = { [weak self] conversationId in
      self?.handleSelectChat(conversationId)
    }

    sideMenuViewController.onSpaceChanged = { [weak self] space, bot in
      self?.handleSpaceChanged(space, bot: bot)
    }

    sideMenuViewController.onBotChanged = { [weak self] bot in
      self?.handleBotChanged(bot)
    }

    let dimmingTapGesture = UITapGestureRecognizer(target: self, action: #selector(dimmingViewTapped))
    dimmingView.addGestureRecognizer(dimmingTapGesture)

    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap))
    tapGesture.cancelsTouchesInView = false
    view.addGestureRecognizer(tapGesture)
  }
}

// MARK: - Side Menu Actions

private extension ChatViewController {
  
  @objc func toggleSideMenu() {
    view.endEditing(true) // Dismiss keyboard
    sideMenuManager.toggle()
  }

  @objc func dimmingViewTapped() {
    sideMenuManager.hide()
  }

  @objc func handleBackgroundTap(_ gesture: UITapGestureRecognizer) {
    guard sideMenuManager.isVisible else { return }

    let location = gesture.location(in: view)
    let menuFrame = sideMenuViewController.view.frame

    if !menuFrame.contains(location) {
      sideMenuManager.hide()
    }
  }

  func handleNewChat() {
    viewModel.clearChat()
    sideMenuManager.hide()
  }

  func handleSelectChat(_ conversationId: String) {
    sideMenuManager.hide()
    
    Task {
      await viewModel.loadConversation(conversationId)
      // Reset after conversation is fully loaded
      DispatchQueue.main.async { [weak self] in
        self?.previousMessageCount = self?.viewModel.messages.count ?? 0
      }
    }
  }

  func handleSpaceChanged(_ space: Space, bot: Bot?) {
    viewModel.currentSpaceId = space.spaceId
    viewModel.currentBotId = bot?.botId
    viewModel.clearChat()
    sideMenuManager.hide()
  }

  func handleBotChanged(_ bot: Bot) {
    viewModel.currentBotId = bot.botId
    viewModel.clearChat()
    sideMenuManager.hide()
  }
}

// MARK: - Button Actions

private extension ChatViewController {
  
  @objc func voiceButtonTapped() {
    viewModel.toggleVoice()
    updateVoiceButtonAppearance()

    let generator = UIImpactFeedbackGenerator(style: .medium)
    generator.impactOccurred()
  }
}

// MARK: - Recording Management

private extension ChatViewController {
  
  func startRecording() {
    let currentText = chatInputView.text
    let keyboardVisible = chatInputView.isTextViewFirstResponder
    
    viewModel.startRecording(currentText: currentText, keyboardWasVisible: keyboardVisible)
    // State updates are handled by observers
    chatInputView.unfocusTextView()
  }
  
  func stopRecording() {
    viewModel.stopRecording()
    // State updates are handled by observers
  }
  
  func showPermissionDeniedAlert() {
    let alert = UIAlertController(
      title: "Microphone Access Required",
      message: "Please enable microphone access in Settings to record voice messages.",
      preferredStyle: .alert
    )
    
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
      if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
        UIApplication.shared.open(settingsURL)
      }
    })
    
    present(alert, animated: true)
  }
  
  func handleTranscriptionCompleted(text: String, shouldRestoreKeyboard: Bool) {
    chatInputView.isTranscribing = false
    chatInputView.isRecording = false
    chatInputView.text = text
    chatInputView.updateButtonStates(hasText: !text.isEmpty)
    
    if shouldRestoreKeyboard {
      chatInputView.focusTextView()
    }
  }
}

// MARK: - UI Updates

private extension ChatViewController {
  
  func updateVoiceButtonAppearance() {
    let iconName = viewModel.isVoiceEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill"
    let image = UIImage(systemName: iconName)
    
    UIView.performWithoutAnimation {
      if let items = navigationItem.rightBarButtonItems, !items.isEmpty {
        items[0].image = image
        items[0].tintColor = viewModel.isVoiceEnabled ? .systemGreen : .systemGray
        // Disable voice button when hands-free mode is active
        items[0].isEnabled = !viewModel.isHandsFreeModeEnabled
      }
    }
  }

  func sendMessage(text: String) async {
    guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
    guard viewModel.isChatInitialized else { return }

    chatInputView.clearText()
    chatInputView.isLoading = true
    
    // Enable auto-scroll before sending
    scrollManager.enableAutoScroll()

    await viewModel.sendMessage(text)

    chatInputView.isLoading = false
    chatInputView.focusTextView()
  }
  
  func setupViewModelObservers() {
    // Observe recording state
    viewModel.$isRecording
      .receive(on: DispatchQueue.main)
      .sink { [weak self] isRecording in
        self?.chatInputView.isRecording = isRecording
        self?.chatInputView.recordingStatusText = self?.viewModel.recordingStatusText ?? ""
      }
      .store(in: &cancellables)
    
    // Observe transcription state
    viewModel.$isTranscribing
      .receive(on: DispatchQueue.main)
      .sink { [weak self] isTranscribing in
        self?.chatInputView.isTranscribing = isTranscribing
        self?.chatInputView.recordingStatusText = self?.viewModel.recordingStatusText ?? ""
      }
      .store(in: &cancellables)
    
    // Observe recording status text changes
    viewModel.$recordingStatusText
      .receive(on: DispatchQueue.main)
      .sink { [weak self] statusText in
        self?.chatInputView.recordingStatusText = statusText
      }
      .store(in: &cancellables)
    
    // Observe hands-free mode
    viewModel.$isHandsFreeModeEnabled
      .receive(on: DispatchQueue.main)
      .sink { [weak self] isEnabled in
        self?.chatInputView.isHandsFreeModeEnabled = isEnabled
      }
      .store(in: &cancellables)
    
    // Observe hands-free listening state
    viewModel.$isHandsFreeListening
      .receive(on: DispatchQueue.main)
      .sink { [weak self] isListening in
        self?.chatInputView.updateHandsFreeButton(
          isEnabled: self?.viewModel.isHandsFreeModeEnabled ?? false,
          isListening: isListening
        )
      }
      .store(in: &cancellables)
    
    // Observe chat initialization state
    viewModel.$isChatInitialized
      .receive(on: DispatchQueue.main)
      .sink { [weak self] isInitialized in
        self?.chatInputView.isChatInitialized = isInitialized
      }
      .store(in: &cancellables)
  }
}

// MARK: - Keyboard Handling

private extension ChatViewController {
  
  @objc func keyboardWillShow(_ notification: Notification) {
    // Keyboard state is now tracked in ViewModel
  }

  @objc func dismissKeyboard() {
    view.endEditing(true)
  }
}

// MARK: - Message Updates

private extension ChatViewController {
  
  func updateMessages() {
    let currentCount = viewModel.messages.count
    let previousCount = previousMessageCount
    
    // Update count immediately
    previousMessageCount = currentCount
    
    if viewModel.isLoadingConversation {
      tableView.reloadData()
      scrollToBottomWithoutChecks(animated: false)
      return
    }
    
    // If user is actively dragging, defer the update
    if scrollManager.isScrolling {
      return
    }
    
    // Capture if user is near bottom BEFORE any updates
    let wasNearBottom = isNearBottom()
    
    // Simple logic: if count changed, reload. If same, update last row.
    if currentCount != previousCount {
      // Count changed - just reload everything
      tableView.reloadData()
      
      // Only scroll if user was near bottom
      if wasNearBottom {
        scrollToBottomWithoutChecks(animated: currentCount > previousCount)
      }
    } else if currentCount > 0 {
      // Same count - update last message (streaming)
      let lastIndexPath = IndexPath(row: currentCount - 1, section: 0)
      UIView.performWithoutAnimation {
        self.tableView.reloadRows(at: [lastIndexPath], with: .none)
      }
      
      // Only scroll if user was near bottom
      if wasNearBottom {
        scrollToBottomWithoutChecks(animated: false)
      }
    }
  }
  
  func isNearBottom() -> Bool {
    // If no content, consider near bottom
    guard tableView.contentSize.height > 0 else { return true }
    
    let contentHeight = tableView.contentSize.height
    let scrollViewHeight = tableView.bounds.height
    let contentInsetBottom = tableView.contentInset.bottom
    let currentOffset = tableView.contentOffset.y
    
    let maxOffset = contentHeight - scrollViewHeight + contentInsetBottom
    let distanceFromBottom = maxOffset - currentOffset
    
    return distanceFromBottom <= 100
  }
  
  func scrollToBottomWithoutChecks(animated: Bool) {
    guard !viewModel.messages.isEmpty else { return }
    
    let lastRow = viewModel.messages.count - 1
    let indexPath = IndexPath(row: lastRow, section: 0)
    
    // Make sure table is laid out
    tableView.layoutIfNeeded()
    
    guard tableView.numberOfRows(inSection: 0) > lastRow else { return }
    
    // Hide scroll indicators completely
    tableView.showsVerticalScrollIndicator = false
    
    if animated {
      UIView.animate(withDuration: 0.3) {
        self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
      }
    } else {
      tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
    }
  }
  
  func scrollToBottom(animated: Bool) {
    // Only scroll if user hasn't manually scrolled away
    guard !scrollManager.isScrolling else { return }
    
    // Check if we should auto-scroll based on current position
    if !scrollManager.canAutoScroll && !isNearBottom() {
      return
    }
    
    scrollToBottomWithoutChecks(animated: animated)
  }
}

// MARK: - UITableViewDataSource

extension ChatViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return viewModel.messages.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(
      withIdentifier: "ChatMessageCell",
      for: indexPath
    ) as? ChatMessageCell else {
      return UITableViewCell()
    }

    let message = viewModel.messages[indexPath.row]
    cell.configure(with: message)

    return cell
  }
}

// MARK: - UITableViewDelegate

extension ChatViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return UITableView.automaticDimension
  }

  func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
    let message = viewModel.messages[indexPath.row]
    if message.isTypingIndicator || message.isProcessingAudio {
      return 50
    } else {
      return message.text.count > 200 ? 150 : 80
    }
  }

  func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    guard !viewModel.isLoadingConversation else {
      cell.alpha = 1
      cell.transform = .identity
      return
    }
    
    if indexPath.row >= previousMessageCount - 1 {
      cell.alpha = 0
      cell.transform = CGAffineTransform(translationX: 0, y: 10)

      UIView.animate(
        withDuration: 0.4,
        delay: 0,
        options: [.curveEaseOut],
        animations: {
          cell.alpha = 1
          cell.transform = .identity
        }
      )
    }
  }
}

// MARK: - Scroll View Delegate

extension ChatViewController {
  func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    scrollManager.beginScrolling()
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    // Update auto-scroll state based on position
    scrollManager.updateAutoScrollBehavior(scrollView: scrollView)
  }

  func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    if !decelerate {
      scrollManager.endScrolling()
      // Trigger update now that user stopped scrolling
      updateMessages()
    }
  }

  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    scrollManager.endScrolling()
    // Trigger update now that user stopped scrolling
    updateMessages()
  }

  func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
    scrollManager.endScrolling()
  }
}

// MARK: - ChatInputViewDelegate

extension ChatViewController: ChatInputViewDelegate {
  func chatInputView(_ inputView: ChatInputView, didChangeText text: String) {
    // Text changed - handled by ChatInputView
  }
  
  func chatInputViewDidRequestSend(_ inputView: ChatInputView, text: String) {
    Task {
      await sendMessage(text: text)
    }
  }
  
  func chatInputViewDidRequestRecord(_ inputView: ChatInputView) {
    if viewModel.isRecording {
      stopRecording()
    } else {
      let permission = viewModel.checkMicrophonePermission()
      
      switch permission {
      case .undetermined:
        viewModel.requestMicrophonePermission { [weak self] granted in
          if granted {
            self?.startRecording()
          } else {
            self?.showPermissionDeniedAlert()
          }
        }
        
      case .denied:
        showPermissionDeniedAlert()
        
      case .granted:
        startRecording()
        
      @unknown default:
        startRecording()
      }
    }
  }
  
  func chatInputViewDidRequestHandsFree(_ inputView: ChatInputView) {
    viewModel.toggleHandsFreeMode()
    chatInputView.updateHandsFreeButton(
      isEnabled: viewModel.isHandsFreeModeEnabled,
      isListening: viewModel.isHandsFreeListening
    )
    updateVoiceButtonAppearance()
    
    let generator = UIImpactFeedbackGenerator(style: .medium)
    generator.impactOccurred()
  }
}
