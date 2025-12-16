//
//  Extension+String.swift
//  MiaUIKitExample
//
//  Created on November 21, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  String extension for markdown parsing in chat messages using MarkdownKit.
//

import UIKit
import MarkdownKit

// MARK: - String Markdown Extension

extension String {
  func parseMarkdown(with textColor: UIColor, isStreaming: Bool = false, collapseDoubleNewlines: Bool = true) -> NSAttributedString {
    var processedText = self
  
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
    
    // Configure MarkdownParser with custom styling
    let markdownParser = MarkdownParser(
      font: .systemFont(ofSize: 16, weight: .regular),
      color: textColor
    )
    
    // Customize header fonts - use bold for all heading levels
    markdownParser.header.font = .systemFont(ofSize: 16, weight: .bold)
    markdownParser.header.color = textColor
    
    // Customize bold
    markdownParser.bold.font = .systemFont(ofSize: 16, weight: .bold)
    markdownParser.bold.color = textColor
    
    // Customize italic
    markdownParser.italic.font = .italicSystemFont(ofSize: 16)
    markdownParser.italic.color = textColor
    
    // Customize code
    markdownParser.code.font = .monospacedSystemFont(ofSize: 15, weight: .regular)
    markdownParser.code.color = textColor
    markdownParser.code.textBackgroundColor = .systemGray5
    
    // Parse the markdown
    let attributedString = markdownParser.parse(processedText)
    let mutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
    
    // Apply paragraph styling
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
