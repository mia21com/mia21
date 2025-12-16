//
//  ChatMessageCell.swift
//  MiaUIKitExample
//
//  Created on November 4, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Custom table view cell for displaying chat messages
//  with ChatGPT-style bubbles and streaming indicators.
//

import UIKit

// MARK: - Chat Message Cell

final class ChatMessageCell: UITableViewCell {

  // MARK: - UI Components

  private lazy var bubbleView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.layer.cornerRadius = 18
    view.layer.cornerCurve = .continuous
    return view
  }()

  private lazy var messageLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.numberOfLines = 0
    label.font = .systemFont(ofSize: 16, weight: .regular)
    return label
  }()

  private lazy var cursorView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .label
    view.alpha = 0
    return view
  }()

  private var cursorWidthConstraint: NSLayoutConstraint!
  private var cursorHeightConstraint: NSLayoutConstraint!
  private var leadingConstraint: NSLayoutConstraint!
  private var trailingConstraint: NSLayoutConstraint!
  private var typingIndicator: TypingIndicatorView?
  private var typingIndicatorConstraints: [NSLayoutConstraint] = []
  private var previousText: String = ""
  private var currentTextColor: UIColor = .label
  private var collapseDoubleNewlines: Bool = true

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
    contentView.addSubview(bubbleView)
    bubbleView.addSubview(messageLabel)
    bubbleView.addSubview(cursorView)

    leadingConstraint = bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
    trailingConstraint = bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)

    cursorWidthConstraint = cursorView.widthAnchor.constraint(equalToConstant: 2)
    cursorHeightConstraint = cursorView.heightAnchor.constraint(equalToConstant: 18)

    NSLayoutConstraint.activate([
      // Bubble constraints
      bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
      bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
      bubbleView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.75),

      // Label constraints
      messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 12),
      messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 14),
      messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -14),
      messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -12),

      // Cursor constraints
      cursorView.leadingAnchor.constraint(equalTo: messageLabel.trailingAnchor, constant: 2),
      cursorView.bottomAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: -2),
      cursorWidthConstraint,
      cursorHeightConstraint
    ])
  }

  // MARK: - Configuration

  func configure(with message: ChatMessage) {
    resetCellState()

    if message.isTypingIndicator || message.isProcessingAudio {
      configureTypingIndicator(isProcessingAudio: message.isProcessingAudio)
    } else if message.isUser {
      configureUserMessage(message)
    } else {
      configureAssistantMessage(message)
    }

    setNeedsLayout()
    layoutIfNeeded()
  }

  // MARK: - Private Configuration Methods

  private func resetCellState() {
    NSLayoutConstraint.deactivate(typingIndicatorConstraints)
    typingIndicatorConstraints.removeAll()
    typingIndicator?.stopAnimating()
    typingIndicator?.removeFromSuperview()
    typingIndicator = nil
    messageLabel.isHidden = false
  }

  private func configureTypingIndicator(isProcessingAudio: Bool) {
    messageLabel.isHidden = true
    messageLabel.text = ""
    cursorView.alpha = 0
    cursorView.layer.removeAllAnimations()

    if isProcessingAudio {
      bubbleView.backgroundColor = .systemBlue.withAlphaComponent(0.7)
      applyBubbleAlignment(isUserMessage: true)
    } else {
      bubbleView.backgroundColor = .secondarySystemBackground
      applyBubbleAlignment(isUserMessage: false)
    }

    setupTypingIndicatorView()
  }

  private func setupTypingIndicatorView() {
    let indicator = TypingIndicatorView()
    indicator.translatesAutoresizingMaskIntoConstraints = false
    bubbleView.addSubview(indicator)

    typingIndicatorConstraints = [
      indicator.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
      indicator.trailingAnchor.constraint(lessThanOrEqualTo: bubbleView.trailingAnchor, constant: -12),
      indicator.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 10),
      indicator.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -10)
    ]
    NSLayoutConstraint.activate(typingIndicatorConstraints)

    typingIndicator = indicator
    indicator.startAnimating()
  }

  private func configureUserMessage(_ message: ChatMessage) {
    messageLabel.isHidden = false
    bubbleView.backgroundColor = .systemBlue
    currentTextColor = .white
    cursorView.backgroundColor = .white
    applyBubbleAlignment(isUserMessage: true)

    messageLabel.textColor = .white
    messageLabel.attributedText = message.text.parseMarkdown(with: currentTextColor)
  }

  private func configureAssistantMessage(_ message: ChatMessage) {
    messageLabel.isHidden = false
    bubbleView.backgroundColor = .secondarySystemBackground
    currentTextColor = .label
    cursorView.backgroundColor = .label
    collapseDoubleNewlines = message.collapseDoubleNewlines
    applyBubbleAlignment(isUserMessage: false)

    updateAssistantMessageText(message)
    updateStreamingState(isStreaming: message.isStreaming)
  }

  private func updateAssistantMessageText(_ message: ChatMessage) {
    messageLabel.attributedText = message.text.parseMarkdown(
      with: currentTextColor,
      isStreaming: message.isStreaming,
      collapseDoubleNewlines: message.collapseDoubleNewlines
    )
    previousText = message.text
  }

  private func animateTextUpdate(_ text: String) {
    // animateTextUpdate is only called during streaming, so always pass true
    messageLabel.attributedText = text.parseMarkdown(
      with: currentTextColor,
      isStreaming: true,
      collapseDoubleNewlines: collapseDoubleNewlines
    )
  }

  private func updateStreamingState(isStreaming: Bool) {
    if isStreaming {
      startCursorAnimation()
    } else {
      stopCursorAnimation()
    }
  }

  private func applyBubbleAlignment(isUserMessage: Bool) {
    if isUserMessage {
      leadingConstraint.isActive = false
      trailingConstraint.isActive = true
    } else {
      trailingConstraint.isActive = false
      leadingConstraint.isActive = true
    }
  }

  // MARK: - Cursor Animation

  private func startCursorAnimation() {
    cursorView.alpha = 1

    UIView.animate(
      withDuration: 0.5,
      delay: 0,
      options: [.repeat, .autoreverse, .curveEaseInOut],
      animations: {
        self.cursorView.alpha = 0.2
      }
    )
  }

  private func stopCursorAnimation() {
    cursorView.layer.removeAllAnimations()
    UIView.animate(withDuration: 0.2) {
      self.cursorView.alpha = 0
    }
  }

  // MARK: - Reuse

  override func prepareForReuse() {
    super.prepareForReuse()
    previousText = ""
    messageLabel.alpha = 1.0
    stopCursorAnimation()
    NSLayoutConstraint.deactivate(typingIndicatorConstraints)
    typingIndicatorConstraints.removeAll()
    typingIndicator?.stopAnimating()
    typingIndicator?.removeFromSuperview()
    typingIndicator = nil
  }
}
