//
//  ChatInputView.swift
//  MiaUIKitExample
//
//  Created on November 20, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Input container view with text field, mic, send, and hands-free buttons.
//  Handles all input-related UI and user interactions.
//

import UIKit

protocol ChatInputViewDelegate: AnyObject {
  func chatInputView(_ inputView: ChatInputView, didChangeText text: String)
  func chatInputViewDidRequestSend(_ inputView: ChatInputView, text: String)
  func chatInputViewDidRequestRecord(_ inputView: ChatInputView)
  func chatInputViewDidRequestHandsFree(_ inputView: ChatInputView)
}

final class ChatInputView: UIView {
  
  // MARK: - Properties
  
  weak var delegate: ChatInputViewDelegate?
  
  var text: String {
    get { messageTextView.text ?? "" }
    set {
      messageTextView.text = newValue
      updatePlaceholderVisibility()
      updateTextViewHeight()
    }
  }
  
  var isLoading: Bool = false {
    didSet {
      updateSendButtonState()
    }
  }
  
  var isRecording: Bool = false {
    didSet {
      updateRecordButtonState()
      updatePlaceholderVisibility()
      updateUIForRecording()
    }
  }
  
  var isTranscribing: Bool = false {
    didSet {
      updateRecordButtonState()
      updatePlaceholderVisibility()
      updateHandsFreeButtonEnabledState()
      updateUIForTranscribing()
    }
  }
  
  var isHandsFreeModeEnabled: Bool = false {
    didSet {
      updateUIForHandsFreeMode()
    }
  }
  
  var recordingStatusText: String = "" {
    didSet {
      statusLabel.text = recordingStatusText
      // Show label when there's text and status container is visible
      updateStatusLabelVisibility()
    }
  }
  
  private func updateStatusLabelVisibility() {
    let shouldShow = !recordingStatusText.isEmpty && !statusContainer.isHidden
    statusLabel.isHidden = !shouldShow
  }
  
  // MARK: - UI Components
  
  private lazy var messageTextView: UITextView = {
    let textView = UITextView()
    textView.translatesAutoresizingMaskIntoConstraints = false
    textView.backgroundColor = .secondarySystemBackground
    textView.layer.cornerRadius = 23
    textView.layer.cornerCurve = .continuous
    textView.font = .systemFont(ofSize: 16)
    textView.textContainerInset = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
    textView.textContainer.lineFragmentPadding = 0
    textView.textContainer.maximumNumberOfLines = 0
    textView.textContainer.lineBreakMode = .byWordWrapping
    textView.isScrollEnabled = false
    textView.delegate = self
    textView.returnKeyType = .send
    textView.enablesReturnKeyAutomatically = true
    textView.showsVerticalScrollIndicator = false
    textView.showsHorizontalScrollIndicator = false
    return textView
  }()
  
  private lazy var placeholderLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = "Message"
    label.textColor = .placeholderText
    label.font = .systemFont(ofSize: 16)
    label.isUserInteractionEnabled = false
    return label
  }()
  
  private lazy var textViewContainer: UIView = {
    let container = UIView()
    container.translatesAutoresizingMaskIntoConstraints = false
    container.backgroundColor = .secondarySystemBackground
    container.layer.cornerRadius = 23
    container.layer.cornerCurve = .continuous
    return container
  }()
  
  private lazy var statusContainer: UIView = {
    let container = UIView()
    container.translatesAutoresizingMaskIntoConstraints = false
    container.backgroundColor = .clear
    container.isHidden = true
    container.clipsToBounds = true
    
    container.addSubview(activityIndicator)
    container.addSubview(statusLabel)
    
    NSLayoutConstraint.activate([
      activityIndicator.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
      activityIndicator.centerYAnchor.constraint(equalTo: container.centerYAnchor),
      
      statusLabel.leadingAnchor.constraint(equalTo: activityIndicator.trailingAnchor, constant: 8),
      statusLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
      statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -16),
      statusLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 20)
    ])
    
    return container
  }()
  
  private lazy var activityIndicator: UIActivityIndicatorView = {
    let indicator = UIActivityIndicatorView(style: .medium)
    indicator.hidesWhenStopped = true
    indicator.translatesAutoresizingMaskIntoConstraints = false
    return indicator
  }()
  
  private lazy var statusLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = .systemFont(ofSize: 16)
    label.textColor = .secondaryLabel
    label.isUserInteractionEnabled = false
    return label
  }()
  
  private lazy var recordButton: UIButton = {
    let button = UIButton(type: .custom)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.backgroundColor = .secondarySystemFill
    button.layer.cornerRadius = 18
    button.layer.cornerCurve = .continuous
    
    let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
    let image = UIImage(systemName: "mic.fill", withConfiguration: config)
    button.setImage(image, for: .normal)
    button.tintColor = .label
    button.addTarget(self, action: #selector(recordButtonTapped), for: .touchUpInside)
    
    return button
  }()
  
  private lazy var sendButton: UIButton = {
    let button = UIButton(type: .custom)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.layer.cornerRadius = 18
    button.layer.cornerCurve = .continuous

    let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)
    let image = UIImage(systemName: "arrow.up", withConfiguration: config)
    button.setImage(image, for: .normal)
    button.tintColor = .white
    button.imageView?.contentMode = .scaleAspectFit
    button.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
    
    return button
  }()
  
  private lazy var handsFreeButton: UIButton = {
    let button = UIButton(type: .custom)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.backgroundColor = .secondarySystemFill
    button.layer.cornerRadius = 18
    button.layer.cornerCurve = .continuous
    
    let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
    let image = UIImage(systemName: "waveform", withConfiguration: config)
    button.setImage(image, for: .normal)
    button.tintColor = .label
    button.addTarget(self, action: #selector(handsFreeButtonTapped), for: .touchUpInside)
    
    return button
  }()
  
  private lazy var buttonStackView: UIStackView = {
    let stack = UIStackView(arrangedSubviews: [recordButton, sendButton, handsFreeButton])
    stack.translatesAutoresizingMaskIntoConstraints = false
    stack.axis = .horizontal
    stack.spacing = 8
    stack.alignment = .fill
    stack.distribution = .fill
    
    sendButton.isHidden = true
    
    return stack
  }()
  
  private var textViewHeightConstraint: NSLayoutConstraint!
  private let buttonManager = InputButtonManager()
  
  // MARK: - Constants
  
  private enum Constants {
    static let buttonSize: CGFloat = 36
    static let textViewMinHeight: CGFloat = 46
    static let textViewMaxHeight: CGFloat = 120
    static let inputContainerMinHeight: CGFloat = 70
  }
  
  // MARK: - Initialization
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
    setupButtonManager()
    addGradientToSendButton()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    
    // Update gradient layer frame
    if let gradientLayer = sendButton.layer.sublayers?.first(where: { $0 is CAGradientLayer }) as? CAGradientLayer {
      gradientLayer.frame = sendButton.bounds
    }
    
    // Update text view height after layout
    DispatchQueue.main.async { [weak self] in
      self?.updateTextViewHeight()
      self?.updatePlaceholderVisibility()
    }
  }
  
  // MARK: - Setup
  
  private func setupUI() {
    backgroundColor = .systemBackground

    let border = UIView()
    border.translatesAutoresizingMaskIntoConstraints = false
    border.backgroundColor = .separator
    addSubview(border)
    
    addSubview(textViewContainer)
    textViewContainer.addSubview(messageTextView)
    textViewContainer.addSubview(placeholderLabel)
    textViewContainer.addSubview(statusContainer)
    addSubview(buttonStackView)
    
    textViewHeightConstraint = messageTextView.heightAnchor.constraint(equalToConstant: Constants.textViewMinHeight)
    
    NSLayoutConstraint.activate([
      border.topAnchor.constraint(equalTo: topAnchor),
      border.leadingAnchor.constraint(equalTo: leadingAnchor),
      border.trailingAnchor.constraint(equalTo: trailingAnchor),
      border.heightAnchor.constraint(equalToConstant: 0.5),
      
      textViewContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
      textViewContainer.topAnchor.constraint(equalTo: topAnchor, constant: 12),
      textViewContainer.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
      textViewContainer.trailingAnchor.constraint(equalTo: buttonStackView.leadingAnchor, constant: -12),
      
      messageTextView.leadingAnchor.constraint(equalTo: textViewContainer.leadingAnchor),
      messageTextView.trailingAnchor.constraint(equalTo: textViewContainer.trailingAnchor),
      messageTextView.topAnchor.constraint(equalTo: textViewContainer.topAnchor),
      messageTextView.bottomAnchor.constraint(equalTo: textViewContainer.bottomAnchor),
      textViewHeightConstraint,
      
      placeholderLabel.leadingAnchor.constraint(equalTo: messageTextView.leadingAnchor, constant: 16),
      placeholderLabel.topAnchor.constraint(equalTo: messageTextView.topAnchor, constant: 12),
      placeholderLabel.trailingAnchor.constraint(equalTo: messageTextView.trailingAnchor, constant: -16),
      
      statusContainer.leadingAnchor.constraint(equalTo: textViewContainer.leadingAnchor),
      statusContainer.trailingAnchor.constraint(equalTo: textViewContainer.trailingAnchor),
      statusContainer.topAnchor.constraint(equalTo: textViewContainer.topAnchor),
      statusContainer.bottomAnchor.constraint(equalTo: textViewContainer.bottomAnchor),
      
      buttonStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
      buttonStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
      
      recordButton.widthAnchor.constraint(equalToConstant: Constants.buttonSize),
      recordButton.heightAnchor.constraint(equalToConstant: Constants.buttonSize),
      
      sendButton.widthAnchor.constraint(equalToConstant: Constants.buttonSize),
      sendButton.heightAnchor.constraint(equalToConstant: Constants.buttonSize),
      
      handsFreeButton.widthAnchor.constraint(equalToConstant: Constants.buttonSize),
      handsFreeButton.heightAnchor.constraint(equalToConstant: Constants.buttonSize),
      
      heightAnchor.constraint(greaterThanOrEqualToConstant: Constants.inputContainerMinHeight)
    ])
  }
  
  private func setupButtonManager() {
    buttonManager.recordButton = recordButton
    buttonManager.sendButton = sendButton
    buttonManager.handsFreeButton = handsFreeButton
  }
  
  private func addGradientToSendButton() {
    let gradientLayer = CAGradientLayer.appGradient(frame: sendButton.bounds, cornerRadius: 18)
    sendButton.layer.insertSublayer(gradientLayer, at: 0)
    
    if let imageView = sendButton.imageView {
      sendButton.bringSubviewToFront(imageView)
    }
  }
  
  // MARK: - Actions
  
  @objc private func recordButtonTapped() {
    delegate?.chatInputViewDidRequestRecord(self)
  }
  
  @objc private func sendButtonTapped() {
    let text = messageTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    guard !text.isEmpty else { return }
    delegate?.chatInputViewDidRequestSend(self, text: text)
  }
  
  @objc private func handsFreeButtonTapped() {
    delegate?.chatInputViewDidRequestHandsFree(self)
  }
  
  // MARK: - UI Updates
  
  func updatePlaceholderVisibility() {
    // Hide placeholder if there's text, or if recording/transcribing
    placeholderLabel.isHidden = !messageTextView.text.isEmpty || isRecording || isTranscribing
  }
  
  func updateTextViewHeight() {
    guard messageTextView.frame.width > 0 else { return }
    
    let fixedWidth = messageTextView.frame.width - messageTextView.textContainerInset.left - messageTextView.textContainerInset.right
    let newSize = messageTextView.sizeThatFits(CGSize(width: fixedWidth, height: .greatestFiniteMagnitude))
    let height = min(max(newSize.height, Constants.textViewMinHeight), Constants.textViewMaxHeight)
    
    textViewHeightConstraint.constant = height
    messageTextView.isScrollEnabled = height >= Constants.textViewMaxHeight
    
    UIView.animate(withDuration: 0.2) {
      self.superview?.layoutIfNeeded()
    }
  }
  
  private func updateRecordButtonState() {
    recordButton.isEnabled = !isTranscribing
    recordButton.alpha = isTranscribing ? 0.5 : 1.0
  }
  
  private func updateSendButtonState() {
    sendButton.isEnabled = !isLoading
    sendButton.alpha = isLoading ? 0.4 : 1.0
  }
  
  private func updateUIForRecording() {
    if isRecording {
      messageTextView.text = ""
      messageTextView.isEditable = false
      messageTextView.isHidden = true
      placeholderLabel.isHidden = true
      statusContainer.isHidden = false
      activityIndicator.startAnimating()
      buttonManager.updateRecordButton(isRecording: true)
      updateStatusLabelVisibility()
      updateHandsFreeButtonEnabledState()
      
      UIView.animate(withDuration: 0.2) {
        // Hide only if hands-free mode is not active
        self.handsFreeButton.isHidden = !self.isHandsFreeModeEnabled
        self.layoutIfNeeded()
      }
    } else {
      if !isTranscribing {
        messageTextView.isEditable = true
        messageTextView.isHidden = false
        statusContainer.isHidden = true
        activityIndicator.stopAnimating()
        statusLabel.isHidden = true
        updatePlaceholderVisibility()
      }
      buttonManager.updateRecordButton(isRecording: false)
      updateHandsFreeButtonEnabledState()
      
      UIView.animate(withDuration: 0.2) {
        // Show if hands-free is active, otherwise hide if text exists or transcribing
        self.handsFreeButton.isHidden = !self.isHandsFreeModeEnabled && (self.hasText || self.isTranscribing)
        self.layoutIfNeeded()
      }
    }
  }
  
  private func updateUIForTranscribing() {
    if isTranscribing {
      messageTextView.text = ""
      messageTextView.isEditable = false
      messageTextView.isHidden = true
      placeholderLabel.isHidden = true
      statusContainer.isHidden = false
      activityIndicator.startAnimating()
      updateStatusLabelVisibility()
      updateRecordButtonState()
      updateHandsFreeButtonEnabledState()
      
      UIView.animate(withDuration: 0.2) {
        // Hide only if hands-free mode is not active
        self.handsFreeButton.isHidden = !self.isHandsFreeModeEnabled
        self.layoutIfNeeded()
      }
    } else {
      if !isRecording {
        messageTextView.isEditable = true
        messageTextView.isHidden = false
        statusContainer.isHidden = true
        activityIndicator.stopAnimating()
        statusLabel.isHidden = true
        updatePlaceholderVisibility()
      }
      updateRecordButtonState()
      updateHandsFreeButtonEnabledState()
      
      UIView.animate(withDuration: 0.2) {
        // Show if hands-free is active, otherwise hide if text exists or recording
        self.handsFreeButton.isHidden = !self.isHandsFreeModeEnabled && (self.hasText || self.isRecording)
        self.layoutIfNeeded()
      }
    }
  }
  
  private func updateUIForHandsFreeMode() {
    buttonManager.updateForHandsFreeMode(isActive: isHandsFreeModeEnabled, messageTextView: messageTextView)
    
    // Update hands-free button visibility when mode is toggled
    let hasText = !messageTextView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    updateButtonStates(hasText: hasText)
  }
  
  func updateButtonStates(hasText: Bool) {
    buttonManager.updateForTextInput(hasText: hasText)
    
    // Show hands-free button only when:
    // - Hands-free mode is active, OR
    // - Text field is empty AND not recording AND not transcribing
    let shouldHide = !isHandsFreeModeEnabled && (hasText || isRecording || isTranscribing)
    guard handsFreeButton.isHidden != shouldHide else {
      updateHandsFreeButtonEnabledState()
      return
    }
    
    UIView.animate(withDuration: 0.2) {
      self.handsFreeButton.isHidden = shouldHide
      self.layoutIfNeeded()
    }
    
    updateHandsFreeButtonEnabledState()
  }
  
  private func updateHandsFreeButtonEnabledState() {
    handsFreeButton.isEnabled = !isTranscribing
    handsFreeButton.alpha = isTranscribing ? 0.5 : 1.0
  }
  
  func updateHandsFreeButton(isEnabled: Bool, isListening: Bool) {
    buttonManager.updateHandsFreeButton(isEnabled: isEnabled, isListening: isListening)
  }
  
  func clearText() {
    messageTextView.text = ""
    updatePlaceholderVisibility()
    updateTextViewHeight()
    updateButtonStates(hasText: false)
  }
  
  func focusTextView() {
    _ = messageTextView.becomeFirstResponder()
  }
  
  func unfocusTextView() {
    _ = messageTextView.resignFirstResponder()
  }
  
  var isTextViewFirstResponder: Bool {
    return messageTextView.isFirstResponder
  }
  
  private var hasText: Bool {
    !messageTextView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }
}

// MARK: - UITextViewDelegate

extension ChatInputView: UITextViewDelegate {
  func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
    return true
  }
  
  func textViewDidChange(_ textView: UITextView) {
    updatePlaceholderVisibility()
    updateTextViewHeight()
    let hasText = !textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    updateButtonStates(hasText: hasText)
    delegate?.chatInputView(self, didChangeText: textView.text ?? "")
  }
}

