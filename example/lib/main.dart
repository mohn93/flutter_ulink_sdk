import 'package:flutter/material.dart';
import 'package:flutter_ulink_sdk/flutter_ulink_sdk.dart';
import 'package:flutter_ulink_sdk/models/models.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _sdk = ULink.instance;
  bool _isInitialized = false;
  String _status = 'Not initialized';
  String? _sessionId;
  String? _installationId;
  ULinkResponse? _createdLink;
  ULinkResolvedData? _resolvedData;
  SessionState _sessionState = SessionState.idle;

  StreamSubscription<ULinkResolvedData>? _dynamicLinkSubscription;
  StreamSubscription<ULinkResolvedData>? _unifiedLinkSubscription;
  final List<String> _linkEvents = [];

  @override
  void initState() {
    super.initState();
    // Auto-initialize SDK for testing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSDK();
    });
  }

  @override
  void dispose() {
    _dynamicLinkSubscription?.cancel();
    _unifiedLinkSubscription?.cancel();
    super.dispose();
  }

  void _setupLinkListeners() {
    debugPrint('DEBUG: Setting up link listeners');

    // Cancel existing subscriptions to prevent duplicates
    _dynamicLinkSubscription?.cancel();
    _unifiedLinkSubscription?.cancel();

    _dynamicLinkSubscription = _sdk.onDynamicLink.listen((linkData) {
      debugPrint('DEBUG: Dynamic link event received: ${linkData.toJson()}');
      setState(() {
        _linkEvents.insert(
          0,
          'Dynamic Link: ${linkData.slug ?? "Unknown"} - ${linkData.parameters}',
        );
        _resolvedData = linkData;
      });
      debugPrint('DEBUG: UI updated with dynamic link event');
    });

    _unifiedLinkSubscription = _sdk.onUnifiedLink.listen((linkData) {
      debugPrint('DEBUG: Unified link event received: ${linkData.toJson()}');
      setState(() {
        _linkEvents.insert(
          0,
          'Unified Link: ${linkData.slug ?? "Unknown"} - ${linkData.parameters}',
        );
        _resolvedData = linkData;
      });
      debugPrint('DEBUG: UI updated with unified link event');
    });
    debugPrint('DEBUG: Link listeners setup complete');
  }

  Future<void> _initializeSDK() async {
    if (_isInitialized) {
      debugPrint('DEBUG: SDK already initialized, skipping...');
      return;
    }

    debugPrint('DEBUG: Starting SDK initialization...');
    try {
      final config = ULinkConfig(
        apiKey:
            'ulk_5653d6d2c53cbbc7c1d09a621cf439782e795c0c437abee6', // Replace with your actual API key
        debug: true,
        enableDeepLinkIntegration:
            true, // Explicitly enable deep link integration
      );

      debugPrint(
        'DEBUG: Config created: ${config.apiKey}, ${config.baseUrl}, ${config.debug}',
      );

      await _sdk.initialize(config);
      debugPrint('DEBUG: SDK initialized successfully');

      final installationId = await _sdk.getInstallationId();
      debugPrint('DEBUG: Installation ID: $installationId');

      final sessionState = await _sdk.getSessionState();
      debugPrint('DEBUG: Session state: $sessionState');

      // Setup link listeners after SDK is initialized
      _setupLinkListeners();

      // Check for initial deep link after listeners are set up
      try {
        final initialData = await _sdk.getInitialDeepLink();
        if (initialData != null) {
          debugPrint('DEBUG: Initial deep link found: ${initialData.toJson()}');
          setState(() {
            _linkEvents.insert(
              0,
              'Initial Link: ${initialData.slug ?? "Unknown"} - ${initialData.parameters}',
            );
            _resolvedData = initialData;
          });
        }
      } catch (e) {
        debugPrint('DEBUG: Error getting initial deep link: $e');
      }

      setState(() {
        _isInitialized = true;
        _status = 'Initialized successfully';
        _installationId = installationId;
        _sessionState = sessionState;
      });
    } catch (e) {
      debugPrint('DEBUG: Initialization error: $e');
      setState(() {
        _status = 'Initialization failed: $e';
      });
    }
  }

  Future<void> _endSession() async {
    debugPrint('DEBUG: _endSession called');
    try {
      debugPrint('DEBUG: Calling SDK endSession');
      await _sdk.endSession();
      debugPrint('DEBUG: Session ended successfully');

      final sessionState = await _sdk.getSessionState();
      debugPrint('DEBUG: Session state after end: $sessionState');

      setState(() {
        _sessionId = null;
        _sessionState = sessionState;
        _status = 'Session ended';
      });
      debugPrint('DEBUG: UI updated after session end');
    } catch (e) {
      debugPrint('DEBUG: Failed to end session - Error: $e');
      debugPrint('DEBUG: Error type: ${e.runtimeType}');
      setState(() {
        _status = 'Failed to end session: $e';
      });
    }
  }

  Future<void> _createDynamicLink() async {
    debugPrint('DEBUG: _createDynamicLink called');
    try {
      final parameters = ULinkParameters.dynamic(
        domain: 'iossdk.shared.ly',
        slug: 'example-dynamic-link1234',
        iosFallbackUrl: 'https://apps.apple.com/app/your-app',
        androidFallbackUrl:
            'https://play.google.com/store/apps/details?id=your.app',
        fallbackUrl: 'https://your-website.com',
        parameters: {'product_id': '12345', 'campaign': 'summer_sale'},
        socialMediaTags: SocialMediaTags(
          ogTitle: 'Check out this amazing product!',
          ogDescription: 'Don\'t miss our summer sale with great discounts.',
          ogImage: 'https://your-website.com/images/product.jpg',
        ),
      );
      debugPrint(
        'DEBUG: Dynamic link parameters created: ${parameters.toJson()}',
      );

      debugPrint('DEBUG: Calling SDK createLink for dynamic link');
      final response = await _sdk.createLink(parameters);
      debugPrint(
        'DEBUG: createLink response - success: ${response.success}, url: ${response.url}, error: ${response.error}',
      );

      setState(() {
        _createdLink = response;
        if (response.success) {
          _status = 'Dynamic link created: ${response.url}';
        } else {
          _status = 'Failed to create link: ${response.error}';
        }
      });
      debugPrint('DEBUG: UI updated with created dynamic link');
    } catch (e) {
      debugPrint('DEBUG: Failed to create dynamic link - Error: $e');
      debugPrint('DEBUG: Error type: ${e.runtimeType}');
      setState(() {
        _status = 'Failed to create dynamic link: $e';
      });
    }
  }

  Future<void> _createUnifiedLink() async {
    debugPrint('DEBUG: _createUnifiedLink called');
    try {
      final parameters = ULinkParameters.unified(
        domain: 'libyanspider.shared.ly',
        slug: 'example-unified-link',
        iosUrl: 'https://apps.apple.com/app/your-app',
        androidUrl: 'https://play.google.com/store/apps/details?id=your.app',
        fallbackUrl: 'https://your-website.com',
        parameters: {'page': 'home', 'ref': 'unified_link'},
      );
      debugPrint(
        'DEBUG: Unified link parameters created: ${parameters.toJson()}',
      );

      debugPrint('DEBUG: Calling SDK createLink for unified link');
      final response = await _sdk.createLink(parameters);
      debugPrint(
        'DEBUG: createLink response - success: ${response.success}, url: ${response.url}, error: ${response.error}',
      );

      setState(() {
        _createdLink = response;
        if (response.success) {
          _status = 'Unified link created: ${response.url}';
        } else {
          _status = 'Failed to create link: ${response.error}';
        }
      });
      debugPrint('DEBUG: UI updated with created unified link');
    } catch (e) {
      debugPrint('DEBUG: Failed to create unified link - Error: $e');
      debugPrint('DEBUG: Error type: ${e.runtimeType}');
      setState(() {
        _status = 'Failed to create unified link: $e';
      });
    }
  }

  Future<void> _resolveLink() async {
    debugPrint('DEBUG: _resolveLink called');
    if (_createdLink?.url == null) {
      debugPrint('DEBUG: No link to resolve - _createdLink is null');
      setState(() {
        _status = 'No link to resolve. Create a link first.';
      });
      return;
    }

    try {
      debugPrint('DEBUG: Resolving link: ${_createdLink!.url}');
      final response = await _sdk.resolveLink(_createdLink!.url!);
      debugPrint('DEBUG: resolveLink response - success: ${response.success}');

      if (response.success && response.data != null) {
        final resolvedData = ULinkResolvedData.fromJson(response.data!);
        debugPrint(
          'DEBUG: Link resolved successfully: ${resolvedData.toJson()}',
        );

        setState(() {
          _resolvedData = resolvedData;
          _status = 'Link resolved successfully';
        });
        debugPrint('DEBUG: UI updated with resolved data');
      } else {
        setState(() {
          _status = 'Failed to resolve link: ${response.error}';
        });
      }
    } catch (e) {
      debugPrint('DEBUG: Failed to resolve link - Error: $e');
      debugPrint('DEBUG: Error type: ${e.runtimeType}');
      setState(() {
        _status = 'Failed to resolve link: $e';
      });
    }
  }

  Future<void> _getLastLinkData() async {
    debugPrint('DEBUG: _getLastLinkData called');
    try {
      debugPrint('DEBUG: Calling SDK getLastLinkData');
      final lastLinkData = await _sdk.getLastLinkData();
      debugPrint(
        'DEBUG: Last link data retrieved: ${lastLinkData?.toJson() ?? "null"}',
      );

      setState(() {
        _status = lastLinkData != null
            ? 'Last link data retrieved'
            : 'No last link data available';
      });
      debugPrint('DEBUG: UI updated with last link data');
    } catch (e) {
      debugPrint('DEBUG: Failed to get last link data - Error: $e');
      debugPrint('DEBUG: Error type: ${e.runtimeType}');
      setState(() {
        _status = 'Failed to get last link data: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ULink Bridge SDK Example',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              title: const Text('ULink Bridge SDK Example'),
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(_status),
                          const SizedBox(height: 8),
                          Text('Initialized: $_isInitialized'),
                          if (_installationId != null)
                            Text('Installation ID: $_installationId'),
                          if (_sessionId != null) Text('Session ID: $_sessionId'),
                          Text('Session State: ${_sessionState.value}'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // SDK Operations
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SDK Operations',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),

                          ElevatedButton(
                            onPressed: _isInitialized ? null : _initializeSDK,
                            child: const Text('Initialize SDK'),
                          ),

                          const SizedBox(height: 8),

                          ElevatedButton(
                            onPressed: _isInitialized && _sessionId != null
                                ? _endSession
                                : null,
                            child: const Text('End Session (Manual)'),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            'Note: Sessions are automatically managed by the SDK',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Link Operations
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Link Operations',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isInitialized
                                      ? _createDynamicLink
                                      : null,
                                  child: const Text('Create Dynamic Link'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isInitialized
                                      ? _createUnifiedLink
                                      : null,
                                  child: const Text('Create Unified Link'),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed:
                                      _isInitialized &&
                                          _createdLink?.success == true
                                      ? _resolveLink
                                      : null,
                                  child: const Text('Resolve Link'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isInitialized
                                      ? _getLastLinkData
                                      : null,
                                  child: const Text('Get Last Link Data'),
                                ),
                              ),
                            ],
                          ),

                          if (_createdLink != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              'Created Link Response:',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text('Success: ${_createdLink!.success}'),
                            if (_createdLink!.url != null)
                              SelectableText(
                                'URL: ${_createdLink!.url}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            if (_createdLink!.error != null)
                              Text(
                                'Error: ${_createdLink!.error}',
                                style: TextStyle(color: Colors.red),
                              ),
                            if (_createdLink!.data != null)
                              Text(
                                'Data: ${_createdLink!.data?.keys.length ?? 0} fields',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Resolved Data
                  if (_resolvedData != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Resolved Link Data',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text('Slug: ${_resolvedData!.slug ?? "N/A"}'),
                            Text('Link Type: ${_resolvedData!.linkType.name}'),
                            Text(
                              'Fallback URL: ${_resolvedData!.fallbackUrl ?? "N/A"}',
                            ),
                            if (_resolvedData!.parameters != null)
                              Text('Parameters: ${_resolvedData!.parameters}'),
                            if (_resolvedData!.socialMediaTags != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Social Media Tags:',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                'Title: ${_resolvedData!.socialMediaTags!.ogTitle ?? "N/A"}',
                              ),
                              Text(
                                'Description: ${_resolvedData!.socialMediaTags!.ogDescription ?? "N/A"}',
                              ),
                              Text(
                                'Image: ${_resolvedData!.socialMediaTags!.ogImage ?? "N/A"}',
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Link Events
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Link Events (${_linkEvents.length})',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          if (_linkEvents.isEmpty)
                            const Text('No link events received yet')
                          else
                            SizedBox(
                              height: 200,
                              child: ListView.builder(
                                itemCount: _linkEvents.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2.0,
                                    ),
                                    child: Text(
                                      _linkEvents[index],
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Debug overlay - tap the floating bug button to see SDK logs!
          const ULinkDebugOverlay(),
        ],
      ),
    );
  }
}
