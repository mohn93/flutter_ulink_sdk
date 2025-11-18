package com.example.flutter_ulink_sdk.models

/**
 * Resolved link data class for ULink SDK
 * This bridges to the native Android ULink SDK
 */
data class ULinkResolvedData(
    val slug: String? = null,
    val iosUrl: String? = null,
    val androidUrl: String? = null,
    val iosFallbackUrl: String? = null,
    val androidFallbackUrl: String? = null,
    val fallbackUrl: String? = null,
    val parameters: Map<String, String>? = null,
    val socialMediaTags: SocialMediaTags? = null,
    val metadata: Map<String, String>? = null,
    val type: LinkType = LinkType.UNIFIED,
    val rawData: Map<String, Any>? = null
)

enum class LinkType {
    DYNAMIC,
    UNIFIED
}