//
//  HandsFreeAudioManager.swift
//  MiaSwiftUIExample
//
//  Created on November 9, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Main coordinator for hands-free mode, managing VAD, transcription, and bot speech coordination.
//

import AVFoundation
import Foundation
import Mia21
import AVKit

// MARK: - HandsFreeAudioManagerDelegate

protocol HandsFreeAudioManagerDelegate: AnyObject {
  func handsFreeDidStartListening()
  func handsFreeDidStopListening()
  func handsFreeDidDetectSpeech(_ text: String)
  func handsFreeDidFailWithError(_ error: Error)
  func handsFreeVoiceActivityChanged(_ isActive: Bool)
  func handsFreeDidStartRecordingChunk()
  func handsFreeDidFinishRecordingChunk(duration: TimeInterval)
  func handsFreePermissionDenied()
}

// MARK: - HandsFreeAudioManager

final class HandsFreeAudioManager: NSObject {
  static let shared = HandsFreeAudioManager()

  private static var _isInitialized = false
  static var isInitialized: Bool { _isInitialized }

  weak var delegate: HandsFreeAudioManagerDelegate?

  private lazy var sileroVAD: SimpleVADManager = {
    let vad = SimpleVADManager.shared
    vad.delegate = self
    return vad
  }()
  private var successfulTranscriptions = 0
  private var isHandsFreeUIActive = false
  private var isBotCurrentlySpeaking = false

  private var processingStartTime: Date?
  private var transcriptionStartTime: Date?
  private var transcriptionEndTime: Date?
  private var botResponseStartTime: Date?
  private var botResponseEndTime: Date?

  private weak var transcriptionClient: Mia21Client?

  private override init() {
    super.init()
    HandsFreeAudioManager._isInitialized = true
  }

  // MARK: - Public Methods

  func setTranscriptionClient(_ client: Mia21Client) {
    transcriptionClient = client
  }

  func isMicrophonePermissionGranted() -> Bool {
    return AVAudioSession.sharedInstance().recordPermission == .granted
  }

  func startHandsFreeModeIfPermitted() {
    let recordPermission = AVAudioSession.sharedInstance().recordPermission
    
    if recordPermission == .granted {
      startHandsFreeMode()
    } else if recordPermission == .undetermined {
      AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
        DispatchQueue.main.async {
          if granted {
            self?.startHandsFreeMode()
          } else {
            self?.delegate?.handsFreePermissionDenied()
          }
        }
      }
    } else {
      delegate?.handsFreePermissionDenied()
    }
  }

  func startHandsFreeMode() {
    isHandsFreeUIActive = true
    processingStartTime = nil
    transcriptionStartTime = nil
    transcriptionEndTime = nil
    botResponseStartTime = nil
    botResponseEndTime = nil

    if isBotCurrentlySpeaking {
      delegate?.handsFreeDidStartListening()
    } else {
      startActualListening()
    }
  }
    
  private func startActualListening() {
    sileroVAD.startVADMode()
  }

  func stopHandsFreeMode() {
    isHandsFreeUIActive = false
    sileroVAD.stopVADMode()
  }

  func interruptPandaSpeaking() {
    sileroVAD.wasInterrupted()
  }

  var isActive: Bool {
    return isHandsFreeUIActive
  }
  
  var isActuallyListening: Bool {
    return sileroVAD.isActive
  }

  // MARK: - Bot Speech Management

  func botDidStartSpeaking() {
    botResponseEndTime = Date()
    isBotCurrentlySpeaking = true
    sileroVAD.botDidStartSpeaking()
  }

  func botDidStopSpeaking() {
    isBotCurrentlySpeaking = false
    sileroVAD.botDidStopSpeaking()

    if isHandsFreeUIActive && !isActuallyListening {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
        self.startActualListening()
      }
    }
  }
}

// MARK: - SimpleVADManagerDelegate

extension HandsFreeAudioManager: SimpleVADManagerDelegate {
  func vadDidStartListening() {
    delegate?.handsFreeDidStartListening()
  }

  func vadDidStopListening() {
    delegate?.handsFreeDidStopListening()
  }

  func vadDidDetectSpeech(_ audioData: Data, duration: TimeInterval) {
    transcribeWAVData(wavData: audioData, duration: duration) { [weak self] result in
      DispatchQueue.main.async {
        switch result {
        case .success(let text):
          self?.successfulTranscriptions += 1
          let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
          if !cleanText.isEmpty && cleanText.count > 1 {
            self?.delegate?.handsFreeDidDetectSpeech(cleanText)
          }
        case .failure(let error):
          self?.delegate?.handsFreeDidFailWithError(error)
        }
      }
    }
  }

  func vadDidFailWithError(_ error: Error) {
    delegate?.handsFreeDidFailWithError(error)
  }

  func vadVoiceActivityChanged(_ isActive: Bool) {
    delegate?.handsFreeVoiceActivityChanged(isActive)
  }

  func vadDidStartRecordingChunk() {
    delegate?.handsFreeDidStartRecordingChunk()
  }

  func vadDidFinishRecordingChunk(duration: TimeInterval) {
    delegate?.handsFreeDidFinishRecordingChunk(duration: duration)
  }
}

// MARK: - Transcription Helper

extension HandsFreeAudioManager {
  private func transcribeWAVData(wavData: Data, duration: TimeInterval, completion: @escaping (Result<String, Error>) -> Void) {
    processingStartTime = Date()
    transcriptionStartTime = Date()
    sileroVAD.startProcessing()

    guard let tempAudioURL = try? createTempWAVFileFromData(wavData) else {
      completion(.failure(NSError(domain: "HandsFreeAudioManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create temp WAV file"])))
      return
    }

    Task {
      do {
        let result = try await transcribeAudioFile(url: tempAudioURL)
        transcriptionEndTime = Date()
        try? FileManager.default.removeItem(at: tempAudioURL)

        switch result {
        case .success(let text):
          successfulTranscriptions += 1
          let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
          if !cleanText.isEmpty && cleanText.count > 1 {
            botResponseStartTime = Date()
            completion(.success(cleanText))
          } else {
            completion(.failure(NSError(domain: "HandsFreeAudioManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "Transcription too short"])))
          }
        case .failure(let error):
          completion(.failure(error))
        }
      } catch {
        try? FileManager.default.removeItem(at: tempAudioURL)
        completion(.failure(error))
      }
    }
  }

  private func transcribeAudioFile(url: URL) async throws -> Result<String, Error> {
    guard let client = transcriptionClient else {
      throw NSError(domain: "HandsFreeAudioManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Transcription client not set"])
    }

    do {
      let audioData: Data
      if url.pathExtension.lowercased() == "wav" {
        let m4aURL = try await convertWAVToM4A(inputURL: url)
        audioData = try Data(contentsOf: m4aURL)
        try? FileManager.default.removeItem(at: m4aURL)
      } else {
        audioData = try Data(contentsOf: url)
      }

      let response = try await client.transcribeAudio(audioData: audioData)
      return .success(response.text)
    } catch {
      return .failure(error)
    }
  }

  private func convertWAVToM4A(inputURL: URL) async throws -> URL {
    let tempDirectory = FileManager.default.temporaryDirectory
    let outputURL = tempDirectory.appendingPathComponent("converted_\(Date().timeIntervalSince1970).m4a")

    let asset = AVAsset(url: inputURL)

    guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
      throw NSError(domain: "HandsFreeAudioManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create export session"])
    }

    exportSession.outputURL = outputURL
    exportSession.outputFileType = .m4a

    await exportSession.export()
    
    switch exportSession.status {
    case .completed:
      return outputURL
    case .failed, .cancelled:
      throw exportSession.error ?? NSError(domain: "HandsFreeAudioManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "Export failed"])
    default:
      throw NSError(domain: "HandsFreeAudioManager", code: -3, userInfo: [NSLocalizedDescriptionKey: "Unknown export error"])
    }
  }

  private func createTempWAVFileFromData(_ wavData: Data) throws -> URL {
    let tempDirectory = FileManager.default.temporaryDirectory
    let fileName = "hands_free_transcription_\(Date().timeIntervalSince1970).wav"
    let tempURL = tempDirectory.appendingPathComponent(fileName)
    try wavData.write(to: tempURL)
    return tempURL
  }
}
