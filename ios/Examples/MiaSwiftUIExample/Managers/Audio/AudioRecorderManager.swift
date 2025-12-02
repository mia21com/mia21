//
//  AudioRecorderManager.swift
//  MiaSwiftUIExample
//
//  Created on November 9, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Manages audio recording for voice messages.
//  Records audio in M4A format for transcription.
//

import Foundation
import AVFoundation

final class AudioRecorderManager: NSObject {
  
  // MARK: - Properties
  
  private var audioRecorder: AVAudioRecorder?
  private var recordingURL: URL?
  private var isPrepared = false
  private var hasRequestedPermission = false
  var onRecordingFinished: ((Data) -> Void)?
  var onRecordingError: ((Error) -> Void)?
  var onPermissionDenied: (() -> Void)?
  
  var isRecording: Bool {
    audioRecorder?.isRecording ?? false
  }
  
  // MARK: - Public Methods
  
  func requestPermission(completion: @escaping (Bool) -> Void) {
    AVAudioSession.sharedInstance().requestRecordPermission { granted in
      DispatchQueue.main.async {
        completion(granted)
      }
    }
  }
  
  func checkPermission() -> AVAudioSession.RecordPermission {
    return AVAudioSession.sharedInstance().recordPermission
  }
  
  private func prepareRecording() {
    guard !isPrepared else { return }
    
    do {
      let audioSession = AVAudioSession.sharedInstance()
      // Only set category when actually preparing to record (after permission granted)
      try audioSession.setCategory(.record, mode: .default)
      
      let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
      let audioFilename = documentsPath.appendingPathComponent("recording-\(UUID().uuidString).m4a")
      recordingURL = audioFilename
      
      let settings: [String: Any] = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey: 44100,
        AVNumberOfChannelsKey: 1,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
      ]
      
      audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
      audioRecorder?.delegate = self
      audioRecorder?.prepareToRecord()
      isPrepared = true
    } catch {
    }
  }
  
  func startRecording() throws {
    // Check permission first
    let permission = checkPermission()
    
    switch permission {
    case .undetermined:
      // Request permission on first use
      requestPermission { [weak self] granted in
        if granted {
          try? self?.startRecording()
        } else {
          self?.onPermissionDenied?()
        }
      }
      return
      
    case .denied:
      onPermissionDenied?()
      return
      
    case .granted:
      break
      
    @unknown default:
      break
    }
    
    startRecordingDirectly()
  }
  
  func startRecordingDirectly() {
    if !isPrepared {
      prepareRecording()
    }
    
    do {
      let audioSession = AVAudioSession.sharedInstance()
      try audioSession.setActive(true)
      audioRecorder?.record()
    } catch {
      onRecordingError?(error)
    }
  }
  
  func stopRecording() {
    audioRecorder?.stop()
    try? AVAudioSession.sharedInstance().setActive(false)
    isPrepared = false
  }
  
  func cancelRecording() {
    audioRecorder?.stop()
    try? AVAudioSession.sharedInstance().setActive(false)
    
    if let url = recordingURL {
      try? FileManager.default.removeItem(at: url)
    }
    recordingURL = nil
    isPrepared = false
  }
}

// MARK: - AVAudioRecorderDelegate

extension AudioRecorderManager: AVAudioRecorderDelegate {
  func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
    guard flag, let url = recordingURL else {
      onRecordingError?(NSError(domain: "AudioRecorder", code: -1, userInfo: [NSLocalizedDescriptionKey: "Recording failed"]))
      isPrepared = false
      return
    }
    
    do {
      let audioData = try Data(contentsOf: url)
      onRecordingFinished?(audioData)
      
      try? FileManager.default.removeItem(at: url)
      recordingURL = nil
      isPrepared = false
      
      // Don't automatically prepare for next recording - only prepare when user presses mic again
    } catch {
      onRecordingError?(error)
      isPrepared = false
    }
  }
  
  func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
    onRecordingError?(error ?? NSError(domain: "AudioRecorder", code: -1, userInfo: [NSLocalizedDescriptionKey: "Encoding error"]))
  }
}
