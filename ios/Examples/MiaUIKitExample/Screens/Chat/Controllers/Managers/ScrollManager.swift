//
//  ScrollManager.swift
//  MiaUIKitExample
//
//  Created on November 20, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//

import UIKit

final class ScrollManager {
  private var isUserScrolling = false
  private var shouldAutoScrollToBottom = true
  private let autoScrollThreshold: CGFloat = 50
  
  func beginScrolling() {
    isUserScrolling = true
  }
  
  func endScrolling() {
    isUserScrolling = false
  }
  
  func isUserNearBottom(scrollView: UIScrollView) -> Bool {
    let contentHeight = scrollView.contentSize.height
    let scrollViewHeight = scrollView.bounds.height
    let contentInsetBottom = scrollView.contentInset.bottom
    let currentOffset = scrollView.contentOffset.y
    
    guard contentHeight > 0, scrollViewHeight > 0 else {
      return true
    }
    
    let maxOffset = contentHeight - scrollViewHeight + contentInsetBottom
    let distanceFromBottom = maxOffset - currentOffset
    
    return distanceFromBottom <= autoScrollThreshold
  }
  
  func updateAutoScrollBehavior(scrollView: UIScrollView) {
    shouldAutoScrollToBottom = isUserNearBottom(scrollView: scrollView)
  }
  
  func checkScrollPosition(contentHeight: CGFloat, contentOffsetY: CGFloat, tableHeight: CGFloat, contentInset: CGFloat) {
    let distanceFromBottom = contentHeight - contentOffsetY - tableHeight + contentInset
    shouldAutoScrollToBottom = distanceFromBottom <= autoScrollThreshold
  }
  
  func enableAutoScroll() {
    shouldAutoScrollToBottom = true
  }
  
  var canAutoScroll: Bool {
    shouldAutoScrollToBottom
  }
  
  var isScrolling: Bool {
    isUserScrolling
  }
}
