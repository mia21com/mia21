//
//  MessageBubble.swift
//  MiaSwiftUIExample
//
//  Created on November 7, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Message bubble component with markdown parsing support using MarkdownKit.
//

import SwiftUI
import MarkdownKit

struct MessageBubble: View {
  let message: ChatMessage
  
  private var maxBubbleWidth: CGFloat {
    UIScreen.main.bounds.width * 0.8
  }

  var body: some View {
    HStack(alignment: .top, spacing: 0) {
      if message.isUser {
        Spacer(minLength: 0)
      }

      Group {
        if message.isTypingIndicator || message.isProcessingAudio {
          TypingIndicatorView()
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(message.isProcessingAudio ? Color.blue.opacity(0.7) : Color(.secondarySystemBackground))
            .cornerRadius(18)
        } else {
          // Use MarkdownText for both streaming and complete messages
          MarkdownText(
            text: message.text,
            textColor: message.isUser ? .white : .label,
            maxWidth: maxBubbleWidth - 28,
            isStreaming: message.isStreaming,
            collapseDoubleNewlines: message.collapseDoubleNewlines
          )
          .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(message.isUser ? Color.blue : Color(.secondarySystemBackground))
            .cornerRadius(18)
        }
      }
      .frame(maxWidth: maxBubbleWidth, alignment: message.isUser ? .trailing : .leading)
      
      if !message.isUser {
        Spacer(minLength: 0)
      }
    }
  }
}

// MARK: - MarkdownText UIViewRepresentable

struct MarkdownText: UIViewRepresentable {
  let text: String
  let textColor: UIColor
  let maxWidth: CGFloat
  let isStreaming: Bool
  let collapseDoubleNewlines: Bool
  
  init(text: String, textColor: UIColor, maxWidth: CGFloat, isStreaming: Bool = false, collapseDoubleNewlines: Bool = true) {
    self.text = text
    self.textColor = textColor
    self.maxWidth = maxWidth
    self.isStreaming = isStreaming
    self.collapseDoubleNewlines = collapseDoubleNewlines
  }
  
  func makeUIView(context: Context) -> UILabel {
    let label = UILabel()
    label.numberOfLines = 0
    label.lineBreakMode = .byWordWrapping
    return label
  }
  
  func updateUIView(_ uiView: UILabel, context: Context) {
    let attributedText = parseMarkdown(text, textColor: textColor, isStreaming: isStreaming, collapseDoubleNewlines: collapseDoubleNewlines)
    uiView.attributedText = attributedText
    uiView.preferredMaxLayoutWidth = maxWidth
  }
  
  func sizeThatFits(_ proposal: ProposedViewSize, uiView: UILabel, context: Context) -> CGSize? {
    let attributedText = parseMarkdown(text, textColor: textColor, isStreaming: isStreaming, collapseDoubleNewlines: collapseDoubleNewlines)
    let maxSize = CGSize(width: maxWidth, height: .greatestFiniteMagnitude)
    let boundingRect = attributedText.boundingRect(
      with: maxSize,
      options: [.usesLineFragmentOrigin, .usesFontLeading],
      context: nil
    )

    let width = min(ceil(boundingRect.width), maxWidth)
    let height = ceil(boundingRect.height)
    
    return CGSize(width: width, height: height)
  }

  private func parseMarkdown(_ text: String, textColor: UIColor, isStreaming: Bool, collapseDoubleNewlines: Bool = true) -> NSAttributedString {
    var processedText = text

    if isStreaming {
      if let regex = try? NSRegularExpression(pattern: "\\n{3,}", options: []) {
        processedText = regex.stringByReplacingMatches(
          in: processedText,
          options: [],
          range: NSRange(location: 0, length: processedText.utf16.count),
          withTemplate: "\n\n"
        )
      }
      
      if collapseDoubleNewlines {
        if let regex = try? NSRegularExpression(pattern: "\\n{2}", options: []) {
          processedText = regex.stringByReplacingMatches(
            in: processedText,
            options: [],
            range: NSRange(location: 0, length: processedText.utf16.count),
            withTemplate: "\n"
          )
        }
      }
    }

    let markdownParser = MarkdownParser(
      font: .systemFont(ofSize: 16, weight: .regular),
      color: textColor
    )
    
    markdownParser.header.font = .systemFont(ofSize: 16, weight: .bold)
    markdownParser.header.color = textColor
    
    markdownParser.bold.font = .systemFont(ofSize: 16, weight: .bold)
    markdownParser.bold.color = textColor
    
    markdownParser.italic.font = .italicSystemFont(ofSize: 16)
    markdownParser.italic.color = textColor
    
    markdownParser.code.font = .monospacedSystemFont(ofSize: 15, weight: .regular)
    markdownParser.code.color = textColor
    markdownParser.code.textBackgroundColor = .systemGray5
    
    let attributedString = markdownParser.parse(processedText)
    let mutableAttributedString = NSMutableAttributedString(attributedString: attributedString)

    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineSpacing = 4
    paragraphStyle.paragraphSpacing = 12
    mutableAttributedString.addAttribute(
      .paragraphStyle,
      value: paragraphStyle,
      range: NSRange(location: 0, length: mutableAttributedString.length)
    )
    
    return mutableAttributedString
  }
}
