//
//  ChatInputView.swift
//  MiaSwiftUIExample
//
//  Created on November 7, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  Input container with text field, mic, send, and hands-free buttons matching UIKit version.
//

import SwiftUI

struct ChatInputView: View {
  @Binding var inputText: String
  @FocusState.Binding var isInputFocused: Bool
  let isLoading: Bool
  let canSend: Bool
  let isRecording: Bool
  let isHandsFreeModeEnabled: Bool
  let isRecordingState: Bool
  let isTranscribingState: Bool
  let onSend: () -> Void
  let onRecord: () -> Void
  let onHandsFreeTapped: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      Divider().frame(height: 0.5)
      HStack(spacing: 8) {
        ZStack(alignment: .leading) {
          // Text field - hidden when recording or transcribing
          if !isRecordingState && !isTranscribingState {
            TextField("Message", text: $inputText, axis: .vertical)
              .lineLimit(1...5)
              .textFieldStyle(.plain)
              .padding(.leading, 16)
              .padding(.trailing, 16)
              .padding(.vertical, 12)
              .frame(minHeight: 46)
              .background(Color(.secondarySystemBackground))
              .cornerRadius(23)
              .focused($isInputFocused)
              .submitLabel(.send)
              .onSubmit {
                if canSend {
                  onSend()
                }
              }
              .disabled(isHandsFreeModeEnabled)
              .opacity(isHandsFreeModeEnabled ? 0.5 : 1.0)
          }
          
          // Status label with spinner for recording/transcribing
          if isRecordingState || isTranscribingState {
            HStack(spacing: 8) {
              ProgressView()
                .scaleEffect(0.8)
                .padding(.leading, 16)
              
              Text(isRecordingState ? "Listening..." : "Transcribing...")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 46)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(23)
            .padding(.leading, 8)
          }
        }

        // Mic button - hidden when typing
        if !hasText {
          Button {
            onRecord()
          } label: {
            Image(systemName: isRecording ? "stop.circle.fill" : "mic.fill")
              .font(.system(size: 18, weight: .medium))
              .foregroundColor(isRecording ? .white : .primary)
          }
          .frame(width: 36, height: 36)
          .background(isRecording ? Color.red : Color(.secondarySystemFill))
          .clipShape(Circle())
          .disabled(isHandsFreeModeEnabled || isTranscribingState)
          .opacity((isHandsFreeModeEnabled || isTranscribingState) ? 0.5 : 1.0)
        }

        // Send button - visible when typing
        if hasText {
          Button {
            onSend()
          } label: {
            Image(systemName: "arrow.up")
              .font(.system(size: 16, weight: .bold))
              .foregroundColor(.white)
          }
          .frame(width: 36, height: 36)
          .background(
            LinearGradient.appGradient
          )
          .clipShape(Circle())
          .disabled(!canSend || isHandsFreeModeEnabled)
          .opacity((canSend && !isHandsFreeModeEnabled) ? 1.0 : 0.5)
        }

        // Hands-free button - hidden when typing, recording, or transcribing
        if !hasText && !isRecording && !isRecordingState && !isTranscribingState {
          Button {
            onHandsFreeTapped()
          } label: {
            Image(systemName: isHandsFreeModeEnabled ? "waveform.circle.fill" : "waveform")
              .font(.system(size: 18, weight: .medium))
              .foregroundColor(isHandsFreeModeEnabled ? .white : .primary)
          }
          .frame(width: 36, height: 36)
          .background(isHandsFreeModeEnabled ? Color.blue : Color(.secondarySystemFill))
          .clipShape(Circle())
          .disabled(isRecordingState || isTranscribingState)
          .opacity((isRecordingState || isTranscribingState) ? 0.5 : 1.0)
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .background(Color(.systemBackground))
      .animation(.easeInOut(duration: 0.2), value: hasText)
      .animation(.easeInOut(duration: 0.2), value: isRecording)
      .animation(.easeInOut(duration: 0.2), value: isRecordingState)
      .animation(.easeInOut(duration: 0.2), value: isTranscribingState)
    }
  }

  private var hasText: Bool {
    !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }
}
