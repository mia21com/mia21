//
//  SimpleVADManager.swift
//  MiaSwiftUIExample
//
//  Created on November 9, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Voice Activity Detection manager using SileroVAD library.
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
  private var isVADSetup = false

  private var isCurrentlySpeaking = false
  private var speechStartTime: Date?
  private var collectedPCMData = Data()
  private let pcmDataQueue = DispatchQueue(label: "com.mia21.pcmDataQueue")
  private var isBotSpeaking = false

  private var totalBuffersProcessed = 0
  private var speechBuffersDetected = 0
  private var chunksRecorded = 0
  private var currentVADSampleRate: Double = 48000

  private override init() {
    super.init()
  }

  // MARK: - Setup

  private func setupVADProcessorIfNeeded() {
    guard !isVADSetup else { return }
    isVADSetup = true
    
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      let vad = VADWrapper()
      vad?.delegate = self
      vad?.setSileroModel(.v5)
      vad?.setSamplerate(.SAMPLERATE_48)
      
      DispatchQueue.main.async {
        self?.vadManager = vad
      }
    }
  }

  // MARK: - Bot Speech Management

  func botDidStartSpeaking() {
    isBotSpeaking = true
  }

  func botDidStopSpeaking() {
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
    guard !isListening else { return }
    
    setupVADProcessorIfNeeded()
    
    guard vadManager != nil else {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
        self?.startVADMode()
      }
      return
    }

    configureAudioSessionWithEchoSuppress()
    realtimeCapture.delegate = self

    do {
      try realtimeCapture.startCapture()
      resetVADState()
      isListening = true
      delegate?.vadDidStartListening()
    } catch {
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
      let currentInput = audioSession.currentRoute.inputs.first?.portType
      if currentInput == .builtInMic {
        try? configureDirectionalMicrophone(audioSession)
      }
      return
    }
    
    do {
      try audioSession.setCategory(.playAndRecord, mode: .default, options: [
        .allowBluetoothHFP,
        .defaultToSpeaker,
        .mixWithOthers
      ])
      try audioSession.setPreferredIOBufferDuration(0.02)
      
      let currentInput = audioSession.currentRoute.inputs.first?.portType
      if currentInput == .builtInMic {
        try configureDirectionalMicrophone(audioSession)
      }
      
      try audioSession.setActive(true)
    } catch {
      do {
        try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try audioSession.setActive(true)
      } catch {}
    }
  }

  private func configureDirectionalMicrophone(_ audioSession: AVAudioSession) throws {
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

    if isBotSpeaking { return }

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
    guard isListening else { return }
    
    // Update VAD sample rate if audio format changed
    let bufferSampleRate = buffer.format.sampleRate
    if bufferSampleRate != currentVADSampleRate {
      updateVADSampleRate(bufferSampleRate)
    }
    
    processSileroVAD(buffer: buffer)
  }

  func didFailWithError(_ error: Error) {
    delegate?.vadDidFailWithError(error)
  }
  
  private func updateVADSampleRate(_ sampleRate: Double) {
    guard let vad = vadManager else { return }
    
    let vadSampleRate: SL
    if sampleRate <= 8000 {
      vadSampleRate = .SAMPLERATE_8
    } else if sampleRate <= 16000 {
      vadSampleRate = .SAMPLERATE_16
    } else if sampleRate <= 24000 {
      vadSampleRate = .SAMPLERATE_24
    } else {
      vadSampleRate = .SAMPLERATE_48
    }
    
    vad.setSamplerate(vadSampleRate)
    currentVADSampleRate = sampleRate
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
