package com.mia21.example.utils

/**
 * AudioPlaybackManager.kt
 * Manages audio playback for voice responses.
 * Handles MP3 audio chunks in a sequential queue system
 * similar to the iOS implementation.
 */

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.util.Log
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import java.io.File
import java.io.FileOutputStream

class AudioPlaybackManager(private val context: Context) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    
    private val audioQueue = mutableListOf<ByteArray>()
    private var currentMediaPlayer: MediaPlayer? = null
    private var isProcessingQueue = false
    private var isPlayingAudio = false
    private var hasStartedPlayingAudio = false
    private var hasNotifiedBotStarted = false
    
    var isEnabled: Boolean = false
    var isHandsFreeActive: Boolean = false
    var onFirstAudioStart: (() -> Unit)? = null
    var onBotDidStartSpeaking: (() -> Unit)? = null
    var onBotDidStopSpeaking: (() -> Unit)? = null
    
    val hasStartedPlaying: Boolean
        get() = hasStartedPlayingAudio
    
    fun queueAudioChunk(audioData: ByteArray) {
        if (!isEnabled) return
        
        synchronized(audioQueue) {
            audioQueue.add(audioData)
        }
        
        if (!isProcessingQueue) {
            playNextInQueue()
        }
    }
    
    fun reset() {
        stopAll()
        synchronized(audioQueue) {
            audioQueue.clear()
        }
        hasStartedPlayingAudio = false
        isProcessingQueue = false
        isPlayingAudio = false
        hasNotifiedBotStarted = false
    }
    
    fun stopAll() {
        val wasPlaying = hasNotifiedBotStarted
        
        scope.launch(Dispatchers.Main) {
            currentMediaPlayer?.let { player ->
                try {
                    if (player.isPlaying) {
                        player.stop()
                    }
                    player.release()
                } catch (e: Exception) {
                    Log.e(Constants.TAG, "Error stopping MediaPlayer", e)
                }
            }
            currentMediaPlayer = null
            isPlayingAudio = false
            isProcessingQueue = false
            
            if (wasPlaying) {
                hasNotifiedBotStarted = false
                onBotDidStopSpeaking?.invoke()
            }
        }
    }
    
    private fun playNextInQueue() {
        if (isProcessingQueue) return
        
        val audioData = synchronized(audioQueue) {
            if (audioQueue.isEmpty()) {
                if (hasNotifiedBotStarted) {
                    isProcessingQueue = false
                    isPlayingAudio = false
                    hasNotifiedBotStarted = false
                    onBotDidStopSpeaking?.invoke()
                }
                return
            }
            audioQueue.removeAt(0)
        }
        
        isProcessingQueue = true
        
        scope.launch(Dispatchers.IO) {
            try {
                // Configure audio session
                val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
                
                if (!isPlayingAudio) {
                    if (isHandsFreeActive) {
                        // Keep playAndRecord mode for hands-free
                        audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
                    } else {
                        // Use playback mode when hands-free is not active
                        audioManager.mode = AudioManager.MODE_NORMAL
                    }
                }
                
                // Write audio data to temporary file
                val tempFile = File(context.cacheDir, "audio_chunk_${System.currentTimeMillis()}.mp3")
                FileOutputStream(tempFile).use { it.write(audioData) }
                
                // Create and play MediaPlayer on main thread
                scope.launch(Dispatchers.Main) {
                    try {
                        val mediaPlayer = MediaPlayer().apply {
                            setAudioAttributes(
                                AudioAttributes.Builder()
                                    .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                                    .setUsage(AudioAttributes.USAGE_MEDIA)
                                    .build()
                            )
                            setDataSource(tempFile.absolutePath)
                            prepare()
                            
                            setOnCompletionListener {
                                isProcessingQueue = false
                                it.release()
                                
                                // Check if queue is empty
                                synchronized(audioQueue) {
                                    if (audioQueue.isEmpty() && hasNotifiedBotStarted) {
                                        hasNotifiedBotStarted = false
                                        onBotDidStopSpeaking?.invoke()
                                    }
                                }
                                
                                // Clean up temp file
                                tempFile.delete()
                                
                                // Play next in queue
                                playNextInQueue()
                            }
                            
                            setOnErrorListener { _, what, extra ->
                                Log.e(Constants.TAG, "MediaPlayer error: what=$what, extra=$extra")
                                isProcessingQueue = false
                                release()
                                tempFile.delete()
                                playNextInQueue()
                                true
                            }
                        }
                        
                        currentMediaPlayer = mediaPlayer
                        isPlayingAudio = true
                        
                        if (!hasStartedPlayingAudio) {
                            hasStartedPlayingAudio = true
                            onFirstAudioStart?.invoke()
                        }
                        
                        // Notify that bot started speaking (only once per session)
                        if (!hasNotifiedBotStarted) {
                            hasNotifiedBotStarted = true
                            onBotDidStartSpeaking?.invoke()
                        }
                        
                        mediaPlayer.start()
                        
                    } catch (e: Exception) {
                        Log.e(Constants.TAG, "Error playing audio chunk", e)
                        isProcessingQueue = false
                        tempFile.delete()
                        playNextInQueue()
                    }
                }
                
            } catch (e: Exception) {
                Log.e(Constants.TAG, "Error processing audio chunk", e)
                isProcessingQueue = false
                playNextInQueue()
            }
        }
    }
    
    fun cleanup() {
        stopAll()
        synchronized(audioQueue) {
            audioQueue.clear()
        }
    }
}

