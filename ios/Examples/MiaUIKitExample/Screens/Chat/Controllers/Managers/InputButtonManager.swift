//
//  InputButtonManager.swift
//  MiaUIKitExample
//
//  Created on November 20, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Manages the state and appearance of input buttons (record, send, hands-free).
//

import UIKit

final class InputButtonManager {
  weak var recordButton: UIButton?
  weak var sendButton: UIButton?
  weak var handsFreeButton: UIButton?
  
  func updateForTextInput(hasText: Bool) {
    if hasText {
      recordButton?.isHidden = true
      sendButton?.isHidden = false
      handsFreeButton?.isHidden = true
    } else {
      recordButton?.isHidden = false
      sendButton?.isHidden = true
      handsFreeButton?.isHidden = false
    }
  }
  
  func updateRecordButton(isRecording: Bool) {
    let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
    let imageName = isRecording ? "stop.fill" : "mic.fill"
    let image = UIImage(systemName: imageName, withConfiguration: config)
    recordButton?.setImage(image, for: .normal)
    
    if isRecording {
      recordButton?.backgroundColor = .systemRed
      recordButton?.tintColor = .white
    } else {
      recordButton?.backgroundColor = .secondarySystemFill
      recordButton?.tintColor = .label
    }
  }
  
  func updateHandsFreeButton(isEnabled: Bool, isListening: Bool) {
    let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
    let iconName = isListening ? "waveform.circle.fill" : "waveform"
    let image = UIImage(systemName: iconName, withConfiguration: config)
    handsFreeButton?.setImage(image, for: .normal)
    
    if isEnabled {
      handsFreeButton?.backgroundColor = .systemBlue
      handsFreeButton?.tintColor = .white
    } else {
      handsFreeButton?.backgroundColor = .secondarySystemFill
      handsFreeButton?.tintColor = .label
    }
  }
  
  func updateForHandsFreeMode(isActive: Bool, messageTextView: UITextView) {
    messageTextView.isEditable = !isActive
    messageTextView.alpha = isActive ? 0.5 : 1.0
    
    recordButton?.isEnabled = !isActive
    recordButton?.alpha = isActive ? 0.5 : 1.0
    
    sendButton?.isEnabled = !isActive
    sendButton?.alpha = isActive ? 0.5 : 1.0
  }
}
