package com.example.flutter_ulink_sdk.models

/**
 * Response class for ULink SDK
 * This is a stub implementation for the Flutter bridge
 */
data class ULinkResponse(
    val success: Boolean,
    val url: String? = null,
    val error: String? = null,
    val data: ULinkResolvedData? = null
)