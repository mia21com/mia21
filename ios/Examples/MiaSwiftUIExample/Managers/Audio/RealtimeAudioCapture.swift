//
//  RealtimeAudioCapture.swift
//  MiaSwiftUIExample
//
//  Created on November 9, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Captures audio in real-time using AVAudioEngine for hands-free mode.
//

import AVFoundation
import Foundation

protocol RealtimeAudioCaptureDelegate: AnyObject {
  func didCaptureAudioBuffer(_ buffer: AVAudioPCMBuffer, timestamp: AVAudioTime)
  func didFailWithError(_ error: Error)
}

final class RealtimeAudioCapture {
  static let shared = RealtimeAudioCapture()

  private var audioEngine: AVAudioEngine?
  private var inputNode: AVAudioInputNode?
  private var isCapturing = false
  private var bufferCount = 0

  weak var delegate: RealtimeAudioCaptureDelegate?

  private let sampleRate: Double = 16000
  private let channels: AVAudioChannelCount = 1
  private let bufferSize: AVAudioFrameCount = 1024

  private init() {}

  deinit {
    cleanup()
  }

  func startCapture() throws {
    if isCapturing && audioEngine?.isRunning == true {
      return
    }

    if isCapturing && audioEngine?.isRunning != true {
      cleanup()
    }

    let permission = AVAudioSession.sharedInstance().recordPermission
    guard permission == .granted else {
      if permission == .undetermined {
        requestMicrophonePermission { [weak self] granted in
          if granted {
            do {
              try self?.startCapture()
            } catch {
              self?.delegate?.didFailWithError(error)
            }
          } else {
            self?.delegate?.didFailWithError(AudioCaptureError.permissionDenied)
          }
        }
        return
      } else {
        throw AudioCaptureError.permissionDenied
      }
    }

    do {
      try setupAudioSession()
      try setupAudioEngine()
      try audioEngine?.start()
      isCapturing = true
      bufferCount = 0
      print("RealtimeAudioCapture: Started capturing audio at \(sampleRate)Hz")

      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
        self?.validateAudioCaptureState()
      }
    } catch {
      cleanup()
      throw error
    }
  }

  func stopCapture() {
    guard isCapturing else {
      return
    }

    cleanup()
  }

  private func cleanup() {
    isCapturing = false
    bufferCount = 0

    NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)

    if let engine = audioEngine {
      if engine.isRunning {
        engine.stop()
        print("RealtimeAudioCapture: Audio engine stopped")
      }

      if let inputNode = inputNode {
        inputNode.removeTap(onBus: 0)
      }
    }

    audioEngine = nil
    inputNode = nil

    DispatchQueue.main.async {
      let audioSession = AVAudioSession.sharedInstance()
      
      print("RealtimeAudioCapture: Deactivating audio session")
      do {
        try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        print("RealtimeAudioCapture: Audio session deactivated successfully")
      } catch {
        print("RealtimeAudioCapture: Audio session deactivation failed: \(error)")
      }
    }
  }

  var isActive: Bool {
    return isCapturing && audioEngine?.isRunning == true
  }

  func forceRestart() {
    cleanup()

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
      guard let self = self else { return }

      do {
        try self.startCapture()
      } catch {
        self.delegate?.didFailWithError(error)
      }
    }
  }

  private func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
    switch AVAudioSession.sharedInstance().recordPermission {
    case .undetermined:
      AVAudioSession.sharedInstance().requestRecordPermission { granted in
        DispatchQueue.main.async {
          if granted {
            print("RealtimeAudioCapture: Microphone permission granted")
          } else {
            print("RealtimeAudioCapture: Microphone permission denied by user")
          }
          completion(granted)
        }
      }
    case .denied:
      print("RealtimeAudioCapture: Microphone permission already denied")
      completion(false)
    case .granted:
      print("RealtimeAudioCapture: Microphone permission already granted")
      completion(true)
    @unknown default:
      print("RealtimeAudioCapture: Unknown microphone permission state")
      completion(false)
    }
  }

  private func setupAudioSession() throws {
    let audioSession = AVAudioSession.sharedInstance()

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleAudioSessionInterruption),
      name: AVAudioSession.interruptionNotification,
      object: audioSession
    )

    let isPlayAndRecordConfigured = audioSession.category == .playAndRecord

    if !isPlayAndRecordConfigured {
      try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [
        .allowBluetoothHFP,
        .defaultToSpeaker,
        .duckOthers,
        .mixWithOthers
      ])
    }

    try audioSession.setPreferredSampleRate(sampleRate)

    let preferredBufferDuration = Double(bufferSize) / sampleRate
    try audioSession.setPreferredIOBufferDuration(preferredBufferDuration)

    DispatchQueue.global(qos: .userInitiated).async {
      try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }
  }

  private func setupAudioEngine() throws {
    audioEngine = AVAudioEngine()
    guard let audioEngine = audioEngine else {
      throw AudioCaptureError.engineSetupFailed
    }

    inputNode = audioEngine.inputNode
    guard let inputNode = inputNode else {
      throw AudioCaptureError.inputNodeNotAvailable
    }

    let inputFormat = inputNode.outputFormat(forBus: 0)
    
    guard let tapFormat = AVAudioFormat(
      commonFormat: .pcmFormatFloat32,
      sampleRate: inputFormat.sampleRate > 0 ? inputFormat.sampleRate : sampleRate,
      channels: inputFormat.channelCount > 0 ? min(inputFormat.channelCount, channels) : channels,
      interleaved: false
    ) else {
      throw AudioCaptureError.formatSetupFailed
    }

    inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: tapFormat) { [weak self] buffer, time in
      self?.handleAudioBuffer(buffer: buffer, timestamp: time)
    }

    audioEngine.prepare()
  }

  private func handleAudioBuffer(buffer: AVAudioPCMBuffer, timestamp: AVAudioTime) {
    bufferCount += 1

    guard buffer.frameLength > 0 else {
      return
    }

    guard buffer.floatChannelData != nil else {
      return
    }

    DispatchQueue.main.async { [weak self] in
      guard let self = self, self.isCapturing else {
        return
      }

      self.delegate?.didCaptureAudioBuffer(buffer, timestamp: timestamp)
    }
  }

  @objc private func handleAudioSessionInterruption(notification: Notification) {
    guard let userInfo = notification.userInfo,
          let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
          let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
      return
    }

    switch type {
    case .began:
      print("🚨 RealtimeAudioCapture: Audio session interruption began - capture may stop")
    case .ended:
      print("🚨 RealtimeAudioCapture: Audio session interruption ended")
      if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
        let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
        if options.contains(.shouldResume) {
          print("🔄 RealtimeAudioCapture: Should resume after interruption - attempting restart")
          if isCapturing {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
              guard let self = self else { return }
              do {
                try self.startCapture()
                print("✅ RealtimeAudioCapture: Successfully restarted after interruption")
              } catch {
                print("❌ RealtimeAudioCapture: Failed to restart after interruption: \(error)")
                self.delegate?.didFailWithError(error)
              }
            }
          }
        }
      }
    @unknown default:
      print("🚨 RealtimeAudioCapture: Unknown audio session interruption type")
    }
  }

  private func validateAudioCaptureState() {
    let audioSession = AVAudioSession.sharedInstance()

    if audioSession.recordPermission == .denied {
      requestMicrophonePermission { [weak self] granted in
        if !granted {
          self?.delegate?.didFailWithError(AudioCaptureError.permissionDenied)
        }
      }
      return
    }

    if audioSession.category != .playAndRecord || audioSession.mode != .default {
      do {
        try setupAudioSession()
      } catch {
        delegate?.didFailWithError(error)
        return
      }
    }

    if audioSession.sampleRate != sampleRate {
      do {
        try audioSession.setPreferredSampleRate(sampleRate)
      } catch {
        delegate?.didFailWithError(error)
        return
      }
    }

    if audioSession.ioBufferDuration != Double(bufferSize) / sampleRate {
      do {
        let preferredBufferDuration = Double(bufferSize) / sampleRate
        try audioSession.setPreferredIOBufferDuration(preferredBufferDuration)
      } catch {
        delegate?.didFailWithError(error)
        return
      }
    }

    DispatchQueue.global(qos: .userInitiated).async {
      try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }

    if audioEngine?.isRunning == false {
      do {
        try audioEngine?.start()
      } catch {
        delegate?.didFailWithError(error)
        return
      }
    }
  }
}

enum AudioCaptureError: Error, LocalizedError {
  case permissionDenied
  case engineSetupFailed
  case inputNodeNotAvailable
  case formatSetupFailed
  case captureFailed

  var errorDescription: String? {
    switch self {
    case .permissionDenied:
      return "Microphone permission denied"
    case .engineSetupFailed:
      return "Audio engine setup failed"
    case .inputNodeNotAvailable:
      return "Audio input node not available"
    case .formatSetupFailed:
      return "Audio format setup failed"
    case .captureFailed:
      return "Audio capture failed"
    }
  }
}
