import Flutter
import UIKit
import ULinkSDK
import Combine

// MARK: - AppDelegate Swizzling Manager
class ULinkAppDelegateSwizzler: NSObject {
    static let shared = ULinkAppDelegateSwizzler()
    private var isSwizzled = false
    private var plugin: FlutterUlinkSdkPlugin?
    
    private override init() {
        super.init()
    }
    
    func setupSwizzling(for plugin: FlutterUlinkSdkPlugin) {
        guard !isSwizzled else { return }
        self.plugin = plugin
        
        swizzleAppDelegateMethods()
        isSwizzled = true
    }
    
    func cleanup() {
        self.plugin = nil
    }
    
    private func swizzleAppDelegateMethods() {
        guard let appDelegate = UIApplication.shared.delegate else {
            print("[ULink] Warning: No app delegate found for swizzling")
            return
        }
        
        let appDelegateClass = type(of: appDelegate)
        
        // Swizzle universal link handling
        swizzleUniversalLinkMethod(in: appDelegateClass)
        
        // Swizzle URL scheme handling
        swizzleURLSchemeMethod(in: appDelegateClass)
    }
    
    private func swizzleUniversalLinkMethod(in appDelegateClass: AnyClass) {
        let originalSelector = #selector(UIApplicationDelegate.application(_:continue:restorationHandler:))
        let swizzledSelector = #selector(ULinkAppDelegateSwizzler.swizzled_application(_:continue:restorationHandler:))
        
        // Get the swizzled method from the class (static method)
        guard let swizzledMethod = class_getClassMethod(ULinkAppDelegateSwizzler.self, swizzledSelector) else {
            print("[ULink] Warning: Could not find swizzled method for universal link swizzling")
            return
        }
        
        // Check if original method exists, if not we'll add our method
        let originalMethod = class_getInstanceMethod(appDelegateClass, originalSelector)
        
        if let originalMethod = originalMethod {
            // Original method exists, exchange implementations
            method_exchangeImplementations(originalMethod, swizzledMethod)
        } else {
            // Original method doesn't exist, add our implementation
            class_addMethod(appDelegateClass,
                          originalSelector,
                          method_getImplementation(swizzledMethod),
                          method_getTypeEncoding(swizzledMethod))
        }
        
        print("[ULink] Universal link method swizzling completed")
    }
    
    private func swizzleURLSchemeMethod(in appDelegateClass: AnyClass) {
        let originalSelector = #selector(UIApplicationDelegate.application(_:open:options:))
        let swizzledSelector = #selector(ULinkAppDelegateSwizzler.swizzled_application(_:open:options:))
        
        // Get the swizzled method from the class (static method)
        guard let swizzledMethod = class_getClassMethod(ULinkAppDelegateSwizzler.self, swizzledSelector) else {
            print("[ULink] Warning: Could not find swizzled method for URL scheme swizzling")
            return
        }
        
        // Check if original method exists, if not we'll add our method
        let originalMethod = class_getInstanceMethod(appDelegateClass, originalSelector)
        
        if let originalMethod = originalMethod {
            // Original method exists, exchange implementations
            method_exchangeImplementations(originalMethod, swizzledMethod)
        } else {
            // Original method doesn't exist, add our implementation
            class_addMethod(appDelegateClass,
                          originalSelector,
                          method_getImplementation(swizzledMethod),
                          method_getTypeEncoding(swizzledMethod))
        }
        
        print("[ULink] URL scheme method swizzling completed")
    }
    
    @objc private static func swizzled_application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        var handled = false
        
        // Handle ULink universal links
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
           let url = userActivity.webpageURL {
            if let plugin = ULinkAppDelegateSwizzler.shared.plugin {
                plugin.handleUniversalLink(url)
                handled = true
            } else {
                print("[ULink] Warning: Plugin not initialized yet, cannot handle universal link: \(url)")
            }
        }
        
        // Call original implementation if it exists
//        if let appDelegate = UIApplication.shared.delegate,
//           appDelegate.responds(to: #selector(UIApplicationDelegate.application(_:continue:restorationHandler:))) {
//            let originalSelector = #selector(ULinkAppDelegateSwizzler.swizzled_application(_:continue:restorationHandler:))
//            if let originalMethod = class_getInstanceMethod(type(of: appDelegate), originalSelector) {
//                typealias OriginalMethodType = @convention(c) (AnyObject, Selector, UIApplication, NSUserActivity, @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool
//                let originalImplementation = method_getImplementation(originalMethod)
//                let originalFunction = unsafeBitCast(originalImplementation, to: OriginalMethodType.self)
//                let originalResult = originalFunction(appDelegate, originalSelector, application, userActivity, restorationHandler)
//                return handled || originalResult
//            }
//        }
        
        restorationHandler(nil)
        return handled
    }
    
    @objc private static func swizzled_application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        var handled = false
        
        // Handle ULink URL schemes
        if let plugin = ULinkAppDelegateSwizzler.shared.plugin {
            plugin.handleURLScheme(url)
            handled = true
        } else {
            print("[ULink] Warning: Plugin not initialized yet, cannot handle URL scheme: \(url)")
        }
        
//        // Call original implementation if it exists
//        if let appDelegate = UIApplication.shared.delegate,
//           appDelegate.responds(to: #selector(UIApplicationDelegate.application(_:open:options:))) {
//            let originalSelector = #selector(ULinkAppDelegateSwizzler.swizzled_application(_:open:options:))
//            if let originalMethod = class_getInstanceMethod(type(of: appDelegate), originalSelector) {
//                typealias OriginalMethodType = @convention(c) (AnyObject, Selector, UIApplication, URL, [UIApplication.OpenURLOptionsKey: Any]) -> Bool
//                let originalImplementation = method_getImplementation(originalMethod)
//                let originalFunction = unsafeBitCast(originalImplementation, to: OriginalMethodType.self)
//                let originalResult = originalFunction(appDelegate, originalSelector, app, url, options)
//                return handled || originalResult
//            }
//        }
        
        return handled
    }
}

public class FlutterUlinkSdkPlugin: NSObject, FlutterPlugin {
    private struct PendingDeepLink {
        let url: URL
        let forceProcessing: Bool
    }
    private var methodChannel: FlutterMethodChannel?
    private var dynamicLinkEventChannel: FlutterEventChannel?
    private var unifiedLinkEventChannel: FlutterEventChannel?
    private var logEventChannel: FlutterEventChannel?
    private var reinstallEventChannel: FlutterEventChannel?
    private var dynamicLinkStreamHandler: StreamHandler?
    private var unifiedLinkStreamHandler: StreamHandler?
    private var logStreamHandler: StreamHandler?
    private var reinstallStreamHandler: StreamHandler?
    private var ulink: ULink?
    private var cancellables = Set<AnyCancellable>()
    private var enableAutomaticAppDelegateIntegration = true
    private var enableDeepLinkIntegration = true
    
    // Initialization waiting mechanism
    private var isInitialized = false
    private var pendingDeepLinks: [PendingDeepLink] = []
    private var initializationCompleted = false
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_ulink_sdk", binaryMessenger: registrar.messenger())
        let instance = FlutterUlinkSdkPlugin()
        instance.methodChannel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
        
        // Set up event channels for streams
        let dynamicLinkEventChannel = FlutterEventChannel(name: "flutter_ulink_sdk/dynamic_links", binaryMessenger: registrar.messenger())
        let unifiedLinkEventChannel = FlutterEventChannel(name: "flutter_ulink_sdk/unified_links", binaryMessenger: registrar.messenger())
        let logEventChannel = FlutterEventChannel(name: "flutter_ulink_sdk/logs", binaryMessenger: registrar.messenger())
        let reinstallEventChannel = FlutterEventChannel(name: "flutter_ulink_sdk/reinstall_detected", binaryMessenger: registrar.messenger())
        
        instance.dynamicLinkEventChannel = dynamicLinkEventChannel
        instance.unifiedLinkEventChannel = unifiedLinkEventChannel
        instance.logEventChannel = logEventChannel
        instance.reinstallEventChannel = reinstallEventChannel
        
        instance.dynamicLinkStreamHandler = StreamHandler()
        instance.unifiedLinkStreamHandler = StreamHandler()
        instance.logStreamHandler = StreamHandler()
        instance.reinstallStreamHandler = StreamHandler()
        
        dynamicLinkEventChannel.setStreamHandler(instance.dynamicLinkStreamHandler)
        unifiedLinkEventChannel.setStreamHandler(instance.unifiedLinkStreamHandler)
        logEventChannel.setStreamHandler(instance.logStreamHandler)
        reinstallEventChannel.setStreamHandler(instance.reinstallStreamHandler)
        
        // Set up automatic AppDelegate integration early to avoid race conditions
        if instance.enableAutomaticAppDelegateIntegration {
            ULinkAppDelegateSwizzler.shared.setupSwizzling(for: instance)
            print("[ULink] Automatic AppDelegate integration enabled during registration")
        }
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            initialize(call: call, result: result)
        case "createLink":
            createLink(call: call, result: result)
        case "resolveLink":
            resolveLink(call: call, result: result)
        case "endSession":
            endSession(result: result)
        case "setInitialUri":
            setInitialUri(call: call, result: result)
        case "getInitialUri":
            getInitialUri(result: result)
        case "getInitialDeepLink":
            getInitialDeepLink(result: result)
        case "getLastLinkData":
            getLastLinkData(result: result)
        case "getCurrentSessionId":
            getCurrentSessionId(result: result)
        case "hasActiveSession":
            hasActiveSession(result: result)
        case "getSessionState":
            getSessionState(result: result)
        case "getInstallationId":
            getInstallationId(result: result)
        case "getInstallationInfo":
            getInstallationInfo(result: result)
        case "isReinstall":
            isReinstall(result: result)
        case "checkDeferredLink":
            checkDeferredLink(result: result)
        case "dispose":
            dispose(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func initialize(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let configMap = args["config"] as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Config is required", details: nil))
            return
        }
        
        do {
            let config = try parseULinkConfig(from: configMap)
            
            Task {
                do {
                    self.ulink = try await ULink.initialize(config: config)
                    
                    // Set up enhanced stream listeners with error handling
                    self.ulink?.dynamicLinkStream
                        .sink { [weak self] linkData in
                            self?.handleStreamLinkData(linkData, streamHandler: self?.dynamicLinkStreamHandler, streamType: "dynamic")
                        }
                        .store(in: &self.cancellables)
                    
                    self.ulink?.unifiedLinkStream
                        .sink { [weak self] linkData in
                            self?.handleStreamLinkData(linkData, streamHandler: self?.unifiedLinkStreamHandler, streamType: "unified")
                        }
                        .store(in: &self.cancellables)
                    
                    // Listen to log stream
                    self.ulink?.logStream
                        .sink { [weak self] logEntry in
                            self?.logStreamHandler?.sendEvent([
                                "level": logEntry.level,
                                "tag": logEntry.tag,
                                "message": logEntry.message,
                                "timestamp": logEntry.timestamp
                            ])
                        }
                        .store(in: &self.cancellables)
                    
                    // Listen to reinstall detection stream
                    self.ulink?.onReinstallDetected
                        .sink { [weak self] installationInfo in
                            print("[ULink] Reinstall detected: previousInstallationId=\(installationInfo.previousInstallationId ?? "nil")")
                            self?.reinstallStreamHandler?.sendEvent([
                                "installationId": installationInfo.installationId,
                                "isReinstall": installationInfo.isReinstall,
                                "previousInstallationId": installationInfo.previousInstallationId as Any,
                                "reinstallDetectedAt": installationInfo.reinstallDetectedAt as Any,
                                "persistentDeviceId": installationInfo.persistentDeviceId as Any
                            ])
                        }
                        .store(in: &self.cancellables)
                    
                    // AppDelegate integration is already set up during registration
                    
                    // Mark as initialized and process pending deep links
                    self.isInitialized = true
                    self.initializationCompleted = true
                    
                    // Process any pending deep links that were received before initialization
                    let pendingLinks = self.pendingDeepLinks
                    self.pendingDeepLinks.removeAll()
                    
                    for pending in pendingLinks {
                        let pendingUrl = pending.url
                        print("[ULink] Processing pending deep link after initialization: \(pendingUrl)")
                        self.processDeepLinkWithErrorHandling(pendingUrl, forceProcessing: pending.forceProcessing)
                    }
                    
                    DispatchQueue.main.async {
                        result(true)
                    }
                } catch {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "INITIALIZATION_ERROR", message: error.localizedDescription, details: nil))
                    }
                }
            }
        } catch {
            result(FlutterError(code: "PARSE_CONFIG_ERROR", message: error.localizedDescription, details: nil))
        }
    }
    
    private func createLink(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let parametersMap = args["parameters"] as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Parameters are required", details: nil))
            return
        }
        
        guard let ulink = ulink else {
            result(FlutterError(code: "NOT_INITIALIZED", message: "ULink not initialized", details: nil))
            return
        }
        
        do {
            let parameters = try parseULinkParameters(from: parametersMap)
            
            Task {
                do {
                    let response = try await ulink.createLink(parameters: parameters)
                    DispatchQueue.main.async {
                        // Check if response indicates success
                        if response.success {
                            // Return full response structure for API parity with flutter_ulink_sdk
                            result(self.responseToMap(response))
                        } else {
                            // Build detailed error message from response data
                            let baseMessage = response.error ?? "Error creating link"
                            let detailedMessage = self.buildDetailedErrorMessage(baseMessage: baseMessage, responseData: response.data)
                            result(FlutterError(code: "CREATE_LINK_ERROR", message: detailedMessage, details: response.data))
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        result(self.mapULinkErrorToFlutter(error))
                    }
                }
            }
        } catch {
            result(FlutterError(code: "PARSE_ERROR", message: error.localizedDescription, details: nil))
        }
    }
    
    private func resolveLink(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let url = args["url"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "URL is required", details: nil))
            return
        }
        
        guard let ulink = ulink else {
            result(FlutterError(code: "NOT_INITIALIZED", message: "ULink not initialized", details: nil))
            return
        }
        
        Task {
            do {
                let response = try await ulink.resolveLink(url: url)
                DispatchQueue.main.async {
                    // Check if response indicates success
                    if response.success {
                        result(self.responseToMap(response))
                    } else {
                        // Build detailed error message from response data
                        let baseMessage = response.error ?? "Error resolving link"
                        let detailedMessage = self.buildDetailedErrorMessage(baseMessage: baseMessage, responseData: response.data)
                        result(FlutterError(code: "RESOLVE_LINK_ERROR", message: detailedMessage, details: response.data))
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    result(self.mapULinkErrorToFlutter(error))
                }
            }
        }
    }
    
    private func endSession(result: @escaping FlutterResult) {
        guard let ulink = ulink else {
            result(FlutterError(code: "NOT_INITIALIZED", message: "ULink not initialized", details: nil))
            return
        }
        
        Task {
            do {
                let success = try await ulink.endSession()
                DispatchQueue.main.async {
                    result(success)
                }
            } catch {
                DispatchQueue.main.async {
                    result(self.mapULinkErrorToFlutter(error))
                }
            }
        }
    }
    
    private func handleDeepLink(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let urlString = args["url"] as? String,
              let url = URL(string: urlString) else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Valid URL is required", details: nil))
            return
        }
        
        guard let ulink = ulink else {
            // If SDK is not initialized yet, queue the deep link for later processing
            if !initializationCompleted {
                print("[ULink] SDK not initialized yet, queuing manual deep link: \(url)")
                pendingDeepLinks.append(PendingDeepLink(url: url, forceProcessing: true))
                result(true) // Return success as the link will be processed later
                return
            }
            
            result(FlutterError(code: "NOT_INITIALIZED", message: "ULink not initialized", details: nil))
            return
        }
        
        ulink.handleDeepLink(url: url)
        result(true)
    }
    
    private func setInitialUri(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let ulink = ulink else {
            result(FlutterError(code: "NOT_INITIALIZED", message: "ULink not initialized", details: nil))
            return
        }
        
        let urlString = (call.arguments as? [String: Any])?["url"] as? String
        let url = urlString != nil ? URL(string: urlString!) : nil
        
        ulink.setInitialUrl(url)
        result(true)
    }
    
    private func getInitialUri(result: @escaping FlutterResult) {
        guard let ulink = ulink else {
            result(FlutterError(code: "NOT_INITIALIZED", message: "ULink not initialized", details: nil))
            return
        }
        
        let uri = ulink.getInitialUrl()
        result(uri?.absoluteString)
    }
    
    private func getInitialDeepLink(result: @escaping FlutterResult) {
        guard let ulink = ulink else {
            result(FlutterError(code: "NOT_INITIALIZED", message: "ULink not initialized", details: nil))
            return
        }
        
        Task {
            do {
                let linkData = try await ulink.getInitialDeepLink()
                DispatchQueue.main.async {
                    result(linkData != nil ? self.linkDataToMap(linkData!) : nil)
                }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "GET_INITIAL_DEEP_LINK_ERROR", message: error.localizedDescription, details: nil))
                }
            }
        }
    }
    
    private func getLastLinkData(result: @escaping FlutterResult) {
        guard let ulink = ulink else {
            result(FlutterError(code: "NOT_INITIALIZED", message: "ULink not initialized", details: nil))
            return
        }
        
        let linkData = ulink.getLastLinkData()
        result(linkData != nil ? linkDataToMap(linkData!) : nil)
    }
    
    private func getCurrentSessionId(result: @escaping FlutterResult) {
        guard let ulink = ulink else {
            result(FlutterError(code: "NOT_INITIALIZED", message: "ULink not initialized", details: nil))
            return
        }
        
        result(ulink.getCurrentSessionId())
    }
    
    private func hasActiveSession(result: @escaping FlutterResult) {
        guard let ulink = ulink else {
            result(FlutterError(code: "NOT_INITIALIZED", message: "ULink not initialized", details: nil))
            return
        }
        
        result(ulink.hasActiveSession())
    }
    
    private func getSessionState(result: @escaping FlutterResult) {
        guard let ulink = ulink else {
            result(FlutterError(code: "NOT_INITIALIZED", message: "ULink not initialized", details: nil))
            return
        }
        
        let sessionState = ulink.getSessionState()
        let stateString: String
        switch sessionState {
        case .idle:
            stateString = "idle"
        case .initializing:
            stateString = "initializing"
        case .active:
            stateString = "active"
        case .ending:
            stateString = "ending"
        case .failed:
            stateString = "failed"
        }
        result(stateString)
    }
    
    private func getInstallationId(result: @escaping FlutterResult) {
        guard let ulink = ulink else {
            result(FlutterError(code: "NOT_INITIALIZED", message: "ULink not initialized", details: nil))
            return
        }
        
        result(ulink.getInstallationId())
    }
    
    private func getInstallationInfo(result: @escaping FlutterResult) {
        guard let ulink = ulink else {
            result(FlutterError(code: "NOT_INITIALIZED", message: "ULink not initialized", details: nil))
            return
        }
        
        if let installationInfo = ulink.getInstallationInfo() {
            result([
                "installationId": installationInfo.installationId,
                "isReinstall": installationInfo.isReinstall,
                "previousInstallationId": installationInfo.previousInstallationId as Any,
                "reinstallDetectedAt": installationInfo.reinstallDetectedAt as Any,
                "persistentDeviceId": installationInfo.persistentDeviceId as Any
            ])
        } else {
            result(nil)
        }
    }
    
    private func isReinstall(result: @escaping FlutterResult) {
        guard let ulink = ulink else {
            result(FlutterError(code: "NOT_INITIALIZED", message: "ULink not initialized", details: nil))
            return
        }
        
        result(ulink.isReinstall())
    }

    private func checkDeferredLink(result: @escaping FlutterResult) {
        guard let ulink = ulink else {
            result(FlutterError(code: "NOT_INITIALIZED", message: "ULink not initialized", details: nil))
            return
        }
        
        Task {
            await ulink.checkDeferredLink()
            DispatchQueue.main.async {
                result(nil)
            }
        }
    }
    
    private func dispose(result: @escaping FlutterResult) {
        ulink?.dispose()
        cancellables.removeAll()
        ulink = nil
        isInitialized = false
        initializationCompleted = false
        pendingDeepLinks.removeAll()
        ULinkAppDelegateSwizzler.shared.cleanup()
        result(true)
    }
    
    // MARK: - Enhanced Stream Data Handling
    
    private func handleStreamLinkData(_ linkData: ULinkResolvedData, streamHandler: StreamHandler?, streamType: String) {
        // Validate if the linkData represents a successful resolution or an error condition
        if isValidLinkData(linkData) {
            // Valid link data - send as normal event
            let linkDataMap = linkDataToMap(linkData)
            streamHandler?.sendEvent(linkDataMap)
        } else {
            // Invalid link data (likely represents an error) - send as error
            let errorMessage = "Failed to resolve \(streamType) link: received invalid or empty link data"
            streamHandler?.sendError(
                code: "INVALID_LINK_DATA",
                message: errorMessage,
                details: [
                    "streamType": streamType,
                    "receivedData": linkDataToMap(linkData)
                ]
            )
        }
    }
    
    private func isValidLinkData(_ linkData: ULinkResolvedData) -> Bool {
        // A valid ULinkResolvedData should have at least one of these essential fields populated:
        // 1. slug (for ULinks)
        // 2. parameters (for deep link data)
        // 3. iosUrl or androidUrl (for platform-specific URLs)
        // 4. fallbackUrl (for fallback handling)
        
        // Check if slug exists and is not empty
        if let slug = linkData.slug, !slug.isEmpty {
            return true
        }
        
        // Check if parameters exist and contain meaningful data
        if let parameters = linkData.parameters, !parameters.isEmpty {
            return true
        }
        
        // Check if any URL fields are populated
        if let iosUrl = linkData.iosUrl, !iosUrl.isEmpty {
            return true
        }
        
        if let androidUrl = linkData.androidUrl, !androidUrl.isEmpty {
            return true
        }
        
        if let fallbackUrl = linkData.fallbackUrl, !fallbackUrl.isEmpty {
            return true
        }
        
        // Check if metadata contains meaningful information
        if let metadata = linkData.metadata, !metadata.isEmpty {
            return true
        }
        
        // If none of the essential fields are populated, consider it invalid
        return false
    }
    
    // MARK: - Automatic AppDelegate Integration Methods
    
    // MARK: - Enhanced Deep Link Processing with Error Handling
    
    private func processDeepLinkWithErrorHandling(_ url: URL, forceProcessing: Bool = false) {
        guard enableDeepLinkIntegration || forceProcessing else {
            print("[ULink] Deep link integration disabled - ignoring automatic link: \(url)")
            return
        }
        
        guard let ulink = self.ulink else {
            // If SDK is not initialized yet, queue the deep link for later processing
            if !initializationCompleted {
                print("[ULink] SDK not initialized yet, queuing deep link: \(url)")
                pendingDeepLinks.append(PendingDeepLink(url: url, forceProcessing: forceProcessing))
                return
            }
            
            // If initialization was completed but ulink is nil, it's an error
            let error = FlutterError(
                code: "NOT_INITIALIZED",
                message: "ULink not initialized, cannot handle deep link: \(url)",
                details: nil
            )
            // Send error to both streams since we don't know which type it would be
            dynamicLinkStreamHandler?.sendError(
                code: error.code,
                message: error.message ?? "ULink not initialized",
                details: error.details
            )
            unifiedLinkStreamHandler?.sendError(
                code: error.code,
                message: error.message ?? "ULink not initialized",
                details: error.details
            )
            return
        }
        
        Task {
            do {
                // Use processULinkUrl to get resolved data or detect errors
                if let resolvedData = await ulink.processULinkUrl(url) {
                    // Success - emit to appropriate stream based on type
                    let linkDataMap = linkDataToMap(resolvedData)
                    
                    if resolvedData.type == "unified" {
                        unifiedLinkStreamHandler?.sendEvent(linkDataMap)
                    } else {
                        dynamicLinkStreamHandler?.sendEvent(linkDataMap)
                    }
                } else {
                    // processULinkUrl returned nil - this means either:
                    // 1. Network error occurred
                    // 2. URL is not a ULink
                    // We need to try resolveLink directly to get the actual error
                    do {
                        let response = try await ulink.resolveLink(url: url.absoluteString)
                        // If we reach here, the link was successfully resolved
                        // but processULinkUrl returned nil, which means the URL is not a ULink
                        // We can silently ignore this case
                    } catch {
                        // resolveLink now throws errors for server errors and network issues
                        // Map ULinkError to appropriate Flutter error
                        let flutterError = mapULinkErrorToFlutter(error)
                        
                        // Send error to both streams
                        dynamicLinkStreamHandler?.sendError(
                            code: flutterError.code,
                            message: flutterError.message ?? "Unknown error occurred while processing link",
                            details: flutterError.details
                        )
                        unifiedLinkStreamHandler?.sendError(
                            code: flutterError.code,
                            message: flutterError.message ?? "Unknown error occurred while processing link",
                            details: flutterError.details
                        )
                    }
                }
            }
        }
    }
    
    internal func handleUniversalLink(_ url: URL) {
        guard enableDeepLinkIntegration else {
            print("[ULink] Deep link integration disabled - ignoring universal link: \(url)")
            return
        }
        print("[ULink] Handling universal link automatically: \(url)")
        processDeepLinkWithErrorHandling(url)
    }
    
    internal func handleURLScheme(_ url: URL) {
        guard enableDeepLinkIntegration else {
            print("[ULink] Deep link integration disabled - ignoring URL scheme: \(url)")
            return
        }
        print("[ULink] Handling URL scheme automatically: \(url)")
        processDeepLinkWithErrorHandling(url)
    }
    
    // MARK: - Centralized Error Handling
    
    private func buildDetailedErrorMessage(baseMessage: String, responseData: [String: Any]?) -> String {
        // If baseMessage already contains HTTP status and response body (like Android format),
        // return it as-is to match Android's error format
        if baseMessage.hasPrefix("HTTP ") && baseMessage.contains(":") {
            return baseMessage
        }
        
        var errorMessage = baseMessage
        
        guard let data = responseData else {
            return errorMessage
        }
        
        // Check for HTTP status code (only add if not already in baseMessage)
        if !errorMessage.contains("HTTP ") {
            if let statusCode = data["statusCode"] as? Int {
                errorMessage += " (HTTP \(statusCode))"
            }
        }
        
        // Check for backend error message (only add if not already in baseMessage)
        if !errorMessage.contains("Backend:") {
            if let backendMessage = data["message"] as? String {
                errorMessage += " - Backend: \(backendMessage)"
            } else if let backendError = data["error"] as? String {
                errorMessage += " - Backend: \(backendError)"
            }
        }
        
        // Check for error details
        if let details = data["details"] as? String {
            errorMessage += " - Details: \(details)"
        }
        
        return errorMessage
    }
    
    private func handleULinkResponse<T>(
        _ response: ULinkResponse,
        errorCode: String,
        defaultErrorMessage: String,
        result: @escaping FlutterResult,
        successHandler: (ULinkResponse) -> T
    ) {
        if response.success {
            result(successHandler(response))
        } else {
            let baseMessage = response.error ?? defaultErrorMessage
            let detailedMessage = buildDetailedErrorMessage(baseMessage: baseMessage, responseData: response.data)
            result(FlutterError(code: errorCode, message: detailedMessage, details: nil))
        }
    }
    
    private func handleULinkSessionResponse<T>(
        _ response: ULinkSessionResponse,
        errorCode: String,
        defaultErrorMessage: String,
        result: @escaping FlutterResult,
        successHandler: (ULinkSessionResponse) -> T
    ) {
        if response.success {
            result(successHandler(response))
        } else {
            let baseMessage = response.error ?? defaultErrorMessage
            let detailedMessage = buildDetailedErrorMessage(baseMessage: baseMessage, responseData: response.data)
            result(FlutterError(code: errorCode, message: detailedMessage, details: nil))
        }
    }
    

    
    private func mapULinkErrorToFlutter(_ error: Error) -> FlutterError {
        // Check if it's a ULinkError from the iOS SDK
        if let ulinkError = error as? ULinkError {
            let errorCode: String
            let errorMessage: String
            
            switch ulinkError {
            case .notInitialized:
                errorCode = "NOT_INITIALIZED"
                errorMessage = "ULink SDK has not been initialized"
            case .invalidConfiguration:
                errorCode = "INVALID_CONFIGURATION"
                errorMessage = "Invalid configuration provided to ULink SDK"
            case .networkError:
                errorCode = "NETWORK_ERROR"
                errorMessage = "Network error occurred while communicating with ULink service"
            case .invalidURL:
                errorCode = "INVALID_URL"
                errorMessage = "Invalid URL provided"
            case .invalidResponse:
                errorCode = "INVALID_RESPONSE"
                errorMessage = "Invalid response received from ULink service"
            case .httpError:
                errorCode = "HTTP_ERROR"
                errorMessage = "HTTP error occurred"
            case .invalidParameters:
                errorCode = "INVALID_PARAMETERS"
                errorMessage = "Invalid parameters provided"
            case .sessionError:
                errorCode = "SESSION_ERROR"
                errorMessage = "Session management error occurred"
            case .installationError:
                errorCode = "INSTALLATION_ERROR"
                errorMessage = "Installation tracking error occurred"
            case .linkCreationError:
                errorCode = "LINK_CREATION_ERROR"
                errorMessage = "Error occurred while creating link"
            case .linkResolutionError:
                errorCode = "LINK_RESOLUTION_ERROR"
                errorMessage = "Error occurred while resolving link"
            case .persistenceError:
                errorCode = "PERSISTENCE_ERROR"
                errorMessage = "Data persistence error occurred"
            case .unknown:
                errorCode = "UNKNOWN_ERROR"
                errorMessage = "An unknown error occurred"
            @unknown default:
                errorCode = "UNKNOWN_ERROR"
                errorMessage = "An unknown error occurred"
            }
            
            return FlutterError(code: errorCode, message: errorMessage, details: ulinkError.localizedDescription)
        }
        
        // Check if it's a ULinkHTTPError
        if let httpError = error as? ULinkHTTPError {
            var details: [String: Any] = [
                "statusCode": httpError.statusCode
            ]
            
            if let responseBody = httpError.responseBody {
                details["responseBody"] = responseBody
            }
            
            if let responseJSON = httpError.responseJSON {
                details["responseJSON"] = responseJSON
            }
            
            return FlutterError(
                code: "HTTP_ERROR",
                message: "HTTP error occurred (status: \(httpError.statusCode))",
                details: details
            )
        }
        
        // Fallback for other errors
        return FlutterError(
            code: "UNKNOWN_ERROR",
            message: error.localizedDescription,
            details: nil
        )
    }
    
    // MARK: - Helper Methods
    
    private func parseULinkConfig(from map: [String: Any]) throws -> ULinkConfig {
        guard let apiKey = map["apiKey"] as? String else {
            throw NSError(domain: "ULinkBridge", code: 1, userInfo: [NSLocalizedDescriptionKey: "API key is required"])
        }
        
        let baseUrl = map["baseUrl"] as? String ?? "https://api.ulink.ly"
        let debug = map["debug"] as? Bool ?? false
        let enableDeepLinkIntegration = map["enableDeepLinkIntegration"] as? Bool ?? true
        
        // Parse persistence options
        let persistLastLinkData = map["persistLastLinkData"] as? Bool ?? false
        var lastLinkTimeToLive: TimeInterval? = nil
        if let ttlMillis = map["lastLinkTimeToLive"] as? Int {
            lastLinkTimeToLive = TimeInterval(ttlMillis) / 1000.0 // Convert ms to seconds
        }
        let clearLastLinkOnRead = map["clearLastLinkOnRead"] as? Bool ?? true
        let redactAllParametersInLastLink = map["redactAllParametersInLastLink"] as? Bool ?? false
        let redactedParameterKeysInLastLink = map["redactedParameterKeysInLastLink"] as? [String] ?? []
        
        // Parse automatic AppDelegate integration option (bridge-layer feature)
        self.enableAutomaticAppDelegateIntegration = map["enableAutomaticAppDelegateIntegration"] as? Bool ?? true
        self.enableDeepLinkIntegration = enableDeepLinkIntegration
        
        return ULinkConfig(
            apiKey: apiKey,
            baseUrl: baseUrl,
            debug: debug,
            enableDeepLinkIntegration: enableDeepLinkIntegration,
            persistLastLinkData: persistLastLinkData,
            lastLinkTimeToLive: lastLinkTimeToLive,
            clearLastLinkOnRead: clearLastLinkOnRead,
            redactAllParametersInLastLink: redactAllParametersInLastLink,
            redactedParameterKeysInLastLink: redactedParameterKeysInLastLink
        )
    }
    
    private func parseULinkParameters(from map: [String: Any]) throws -> ULinkParameters {
        guard let type = map["type"] as? String else {
            throw NSError(domain: "ULinkBridge", code: 1, userInfo: [NSLocalizedDescriptionKey: "Type is required"])
        }
        
        guard let domain = map["domain"] as? String else {
            throw NSError(domain: "ULinkBridge", code: 1, userInfo: [NSLocalizedDescriptionKey: "Domain is required"])
        }
        
        let slug = map["slug"] as? String
        let iosFallbackUrl = map["iosFallbackUrl"] as? String
        let androidFallbackUrl = map["androidFallbackUrl"] as? String
        let fallbackUrl = map["fallbackUrl"] as? String
        let additionalParameters = map["parameters"] as? [String: String]
        let metadata = map["metadata"] as? [String: Any]
        
        var socialTags: SocialMediaTags? = nil
        if let socialMediaArgs = map["socialMediaTags"] as? [String: Any] {
            let ogTitle = socialMediaArgs["ogTitle"] as? String
            let ogDescription = socialMediaArgs["ogDescription"] as? String
            let ogImage = socialMediaArgs["ogImage"] as? String
            
            socialTags = SocialMediaTags(
                ogTitle: ogTitle,
                ogDescription: ogDescription,
                ogImage: ogImage
            )
        }
        
        let parameters: ULinkParameters
        if type == "dynamic" {
            parameters = ULinkParameters.dynamic(
                domain: domain,
                slug: slug,
                iosFallbackUrl: iosFallbackUrl,
                androidFallbackUrl: androidFallbackUrl,
                fallbackUrl: fallbackUrl,
                parameters: additionalParameters,
                socialMediaTags: socialTags,
                metadata: metadata
            )
        } else {
            let iosUrl = map["iosUrl"] as? String ?? ""
            let androidUrl = map["androidUrl"] as? String ?? ""
            let fallbackUrlRequired = fallbackUrl ?? ""
            
            parameters = ULinkParameters.unified(
                domain: domain,
                slug: slug,
                iosUrl: iosUrl,
                androidUrl: androidUrl,
                fallbackUrl: fallbackUrlRequired,
                parameters: additionalParameters,
                socialMediaTags: socialTags,
                metadata: metadata
            )
        }
        
        return parameters
    }
    
    private func responseToMap(_ response: ULinkResponse) -> [String: Any?] {
        return [
            "success": response.success,
            "url": response.url,
            "error": response.error,
            "data": response.data
        ]
    }
    
    private func sessionResponseToMap(_ response: ULinkSessionResponse) -> [String: Any?] {
        return [
            "success": response.success,
            "sessionId": response.sessionId,
            "error": response.error
        ]
    }
    
    private func linkDataToMap(_ linkData: ULinkResolvedData) -> [String: Any?] {
        var socialMediaTagsMap: [String: Any?]? = nil
        if let tags = linkData.socialMediaTags {
            socialMediaTagsMap = [
                "title": tags.ogTitle,
                "description": tags.ogDescription,
                "imageUrl": tags.ogImage
            ]
        }
        
        return [
            "slug": linkData.slug,
            "iosUrl": linkData.iosUrl,
            "androidUrl": linkData.androidUrl,
            "iosFallbackUrl": linkData.iosFallbackUrl,
            "androidFallbackUrl": linkData.androidFallbackUrl,
            "fallbackUrl": linkData.fallbackUrl,
            "parameters": linkData.parameters,
            "socialMediaTags": socialMediaTagsMap,
            "metadata": linkData.metadata,
            "type": linkData.type,
            "isDeferred": linkData.isDeferred,
            "matchType": linkData.matchType,
            "resolvedAt": linkData.resolvedAt?.timeIntervalSince1970
        ]
    }
}

// MARK: - Stream Handler

class StreamHandler: NSObject, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
    
    func sendEvent(_ event: Any) {
        eventSink?(event)
    }
    
    func sendError(code: String, message: String, details: Any? = nil) {
        eventSink?(FlutterError(code: code, message: message, details: details))
    }
}
