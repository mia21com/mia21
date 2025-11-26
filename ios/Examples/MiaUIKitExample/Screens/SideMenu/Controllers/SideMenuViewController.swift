//
//  SideMenuViewController.swift
//  MiaUIKitExample
//
//  Created on November 4, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Side menu with ChatGPT-style design following MVVM architecture.
//  Displays chat history organized by space and provides space selection.
//

import UIKit
import Mia21

// MARK: - Side Menu View Controller

final class SideMenuViewController: UIViewController {

  // MARK: - Properties
  
  private let viewModel: SideMenuViewModel
  
  // Coordinator callbacks

  var onNewChat: (() -> Void)?
  var onSelectChat: ((String) -> Void)?
  var onSpaceChanged: ((Space, Bot?) -> Void)?
  var onBotChanged: ((Bot) -> Void)?

  // MARK: - UI Components

  private lazy var headerView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .clear
    return view
  }()

  private lazy var newChatButton: UIButton = {
    let button = UIButton(type: .system)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.contentHorizontalAlignment = .center

    let iconView = UIImageView(image: UIImage(systemName: "plus"))
    iconView.tintColor = .white
    iconView.contentMode = .scaleAspectFit
    iconView.translatesAutoresizingMaskIntoConstraints = false

    let label = UILabel()
    label.text = "New Chat"
    label.font = .systemFont(ofSize: 15, weight: .medium)
    label.textColor = .white
    label.translatesAutoresizingMaskIntoConstraints = false

    let stackView = UIStackView(arrangedSubviews: [iconView, label])
    stackView.axis = .horizontal
    stackView.spacing = 8
    stackView.alignment = .center
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.isUserInteractionEnabled = false

    button.addSubview(stackView)

    NSLayoutConstraint.activate([
      iconView.widthAnchor.constraint(equalToConstant: 16),
      iconView.heightAnchor.constraint(equalToConstant: 16),
      stackView.centerXAnchor.constraint(equalTo: button.centerXAnchor),
      stackView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
      stackView.leadingAnchor.constraint(greaterThanOrEqualTo: button.leadingAnchor, constant: 16),
      stackView.trailingAnchor.constraint(lessThanOrEqualTo: button.trailingAnchor, constant: -16)
    ])

    button.layer.cornerRadius = 10
    button.clipsToBounds = true
    button.addAction(UIAction { [weak self] _ in
      self?.handleNewChat()
    }, for: .touchUpInside)

    return button
  }()

  private lazy var recentsHeaderView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .clear
    return view
  }()

  private lazy var recentsLabel: UILabel = {
    let label = UILabel()
    label.text = "RECENTS"
    label.font = .systemFont(ofSize: 11, weight: .semibold)
    label.textColor = .secondaryLabel
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()

  private lazy var spaceSelectorContainer: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .clear
    return view
  }()

  private lazy var spaceButton: SelectorButton = {
    let button = SelectorButton(
      avatarText: "S",
      titleText: "Select Space",
      isBot: false
    )
    button.addTarget(self, action: #selector(spaceButtonTapped), for: .touchUpInside)
    return button
  }()

  private lazy var botButton: SelectorButton = {
    let button = SelectorButton(
      avatarText: "✨",
      titleText: "Select Bot",
      isBot: true
    )
    button.addTarget(self, action: #selector(botButtonTapped), for: .touchUpInside)
    return button
  }()

  private lazy var tableView: UITableView = {
    let table = UITableView(frame: .zero, style: .plain)
    table.translatesAutoresizingMaskIntoConstraints = false
    table.backgroundColor = .clear
    table.separatorStyle = .none
    table.dataSource = self
    table.delegate = self
    table.register(ChatHistoryCell.self, forCellReuseIdentifier: "ChatHistoryCell")
    return table
  }()
  
  // MARK: - Initialization
  
  init(client: Mia21Client, appId: String) {
    self.viewModel = SideMenuViewModel(client: client, appId: appId)
    super.init(nibName: nil, bundle: nil)
    setupViewModelBindings()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    addGradients()

      Task {
      await viewModel.loadInitialDataIfNeeded()
    }
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    updateGradientFrames()
  }
  
  // MARK: - Setup
  
  private func setupViewModelBindings() {
    viewModel.onConversationsChanged = { [weak self] in
      self?.tableView.reloadData()
    }
    
    viewModel.onSelectedSpaceChanged = { [weak self] in
      self?.updateSpaceButton()
    }
    
    viewModel.onSelectedBotChanged = { [weak self] in
      self?.updateBotButton()
    }
    
    viewModel.onSelectedConversationChanged = { [weak self] in
      self?.tableView.reloadData()
      
      if self?.viewModel.selectedConversationId == nil {
        self?.onNewChat?()
    }
  }

    viewModel.onError = { [weak self] message in
      self?.showError(message)
    }
  }

  private func setupUI() {
    view.backgroundColor = .sideMenuBackgroundLight

    view.layer.shadowColor = UIColor.black.cgColor
    view.layer.shadowOpacity = 0.08
    view.layer.shadowOffset = CGSize(width: 2, height: 0)
    view.layer.shadowRadius = 8

    view.addSubview(headerView)
    headerView.addSubview(newChatButton)
    view.addSubview(recentsHeaderView)
    recentsHeaderView.addSubview(recentsLabel)
    view.addSubview(tableView)
    view.addSubview(spaceSelectorContainer)

    let separatorLine = UIView()
    separatorLine.backgroundColor = .separator
    separatorLine.translatesAutoresizingMaskIntoConstraints = false
    spaceSelectorContainer.addSubview(separatorLine)
    spaceSelectorContainer.addSubview(spaceButton)
    spaceSelectorContainer.addSubview(botButton)

    NSLayoutConstraint.activate([
      headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -10),
      headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      headerView.heightAnchor.constraint(equalToConstant: 44),

      newChatButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 12),
      newChatButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -12),
      newChatButton.topAnchor.constraint(equalTo: headerView.topAnchor),
      newChatButton.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),

      recentsHeaderView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 20),
      recentsHeaderView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      recentsHeaderView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      recentsHeaderView.heightAnchor.constraint(equalToConstant: 24),

      recentsLabel.leadingAnchor.constraint(equalTo: recentsHeaderView.leadingAnchor, constant: 16),
      recentsLabel.centerYAnchor.constraint(equalTo: recentsHeaderView.centerYAnchor),

      tableView.topAnchor.constraint(equalTo: recentsHeaderView.bottomAnchor, constant: 8),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: spaceSelectorContainer.topAnchor),
   
      spaceSelectorContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      spaceSelectorContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      spaceSelectorContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
      spaceSelectorContainer.heightAnchor.constraint(equalToConstant: 136),

      separatorLine.topAnchor.constraint(equalTo: spaceSelectorContainer.topAnchor),
      separatorLine.leadingAnchor.constraint(equalTo: spaceSelectorContainer.leadingAnchor, constant: 12),
      separatorLine.trailingAnchor.constraint(equalTo: spaceSelectorContainer.trailingAnchor, constant: -12),
      separatorLine.heightAnchor.constraint(equalToConstant: 0.5),

      spaceButton.topAnchor.constraint(equalTo: separatorLine.bottomAnchor, constant: 12),
      spaceButton.leadingAnchor.constraint(equalTo: spaceSelectorContainer.leadingAnchor, constant: 12),
      spaceButton.trailingAnchor.constraint(equalTo: spaceSelectorContainer.trailingAnchor, constant: -12),
      spaceButton.heightAnchor.constraint(equalToConstant: 52),

      botButton.topAnchor.constraint(equalTo: spaceButton.bottomAnchor, constant: 8),
      botButton.leadingAnchor.constraint(equalTo: spaceSelectorContainer.leadingAnchor, constant: 12),
      botButton.trailingAnchor.constraint(equalTo: spaceSelectorContainer.trailingAnchor, constant: -12),
      botButton.heightAnchor.constraint(equalToConstant: 52)
    ])
  }

  // MARK: - UI Helpers
  
  private func addGradients() {
    addGradient(to: newChatButton, cornerRadius: 10)
    addGradient(to: spaceButton.avatarView, cornerRadius: 18)
    addGradient(to: botButton.avatarView, cornerRadius: 18)
  }

  private func addGradient(to view: UIView, cornerRadius: CGFloat) {
    let gradientLayer = CAGradientLayer.appGradient(frame: view.bounds, cornerRadius: cornerRadius)
    view.layer.insertSublayer(gradientLayer, at: 0)
  }

  private func updateGradientFrames() {
    updateGradientFrame(for: newChatButton)
    updateGradientFrame(for: spaceButton.avatarView)
    updateGradientFrame(for: botButton.avatarView)
  }
  
  private func updateGradientFrame(for view: UIView) {
    if let gradientLayer = view.layer.sublayers?.first(where: { $0 is CAGradientLayer }) as? CAGradientLayer {
      gradientLayer.frame = view.bounds
    }
  }

  private func updateSpaceButton() {
    spaceButton.updateTitle(viewModel.spaceDisplayName)
    spaceButton.updateAvatar(viewModel.spaceAvatarLetter)
  }

  private func updateBotButton() {
    botButton.updateTitle(viewModel.botDisplayName)
  }
  
  private func showError(_ message: String) {
    let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default))
    present(alert, animated: true)
  }
  
  // MARK: - Public Methods
  
  func setInitialData(
    spaces: [Space],
    selectedSpace: Space?,
    bots: [Bot],
    selectedBot: Bot?
  ) {
    viewModel.setInitialData(
      spaces: spaces,
      selectedSpace: selectedSpace,
      bots: bots,
      selectedBot: selectedBot
    )
    
    _ = self.view
    
    DispatchQueue.main.async { [weak self] in
      self?.updateSpaceButton()
      self?.updateBotButton()
    }
    
    Task {
      await viewModel.loadConversations()
    }
  }
  
  func reloadConversationsAfterCreation() {
    viewModel.reloadConversationsAfterCreation()
  }
  
  // MARK: - Actions

  @objc private func spaceButtonTapped() {
    guard viewModel.hasSpaces else { return }
    
    let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

    for space in viewModel.spaces {
      let action = UIAlertAction(title: space.name, style: .default) { [weak self] _ in
        self?.handleSpaceSelection(space)
      }

      if space.spaceId == viewModel.selectedSpace?.spaceId {
        action.setValue(true, forKey: "checked")
      }

      alert.addAction(action)
    }

    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

    if let popoverController = alert.popoverPresentationController {
      popoverController.sourceView = spaceButton
      popoverController.sourceRect = spaceButton.bounds
    }

    present(alert, animated: true)
  }

  @objc private func botButtonTapped() {
    guard viewModel.hasBots else { return }

    let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

    for bot in viewModel.bots {
      let action = UIAlertAction(title: bot.name, style: .default) { [weak self] _ in
        self?.handleBotSelection(bot)
      }

      if bot.id == viewModel.selectedBot?.id {
        action.setValue(true, forKey: "checked")
      }

      alert.addAction(action)
    }

    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

    if let popoverController = alert.popoverPresentationController {
      popoverController.sourceView = botButton
      popoverController.sourceRect = botButton.bounds
      popoverController.permittedArrowDirections = .down
    }

    present(alert, animated: true)
  }

  private func handleNewChat() {
    viewModel.clearConversationSelection()
    onNewChat?()
  }
  
  private func handleSpaceSelection(_ space: Space) {
    viewModel.selectSpace(space)
    tableView.reloadData()
    onSpaceChanged?(space, viewModel.selectedBot)
  }
    
  private func handleBotSelection(_ bot: Bot) {
    viewModel.selectBot(bot)
    onBotChanged?(bot)
  }
}

// MARK: - UITableViewDataSource

extension SideMenuViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return viewModel.numberOfConversations
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(
      withIdentifier: "ChatHistoryCell",
      for: indexPath
    ) as? ChatHistoryCell,
          let conversation = viewModel.conversation(at: indexPath.row) else {
      return UITableViewCell()
    }
    
    let isSelected = viewModel.isConversationSelected(at: indexPath.row)
    cell.configure(
      with: conversation,
      spaces: viewModel.spaces,
      bots: viewModel.bots,
      isSelected: isSelected
    )
    return cell
  }
}

// MARK: - UITableViewDelegate

extension SideMenuViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let conversation = viewModel.conversation(at: indexPath.row) else { return }
    viewModel.selectConversation(conversation.id)
    onSelectChat?(conversation.id)
  }

  func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (_, _, completionHandler) in
      guard let self = self else {
        completionHandler(false)
        return
      }
      
      Task {
        let success = await self.viewModel.deleteConversation(at: indexPath.row)
        completionHandler(success)
      }
    }
    
    deleteAction.image = UIImage(systemName: "trash")
    return UISwipeActionsConfiguration(actions: [deleteAction])
  }
}
