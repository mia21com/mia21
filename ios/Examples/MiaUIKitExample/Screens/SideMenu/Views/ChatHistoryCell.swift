//
//  ChatHistoryCell.swift
//  MiaUIKitExample
//
//  Created on November 20, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Table view cell displaying a chat history item.
//

import UIKit
import Mia21

// MARK: - Chat History Cell

class ChatHistoryCell: UITableViewCell {

  // MARK: - UI Components

  private lazy var containerView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .clear
    view.layer.cornerRadius = 6
    return view
  }()

  private lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = .systemFont(ofSize: 14, weight: .regular)
    label.textColor = .label
    label.numberOfLines = 1
    return label
  }()

  // MARK: - Initialization

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setupUI()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Setup

  private func setupUI() {
    backgroundColor = .clear
    selectionStyle = .none

    contentView.addSubview(containerView)
    containerView.addSubview(titleLabel)

    NSLayoutConstraint.activate([
      containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 1),
      containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
      containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
      containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -1),

      titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
      titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
      titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
      titleLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
    ])
  }

  // MARK: - Overrides

  override func setHighlighted(_ highlighted: Bool, animated: Bool) {
    super.setHighlighted(highlighted, animated: animated)

  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

  }

  // MARK: - Configuration

  func setSelectedState(_ isSelected: Bool) {
    containerView.backgroundColor = isSelected ? UIColor.chatHistorySelectedBackground : .clear
  }

  func configure(with conversation: ConversationSummary, spaces: [Space], bots: [Bot], isSelected: Bool = false) {
    let spaceName = spaces.first(where: { $0.spaceId == conversation.spaceId })?.name
    let botName = bots.first(where: { $0.botId == conversation.botId })?.name

    titleLabel.text = conversation.displayTitle(spaceName: spaceName, botName: botName)
    setSelectedState(isSelected)
  }

  func configure(with chat: ChatHistoryItem) {
    titleLabel.text = chat.title
  }
}
