package com.mia21.example.utils

/**
 * AudioRecorderManager.kt
 * Utility class for recording audio using MediaRecorder.
 * Handles permission checks, recording start/stop, and returns
 * audio data as ByteArray. Used for voice input transcription.
 */

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.media.MediaRecorder
import android.os.Build
import android.util.Log
import androidx.core.content.ContextCompat
import java.io.File
import java.io.IOException

class AudioRecorderManager(private val context: Context) {
    private var mediaRecorder: MediaRecorder? = null
    private var outputFile: File? = null
    private var isRecording = false

    var onRecordingError: ((Exception) -> Unit)? = null
    var onPermissionDenied: (() -> Unit)? = null

    fun hasPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.RECORD_AUDIO
        ) == PackageManager.PERMISSION_GRANTED
    }

    fun startRecording(): Boolean {
        if (!hasPermission()) {
            onPermissionDenied?.invoke()
            return false
        }

        if (isRecording) {
            return false
        }

        try {
            // Create temporary file for recording
            val tempDir = File(context.cacheDir, "audio_recordings")
            if (!tempDir.exists()) {
                tempDir.mkdirs()
            }
            outputFile = File(tempDir, "recording_${System.currentTimeMillis()}.m4a")

            mediaRecorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                MediaRecorder(context)
            } else {
                @Suppress("DEPRECATION")
                (MediaRecorder())
            }

            mediaRecorder?.apply {
                setAudioSource(MediaRecorder.AudioSource.MIC)
                setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
                setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
                setAudioSamplingRate(44100)
                setAudioChannels(1)
                setAudioEncodingBitRate(128000)
                setOutputFile(outputFile?.absolutePath)

                try {
                    prepare()
                    start()
                    isRecording = true
                    Log.d("AudioRecorder", "Recording started: ${outputFile?.absolutePath}")
                    return true
                } catch (e: IOException) {
                    Log.e("AudioRecorder", "Failed to prepare recorder", e)
                    release()
                    mediaRecorder = null
                    onRecordingError?.invoke(e)
                    return false
                }
            }
        } catch (e: Exception) {
            Log.e("AudioRecorder", "Failed to start recording", e)
            onRecordingError?.invoke(e)
            return false
        }

        return false
    }

    fun stopRecording(): ByteArray? {
        if (!isRecording || mediaRecorder == null) {
            return null
        }

        try {
            mediaRecorder?.apply {
                stop()
                release()
            }
            mediaRecorder = null
            isRecording = false

            val audioData = outputFile?.readBytes()
            outputFile?.delete() // Clean up temp file

            Log.d("AudioRecorder", "Recording stopped. Size: ${audioData?.size ?: 0} bytes")
            return audioData
        } catch (e: Exception) {
            Log.e("AudioRecorder", "Failed to stop recording", e)
            onRecordingError?.invoke(e)
            mediaRecorder?.release()
            mediaRecorder = null
            isRecording = false
            outputFile?.delete()
            return null
        }
    }
}