//
//  AudioPlaybackManager.swift
//  MiaSwiftUIExample
//
//  Created on November 4, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Manages audio playback for voice responses.
//  Handles MP3 audio chunks in a sequential queue system.
//

import Foundation
import AVFoundation

// MARK: - Audio Playback Manager

final class AudioPlaybackManager: NSObject {

  // MARK: - Properties

  private var audioQueue: [Data] = []
  private var currentAudioPlayer: AVAudioPlayer?
  private var isProcessingQueue = false
  private var isPlayingAudio = false
  private var hasStartedPlayingAudio = false
  private var receivedAudioChunks = 0
  private var hasNotifiedBotStarted = false
  var onFirstAudioStart: (() -> Void)?
  var onBotDidStartSpeaking: (() -> Void)?
  var onBotDidStopSpeaking: (() -> Void)?

  // MARK: - Public Properties

  var isEnabled: Bool = false
  var hasStartedPlaying: Bool {
    hasStartedPlayingAudio
  }

  // MARK: - Public Methods

  func queueAudioChunk(_ audioData: Data) {
    guard isEnabled else { return }

    receivedAudioChunks += 1
    audioQueue.append(audioData)

    if !isProcessingQueue {
      playNextInQueue()
    }
  }

  func reset() {
    stopAll()
    audioQueue.removeAll()
    receivedAudioChunks = 0
    hasStartedPlayingAudio = false
    isProcessingQueue = false
    isPlayingAudio = false
    hasNotifiedBotStarted = false
  }

  func stopAll() {
    let wasPlaying = hasNotifiedBotStarted
    
    currentAudioPlayer?.stop()
    currentAudioPlayer = nil

    // Check if hands-free is active - if so, keep session active
    let handsFreeActive = HandsFreeAudioManager.isInitialized && HandsFreeAudioManager.shared.isActive
    
    if isPlayingAudio {
      if !handsFreeActive {
        // Only deactivate if hands-free is not active
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
      } else {
        // Keep session active but ensure it's in playAndRecord mode
        let audioSession = AVAudioSession.sharedInstance()
        if audioSession.category != .playAndRecord {
          try? audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [
            .allowBluetooth,
            .defaultToSpeaker,
            .duckOthers,
            .mixWithOthers
          ])
        }
      }
      isPlayingAudio = false
    }
    
    // Notify that bot stopped speaking if it was playing
    if wasPlaying {
      hasNotifiedBotStarted = false
      onBotDidStopSpeaking?()
    }
  }

  // MARK: - Private Methods

  private func playNextInQueue() {
    guard !isProcessingQueue, !audioQueue.isEmpty else {
      if audioQueue.isEmpty && hasNotifiedBotStarted {
        isProcessingQueue = false
        isPlayingAudio = false
        hasNotifiedBotStarted = false
        // Notify that bot stopped speaking when queue is empty
        onBotDidStopSpeaking?()
      }
      return
    }

    isProcessingQueue = true
    let audioData = audioQueue.removeFirst()

    // Move audio session setup off main thread to prevent hangs
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      guard let self = self else { return }
      
      do {
        let audioSession = AVAudioSession.sharedInstance()
        
        // Check if hands-free mode is active - if so, use playAndRecord
        let handsFreeActive = HandsFreeAudioManager.isInitialized && HandsFreeAudioManager.shared.isActive
        
        if !self.isPlayingAudio {
          if handsFreeActive {
            // Keep playAndRecord mode for hands-free
            if audioSession.category != .playAndRecord {
              try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [
                .allowBluetoothHFP,
                .defaultToSpeaker,
                .duckOthers,
                .mixWithOthers
              ])
            }
          } else {
            // Use playback mode when hands-free is not active
            try audioSession.setCategory(.playback, mode: .default)
          }
          try audioSession.setActive(true)
        }
        
        // Create and configure player on main thread
        DispatchQueue.main.async { [weak self] in
          guard let self = self else { return }
          
          do {
            self.isPlayingAudio = true
            
            let player = try AVAudioPlayer(data: audioData)
            player.delegate = self
            player.prepareToPlay()
            self.currentAudioPlayer = player

            if !self.hasStartedPlayingAudio {
              self.hasStartedPlayingAudio = true
              self.onFirstAudioStart?()
            }

            // Notify that bot started speaking (only once per session)
            if !self.hasNotifiedBotStarted {
              self.hasNotifiedBotStarted = true
              self.onBotDidStartSpeaking?()
            }

            player.play()

          } catch {
            self.isProcessingQueue = false
            self.playNextInQueue()
          }
        }
        
      } catch {
        DispatchQueue.main.async {
          self.isProcessingQueue = false
          self.playNextInQueue()
        }
      }
    }
  }
}

// MARK: - AVAudioPlayerDelegate

extension AudioPlaybackManager: AVAudioPlayerDelegate {
  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    isProcessingQueue = false
    
    // Check if queue is empty - if so, bot stopped speaking
    if audioQueue.isEmpty && hasNotifiedBotStarted {
      hasNotifiedBotStarted = false
      onBotDidStopSpeaking?()
    }
    
    playNextInQueue()
  }

  func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
    isProcessingQueue = false
    
    // Check if queue is empty - if so, bot stopped speaking
    if audioQueue.isEmpty && hasNotifiedBotStarted {
      hasNotifiedBotStarted = false
      onBotDidStopSpeaking?()
    }
    
    playNextInQueue()
  }
}
