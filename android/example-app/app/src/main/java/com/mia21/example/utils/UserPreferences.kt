package com.mia21.example.utils

/**
 * UserPreferences.kt
 * Utility for managing user ID persistence.
 * Generates or retrieves a persistent user ID from SharedPreferences,
 * using Android ID or UUID as fallback.
 */

import android.content.Context
import android.provider.Settings
import android.util.Log
import androidx.core.content.edit
import java.util.UUID

object UserPreferences {
    private const val PREFS_NAME = "mia_prefs"
    private const val KEY_USER_ID = "mia_user_id"

    fun getOrCreateUserId(context: Context): String {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val savedUserId = prefs.getString(KEY_USER_ID, null)

        return if (savedUserId != null) {
            Log.d("UserPreferences", "📱 Using saved user ID: $savedUserId")
            savedUserId
        } else {
            val androidId = Settings.Secure.getString(context.contentResolver, Settings.Secure.ANDROID_ID)
            val newUserId = androidId?.takeIf { it.isNotEmpty() } ?: UUID.randomUUID().toString()

            prefs.edit { putString(KEY_USER_ID, newUserId) }
            Log.d("UserPreferences", "📱 Created new user ID: $newUserId")
            newUserId
        }
    }
}