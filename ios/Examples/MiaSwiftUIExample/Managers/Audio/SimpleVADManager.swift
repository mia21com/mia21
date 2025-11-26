//
//  SimpleVADManager.swift
//  MiaUIKitExample
//
//  Created on November 9, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Voice Activity Detection manager using SileroVAD library.
//  Exact copy of earkick's SileroVADManager implementation.
//

import AVFoundation
import Foundation
import RealTimeCutVADLibrary

// MARK: - SimpleVADManagerDelegate

protocol SimpleVADManagerDelegate: AnyObject {
  func vadDidStartListening()
  func vadDidStopListening()
  func vadDidDetectSpeech(_ audioData: Data, duration: TimeInterval)
  func vadDidFailWithError(_ error: Error)
  func vadVoiceActivityChanged(_ isActive: Bool)
  func vadDidStartRecordingChunk()
  func vadDidFinishRecordingChunk(duration: TimeInterval)
}

// MARK: - SimpleVADManager

final class SimpleVADManager: NSObject {
  static let shared = SimpleVADManager()

  weak var delegate: SimpleVADManagerDelegate?

  private let realtimeCapture = RealtimeAudioCapture.shared
  private var isListening = false

  private var vadManager: VADWrapper?

  // Speech chunk tracking
  private var isCurrentlySpeaking = false
  private var speechStartTime: Date?
  private var collectedPCMData = Data()
  private let pcmDataQueue = DispatchQueue(label: "com.mia21.pcmDataQueue")

  private var isBotSpeaking = false

  // Debug metrics
  private var totalBuffersProcessed = 0
  private var speechBuffersDetected = 0
  private var chunksRecorded = 0

  private override init() {
    super.init()
    setupVADProcessor()
  }

  // MARK: - Setup

  private func setupVADProcessor() {
    vadManager = VADWrapper()
    
    guard let vadManager = vadManager else {
      print("❌ SimpleVADManager: Failed to create VADWrapper")
      return
    }

    vadManager.delegate = self
    vadManager.setSileroModel(.v5)
    vadManager.setSamplerate(.SAMPLERATE_48)
  }

  // MARK: - Bot Speech Management

  func botDidStartSpeaking() {
    print("🎤 VAD: botDidStartSpeaking - setting isBotSpeaking=true (isListening=\(isListening))")
    isBotSpeaking = true
  }

  func botDidStopSpeaking() {
    print("🎤 VAD: botDidStopSpeaking - setting isBotSpeaking=false (isListening=\(isListening))")
    isBotSpeaking = false
  }

  func startProcessing() {
    isListening = false
  }

  func wasInterrupted() {
    isListening = false
  }

  // MARK: - Public Methods

  func startVADMode() {
    print("🎤 SimpleVADManager: startVADMode called - isListening=\(isListening), isBotSpeaking=\(isBotSpeaking)")
    guard !isListening else { 
      print("🎤 SimpleVADManager: Already listening, ignoring startVADMode")
      return 
    }
    guard let vadManager = vadManager else {
      let error = NSError(domain: "SimpleVADManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "VAD Manager not initialized"])
      delegate?.vadDidFailWithError(error)
      return
    }

    configureAudioSessionWithEchoSuppress()
    realtimeCapture.delegate = self

    do {
      try realtimeCapture.startCapture()
      resetVADState()
      isListening = true
      print("🎤 SimpleVADManager: VAD started successfully - isListening=\(isListening), isBotSpeaking=\(isBotSpeaking)")
      delegate?.vadDidStartListening()
    } catch {
      print("🎤 SimpleVADManager: Failed to start VAD: \(error)")
      stopVADMode()
      delegate?.vadDidFailWithError(error)
    }
  }

  func stopVADMode() {
    guard isListening else {
      resetVADState()
      delegate?.vadDidStopListening()
      return
    }

    isListening = false
    realtimeCapture.stopCapture()
    resetVADState()
    delegate?.vadDidStopListening()
  }

  var isActive: Bool {
    return isListening
  }

  // MARK: - Private Methods

  private func configureAudioSessionWithEchoSuppress() {
    let audioSession = AVAudioSession.sharedInstance()
    
    let isPlayAndRecordConfigured = audioSession.category == .playAndRecord
    
    if isPlayAndRecordConfigured {
      print("🎤 SimpleVADManager: Audio session already configured for playAndRecord, keeping current mode")
      try? configureDirectionalMicrophone(audioSession)
      return
    }
    
    do {
      try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [
        .allowBluetooth,
        .defaultToSpeaker,
        .duckOthers,
        .mixWithOthers
      ])
      
      try audioSession.setPreferredSampleRate(16000.0)
      try audioSession.setPreferredIOBufferDuration(0.02)
      try configureDirectionalMicrophone(audioSession)
      
      try audioSession.setActive(true)
    } catch {
      do {
        try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker])
        try audioSession.setActive(true)
      } catch {
        print("❌ SimpleVADManager: Audio session configuration failed: \(error)")
      }
    }
  }

  private func configureDirectionalMicrophone(_ audioSession: AVAudioSession) throws {
    // Configure input data source for beamforming if available
    if let availableInputs = audioSession.availableInputs {
      for input in availableInputs {
        if input.portType == AVAudioSession.Port.builtInMic {
          try audioSession.setPreferredInput(input)
          
          if let dataSources = input.dataSources {
            for dataSource in dataSources {
              if dataSource.dataSourceName.lowercased().contains("front") ||
                 dataSource.dataSourceName.lowercased().contains("bottom") {
                try input.setPreferredDataSource(dataSource)
                break
              }
            }
          }
          break
        }
      }
    }

    try audioSession.setPreferredInputOrientation(.portrait)
  }

  private func resetVADState() {
    print("🎤 SimpleVADManager: resetVADState called - preserving isBotSpeaking=\(isBotSpeaking)")
    
    isCurrentlySpeaking = false
    speechStartTime = nil
    
    pcmDataQueue.async { [weak self] in
      self?.collectedPCMData = Data()
    }
  }

  private func shouldFilterSpeech() -> Bool {
    guard isListening else { return true }
    
    return isBotSpeaking
  }

  // MARK: - Silero VAD Processing

  private func processSileroVAD(buffer: AVAudioPCMBuffer) {
    guard let vadManager = vadManager,
          let channelData = buffer.floatChannelData,
          buffer.frameLength > 0 else {
      return
    }

    totalBuffersProcessed += 1
    let samples = channelData[0]

    if isBotSpeaking {
      return
    }

    vadManager.processAudioData(withBuffer: samples, count: UInt(buffer.frameLength))
  }
  
  private func calculateRMS(samples: UnsafeMutablePointer<Float>, frameLength: Int) -> Float {
    var energy: Float = 0
    for i in 0..<frameLength {
      let sample = samples[i]
      energy += sample * sample
    }
    return sqrt(energy / Float(frameLength))
  }
}

extension SimpleVADManager: RealtimeAudioCaptureDelegate {
  func didCaptureAudioBuffer(_ buffer: AVAudioPCMBuffer, timestamp: AVAudioTime) {
    guard isListening else { 
      return 
    }
    
    processSileroVAD(buffer: buffer)
  }

  func didFailWithError(_ error: Error) {
    delegate?.vadDidFailWithError(error)
  }
}

// MARK: - VADDelegate (RealTimeCutVADLibrary)

extension SimpleVADManager: VADDelegate {
  func voiceStarted() {
    speechBuffersDetected += 1

    guard !shouldFilterSpeech() else { return }

    if !isCurrentlySpeaking {
      isCurrentlySpeaking = true
      speechStartTime = Date()
      chunksRecorded += 1

      pcmDataQueue.async { [weak self] in
        self?.collectedPCMData = Data()
      }

      delegate?.vadVoiceActivityChanged(true)
      delegate?.vadDidStartRecordingChunk()
    }
  }

  func voiceEnded(withWavData wavData: Data!) {
    guard let wavData = wavData else { return }

    let duration = speechStartTime?.timeIntervalSinceNow.magnitude ?? 0

    guard !shouldFilterSpeech() else {
      isCurrentlySpeaking = false
      speechStartTime = nil
      return
    }

    isCurrentlySpeaking = false
    speechStartTime = nil
    
    delegate?.vadVoiceActivityChanged(false)
    delegate?.vadDidFinishRecordingChunk(duration: duration)
    delegate?.vadDidDetectSpeech(wavData, duration: duration)
  }

  func voiceDidContinue(withPCMFloat pcmData: Data!) {
    guard let pcmData = pcmData else { return }

    if shouldFilterSpeech() && isCurrentlySpeaking {
      isCurrentlySpeaking = false
      speechStartTime = nil
      
      pcmDataQueue.async { [weak self] in
        self?.collectedPCMData = Data()
      }
      
      delegate?.vadVoiceActivityChanged(false)
      return
    }

    pcmDataQueue.async { [weak self] in
      self?.collectedPCMData.append(pcmData)
    }
  }
}
