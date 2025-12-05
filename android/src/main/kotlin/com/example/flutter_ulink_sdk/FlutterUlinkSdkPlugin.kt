package com.example.flutter_ulink_sdk

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import kotlinx.coroutines.*
import kotlinx.coroutines.launch
import kotlinx.serialization.json.*
import ly.ulink.sdk.ULink
import ly.ulink.sdk.models.*

/** FlutterUlinkSdkPlugin */
class FlutterUlinkSdkPlugin: FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.NewIntentListener {
  private lateinit var channel: MethodChannel
  private lateinit var dynamicLinkEventChannel: EventChannel
  private lateinit var unifiedLinkEventChannel: EventChannel
  private lateinit var logEventChannel: EventChannel
  private var context: Context? = null
  private var ulink: ULink? = null
  private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())
  
  private var dynamicLinkStreamHandler: StreamHandler? = null
  private var unifiedLinkStreamHandler: StreamHandler? = null
  private var logStreamHandler: StreamHandler? = null
  private var activity: Activity? = null
  private var activityBinding: ActivityPluginBinding? = null
  private var pendingIntent: Intent? = null
  private var initialIntentProcessed = false
  private var lastProcessedIntent: String? = null
  private var lastProcessedTime: Long = 0
  private var enableDeepLinkIntegration: Boolean = true
  
  // Initialization waiting mechanism
  private var isInitialized = false
  private var initializationCompleted = false
  private val pendingMethodCalls = mutableListOf<PendingMethodCall>()
  
  private data class PendingMethodCall(
    val call: MethodCall,
    val result: Result,
    val methodName: String
  )

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    context = flutterPluginBinding.applicationContext
    
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_ulink_sdk")
    channel.setMethodCallHandler(this)
    
    // Set up event channels for streams
    dynamicLinkEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "flutter_ulink_sdk/dynamic_links")
    unifiedLinkEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "flutter_ulink_sdk/unified_links")
    logEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "flutter_ulink_sdk/logs")
    
    dynamicLinkStreamHandler = StreamHandler()
    unifiedLinkStreamHandler = StreamHandler()
    logStreamHandler = StreamHandler()
    
    dynamicLinkEventChannel.setStreamHandler(dynamicLinkStreamHandler)
    unifiedLinkEventChannel.setStreamHandler(unifiedLinkStreamHandler)
    logEventChannel.setStreamHandler(logStreamHandler)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "initialize" -> initialize(call, result)
      else -> handleMethodCallWithInitCheck(call, result, call.method)
    }
  }
  
  private fun processPendingMethodCalls() {
    val callsToProcess = pendingMethodCalls.toList()
    pendingMethodCalls.clear()
    
    // Only process pending calls if ulink is actually initialized
    if (ulink == null) {
      for (pendingCall in callsToProcess) {
        pendingCall.result.error("INITIALIZATION_ERROR", "ULink not initialized", null)
      }
      return
    }
    
    for (pendingCall in callsToProcess) {
      when (pendingCall.methodName) {
        "createLink" -> createLink(pendingCall.call, pendingCall.result)
        "resolveLink" -> resolveLink(pendingCall.call, pendingCall.result)
        "endSession" -> endSession(pendingCall.result)
        "getCurrentSessionId" -> getCurrentSessionId(pendingCall.result)
        "hasActiveSession" -> hasActiveSession(pendingCall.result)
        "getSessionState" -> getSessionState(pendingCall.result)
        "getInstallationId" -> getInstallationId(pendingCall.result)
        "getInitialDeepLink" -> getInitialDeepLink(pendingCall.result)
      }
    }
  }
  
  private fun requiresInitialization(methodName: String): Boolean {
    return when (methodName) {
      "createLink", "resolveLink", "endSession",
      "getCurrentSessionId", "hasActiveSession", "getSessionState", "getInstallationId",
      "getInitialDeepLink" -> true
      else -> false
    }
  }
  
  private fun handleMethodCallWithInitCheck(call: MethodCall, result: Result, methodName: String) {
    if (requiresInitialization(methodName)) {
      if (!isInitialized) {
        // Queue the method call if not initialized yet
        pendingMethodCalls.add(PendingMethodCall(call, result, methodName))
        return
      } else if (initializationCompleted && ulink == null) {
        // Initialization completed but ulink is still null - this is an error
        result.error("INITIALIZATION_ERROR", "ULink not initialized", null)
        return
      }
    }
    
    // Process the method call normally
    when (methodName) {
      "createLink" -> createLink(call, result)
      "resolveLink" -> resolveLink(call, result)
      "endSession" -> endSession(result)
      "setInitialUri" -> setInitialUri(call, result)
      "getInitialUri" -> getInitialUri(result)
      "getInitialDeepLink" -> getInitialDeepLink(result)
      "getLastLinkData" -> getLastLinkData(result)
      "getCurrentSessionId" -> getCurrentSessionId(result)
      "hasActiveSession" -> hasActiveSession(result)
      "getSessionState" -> getSessionState(result)
      "getInstallationId" -> getInstallationId(result)
      "checkDeferredLink" -> checkDeferredLink(result)
      "dispose" -> dispose(result)
      else -> result.notImplemented()
    }
  }
  
  private fun initialize(call: MethodCall, result: Result) {
    android.util.Log.d("ULinkBridge", "Initialize method called - ulink already exists: ${ulink != null}")
    
    try {
      val configMap = call.argument<Map<String, Any>>("config") ?: throw IllegalArgumentException("Config is required")
      val config = parseULinkConfig(configMap)
      enableDeepLinkIntegration = config.enableDeepLinkIntegration
      
      context?.let { ctx ->
        ulink = ULink.initialize(ctx, config)
        android.util.Log.d("ULinkBridge", "ULink initialized successfully, instance: ${ulink != null}")
        
        // Set up stream listeners to connect Android SDK events to Flutter
        setupStreamListeners()
        
        // Set initialization flags
        isInitialized = true
        initializationCompleted = true
        
        // Process any pending intent that was received before initialization
        if (pendingIntent != null && shouldHandleDeepLinks()) {
          android.util.Log.d("ULinkBridge", "Processing pending intent after initialization")
          handleIntent(pendingIntent!!)
          initialIntentProcessed = true
        } else if (!shouldHandleDeepLinks()) {
          android.util.Log.d("ULinkBridge", "Deep link integration disabled - dropping pending intent")
        }
        pendingIntent = null
        
        // Process any pending method calls
        processPendingMethodCalls()
        
        result.success(true)
      } ?: result.error("CONTEXT_ERROR", "Context not available", null)
    } catch (e: Exception) {
      android.util.Log.e("ULinkBridge", "Initialization failed", e)
      result.error("INITIALIZATION_ERROR", e.message, null)
    }
  }
  
  private fun setupStreamListeners() {
        android.util.Log.d("ULinkBridge", "Setting up stream listeners - ulink: ${ulink != null}")
        ulink?.let { ulinkInstance ->
            // Listen to dynamic link stream from Android SDK
            scope.launch {
                android.util.Log.d("ULinkBridge", "Starting dynamic link stream collection")
                ulinkInstance.dynamicLinkStream.collect { linkData ->
                    android.util.Log.d("ULinkBridge", "[STREAM] Dynamic link received from native SDK: ${linkData.slug}")
                    dynamicLinkStreamHandler?.sendEvent(linkDataToMap(linkData))
                }
            }
            
            // Listen to unified link stream from Android SDK
            scope.launch {
                android.util.Log.d("ULinkBridge", "Starting unified link stream collection")
                ulinkInstance.unifiedLinkStream.collect { linkData ->
                    android.util.Log.d("ULinkBridge", "[STREAM] Unified link received from native SDK: ${linkData.slug}")
                    unifiedLinkStreamHandler?.sendEvent(linkDataToMap(linkData))
                }
            }
            
            // Listen to log stream from Android SDK
            scope.launch {
                android.util.Log.d("ULinkBridge", "Starting log stream collection")
                ulinkInstance.logStream.collect { logEntry ->
                    logStreamHandler?.sendEvent(mapOf(
                        "level" to logEntry.level,
                        "tag" to logEntry.tag,
                        "message" to logEntry.message,
                        "timestamp" to logEntry.timestamp
                    ))
                }
            }
        }
    }
    
    private fun linkDataToMap(linkData: ly.ulink.sdk.models.ULinkResolvedData): Map<String, Any?> {
        return mapOf(
            "slug" to linkData.slug,
            "iosFallbackUrl" to linkData.iosFallbackUrl,
            "androidFallbackUrl" to linkData.androidFallbackUrl,
            "fallbackUrl" to linkData.fallbackUrl,
            "parameters" to linkData.parameters?.let { jsonElementToMap(it) },
            "socialMediaTags" to linkData.socialMediaTags?.let { socialMediaTagsToMap(it) },
            "metadata" to linkData.metadata?.let { jsonElementToMap(it) },
            "type" to linkData.type,
            "isDeferred" to linkData.isDeferred,
            "matchType" to linkData.matchType,
            "rawData" to linkData.rawData?.let { jsonObjectToMap(it) }
        )
    }
    
    private fun socialMediaTagsToMap(tags: ly.ulink.sdk.models.SocialMediaTags): Map<String, Any?> {
        return mapOf(
            "ogTitle" to tags.ogTitle,
            "ogDescription" to tags.ogDescription,
            "ogImage" to tags.ogImage
        )
    }
    
    private fun jsonElementToMap(jsonElement: JsonElement): Any? {
        return when (jsonElement) {
            is JsonPrimitive -> {
                when {
                    jsonElement.isString -> jsonElement.content
                    jsonElement.booleanOrNull != null -> jsonElement.boolean
                    jsonElement.intOrNull != null -> jsonElement.int
                    jsonElement.longOrNull != null -> jsonElement.long
                    jsonElement.doubleOrNull != null -> jsonElement.double
                    else -> jsonElement.content
                }
            }
            is JsonObject -> jsonObjectToMap(jsonElement)
            is JsonArray -> jsonElement.map { jsonElementToMap(it) }
            else -> null
        }
    }
  
  private fun createLink(call: MethodCall, result: Result) {
    scope.launch {
      try {
        val parametersMap = call.argument<Map<String, Any>>("parameters") ?: throw IllegalArgumentException("Parameters are required")
        val parameters = parseULinkParameters(parametersMap)
        
        val response = ulink?.createLink(parameters) ?: throw IllegalStateException("ULink not initialized")
        // Return full response structure for API parity with flutter_ulink_sdk
        result.success(responseToMap(response))
      } catch (e: Exception) {
        result.error("CREATE_LINK_ERROR", e.message, null)
      }
    }
  }
  
  private fun resolveLink(call: MethodCall, result: Result) {
    scope.launch {
      try {
        val url = call.argument<String>("url") ?: throw IllegalArgumentException("URL is required")
        
        val response = ulink?.resolveLink(url) ?: throw IllegalStateException("ULink not initialized")
        result.success(responseToMap(response))
      } catch (e: Exception) {
        result.error("RESOLVE_LINK_ERROR", e.message, null)
      }
    }
  }
  
  private fun endSession(result: Result) {
    scope.launch {
      try {
        val success = ulink?.endSession() ?: throw IllegalStateException("ULink not initialized")
        result.success(success)
      } catch (e: Exception) {
        result.error("END_SESSION_ERROR", e.message, null)
      }
    }
  }
  
  private fun handleDeepLink(call: MethodCall, result: Result) {
    try {
      val url = call.argument<String>("url") ?: throw IllegalArgumentException("URL is required")
      val uri = Uri.parse(url)
      
      ulink?.handleDeepLink(uri) ?: throw IllegalStateException("ULink not initialized")
      result.success(true)
    } catch (e: Exception) {
      result.error("HANDLE_DEEP_LINK_ERROR", e.message, null)
    }
  }
  
  private fun setInitialUri(call: MethodCall, result: Result) {
    try {
      val url = call.argument<String?>("url")
      val uri = url?.let { Uri.parse(it) }
      
      ulink?.setInitialUri(uri) ?: throw IllegalStateException("ULink not initialized")
      result.success(true)
    } catch (e: Exception) {
      result.error("SET_INITIAL_URI_ERROR", e.message, null)
    }
  }
  
  private fun getInitialUri(result: Result) {
    try {
      val uri = ulink?.getInitialUri() ?: throw IllegalStateException("ULink not initialized")
      result.success(uri?.toString())
    } catch (e: Exception) {
      result.error("GET_INITIAL_URI_ERROR", e.message, null)
    }
  }
  
  private fun getInitialDeepLink(result: Result) {
    val ulinkInstance = ulink
    if (ulinkInstance == null) {
      result.error("NOT_INITIALIZED", "ULink not initialized", null)
      return
    }
    
    scope.launch {
      try {
        val linkData = ulinkInstance.getInitialDeepLink()
        result.success(linkData?.let { linkDataToMap(it) })
      } catch (e: Exception) {
        result.error("GET_INITIAL_DEEP_LINK_ERROR", e.message, null)
      }
    }
  }
  
  private fun getLastLinkData(result: Result) {
    try {
      android.util.Log.d("ULinkBridge", "getLastLinkData called, ulink instance: ${ulink != null}")
      if (ulink == null) {
        android.util.Log.e("ULinkBridge", "ULink instance is null")
        result.error("GET_LAST_LINK_DATA_ERROR", "ULink not initialized", null)
        return
      }
      
      val linkData = ulink!!.getLastLinkData()
      android.util.Log.d("ULinkBridge", "Last link data retrieved: ${linkData != null}")
      result.success(linkData?.let { linkDataToMap(it) })
    } catch (e: Exception) {
      android.util.Log.e("ULinkBridge", "getLastLinkData failed", e)
      result.error("GET_LAST_LINK_DATA_ERROR", e.message, null)
    }
  }
  
  private fun getCurrentSessionId(result: Result) {
    try {
      val sessionId = ulink?.getCurrentSessionId() ?: throw IllegalStateException("ULink not initialized")
      result.success(sessionId)
    } catch (e: Exception) {
      result.error("GET_CURRENT_SESSION_ID_ERROR", e.message, null)
    }
  }
  
  private fun hasActiveSession(result: Result) {
    try {
      val hasActive = ulink?.hasActiveSession() ?: throw IllegalStateException("ULink not initialized")
      result.success(hasActive)
    } catch (e: Exception) {
      result.error("HAS_ACTIVE_SESSION_ERROR", e.message, null)
    }
  }
  
  private fun getSessionState(result: Result) {
    try {
      val state = ulink?.getSessionState() ?: throw IllegalStateException("ULink not initialized")
      result.success(state.name)
    } catch (e: Exception) {
      result.error("GET_SESSION_STATE_ERROR", e.message, null)
    }
  }
  
  private fun getInstallationId(result: Result) {
    try {
      val installationId = ulink?.getInstallationId() ?: throw IllegalStateException("ULink not initialized")
      result.success(installationId)
    } catch (e: Exception) {
      result.error("GET_INSTALLATION_ID_ERROR", e.message, null)
    }
  }

  private fun checkDeferredLink(result: Result) {
    try {
      ulink?.checkDeferredLink() ?: throw IllegalStateException("ULink not initialized")
      result.success(null)
    } catch (e: Exception) {
      result.error("CHECK_DEFERRED_LINK_ERROR", e.message, null)
    }
  }

  
  private fun dispose(result: Result) {
    try {
      ulink?.dispose()
      ulink = null
      
      // Reset initialization state
      isInitialized = false
      initializationCompleted = false
      
      // Clear pending method calls
      pendingMethodCalls.clear()
      
      scope.cancel()
      result.success(true)
    } catch (e: Exception) {
      result.error("DISPOSE_ERROR", e.message, null)
    }
  }
  
  // Helper methods for data conversion
  private fun parseULinkConfig(configMap: Map<String, Any>): ULinkConfig {
    // Parse lastLinkTimeToLive (comes as Duration milliseconds from Flutter)
    val lastLinkTTLSeconds: Long = if (configMap["lastLinkTimeToLive"] != null) {
      // Convert from milliseconds to seconds
      ((configMap["lastLinkTimeToLive"] as? Number)?.toLong() ?: 0) / 1000
    } else {
      24 * 60 * 60  // Default 24 hours
    }
    
    return ULinkConfig(
      apiKey = configMap["apiKey"] as String,
      baseUrl = configMap["baseUrl"] as? String ?: "https://api.ulink.ly",
      debug = configMap["debug"] as? Boolean ?: false,
      enableDeepLinkIntegration = configMap["enableDeepLinkIntegration"] as? Boolean ?: true,
      persistLastLinkData = configMap["persistLastLinkData"] as? Boolean ?: false,
      lastLinkTimeToLiveSeconds = lastLinkTTLSeconds,
      clearLastLinkOnRead = configMap["clearLastLinkOnRead"] as? Boolean ?: true,
      redactAllParametersInLastLink = configMap["redactAllParametersInLastLink"] as? Boolean ?: false,
      redactedParameterKeysInLastLink = (configMap["redactedParameterKeysInLastLink"] as? List<*>)
        ?.filterIsInstance<String>() ?: emptyList()
    )
  }
  
  private fun parseULinkParameters(parametersMap: Map<String, Any>): ULinkParameters {
    val socialMediaTagsMap = parametersMap["socialMediaTags"] as? Map<String, Any>
    val socialMediaTags = socialMediaTagsMap?.let {
      SocialMediaTags(
        ogTitle = when (val value = it["ogTitle"]) {
          is String -> value
          else -> value?.toString()
        },
        ogDescription = when (val value = it["ogDescription"]) {
          is String -> value
          else -> value?.toString()
        },
        ogImage = when (val value = it["ogImage"]) {
          is String -> value
          else -> value?.toString()
        }
      )
    }
    
    // Convert parameters map from Map<String, Any> to JsonElement
    val parametersAny = parametersMap["parameters"] as? Map<String, Any>
    val parametersConverted = parametersAny?.let { params ->
      buildJsonObject {
        params.forEach { (key, value) ->
          when (value) {
            is String -> put(key, value)
            is Number -> put(key, value.toString())
            is Boolean -> put(key, value)
            else -> put(key, value.toString())
          }
        }
      }
    }
    
    // Convert metadata map from Map<String, Any> to JsonElement
    val metadataAny = parametersMap["metadata"] as? Map<String, Any>
    val metadataConverted = metadataAny?.let { meta ->
      buildJsonObject {
        meta.forEach { (key, value) ->
          when (value) {
            is String -> put(key, value)
            is Number -> put(key, value.toString())
            is Boolean -> put(key, value)
            else -> put(key, value.toString())
          }
        }
      }
    }
    
    return ULinkParameters(
      type = parametersMap["type"] as? String ?: "unified",
      domain = parametersMap["domain"] as? String ?: throw IllegalArgumentException("Domain is required"),
      slug = parametersMap["slug"] as? String,
      iosUrl = parametersMap["iosUrl"] as? String,
      androidUrl = parametersMap["androidUrl"] as? String,
      iosFallbackUrl = parametersMap["iosFallbackUrl"] as? String,
      androidFallbackUrl = parametersMap["androidFallbackUrl"] as? String,
      fallbackUrl = parametersMap["fallbackUrl"] as? String,
      parameters = parametersConverted,
      socialMediaTags = socialMediaTags,
      metadata = metadataConverted
    )
  }
  
  private fun responseToMap(response: ly.ulink.sdk.models.ULinkResponse): Map<String, Any?> {
    return mapOf(
      "success" to response.success,
      "url" to response.url,
      "error" to response.error,
      "data" to response.data?.let { jsonObjectToMap(it) }
    )
  }
  
  private fun jsonObjectToMap(jsonObject: JsonObject): Map<String, Any?> {
    val map = mutableMapOf<String, Any?>()
    for ((key, value) in jsonObject) {
      map[key] = when (value) {
        is JsonPrimitive -> {
          when {
            value.isString -> value.content
            value.booleanOrNull != null -> value.boolean
            value.intOrNull != null -> value.int
            value.longOrNull != null -> value.long
            value.doubleOrNull != null -> value.double
            else -> value.content
          }
        }
        is JsonObject -> jsonObjectToMap(value)
        is JsonArray -> value.map { element ->
          when (element) {
            is JsonPrimitive -> {
              when {
                element.isString -> element.content
                element.booleanOrNull != null -> element.boolean
                element.intOrNull != null -> element.int
                element.longOrNull != null -> element.long
                element.doubleOrNull != null -> element.double
                else -> element.content
              }
            }
            is JsonObject -> jsonObjectToMap(element)
            else -> null
          }
        }
        else -> null
      }
    }
    return map
  }
  
  private fun sessionResponseToMap(response: ULinkSessionResponse): Map<String, Any?> {
    return mapOf(
      "success" to response.success,
      "sessionId" to response.sessionId,
      "error" to response.error
    )
  }
  


  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    dynamicLinkEventChannel.setStreamHandler(null)
    unifiedLinkEventChannel.setStreamHandler(null)
    scope.cancel()
  }
  
  private fun shouldHandleDeepLinks(): Boolean = enableDeepLinkIntegration

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activityBinding = binding
    activity = binding.activity
    binding.addOnNewIntentListener(this)
    
    if (!shouldHandleDeepLinks()) {
      android.util.Log.d("ULinkBridge", "Deep link integration disabled - skipping automatic intent capture")
      return
    }
    
    // Store initial intent if app was opened with a deep link
    // It will be processed after SDK initialization
    activity?.intent?.let { intent ->
      if (!initialIntentProcessed && intent.data != null) {
        if (ulink == null) {
          android.util.Log.d("ULinkBridge", "Storing initial intent for later processing")
          pendingIntent = intent
        } else {
          android.util.Log.d("ULinkBridge", "Processing initial intent immediately")
          handleIntent(intent)
          initialIntentProcessed = true
        }
      }
    }
  }
  
  override fun onDetachedFromActivityForConfigChanges() {
    activityBinding?.removeOnNewIntentListener(this)
  }
  
  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activityBinding = binding
    activity = binding.activity
    binding.addOnNewIntentListener(this)
  }
  
  override fun onDetachedFromActivity() {
    activityBinding?.removeOnNewIntentListener(this)
    activityBinding = null
    activity = null
  }
  
  override fun onNewIntent(intent: Intent): Boolean {
    if (!shouldHandleDeepLinks()) {
      android.util.Log.d("ULinkBridge", "Deep link integration disabled - ignoring intent: ${intent.data}")
      return false
    }
    handleIntent(intent)
    return true
  }
  
  private fun handleIntent(intent: Intent) {
    if (!shouldHandleDeepLinks()) {
      android.util.Log.d("ULinkBridge", "Deep link integration disabled - handleIntent skipped for ${intent.data}")
      return
    }
    val data = intent.data
    if (data != null && ulink != null) {
      val uriString = data.toString()
      val currentTime = System.currentTimeMillis()
      
      // Check if this is the same intent processed within the last 2 seconds
      // This prevents duplicate processing during app lifecycle events
      // but allows the same link to be processed again after a reasonable delay
      if (lastProcessedIntent == uriString && (currentTime - lastProcessedTime) < 2000) {
        android.util.Log.d("ULinkBridge", "Skipping recently processed intent: $uriString (${currentTime - lastProcessedTime}ms ago)")
        return
      }
      
      scope.launch {
        try {
          android.util.Log.d("ULinkBridge", "Handling intent with URI: $data (initialIntentProcessed: $initialIntentProcessed)")
          // handleDeepLink returns Unit, so we don't assign its result
          ulink!!.handleDeepLink(data)
          android.util.Log.d("ULinkBridge", "Intent handled, native SDK streams will emit events automatically")
          
          // Track this intent and time to prevent immediate re-processing
          lastProcessedIntent = uriString
          lastProcessedTime = currentTime
          
          // Note: Removed manual event sending here as the native SDK streams 
          // in setupStreamListeners() will automatically emit events when 
          // handleDeepLink() processes the link
        } catch (e: Exception) {
          android.util.Log.e("ULinkBridge", "Error handling intent: ${e.message}")
        }
      }
    } else {
      android.util.Log.d("ULinkBridge", "Skipping intent handling - data: $data, ulink: ${ulink != null}")
    }
  }
  
  // Stream handler for event channels
  private class StreamHandler : EventChannel.StreamHandler {
    private var eventSink: EventChannel.EventSink? = null
    
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
      android.util.Log.d("ULinkBridge", "Flutter started listening to event stream")
      eventSink = events
    }
    
    override fun onCancel(arguments: Any?) {
      android.util.Log.d("ULinkBridge", "Flutter stopped listening to event stream")
      eventSink = null
    }
    
    fun sendEvent(event: Any) {
      android.util.Log.d("ULinkBridge", "Dynamic link event received")
      if (eventSink != null) {
        android.util.Log.d("ULinkBridge", "Sending event to Flutter: $event")
        eventSink?.success(event)
      } else {
        android.util.Log.w("ULinkBridge", "EventSink is null, cannot send event")
      }
    }
  }
}
