//
//  SceneDelegate.swift
//  MiaUIKitExample
//
//  Created on November 4, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Scene delegate managing the app's window and navigation flow.
//  Coordinates between LoadingViewController and ChatViewController.
//

import UIKit
import Mia21

// MARK: - Configuration

private enum Configuration {
  static let apiKey = "mia_sk_cust_3406ioja0VU6GQGQ_kAkf8KBtvjuxXb4p6oxsO-6ejwNpAzynsVYCVD3a5no"
  static let environment: Mia21Environment = .production
  static let userIdKey = "mia_user_id"
  static let transitionDuration: TimeInterval = 0.3
}

// MARK: - Scene Delegate

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  
  // MARK: - Properties

  var window: UIWindow?
  
  private var client: Mia21Client?
  private var chatViewController: ChatViewController?

  // MARK: - Scene Lifecycle
  
  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let windowScene = scene as? UIWindowScene else { return }

    setupLogging()

    let window = UIWindow(windowScene: windowScene)
    self.window = window
    
    let appId = getOrCreateUserId()
    let client = createClient(userId: appId)
    self.client = client
    
    showLoadingScreen(client: client, appId: appId, in: window)
    
    window.makeKeyAndVisible()
  }
  
  // MARK: - Setup
  
  private func setupLogging() {
    Mia21Client.setLogLevel(.debug)
  }
  
  private func getOrCreateUserId() -> String {
    if let savedUserId = UserDefaults.standard.string(forKey: Configuration.userIdKey) {
      print("📱 Using saved user ID: \(savedUserId)")
      return savedUserId
    }
    
    let newUserId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    UserDefaults.standard.set(newUserId, forKey: Configuration.userIdKey)
    print("📱 Created new user ID: \(newUserId)")
    return newUserId
    }
    
  private func createClient(userId: String) -> Mia21Client {
    return Mia21Client(
      apiKey: Configuration.apiKey,
      userId: userId,
      environment: Configuration.environment
    )
  }
  
  // MARK: - Navigation Flow
  
  private func showLoadingScreen(client: Mia21Client, appId: String, in window: UIWindow) {
    let loadingVC = LoadingViewController(client: client, appId: appId)

    loadingVC.onLoadComplete = { [weak self, weak window] spaces, selectedSpace, bots, selectedBot in
      self?.showChatScreen(
        client: client,
        appId: appId,
        spaces: spaces,
        selectedSpace: selectedSpace,
        bots: bots,
        selectedBot: selectedBot,
        in: window
      )
    }
    
    window.rootViewController = loadingVC
  }
  
  private func showChatScreen(
    client: Mia21Client,
    appId: String,
    spaces: [Space],
    selectedSpace: Space?,
    bots: [Bot],
    selectedBot: Bot?,
    in window: UIWindow?
  ) {
    guard let window = window else { return }
    
      let chatVC = ChatViewController(client: client, appId: appId)
    chatViewController = chatVC
      
      chatVC.setInitialData(
        spaces: spaces,
        selectedSpace: selectedSpace,
        bots: bots,
        selectedBot: selectedBot
      )

    let navigationController = createNavigationController(rootViewController: chatVC)
    
    transitionToViewController(navigationController, in: window)
  }
  
  private func createNavigationController(rootViewController: UIViewController) -> UINavigationController {
    let navController = UINavigationController(rootViewController: rootViewController)

      let appearance = UINavigationBarAppearance()
      appearance.configureWithOpaqueBackground()
      navController.navigationBar.standardAppearance = appearance
      navController.navigationBar.scrollEdgeAppearance = appearance

    return navController
  }
  
  private func transitionToViewController(_ viewController: UIViewController, in window: UIWindow) {
      UIView.transition(
      with: window,
      duration: Configuration.transitionDuration,
        options: .transitionCrossDissolve,
        animations: {
      window.rootViewController = viewController
    }
  )
  }
}
