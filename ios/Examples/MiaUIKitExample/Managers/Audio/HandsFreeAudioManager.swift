//
//  HandsFreeAudioManager.swift
//  MiaUIKitExample
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

  private let sileroVAD = SimpleVADManager.shared
  private var successfulTranscriptions = 0
  private var isHandsFreeUIActive = false
  private var isBotCurrentlySpeaking = false

  // Timing measurements for complete flow tracking
  private var processingStartTime: Date?
  private var transcriptionStartTime: Date?
  private var transcriptionEndTime: Date?
  private var botResponseStartTime: Date?
  private var botResponseEndTime: Date?

  // Reference to client for transcription
  private weak var transcriptionClient: Mia21Client?

  private override init() {
    super.init()

    sileroVAD.delegate = self
    HandsFreeAudioManager._isInitialized = true
  }

  // MARK: - Public Methods

  func setTranscriptionClient(_ client: Mia21Client) {
    transcriptionClient = client
  }

  func isMicrophonePermissionGranted() -> Bool {
    let recordPermission = AVAudioSession.sharedInstance().recordPermission
    return recordPermission == .granted
  }

  func startHandsFreeModeIfPermitted() {
    // First check if permission is granted
    let recordPermission = AVAudioSession.sharedInstance().recordPermission
    
    if recordPermission == .granted {
      print("🎤 HandsFreeAudioManager: Microphone permission already granted - starting hands-free")
      startHandsFreeMode()
    } else if recordPermission == .undetermined {
      print("🎤 HandsFreeAudioManager: Microphone permission undetermined - requesting permission")
      AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
        DispatchQueue.main.async {
          if granted {
            print("🎤 HandsFreeAudioManager: Microphone permission granted - starting hands-free")
            self?.startHandsFreeMode()
          } else {
            print("🎤 HandsFreeAudioManager: Microphone permission denied")
            self?.delegate?.handsFreePermissionDenied()
          }
        }
      }
    } else {
      print("🎤 HandsFreeAudioManager: Microphone permission denied - ignoring hands-free request")
      delegate?.handsFreePermissionDenied()
    }
  }

  func startHandsFreeMode() {
    print("🎤 HandsFreeAudioManager: startHandsFreeMode called - isBotCurrentlySpeaking=\(isBotCurrentlySpeaking)")
    isHandsFreeUIActive = true

    // Reset timing data for fresh measurements
    processingStartTime = nil
    transcriptionStartTime = nil
    transcriptionEndTime = nil
    botResponseStartTime = nil
    botResponseEndTime = nil

    print("⏱️ TIMING: Reset timing data for new session")

    if isBotCurrentlySpeaking {
      print("🎤 HandsFreeAudioManager: Bot is speaking - activating UI but waiting to start listening")
      delegate?.handsFreeDidStartListening()
    } else {
      print("🎤 HandsFreeAudioManager: Bot not speaking - starting VAD immediately")
      startActualListening()
    }
  }
    
  private func startActualListening() {
    print("🎤 HandsFreeAudioManager: startActualListening called")
    sileroVAD.startVADMode()
  }

  func stopHandsFreeMode() {
    print("🎤 HandsFreeAudioManager: stopHandsFreeMode called - preserving isBotCurrentlySpeaking=\(isBotCurrentlySpeaking)")
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
    print("🎤 HandsFreeAudioManager: botDidStartSpeaking - isBotCurrentlySpeaking=\(isBotCurrentlySpeaking) → true, isActuallyListening=\(isActuallyListening), isHandsFreeUIActive=\(isHandsFreeUIActive)")

    if let processingStart = processingStartTime,
       let botResponseStart = botResponseStartTime,
       let botResponseEnd = botResponseEndTime {

      let transcriptionTime = transcriptionEndTime?.timeIntervalSince(transcriptionStartTime ?? Date()) ?? 0
      let botResponseTime = botResponseEnd.timeIntervalSince(botResponseStart)
      let totalTime = botResponseEnd.timeIntervalSince(processingStart)

      print("⏱️ TIMING BREAKDOWN:")
      print("   - Transcription: \(String(format: "%.3f", transcriptionTime))s")
      print("   - Bot Response: \(String(format: "%.3f", botResponseTime))s")
      print("   - Total (processing to talking): \(String(format: "%.3f", totalTime))s")
    }

    isBotCurrentlySpeaking = true

    sileroVAD.botDidStartSpeaking()
  }

  func botDidStopSpeaking() {
    print("🎤 HandsFreeAudioManager: botDidStopSpeaking - isBotCurrentlySpeaking=\(isBotCurrentlySpeaking) → false, isHandsFreeUIActive=\(isHandsFreeUIActive), isActuallyListening=\(isActuallyListening)")
    isBotCurrentlySpeaking = false

    sileroVAD.botDidStopSpeaking()

    if isHandsFreeUIActive && !isActuallyListening {
      print("🎤 HandsFreeAudioManager: Bot stopped speaking - now starting actual listening")
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
        self.startActualListening()
      }
    }
  }
}

// MARK: - SimpleVADManagerDelegate

extension HandsFreeAudioManager: SimpleVADManagerDelegate {
  func vadDidStartListening() {
    print("🎤 HandsFreeAudioManager: Received vadDidStartListening from SimpleVADManager")
    delegate?.handsFreeDidStartListening()
  }

  func vadDidStopListening() {
    print("🎤 HandsFreeAudioManager: Received vadDidStopListening from SimpleVADManager")
    delegate?.handsFreeDidStopListening()
  }

  func vadDidDetectSpeech(_ audioData: Data, duration: TimeInterval) {
    print("🎤 HandsFreeAudioManager: Received speech data from SimpleVADManager - Size: \(audioData.count) bytes, Duration: \(String(format: "%.2f", duration))s")

    transcribeWAVData(wavData: audioData, duration: duration) { [weak self] result in
      DispatchQueue.main.async {
        switch result {
        case .success(let text):
          self?.successfulTranscriptions += 1
          let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
          print("✅ SimpleVAD Transcription successful (#\(self?.successfulTranscriptions ?? 0)): \"\(cleanText)\"")

          if !cleanText.isEmpty && cleanText.count > 1 {
            self?.delegate?.handsFreeDidDetectSpeech(cleanText)
          } else {
            print("⚠️ Transcription too short or empty, ignoring: \"\(text)\"")
          }
        case .failure(let error):
          print("❌ SimpleVAD Transcription failed: \(error)")
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
    print("🎙️ Transcribing WAV data - Size: \(wavData.count) bytes, Duration: \(String(format: "%.2f", duration))s")

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

        do {
          try FileManager.default.removeItem(at: tempAudioURL)
        } catch {
          print("⚠️ Failed to remove temp file: \(error)")
        }

        switch result {
        case .success(let text):
          successfulTranscriptions += 1
          let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
          print("✅ Transcription successful (#\(successfulTranscriptions)): \"\(cleanText)\"")

          if !cleanText.isEmpty && cleanText.count > 1 {
            botResponseStartTime = Date()

            completion(.success(cleanText))
          } else {
            print("⚠️ Transcription too short or empty, ignoring: \"\(text)\"")
            completion(.failure(NSError(domain: "HandsFreeAudioManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "Transcription too short"])))
          }
        case .failure(let error):
          print("❌ Transcription failed: \(error)")
          completion(.failure(error))
        }
      } catch {
        do {
          try FileManager.default.removeItem(at: tempAudioURL)
        } catch {}
        completion(.failure(error))
      }
    }
  }

  private func transcribeAudioFile(url: URL) async throws -> Result<String, Error> {
    guard let client = transcriptionClient else {
      throw NSError(domain: "HandsFreeAudioManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Transcription client not set"])
    }

    do {
      // Convert WAV to M4A if needed (transcription API expects M4A)
      let audioData: Data
      if url.pathExtension.lowercased() == "wav" {
        let m4aURL = try await convertWAVToM4A(inputURL: url)
        audioData = try Data(contentsOf: m4aURL)
        // Clean up temp M4A file
        try? FileManager.default.removeItem(at: m4aURL)
      } else {
        // Already in correct format
        audioData = try Data(contentsOf: url)
      }

      // Use Mia21Client to transcribe
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
      let error = exportSession.error ?? NSError(domain: "HandsFreeAudioManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "Export failed"])
      throw error
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
