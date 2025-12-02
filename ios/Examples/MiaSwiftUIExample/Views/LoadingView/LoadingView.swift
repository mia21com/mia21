//
//  LoadingView.swift
//  MiaSwiftUIExample
//
//  Created on November 7, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Loading screen with Mia logo displayed while spaces and bots are being loaded.

import SwiftUI
import Mia21

struct LoadingView: View {
  let client: Mia21Client
  let appId: String
  let onLoadComplete: ([Space], Space?, [Bot], Bot?) -> Void

  @State private var logoScale: CGFloat = 0.5
  @State private var logoOpacity: Double = 0
  @State private var isBreathing = false
  @State private var showError = false
  @State private var errorMessage = ""

  var body: some View {
    ZStack {
      Color(.systemBackground)
        .ignoresSafeArea()

      VStack(spacing: 40) {
        Image("mia_loader_logo")
          .renderingMode(.template)
          .resizable()
          .scaledToFit()
          .foregroundColor(Color.primary)
          .frame(width: 140, height: 140)
          .scaleEffect(logoScale)
          .opacity(logoOpacity)
          .animation(
            isBreathing
            ? Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)
            : .default,
            value: isBreathing
          )

        if showError {
          VStack(spacing: 16) {
            Text(errorMessage)
              .font(.subheadline)
              .foregroundColor(.secondary)
              .multilineTextAlignment(.center)
              .padding(.horizontal, 32)
            
            Button("Retry") {
              retry()
            }
            .buttonStyle(.borderedProminent)
          }
        }
      }
    }
    .onAppear {
      startAnimation()
      startLoading()
    }
  }

  private func startAnimation() {
    withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
      logoScale = 1.0
      logoOpacity = 1.0
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
      isBreathing = true
    }
  }

  private func startLoading() {
    Task {
      do {
        let spaces = try await client.listSpaces()
        let bots = try await client.listBots()
        
        // Use first space if available, otherwise nil (app will still work)
        let firstSpace = spaces.first
        let selectedBot = bots.first(where: { $0.isDefault }) ?? bots.first

        try await Task.sleep(nanoseconds: 500_000_000)

        await MainActor.run {
          onLoadComplete(spaces, firstSpace, bots, selectedBot)
        }

      } catch {
        await showErrorState("Failed to load: \(error.localizedDescription)")
      }
    }
  }

  private func showErrorState(_ message: String) async {
    await MainActor.run {
      isBreathing = false
      showError = true
      errorMessage = message
    }
  }

  private func retry() {
    showError = false
    isBreathing = true
    startLoading()
  }
}
