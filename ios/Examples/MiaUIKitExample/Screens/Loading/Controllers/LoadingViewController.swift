//
//  LoadingViewController.swift
//  MiaUIKitExample
//
//  Created on November 7, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Loading screen with Mia logo following MVVM architecture.
//  Displays loading animation while spaces and bots are being loaded.
//

import UIKit
import Mia21

// MARK: - Loading View Controller

final class LoadingViewController: UIViewController {
  
  // MARK: - Properties
  
  private let viewModel: LoadingViewModel
  var onLoadComplete: (([Space], Space?, [Bot], Bot?) -> Void)?
  
  private var isBreathing = false
  
  // MARK: - UI Components
  
  private lazy var logoImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFit
    imageView.translatesAutoresizingMaskIntoConstraints = false
    if let image = UIImage(named: "mia_loader_logo") {
      imageView.image = image.withRenderingMode(.alwaysTemplate)
    }
    imageView.tintColor = .label
    return imageView
  }()
  
  private lazy var retryButton: UIButton = {
    let button = UIButton(type: .system)
    button.setTitle("Retry", for: .normal)
    button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.isHidden = true
    
    if #available(iOS 15.0, *) {
      var config = UIButton.Configuration.filled()
      config.title = "Retry"
      config.cornerStyle = .medium
      button.configuration = config
    } else {
      button.backgroundColor = .systemBlue
      button.setTitleColor(.white, for: .normal)
      button.layer.cornerRadius = 10
      button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
    }
    
    button.addAction(UIAction { [weak self] _ in
      self?.handleRetry()
    }, for: .touchUpInside)
    
    return button
  }()
  
  private lazy var containerStackView: UIStackView = {
    let stackView = UIStackView()
    stackView.axis = .vertical
    stackView.spacing = 40
    stackView.alignment = .center
    stackView.translatesAutoresizingMaskIntoConstraints = false
    return stackView
  }()
  
  // MARK: - Initialization
  
  init(client: Mia21Client, appId: String) {
    self.viewModel = LoadingViewModel(client: client, appId: appId)
    super.init(nibName: nil, bundle: nil)
    setupViewModelBindings()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    startAnimation()
    
    Task {
      await viewModel.load()
    }
  }
  
  // MARK: - Setup
  
  private func setupViewModelBindings() {
    viewModel.onStateChanged = { [weak self] state in
      self?.handleStateChange(state)
    }
  }
  
  private func setupUI() {
    view.backgroundColor = .systemBackground
    
    containerStackView.addArrangedSubview(logoImageView)
    containerStackView.addArrangedSubview(retryButton)
    view.addSubview(containerStackView)
    
    NSLayoutConstraint.activate([
      containerStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      containerStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      
      logoImageView.widthAnchor.constraint(equalToConstant: 140),
      logoImageView.heightAnchor.constraint(equalToConstant: 140),
      
      retryButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
    ])
    
    // Initial state for animation
    logoImageView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
    logoImageView.alpha = 0
  }
  
  // MARK: - State Handling
  
  private func handleStateChange(_ state: LoadingState) {
    switch state {
    case .loading:
      handleLoadingState()
      
    case .success(let spaces, let selectedSpace, let bots, let selectedBot):
      handleSuccessState(spaces: spaces, selectedSpace: selectedSpace, bots: bots, selectedBot: selectedBot)
      
    case .error(let message):
      handleErrorState(message)
    }
  }
  
  private func handleLoadingState() {
    retryButton.isHidden = true
    startBreathingAnimation()
  }
  
  private func handleSuccessState(spaces: [Space], selectedSpace: Space?, bots: [Bot], selectedBot: Bot?) {
    stopBreathingAnimation()
    onLoadComplete?(spaces, selectedSpace, bots, selectedBot)
  }
  
  private func handleErrorState(_ message: String) {
    stopBreathingAnimation()
    retryButton.isHidden = false
    
    // Fade in retry button
    retryButton.alpha = 0
    UIView.animate(withDuration: 0.3) {
      self.retryButton.alpha = 1.0
    }
    
    print("❌ Loading Error: \(message)")
  }
  
  // MARK: - Animations
  
  private func startAnimation() {
    UIView.animate(
      withDuration: 0.8,
      delay: 0,
      usingSpringWithDamping: 0.6,
      initialSpringVelocity: 0,
      options: .curveEaseOut,
      animations: {
        self.logoImageView.transform = .identity
        self.logoImageView.alpha = 1.0
      },
      completion: { _ in
        self.startBreathingAnimation()
      }
    )
  }
  
  private func startBreathingAnimation() {
    guard !isBreathing else { return }
    isBreathing = true
    
    UIView.animate(
      withDuration: 1.5,
      delay: 0,
      options: [.autoreverse, .repeat, .allowUserInteraction],
      animations: {
        self.logoImageView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
      }
    )
  }
  
  private func stopBreathingAnimation() {
    guard isBreathing else { return }
    isBreathing = false
    
    logoImageView.layer.removeAllAnimations()
    
    UIView.animate(withDuration: 0.3) {
      self.logoImageView.transform = .identity
    }
  }
  
  // MARK: - Actions
  
  private func handleRetry() {
    UIView.animate(
      withDuration: 0.3,
      animations: {
        self.retryButton.alpha = 0
      },
      completion: { _ in
        self.retryButton.isHidden = true
        self.startBreathingAnimation()
        
        Task {
          await self.viewModel.retry()
        }
      }
    )
  }
}
