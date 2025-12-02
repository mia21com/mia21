package com.mia21.example.utils

/**
 * EnvironmentPreferences.kt
 * Utility for managing API environment selection (Production/Staging).
 * Persists environment choice in SharedPreferences and provides
 * conversion to Mia21Environment enum.
 */

import android.content.Context
import com.mia21.models.Mia21Environment

sealed class EnvironmentType {
    abstract val baseURL: String

    data class Production(override val baseURL: String = "https://api.mia21.com") :
        EnvironmentType()

    data class Staging(override val baseURL: String = "https://api-staging.mia21.com") :
        EnvironmentType()

    fun toMia21Environment(): Mia21Environment {
        return when (this) {
            is Production -> Mia21Environment.PRODUCTION
            is Staging -> Mia21Environment.STAGING
        }
    }
}

object EnvironmentPreferences {
    private const val PREFS_NAME = "mia_prefs"
    private const val KEY_ENVIRONMENT = "mia_environment"

    fun getEnvironment(context: Context): EnvironmentType {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val envName = prefs.getString(KEY_ENVIRONMENT, "PRODUCTION")

        return when (envName) {
            "STAGING" -> EnvironmentType.Staging()
            else -> EnvironmentType.Production()
        }
    }

    fun setEnvironment(context: Context, environment: EnvironmentType) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().apply {
            when (environment) {
                is EnvironmentType.Production -> {
                    putString(KEY_ENVIRONMENT, "PRODUCTION")
                }

                is EnvironmentType.Staging -> {
                    putString(KEY_ENVIRONMENT, "STAGING")
                }
            }
            commit()
        }
    }
}

