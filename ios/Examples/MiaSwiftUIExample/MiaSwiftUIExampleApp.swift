//
//  MiaSwiftUIExampleApp.swift
//  MiaSwiftUIExample
//
//  Created on November 7, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  App entry point with loading screen, matching UIKit version.

import SwiftUI
import Mia21

@main
struct MiaSwiftUIExampleApp: App {
  @State private var isLoading = true
  @State private var spaces: [Space] = []
  @State private var selectedSpace: Space?
  @State private var bots: [Bot] = []
  @State private var selectedBot: Bot?

  init() {
    Mia21Client.setLogLevel(.debug)
  }

  private var appId: String {
    // Get or create persistent user ID
    if let savedUserId = UserDefaults.standard.string(forKey: "mia_user_id") {
      print("📱 Using saved user ID: \(savedUserId)")
      return savedUserId
    } else {
      let newUserId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
      UserDefaults.standard.set(newUserId, forKey: "mia_user_id")
      print("📱 Created new user ID: \(newUserId)")
      return newUserId
    }
  }

  private var client: Mia21Client {
    Mia21Client(
      apiKey: "mia_sk_cust_3406ioja0VU6GQGQ_kAkf8KBtvjuxXb4p6oxsO-6ejwNpAzynsVYCVD3a5no",
      userId: appId
    )
  }

  private let audioManager = AudioPlaybackManager()

  var body: some Scene {
    WindowGroup {
      if isLoading {
        LoadingView(
          client: client,
          appId: appId,
          onLoadComplete: { loadedSpaces, loadedSpace, loadedBots, loadedBot in
            spaces = loadedSpaces
            selectedSpace = loadedSpace
            bots = loadedBots
            selectedBot = loadedBot
            isLoading = false
          }
        )
      } else {
        ChatView(
          client: client,
          audioManager: audioManager,
          appId: appId,
          spaces: spaces,
          selectedSpace: selectedSpace,
          bots: bots,
          selectedBot: selectedBot
        )
      }
    }
  }
}
