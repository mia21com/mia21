//
//  MessageBubble.swift
//  MiaSwiftUIExample
//
//  Created on November 7, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Message bubble component with markdown parsing support.
//

import SwiftUI

struct MessageBubble: View {
  let message: ChatMessage

  var body: some View {
    HStack {
      if message.isUser {
        Spacer()
      }

      if message.isTypingIndicator || message.isProcessingAudio {
        TypingIndicatorView()
          .padding(.horizontal, 14)
          .padding(.vertical, 12)
          .background(message.isProcessingAudio ? Color.blue.opacity(0.7) : Color(.secondarySystemBackground))
          .cornerRadius(18)
      } else {
        Text(parseMarkdown(message.text))
          .font(.system(size: 16))
          .foregroundColor(message.isUser ? .white : .primary)
          .padding(.horizontal, 14)
          .padding(.vertical, 12)
          .background(message.isUser ? Color.blue : Color(.secondarySystemBackground))
          .cornerRadius(18)
          .textSelection(.enabled)
      }

      if !message.isUser && !message.isProcessingAudio {
        Spacer()
      }
    }
  }

  private func parseMarkdown(_ text: String) -> AttributedString {
    var processedText = text

    let colonPattern = ":(\\d+)\\."
    if let regex = try? NSRegularExpression(pattern: colonPattern, options: []) {
      let matches = regex.matches(in: processedText, options: [], range: NSRange(location: 0, length: processedText.utf16.count))

      for match in matches.reversed() {
        let range = match.range
        if let swiftRange = Range(range, in: processedText) {
          let matchedText = String(processedText[swiftRange])
          let numberStart = matchedText.index(after: matchedText.startIndex)
          let numberEnd = matchedText.index(before: matchedText.endIndex)
          let number = String(matchedText[numberStart..<numberEnd])
          processedText.replaceSubrange(swiftRange, with: ":\n\n\(number).")
        }
      }
    }

    let periodPattern = "\\.(\\d+)\\."
    if let regex = try? NSRegularExpression(pattern: periodPattern, options: []) {
      let matches = regex.matches(in: processedText, options: [], range: NSRange(location: 0, length: processedText.utf16.count))

      for match in matches.reversed() {
        let range = match.range
        if let swiftRange = Range(range, in: processedText) {
          let matchedText = String(processedText[swiftRange])
          let numberStart = matchedText.index(after: matchedText.startIndex)
          let numberEnd = matchedText.index(before: matchedText.endIndex)
          let number = String(matchedText[numberStart..<numberEnd])
          processedText.replaceSubrange(swiftRange, with: ".\n\n\(number).")
        }
      }
    }

    var attributed = AttributedString(processedText)
    attributed.font = .systemFont(ofSize: 16, weight: .regular)

    let boldPattern = "\\*\\*([^*]+)\\*\\*"
    if let boldRegex = try? NSRegularExpression(pattern: boldPattern, options: []) {
      let nsString = processedText as NSString
      let matches = boldRegex.matches(in: processedText, options: [], range: NSRange(location: 0, length: nsString.length))

      for match in matches.reversed() {
        if match.numberOfRanges > 1 {
          let boldRange = match.range(at: 1)
          let fullMatchRange = match.range(at: 0)
          let boldText = nsString.substring(with: boldRange)

          if let fullRange = Range(fullMatchRange, in: attributed) {
            attributed.replaceSubrange(fullRange, with: AttributedString(boldText))

            if let newRange = Range(NSRange(location: fullMatchRange.location, length: boldText.count), in: attributed) {
              attributed[newRange].font = .boldSystemFont(ofSize: 16)
            }
          }
        }
      }
    }

    let italicPattern = "(?<!\\*)\\*([^*]+)\\*(?!\\*)"
    if let italicRegex = try? NSRegularExpression(pattern: italicPattern, options: []) {
      let currentText = String(attributed.characters)
      let nsString = currentText as NSString
      let matches = italicRegex.matches(in: currentText, options: [], range: NSRange(location: 0, length: nsString.length))

      for match in matches.reversed() {
        if match.numberOfRanges > 1 {
          let italicRange = match.range(at: 1)
          let fullMatchRange = match.range(at: 0)
          let italicText = nsString.substring(with: italicRange)

          if let fullRange = Range(fullMatchRange, in: attributed) {
            attributed.replaceSubrange(fullRange, with: AttributedString(italicText))

            if let newRange = Range(NSRange(location: fullMatchRange.location, length: italicText.count), in: attributed) {
              attributed[newRange].font = .italicSystemFont(ofSize: 16)
            }
          }
        }
      }
    }

    let codePattern = "`([^`]+)`"
    if let codeRegex = try? NSRegularExpression(pattern: codePattern, options: []) {
      let currentText = String(attributed.characters)
      let nsString = currentText as NSString
      let matches = codeRegex.matches(in: currentText, options: [], range: NSRange(location: 0, length: nsString.length))

      for match in matches.reversed() {
        if match.numberOfRanges > 1 {
          let codeRange = match.range(at: 1)
          let fullMatchRange = match.range(at: 0)
          let codeText = nsString.substring(with: codeRange)

          if let fullRange = Range(fullMatchRange, in: attributed) {
            attributed.replaceSubrange(fullRange, with: AttributedString(codeText))

            if let newRange = Range(NSRange(location: fullMatchRange.location, length: codeText.count), in: attributed) {
              attributed[newRange].font = .monospacedSystemFont(ofSize: 15, weight: .regular)
              attributed[newRange].backgroundColor = Color(.systemGray5)
            }
          }
        }
      }
    }

    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineSpacing = 4
    paragraphStyle.paragraphSpacing = 12

    let fullRange = attributed.startIndex..<attributed.endIndex
    attributed[fullRange].paragraphStyle = paragraphStyle

    return attributed
  }
}
