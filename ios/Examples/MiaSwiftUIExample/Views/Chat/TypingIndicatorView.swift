//
//  TypingIndicatorView.swift
//  MiaSwiftUIExample
//
//  Created on November 7, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Animated typing indicator with bouncing dots.
//

import SwiftUI

struct TypingIndicatorView: View {
  @State private var animatingDot1 = false
  @State private var animatingDot2 = false
  @State private var animatingDot3 = false

  var body: some View {
    HStack(spacing: 4) {
      Circle()
        .fill(Color.gray)
        .frame(width: 6, height: 6)
        .offset(y: animatingDot1 ? -6 : 0)
        .animation(
          Animation.easeInOut(duration: 0.6)
            .repeatForever(autoreverses: true)
            .delay(0),
          value: animatingDot1
        )

      Circle()
        .fill(Color.gray)
        .frame(width: 6, height: 6)
        .offset(y: animatingDot2 ? -6 : 0)
        .animation(
          Animation.easeInOut(duration: 0.6)
            .repeatForever(autoreverses: true)
            .delay(0.2),
          value: animatingDot2
        )

      Circle()
        .fill(Color.gray)
        .frame(width: 6, height: 6)
        .offset(y: animatingDot3 ? -6 : 0)
        .animation(
          Animation.easeInOut(duration: 0.6)
            .repeatForever(autoreverses: true)
            .delay(0.4),
          value: animatingDot3
        )
    }
    .onAppear {
      animatingDot1 = true
      animatingDot2 = true
      animatingDot3 = true
    }
  }
}
