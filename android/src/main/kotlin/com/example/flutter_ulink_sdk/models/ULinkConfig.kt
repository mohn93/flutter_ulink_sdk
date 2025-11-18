package com.example.flutter_ulink_sdk.models

/**
 * Configuration class for ULink SDK
 * This bridges to the native Android ULink SDK
 */
data class ULinkConfig(
    val apiKey: String,
    val baseUrl: String = "https://api.ulink.io",
    val debug: Boolean = false,
    val enableDeepLinkIntegration: Boolean = true,
    val enableAnalytics: Boolean = true,
    val enableCrashReporting: Boolean = true,
    val timeout: Long = 30000L,
    val retryCount: Int = 3,
    val metadata: Map<String, String>? = null
)