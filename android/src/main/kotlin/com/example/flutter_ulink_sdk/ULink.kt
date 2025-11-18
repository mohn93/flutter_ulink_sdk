package com.example.flutter_ulink_sdk

import android.content.ContentValues.TAG
import android.content.Context
import android.net.Uri
import android.util.Log
import com.example.flutter_ulink_sdk.models.*
import ly.ulink.sdk.ULink as NativeULink
import ly.ulink.sdk.models.ULinkConfig as NativeULinkConfig
import ly.ulink.sdk.models.ULinkParameters as NativeULinkParameters
import ly.ulink.sdk.models.ULinkResolvedData as NativeULinkResolvedData
import ly.ulink.sdk.models.SessionState as NativeSessionState
import ly.ulink.sdk.models.ULinkType as NativeULinkType
import ly.ulink.sdk.models.SocialMediaTags as NativeSocialMediaTags
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

/**
 * Flutter bridge implementation of ULink SDK that delegates to the native Android SDK
 */
class ULink private constructor(private val context: Context, private val config: ULinkConfig) {
    
    companion object {
        @Volatile
        private var INSTANCE: ULink? = null
        
        fun initialize(context: Context, config: ULinkConfig): ULink {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: run {
                    // Initialize native SDK
                    val nativeConfig = NativeULinkConfig(
                        apiKey = config.apiKey,
                        baseUrl = config.baseUrl,
                        debug = config.debug,
                        enableDeepLinkIntegration = config.enableDeepLinkIntegration
                        // Note: redact fields not available in bridge SDK config
                    )
                    NativeULink.initialize(context, nativeConfig)
                    ULink(context, config).also { INSTANCE = it }
                }
            }
        }
        
        fun getInstance(): ULink? = INSTANCE
    }
    
    private fun getNativeInstance(): NativeULink {
        return try {
            android.util.Log.d("ULinkBridge", "Attempting to get native ULink instance")
            val instance = NativeULink.getInstance()
            android.util.Log.d("ULinkBridge", "Successfully got native ULink instance: ${instance != null}")
            instance
        } catch (e: Exception) {
            android.util.Log.e("ULinkBridge", "Failed to get native ULink instance", e)
            throw IllegalStateException("ULink not initialized. Call initialize() first. Original error: ${e.message}")
        }
    }
    
    suspend fun createLink(parameters: ULinkParameters): ULinkResponse {
        val nativeParams = NativeULinkParameters(
            type = convertLinkType(parameters.type),
            slug = parameters.slug,
            iosUrl = parameters.iosUrl,
            androidUrl = parameters.androidUrl,
            iosFallbackUrl = parameters.iosFallbackUrl,
            androidFallbackUrl = parameters.androidFallbackUrl,
            fallbackUrl = parameters.fallbackUrl,
            parameters = parameters.parameters?.let { mapToJsonElement(it) },
            socialMediaTags = convertSocialMediaTags(parameters.socialMediaTags),
            metadata = parameters.metadata?.let { mapToJsonElement(it) },
            domain = parameters.domain
        )
        
        val nativeResponse = getNativeInstance().createLink(nativeParams)
        
        val response = ULinkResponse(
            success = nativeResponse.success,
            url = nativeResponse.url,
            error = nativeResponse.error,
            data = nativeResponse.data?.let { convertJsonObjectToResolvedData(it) }
        )
        
        // Throw exception if the operation failed
        if (!response.success) {
            throw IllegalStateException(response.error ?: "Failed to create link")
        }
        
        return response
    }
    
    suspend fun resolveLink(url: String): ULinkResponse {
        val nativeResponse = getNativeInstance().resolveLink(url)
        
        val response = ULinkResponse(
            success = nativeResponse.success,
            url = nativeResponse.url,
            error = nativeResponse.error,
            data = nativeResponse.data?.let { convertJsonObjectToResolvedData(it) }
        )
        
        // Throw exception if the operation failed
        if (!response.success) {
            throw IllegalStateException(response.error ?: "Failed to resolve link")
        }
        
        return response
    }
    
    suspend fun endSession(): Boolean {
        return getNativeInstance().endSession()
    }
    
    fun handleDeepLink(uri: Uri) {
        try {
            getNativeInstance().handleDeepLink(uri)
        } catch (e: Exception) {
            // Handle silently
        }
    }
    
    fun setInitialUri(uri: Uri?) {
        getNativeInstance().setInitialUri(uri)
    }
    
    fun getInitialUri(): Uri? {
        return getNativeInstance().getInitialUri()
    }
    
    suspend fun getInitialDeepLink(): ULinkResolvedData? {
        val result = getNativeInstance().getInitialDeepLink()
        return result?.let { convertNativeResolvedData(it) }
    }
    
    fun getCurrentSessionId(): String? {
        return getNativeInstance().getCurrentSessionId()
    }
    
    fun hasActiveSession(): Boolean {
        return getNativeInstance().hasActiveSession()
    }
    
    fun getSessionState(): SessionState {
        return convertNativeSessionState(getNativeInstance().getSessionState())
    }
    
    fun getLastLinkData(): ULinkResolvedData? {
        val result = getNativeInstance().getLastLinkData()
        return result?.let { convertNativeResolvedData(it) }
    }
    
    fun getInstallationId(): String? {
        return getNativeInstance().getInstallationId()
    }
    
    fun dispose() {
        try {
            getNativeInstance().dispose()
        } catch (e: Exception) {
            // Handle silently
        } finally {
            INSTANCE = null
        }
    }
    
    private fun convertNativeResolvedData(nativeData: NativeULinkResolvedData): ULinkResolvedData {
        return ULinkResolvedData(
            slug = nativeData.slug,
            iosUrl = null, // Not available in native SDK
            androidUrl = null, // Not available in native SDK
            iosFallbackUrl = nativeData.iosFallbackUrl,
            androidFallbackUrl = nativeData.androidFallbackUrl,
            fallbackUrl = nativeData.fallbackUrl,
            parameters = jsonElementToMap(nativeData.parameters),
            socialMediaTags = convertNativeSocialMediaTags(nativeData.socialMediaTags),
            metadata = jsonElementToMap(nativeData.metadata),
            type = convertNativeLinkType(nativeData.type),
            rawData = nativeData.rawData
        )
    }
    
    private fun convertNativeLinkType(nativeType: String?): LinkType {
        return when (nativeType) {
            "dynamic" -> LinkType.DYNAMIC
            "unified" -> LinkType.UNIFIED
            else -> LinkType.UNIFIED
        }
    }
    
    private fun convertNativeSessionState(nativeState: NativeSessionState): SessionState {
        return when (nativeState) {
            NativeSessionState.IDLE -> SessionState.INACTIVE
            NativeSessionState.INITIALIZING -> SessionState.STARTING
            NativeSessionState.ACTIVE -> SessionState.ACTIVE
            NativeSessionState.ENDING -> SessionState.ENDING
            NativeSessionState.FAILED -> SessionState.ERROR
        }
    }
    
    private fun mapToJsonElement(map: Map<String, String>) = buildJsonObject {
        map.forEach { (key, value) ->
            put(key, value)
        }
    }
    
    private fun convertLinkType(type: String): String {
        return when (type.lowercase()) {
            "dynamic" -> "dynamic"
            "unified" -> "unified"
            else -> "unified"
        }
    }
    
    private fun convertSocialMediaTags(tags: SocialMediaTags?): NativeSocialMediaTags? {
        return tags?.let {
            NativeSocialMediaTags(
                ogTitle = it.ogTitle,
                ogDescription = it.ogDescription,
                ogImage = it.ogImage
            )
        }
    }
    
    private fun convertNativeSocialMediaTags(nativeTags: NativeSocialMediaTags?): SocialMediaTags? {
        return nativeTags?.let {
            SocialMediaTags(
                ogTitle = it.ogTitle,
                ogDescription = it.ogDescription,
                ogImage = it.ogImage
            )
        }
    }
    
    private fun jsonElementToMap(jsonElement: kotlinx.serialization.json.JsonElement?): Map<String, String>? {
        return jsonElement?.let { element ->
            if (element is JsonObject) {
                element.mapValues { (_, value) ->
                    when (value) {
                        is JsonPrimitive -> value.content
                        else -> value.toString()
                    }
                }
            } else {
                null
            }
        }
    }

    private fun convertJsonObjectToResolvedData(jsonObject: JsonObject?): ULinkResolvedData? {
        return jsonObject?.let { json ->
            val typeString = json["type"]?.toString()?.removeSurrounding("\"") ?: "dynamic"
            val linkType = when (typeString.lowercase()) {
                "unified" -> LinkType.UNIFIED
                else -> LinkType.DYNAMIC
            }
            
            ULinkResolvedData(
                type = linkType,
                slug = json["slug"]?.toString()?.removeSurrounding("\""),
                iosUrl = json["iosUrl"]?.toString()?.removeSurrounding("\""),
                androidUrl = json["androidUrl"]?.toString()?.removeSurrounding("\""),
                fallbackUrl = json["fallbackUrl"]?.toString()?.removeSurrounding("\""),
                iosFallbackUrl = json["iosFallbackUrl"]?.toString()?.removeSurrounding("\""),
                androidFallbackUrl = json["androidFallbackUrl"]?.toString()?.removeSurrounding("\""),
                parameters = jsonElementToMap(json["parameters"]),
                metadata = jsonElementToMap(json["metadata"]),
                rawData = jsonObjectToMap(json)
            )
        }
     }

    private fun jsonObjectToMap(jsonObject: JsonObject): Map<String, Any> {
        return jsonObject.mapValues { (_, value) ->
            when (value) {
                is JsonPrimitive -> {
                    when {
                        value.isString -> value.content
                        else -> value.content
                    }
                }
                is JsonObject -> jsonObjectToMap(value)
                else -> value.toString()
            }
        }
    }
}