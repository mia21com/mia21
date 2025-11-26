//
//  TypingIndicatorView.swift
//  MiaUIKitExample
//
//  Created on November 4, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Animated typing indicator with bouncing dots
//  to show when AI is processing a response.
//

import UIKit

// MARK: - Typing Indicator View

final class TypingIndicatorView: UIView {

  // MARK: - Properties

  private let dotSize: CGFloat = 6
  private let spacing: CGFloat = 4
  private var dots: [UIView] = []

  override var intrinsicContentSize: CGSize {
    let width = (dotSize * 3) + (spacing * 2)
    let height = dotSize + 12 // Extra space for bounce animation
    return CGSize(width: width, height: height)
  }

  // MARK: - Initialization

  override init(frame: CGRect) {
    super.init(frame: frame)
    setContentHuggingPriority(.required, for: .horizontal)
    setContentHuggingPriority(.required, for: .vertical)
    setContentCompressionResistancePriority(.required, for: .horizontal)
    setContentCompressionResistancePriority(.required, for: .vertical)
    setupDots()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Setup

  private func setupDots() {
    for i in 0..<3 {
      let dot = UIView()
      dot.backgroundColor = .systemGray
      dot.layer.cornerRadius = dotSize / 2
      dot.translatesAutoresizingMaskIntoConstraints = false
      addSubview(dot)

      NSLayoutConstraint.activate([
        dot.centerYAnchor.constraint(equalTo: centerYAnchor),
        dot.widthAnchor.constraint(equalToConstant: dotSize),
        dot.heightAnchor.constraint(equalToConstant: dotSize)
      ])

      if i == 0 {
        dot.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
      } else {
        dot.leadingAnchor.constraint(equalTo: dots[i-1].trailingAnchor, constant: spacing).isActive = true
      }

      if i == 2 {
        dot.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
      }

      dots.append(dot)
    }
  }

  // MARK: - Animation

  func startAnimating() {
    for (index, dot) in dots.enumerated() {
      let delay = Double(index) * 0.2

      UIView.animate(
        withDuration: 0.6,
        delay: delay,
        options: [.repeat, .autoreverse, .curveEaseInOut],
        animations: {
          dot.transform = CGAffineTransform(translationX: 0, y: -6)
        }
      )
    }
  }

  func stopAnimating() {
    dots.forEach { dot in
      dot.layer.removeAllAnimations()
      dot.transform = .identity
    }
  }
}
