import 'package:flutter/material.dart';
import 'package:flutter_ulink_sdk/flutter_ulink_sdk.dart';

/// Example demonstrating graceful handling of unified/simple links
class UnifiedLinkExample extends StatefulWidget {
  const UnifiedLinkExample({super.key});

  @override
  State<UnifiedLinkExample> createState() => _UnifiedLinkExampleState();
}

class _UnifiedLinkExampleState extends State<UnifiedLinkExample> {
  String _status = 'Ready';
  ULinkResolvedData? _lastLinkData;

  @override
  void initState() {
    super.initState();
    _initializeULink();
  }

  Future<void> _initializeULink() async {
    try {
      // Initialize ULink with your API key
      await ULink.initialize(config: 
        ULinkConfig(
          apiKey: 'your-api-key-here',
          debug: true,
        ),
      );

      // Listen for dynamic links (in-app handling)
      ULink.instance.onLink.listen((linkData) {
        setState(() {
          _lastLinkData = linkData;
          _status = 'Dynamic link received for in-app handling';
        });
      });

      // Listen for unified links (external redirects)
      ULink.instance.onUnifiedLink.listen((linkData) {
        setState(() {
          _lastLinkData = linkData;
          _status = 'Unified link received and redirected externally';
        });
      });

      setState(() {
        _status = 'ULink initialized and listening for links';
      });
    } catch (e) {
      setState(() {
        _status = 'Error initializing ULink: $e';
      });
    }
  }

  Future<void> _createDynamicLink() async {
    try {
      setState(() {
        _status = 'Creating dynamic link...';
      });

      final response = await ULink.instance.createLink(
        ULinkParameters.dynamic(
          slug: 'dynamic-example-${DateTime.now().millisecondsSinceEpoch}',
          iosFallbackUrl: 'https://apps.apple.com/app/example',
          androidFallbackUrl: 'https://play.google.com/store/apps/details?id=com.example',
          fallbackUrl: 'https://example.com/dynamic',
          parameters: {
            'screen': 'home',
            'userId': '12345',
            'utm_source': 'app',
            'campaign': 'dynamic_example',
          },
        ),
      );

      if (response.success) {
        setState(() {
          _status = 'Dynamic link created: ${response.url}';
        });
      } else {
        setState(() {
          _status = 'Error creating dynamic link: ${response.error}';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  Future<void> _createUnifiedLink() async {
    try {
      setState(() {
        _status = 'Creating unified link...';
      });

      final response = await ULink.instance.createLink(
        ULinkParameters.unified(
          slug: 'unified-example-${DateTime.now().millisecondsSinceEpoch}',
          iosUrl: 'https://apps.apple.com/app/my-app/id123456789',
          androidUrl: 'https://play.google.com/store/apps/details?id=com.example.myapp',
          fallbackUrl: 'https://myapp.com/product/123',
          parameters: {
            'utm_source': 'email',
            'campaign': 'summer',
          },
          metadata: {
            'custom_param': 'value',
          },
        ),
      );

      if (response.success) {
        setState(() {
          _status = 'Unified link created: ${response.url}';
        });
      } else {
        setState(() {
          _status = 'Error creating unified link: ${response.error}';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  Future<void> _testUnifiedLink() async {
    // Simulate receiving a unified link
    await ULink.instance.testListener('https://ulink.ly/unified-test-link');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unified Link Example'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(_status),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _createDynamicLink,
              child: const Text('Create Dynamic Link (In-App Handling)'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _createUnifiedLink,
              child: const Text('Create Unified Link (External Redirect)'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _testUnifiedLink,
              child: const Text('Test Unified Link Handling'),
            ),
            const SizedBox(height: 16),
            if (_lastLinkData != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Last Link Data:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('Type: ${_lastLinkData!.linkType}'),
                      Text('Link Type: ${_lastLinkData!.linkType}'),
                      Text('Fallback URL: ${_lastLinkData!.fallbackUrl}'),
                      if (_lastLinkData!.parameters != null)
                        Text('Parameters: ${_lastLinkData!.parameters}'),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How it works:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Dynamic links (type: dynamic) use fallback URLs for in-app handling\n'
                      '• Unified links (type: unified) use iosUrl/androidUrl for direct platform redirects\n'
                      '• Dynamic links are handled via onLink stream with parameters\n'
                      '• Unified links are redirected externally via onUnifiedLink stream\n'
                      '• Field usage: Dynamic (iosFallbackUrl, androidFallbackUrl) vs Unified (iosUrl, androidUrl)',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}