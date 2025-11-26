//
//  SelectorButton.swift
//  MiaUIKitExample
//
//  Created on November 21, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Custom button for space/bot selection with avatar and title.
//

import UIKit

// MARK: - Selector Button

final class SelectorButton: UIButton {
  
  // MARK: - UI Components
  
  let avatarView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.layer.cornerRadius = 18
    view.isUserInteractionEnabled = false
    return view
  }()
  
  private lazy var customAvatarLabel: UILabel = {
    let label = UILabel()
    label.textColor = .white
    label.textAlignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    label.isUserInteractionEnabled = false
    return label
  }()
  
  private lazy var customTitleLabel: UILabel = {
    let label = UILabel()
    label.font = .systemFont(ofSize: 15, weight: .medium)
    label.textColor = .label
    label.isUserInteractionEnabled = false
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()
  
  private lazy var customChevronIcon: UIImageView = {
    let icon = UIImageView(image: UIImage(systemName: "chevron.down"))
    icon.tintColor = .secondaryLabel
    icon.contentMode = .scaleAspectFit
    icon.translatesAutoresizingMaskIntoConstraints = false
    icon.isUserInteractionEnabled = false
    return icon
  }()
  
  // MARK: - Initialization
  
  init(avatarText: String, titleText: String, isBot: Bool) {
    super.init(frame: .zero)
    setupUI(avatarText: avatarText, titleText: titleText, isBot: isBot)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - Setup
  
  private func setupUI(avatarText: String, titleText: String, isBot: Bool) {
    translatesAutoresizingMaskIntoConstraints = false
    backgroundColor = .selectorButtonBackground
    layer.cornerRadius = 10
    layer.borderWidth = 1
    layer.borderColor = UIColor.selectorButtonBorder.cgColor
    
    customAvatarLabel.text = avatarText
    customAvatarLabel.font = isBot ? .systemFont(ofSize: 20) : .systemFont(ofSize: 16, weight: .semibold)
    customTitleLabel.text = titleText
    
    avatarView.addSubview(customAvatarLabel)
    addSubview(avatarView)
    addSubview(customTitleLabel)
    addSubview(customChevronIcon)
    
    NSLayoutConstraint.activate([
      avatarView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
      avatarView.centerYAnchor.constraint(equalTo: centerYAnchor),
      avatarView.widthAnchor.constraint(equalToConstant: 36),
      avatarView.heightAnchor.constraint(equalToConstant: 36),
      
      customAvatarLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
      customAvatarLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
      
      customTitleLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 12),
      customTitleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
      customTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: customChevronIcon.leadingAnchor, constant: -8),
      
      customChevronIcon.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
      customChevronIcon.centerYAnchor.constraint(equalTo: centerYAnchor),
      customChevronIcon.widthAnchor.constraint(equalToConstant: 10),
      customChevronIcon.heightAnchor.constraint(equalToConstant: 10)
    ])
  }
  
  // MARK: - Public Methods
  
  func updateTitle(_ text: String) {
    customTitleLabel.text = text
  }
  
  func updateAvatar(_ text: String) {
    customAvatarLabel.text = text
  }
}
