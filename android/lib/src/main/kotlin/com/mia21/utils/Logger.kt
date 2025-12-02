/**
 * Logger.kt
 * Mia21
 *
 * Created on November 25, 2025.
 * Copyright © 2025 Mia21. All rights reserved.
 *
 * Description:
 * Centralized logging utility for the Mia21 SDK.
 * Respects log levels and uses Android's Log class.
 */

package com.mia21.utils

import android.util.Log
import com.mia21.LogLevel

/**
 * Logger utility for Mia21 SDK
 */
internal object Logger {
    private const val TAG = "Mia21"
    private var currentLogLevel: LogLevel = LogLevel.INFO
    
    /**
     * Set the minimum log level
     */
    fun setLogLevel(level: LogLevel) {
        currentLogLevel = level
    }
    
    /**
     * Get the current log level
     */
    fun getLogLevel(): LogLevel = currentLogLevel
    
    /**
     * Log a debug message
     */
    fun debug(message: String) {
        if (shouldLog(LogLevel.DEBUG)) {
            Log.d(TAG, message)
        }
    }
    
    /**
     * Log an info message
     */
    fun info(message: String) {
        if (shouldLog(LogLevel.INFO)) {
            Log.i(TAG, message)
        }
    }
    
    /**
     * Log an error message
     */
    fun error(message: String, throwable: Throwable? = null) {
        if (shouldLog(LogLevel.ERROR)) {
            if (throwable != null) {
                Log.e(TAG, message, throwable)
            } else {
                Log.e(TAG, message)
            }
        }
    }
    
    /**
     * Check if we should log at the given level
     */
    private fun shouldLog(level: LogLevel): Boolean {
        if (currentLogLevel == LogLevel.NONE) {
            return false
        }
        
        return when (currentLogLevel) {
            LogLevel.DEBUG -> true // DEBUG logs everything
            LogLevel.INFO -> level == LogLevel.INFO || level == LogLevel.ERROR
            LogLevel.ERROR -> level == LogLevel.ERROR
            LogLevel.NONE -> false
        }
    }
}

