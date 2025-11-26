//
//  Extension+String.swift
//  MiaUIKitExample
//
//  Created on November 21, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  String extension for markdown parsing in chat messages.
//

import UIKit

// MARK: - String Markdown Extension

extension String {
  func parseMarkdown(with textColor: UIColor) -> NSAttributedString {
    var processedText = self
    
    // Pattern 1: Convert ":1." -> ":\n\n1."
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
    
    // Pattern 2: Convert ".1." -> ".\n\n1."
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
    
    let attributedString = NSMutableAttributedString(string: processedText)
    let fullRange = NSRange(location: 0, length: processedText.count)
    
    // Base attributes
    let baseFont = UIFont.systemFont(ofSize: 16, weight: .regular)
    attributedString.addAttribute(.font, value: baseFont, range: fullRange)
    attributedString.addAttribute(.foregroundColor, value: textColor, range: fullRange)
    
    // Bold: **text**
    let boldPattern = "\\*\\*([^*]+)\\*\\*"
    if let boldRegex = try? NSRegularExpression(pattern: boldPattern, options: []) {
      let matches = boldRegex.matches(in: processedText, options: [], range: fullRange)
      
      for match in matches.reversed() {
        if match.numberOfRanges > 1 {
          let boldRange = match.range(at: 1)
          let fullMatchRange = match.range(at: 0)
          
          if let range = Range(boldRange, in: processedText) {
            let boldText = String(processedText[range])
            
            attributedString.replaceCharacters(in: fullMatchRange, with: boldText)
            
            let boldFont = UIFont.systemFont(ofSize: 16, weight: .bold)
            let newRange = NSRange(location: fullMatchRange.location, length: boldText.count)
            attributedString.addAttribute(.font, value: boldFont, range: newRange)
          }
        }
      }
    }
    
    // Italic: *text*
    let italicPattern = "(?<!\\*)\\*([^*]+)\\*(?!\\*)"
    if let italicRegex = try? NSRegularExpression(pattern: italicPattern, options: []) {
      let currentText = attributedString.string
      let currentRange = NSRange(location: 0, length: currentText.count)
      let matches = italicRegex.matches(in: currentText, options: [], range: currentRange)
      
      for match in matches.reversed() {
        if match.numberOfRanges > 1 {
          let italicRange = match.range(at: 1)
          let fullMatchRange = match.range(at: 0)
          
          if let range = Range(italicRange, in: currentText) {
            let italicText = String(currentText[range])
            
            attributedString.replaceCharacters(in: fullMatchRange, with: italicText)
            
            let italicFont = UIFont.italicSystemFont(ofSize: 16)
            let newRange = NSRange(location: fullMatchRange.location, length: italicText.count)
            attributedString.addAttribute(.font, value: italicFont, range: newRange)
          }
        }
      }
    }
    
    // Code: `text`
    let codePattern = "`([^`]+)`"
    if let codeRegex = try? NSRegularExpression(pattern: codePattern, options: []) {
      let currentText = attributedString.string
      let currentRange = NSRange(location: 0, length: currentText.count)
      let matches = codeRegex.matches(in: currentText, options: [], range: currentRange)
      
      for match in matches.reversed() {
        if match.numberOfRanges > 1 {
          let codeRange = match.range(at: 1)
          let fullMatchRange = match.range(at: 0)
          
          if let range = Range(codeRange, in: currentText) {
            let codeText = String(currentText[range])
            
            attributedString.replaceCharacters(in: fullMatchRange, with: codeText)
            
            let codeFont = UIFont.monospacedSystemFont(ofSize: 15, weight: .regular)
            let newRange = NSRange(location: fullMatchRange.location, length: codeText.count)
            attributedString.addAttribute(.font, value: codeFont, range: newRange)
            attributedString.addAttribute(.backgroundColor, value: UIColor.systemGray5, range: newRange)
          }
        }
      }
    }
    
    // Paragraph styling
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineSpacing = 4
    paragraphStyle.paragraphSpacing = 12
    attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributedString.length))
    
    return attributedString
  }
}
