package com.example.flutter_ulink_sdk.models

/**
 * Parameters class for ULink SDK
 * This bridges to the native Android ULink SDK
 */
data class ULinkParameters(
    val type: String = "unified",
    val domain: String,
    val slug: String? = null,
    val iosUrl: String? = null,
    val androidUrl: String? = null,
    val iosFallbackUrl: String? = null,
    val androidFallbackUrl: String? = null,
    val fallbackUrl: String? = null,
    val parameters: Map<String, String>? = null,
    val socialMediaTags: SocialMediaTags? = null,
    val metadata: Map<String, String>? = null
)

data class SocialMediaTags(
    val ogTitle: String? = null,
    val ogDescription: String? = null,
    val ogImage: String? = null
)