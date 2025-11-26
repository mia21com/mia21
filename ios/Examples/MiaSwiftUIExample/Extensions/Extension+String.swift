//
//  Extension+String.swift
//  MiaSwiftUIExample
//
//  Created on November 21, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  String utilities for SwiftUI.
//

import Foundation

// MARK: - String Extensions

extension String {
  // SwiftUI Text views support Markdown natively in iOS 15+
  // This extension provides additional text processing if needed
  
  func formatForChat() -> String {
    var processedText = self
    
    // Convert ":1." -> ":\n\n1."
    let colonPattern = ":(\\d+)\\."
    if let regex = try? NSRegularExpression(pattern: colonPattern, options: []) {
      let nsString = processedText as NSString
      let matches = regex.matches(in: processedText, options: [], range: NSRange(location: 0, length: nsString.length))
      
      for match in matches.reversed() {
        if let range = Range(match.range, in: processedText) {
          let matchedText = String(processedText[range])
          let number = matchedText.dropFirst().dropLast()
          processedText.replaceSubrange(range, with: ":\n\n\(number).")
        }
      }
    }
    
    // Convert ".1." -> ".\n\n1."
    let periodPattern = "\\.(\\d+)\\."
    if let regex = try? NSRegularExpression(pattern: periodPattern, options: []) {
      let nsString = processedText as NSString
      let matches = regex.matches(in: processedText, options: [], range: NSRange(location: 0, length: nsString.length))
      
      for match in matches.reversed() {
        if let range = Range(match.range, in: processedText) {
          let matchedText = String(processedText[range])
          let number = matchedText.dropFirst().dropLast()
          processedText.replaceSubrange(range, with: ".\n\n\(number).")
        }
      }
    }
    
    return processedText
  }
}

