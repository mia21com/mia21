//
//  Extension+CAGradientLayer.swift
//  MiaUIKitExample
//
//  Created on November 20, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  CAGradientLayer extension providing app-specific gradient creation.
//

import UIKit

// MARK: - CAGradientLayer Extensions

extension CAGradientLayer {
  
  static func appGradient(frame: CGRect, cornerRadius: CGFloat = 0) -> CAGradientLayer {
    let gradientLayer = CAGradientLayer()
    gradientLayer.frame = frame
    gradientLayer.colors = [
      UIColor.gradientBlue.cgColor,
      UIColor.gradientPurple.cgColor
    ]
    gradientLayer.startPoint = CGPoint(x: 0, y: 0)
    gradientLayer.endPoint = CGPoint(x: 1, y: 1)
    gradientLayer.cornerRadius = cornerRadius
    return gradientLayer
  }
}
