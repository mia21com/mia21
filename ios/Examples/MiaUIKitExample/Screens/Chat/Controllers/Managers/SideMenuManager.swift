//
//  SideMenuManager.swift
//  MiaUIKitExample
//
//  Created on November 20, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Manages the side menu presentation and animation.
//

import UIKit

final class SideMenuManager {
  weak var menuButton: UIBarButtonItem?
  weak var dimmingView: UIView?
  weak var sideMenuView: UIView?
  weak var navigationBar: UINavigationBar?
  weak var tableView: UITableView?
  weak var inputContainer: UIView?
  
  private(set) var isVisible = false
  private let menuWidth: CGFloat
  
  init(menuWidth: CGFloat = 280) {
    self.menuWidth = menuWidth
  }
  
  func show() {
    guard !isVisible else { return }
    isVisible = true
    
    menuButton?.image = UIImage(systemName: "chevron.left")
    dimmingView?.isUserInteractionEnabled = true
    
    UIView.animate(
      withDuration: 0.3,
      delay: 0,
      options: [.curveEaseOut],
      animations: {
        self.dimmingView?.alpha = 1.0
        self.sideMenuView?.frame.origin.x = 0
        self.navigationBar?.transform = CGAffineTransform(translationX: self.menuWidth, y: 0)
        self.tableView?.transform = CGAffineTransform(translationX: self.menuWidth, y: 0)
        self.inputContainer?.transform = CGAffineTransform(translationX: self.menuWidth, y: 0)
        self.tableView?.alpha = 0.3
        self.inputContainer?.alpha = 0.3
      }
    )
  }
  
  func hide() {
    guard isVisible else { return }
    isVisible = false
    
    menuButton?.image = UIImage(systemName: "line.3.horizontal")
    
    UIView.animate(
      withDuration: 0.25,
      delay: 0,
      options: [.curveEaseIn],
      animations: {
        self.dimmingView?.alpha = 0
        self.sideMenuView?.frame.origin.x = -self.menuWidth
        self.navigationBar?.transform = .identity
        self.tableView?.transform = .identity
        self.inputContainer?.transform = .identity
        self.tableView?.alpha = 1.0
        self.inputContainer?.alpha = 1.0
      },
      completion: { _ in
        self.dimmingView?.isUserInteractionEnabled = false
      }
    )
  }
  
  func toggle() {
    if isVisible {
      hide()
    } else {
      show()
    }
  }
}
