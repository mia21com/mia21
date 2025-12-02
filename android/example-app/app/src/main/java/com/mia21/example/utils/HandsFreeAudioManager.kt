package com.mia21.example.utils

import android.annotation.SuppressLint
import android.content.Context
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.util.Log
import androidx.core.content.ContextCompat
import android.Manifest
import android.content.pm.PackageManager
import com.mia21.Mia21Client
import com.mia21.example.utils.Constants.TAG
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder

/**
 * Delegate interface for hands-free audio events
 */
interface HandsFreeAudioManagerDelegate {
    fun onSpeechDetected(text: String)
    fun onListeningStateChanged(isListening: Boolean)
    fun onVoiceActivityChanged(isActive: Boolean)
    fun onError(error: Exception)
    fun onPermissionDenied()
}

/**
 * Manager for hands-free mode with Voice Activity Detection (VAD)
 * Continuously listens for speech, detects voice activity, and transcribes automatically
 */
class HandsFreeAudioManager(
    private val context: Context,
    private val client: Mia21Client
) {
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    
    private var audioRecord: AudioRecord? = null
    private var isListeningInternal = false
    private var isBotSpeaking = false
    
    // VAD parameters
    private val sampleRate = 16000
    private val channelConfig = AudioFormat.CHANNEL_IN_MONO
    private val audioFormat = AudioFormat.ENCODING_PCM_16BIT
    private val bufferSize = AudioRecord.getMinBufferSize(sampleRate, channelConfig, audioFormat)
    
    // Voice activity detection
    private val silenceThreshold = 500 // RMS threshold for silence
    private val speechThreshold = 1500 // RMS threshold for speech
    private val minSpeechDurationMs = 300L // Minimum speech duration to process
    private val maxSilenceDurationMs = 2000L // Max silence before ending speech
    
    // Speech detection state
    private var isCurrentlySpeaking = false
    private var speechStartTime = 0L
    private var lastSpeechTime = 0L
    private val speechBuffer = ByteArrayOutputStream()
    
    // State flows
    private val _isListening = MutableStateFlow(false)
    val isListening: StateFlow<Boolean> = _isListening.asStateFlow()
    
    private val _isVoiceActive = MutableStateFlow(false)
    val isVoiceActive: StateFlow<Boolean> = _isVoiceActive.asStateFlow()
    
    var delegate: HandsFreeAudioManagerDelegate? = null
    
    fun hasPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.RECORD_AUDIO
        ) == PackageManager.PERMISSION_GRANTED
    }
    
    fun startHandsFreeMode() {
        if (!hasPermission()) {
            Log.w(TAG, "HandsFree: No microphone permission")
            delegate?.onPermissionDenied()
            return
        }
        
        if (isListeningInternal) {
            Log.d(TAG, "HandsFree: Already listening")
            return
        }
        
        if (isBotSpeaking) {
            Log.d(TAG, "HandsFree: Bot is speaking, will start listening when bot stops")
            _isListening.value = true
            delegate?.onListeningStateChanged(true)
            return
        }
        
        startActualListening()
    }
    
    private fun startActualListening() {
        if (isListeningInternal) return
        
        // Check permission before creating AudioRecord
        if (!hasPermission()) {
            Log.w(TAG, "HandsFree: No microphone permission")
            delegate?.onPermissionDenied()
            return
        }
        
        try {
            if (bufferSize == AudioRecord.ERROR_BAD_VALUE || bufferSize == AudioRecord.ERROR) {
                throw Exception("Invalid buffer size")
            }
            
            @SuppressLint("MissingPermission")
            val record = try {
                AudioRecord(
                    MediaRecorder.AudioSource.MIC,
                    sampleRate,
                    channelConfig,
                    audioFormat,
                    bufferSize * 2
                )
            } catch (e: SecurityException) {
                Log.e(TAG, "HandsFree: SecurityException creating AudioRecord", e)
                delegate?.onPermissionDenied()
                return
            }
            audioRecord = record
            
            if (audioRecord?.state != AudioRecord.STATE_INITIALIZED) {
                throw Exception("AudioRecord initialization failed")
            }
            
            isListeningInternal = true
            _isListening.value = true
            delegate?.onListeningStateChanged(true)
            
            // Reset speech detection state
            isCurrentlySpeaking = false
            speechStartTime = 0L
            lastSpeechTime = 0L
            speechBuffer.reset()
            
            scope.launch {
                audioRecord?.startRecording()
                Log.d(TAG, "HandsFree: Started listening")
                
                val buffer = ByteArray(bufferSize)
                
                while (isListeningInternal && audioRecord != null) {
                    val readResult = audioRecord!!.read(buffer, 0, buffer.size)
                    
                    if (readResult > 0) {
                        processAudioChunk(buffer, readResult)
                    } else if (readResult == AudioRecord.ERROR_INVALID_OPERATION) {
                        Log.e(TAG, "HandsFree: Invalid operation")
                        break
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "HandsFree: Failed to start listening", e)
            isListeningInternal = false
            _isListening.value = false
            delegate?.onError(e)
        }
    }
    
    private suspend fun processAudioChunk(buffer: ByteArray, size: Int) {
        if (isBotSpeaking) {
            // Discard audio while bot is speaking
            return
        }
        
        // Calculate RMS (Root Mean Square) for voice activity detection
        val rms = calculateRMS(buffer, size)
        val currentTime = System.currentTimeMillis()
        
        if (rms > speechThreshold) {
            // Speech detected
            if (!isCurrentlySpeaking) {
                // Start of speech
                isCurrentlySpeaking = true
                speechStartTime = currentTime
                speechBuffer.reset()
                _isVoiceActive.value = true
                delegate?.onVoiceActivityChanged(true)
                Log.d(TAG, "HandsFree: Speech started (RMS: $rms)")
            }
            
            lastSpeechTime = currentTime
            speechBuffer.write(buffer, 0, size)
        } else if (rms < silenceThreshold && isCurrentlySpeaking) {
            // Silence detected during speech
            val silenceDuration = currentTime - lastSpeechTime
            
            if (silenceDuration > maxSilenceDurationMs) {
                // End of speech
                val speechDuration = currentTime - speechStartTime
                
                if (speechDuration >= minSpeechDurationMs) {
                    // Process the speech
                    val audioData = speechBuffer.toByteArray()
                    if (audioData.isNotEmpty()) {
                        processSpeech(audioData, speechDuration)
                    }
                }
                
                isCurrentlySpeaking = false
                speechStartTime = 0L
                lastSpeechTime = 0L
                speechBuffer.reset()
                _isVoiceActive.value = false
                delegate?.onVoiceActivityChanged(false)
                Log.d(TAG, "HandsFree: Speech ended (duration: ${speechDuration}ms)")
            } else {
                // Still in speech, continue collecting
                speechBuffer.write(buffer, 0, size)
            }
        } else if (isCurrentlySpeaking) {
            // Continue collecting speech
            speechBuffer.write(buffer, 0, size)
        }
    }
    
    private fun calculateRMS(buffer: ByteArray, size: Int): Double {
        var sum = 0.0
        val samples = ByteBuffer.wrap(buffer, 0, size)
            .order(ByteOrder.LITTLE_ENDIAN)
            .asShortBuffer()
        
        for (i in 0 until samples.remaining()) {
            val sample = samples[i].toDouble()
            sum += sample * sample
        }
        
        return if (samples.remaining() > 0) {
            kotlin.math.sqrt(sum / samples.remaining())
        } else {
            0.0
        }
    }
    
    private suspend fun processSpeech(audioData: ByteArray, durationMs: Long) {
        try {
            Log.d(TAG, "HandsFree: Processing speech (${audioData.size} bytes, ${durationMs}ms)")
            
            // Convert PCM to WAV format for transcription
            val wavData = convertPCMToWAV(audioData)
            
            // Transcribe audio
            val response = withContext(Dispatchers.IO) {
                client.transcribeAudio(wavData)
            }
            
            val text = response.text.trim()
            
            if (text.isNotEmpty() && text.length > 1) {
                Log.d(TAG, "HandsFree: Transcribed: \"$text\"")
                delegate?.onSpeechDetected(text)
            } else {
                Log.d(TAG, "HandsFree: Transcription too short or empty")
            }
        } catch (e: Exception) {
            Log.e(TAG, "HandsFree: Transcription failed", e)
            delegate?.onError(e)
        }
    }
    
    private fun convertPCMToWAV(pcmData: ByteArray): ByteArray {
        val wav = ByteArrayOutputStream()
        
        // WAV header
        val totalDataLen = pcmData.size + 36
        val longSampleRate = sampleRate.toLong()
        val channels = 1
        val byteRate = sampleRate * channels * 2
        
        // RIFF header
        wav.write("RIFF".toByteArray())
        wav.write(intToByteArray(totalDataLen), 0, 4)
        wav.write("WAVE".toByteArray())
        
        // fmt chunk
        wav.write("fmt ".toByteArray())
        wav.write(intToByteArray(16), 0, 4) // Subchunk1Size
        wav.write(shortToByteArray(1), 0, 2) // AudioFormat (PCM)
        wav.write(shortToByteArray(channels), 0, 2) // NumChannels
        wav.write(intToByteArray(longSampleRate.toInt()), 0, 4) // SampleRate
        wav.write(intToByteArray(byteRate), 0, 4) // ByteRate
        wav.write(shortToByteArray(2), 0, 2) // BlockAlign
        wav.write(shortToByteArray(16), 0, 2) // BitsPerSample
        
        // data chunk
        wav.write("data".toByteArray())
        wav.write(intToByteArray(pcmData.size), 0, 4)
        wav.write(pcmData)
        
        return wav.toByteArray()
    }
    
    private fun intToByteArray(value: Int): ByteArray {
        return byteArrayOf(
            (value and 0xFF).toByte(),
            ((value shr 8) and 0xFF).toByte(),
            ((value shr 16) and 0xFF).toByte(),
            ((value shr 24) and 0xFF).toByte()
        )
    }
    
    private fun shortToByteArray(value: Int): ByteArray {
        return byteArrayOf(
            (value and 0xFF).toByte(),
            ((value shr 8) and 0xFF).toByte()
        )
    }
    
    fun stopHandsFreeMode() {
        if (!isListeningInternal) return
        
        isListeningInternal = false
        _isListening.value = false
        _isVoiceActive.value = false
        
        try {
            audioRecord?.apply {
                if (state == AudioRecord.STATE_INITIALIZED) {
                    stop()
                }
                release()
            }
        } catch (e: Exception) {
            Log.e(TAG, "HandsFree: Error stopping", e)
        }
        
        audioRecord = null
        isCurrentlySpeaking = false
        speechBuffer.reset()
        
        delegate?.onListeningStateChanged(false)
        Log.d(TAG, "HandsFree: Stopped listening")
    }
    
    fun botDidStartSpeaking() {
        Log.d(TAG, "HandsFree: Bot started speaking - ignoring microphone input")
        isBotSpeaking = true
        
        // Reset any ongoing speech detection to prevent processing bot's audio
        if (isCurrentlySpeaking) {
            isCurrentlySpeaking = false
            speechStartTime = 0L
            lastSpeechTime = 0L
            speechBuffer.reset()
            _isVoiceActive.value = false
            delegate?.onVoiceActivityChanged(false)
        }
    }
    
    fun botDidStopSpeaking() {
        Log.d(TAG, "HandsFree: Bot stopped speaking - resuming microphone input")
        isBotSpeaking = false
        
        if (_isListening.value && !isListeningInternal) {
            // Start listening if we were waiting for bot to finish
            startActualListening()
        }
    }
    
    fun cleanup() {
        stopHandsFreeMode()
        scope.cancel()
    }
}

