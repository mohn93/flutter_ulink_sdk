import 'package:flutter/material.dart';
import 'package:flutter_ulink_sdk/flutter_ulink_sdk.dart';
import 'config/env.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the SDK using example app's environment configuration
  final ulink = await ULink.initialize(
    config: ULinkConfig(
      apiKey: Environment.apiKey,
      baseUrl: Environment.baseUrl,
      debug: true,
    ),
  );

  try {
    // Create a dynamic link with social media tags
    final response = await ulink.createLink(
      ULinkParameters(
        slug: 'product-123',
        iosFallbackUrl: 'myapp://product/123',
        androidFallbackUrl: 'myapp://product/123',
        fallbackUrl: 'https://myapp.com/product/123',
        socialMediaTags: SocialMediaTags(
          ogTitle: 'Check out this awesome product!',
          ogDescription: 'This is a detailed description of the product.',
          ogImage: 'https://example.com/product-image.jpg',
        ),
        // You can still include other parameters
        parameters: {
          'utm_source': 'share_button',
          'campaign': 'summer_sale',
        },
      ),
    );

    // setState(() {
    if (response.success) {
      // _createdLink = response.url!;
    } else {
      // _createdLink = 'Error: ${response.error}';
    }
    // });
  } finally {
    // setState(() {
    //   _isLoading = false;
    // });
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ULink SDK Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ULink _ulink = ULink.instance;
  ULinkResolvedData? _lastLinkData;
  String _createdLink = 'No link created yet';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Listen for incoming links
    _ulink.onLink.listen((ULinkResolvedData data) {
      setState(() {
        _lastLinkData = data;
      });

      // Process the link parameters
      final params = data.parameters;
      debugPrint('Link parameters: $params');
    });
  }

  // Example 1: Create a link with social media tags using the SocialMediaTags class
  Future<void> _createLinkWithSocialMediaTags() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Create a dynamic link with social media tags
      final response = await _ulink.createLink(
        ULinkParameters(
          slug: 'product-123',
          iosFallbackUrl: 'myapp://product/123',
          androidFallbackUrl: 'myapp://product/123',
          fallbackUrl: 'https://myapp.com/product/123',
          socialMediaTags: SocialMediaTags(
            ogTitle: 'Check out this awesome product!',
            ogDescription: 'This is a detailed description of the product.',
            ogImage: 'https://example.com/product-image.jpg',
          ),
          // You can still include other parameters
          parameters: {
            'utm_source': 'share_button',
            'campaign': 'summer_sale',
          },
        ),
      );

      setState(() {
        if (response.success) {
          _createdLink = response.url!;
        } else {
          _createdLink = 'Error: ${response.error}';
        }
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Example 2: Create a link with social media tags directly in the parameters
  Future<void> _createLinkWithParametersOnly() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Create a dynamic link with social media tags in parameters
      final response = await _ulink.createLink(
        ULinkParameters(
          slug: 'example-link',
          iosFallbackUrl: 'myapp://product/123',
          androidFallbackUrl: 'myapp://product/123',
          fallbackUrl: 'https://myapp.com/product/123',
          parameters: {
            'utm_source': 'example_app',
            'campaign': 'test',
            // Social media tags directly in parameters
            'ogTitle': 'Amazing Product Title',
            'ogDescription': 'Product description for social sharing',
            'ogImage': 'https://example.com/images/product.jpg',
          },
        ),
      );

      setState(() {
        if (response.success) {
          _createdLink = response.url!;
        } else {
          _createdLink = 'Error: ${response.error}';
        }
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ULink SDK Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Last Received Link:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _lastLinkData == null
                ? const Text('No link received yet')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Slug: ${_lastLinkData!.slug ?? 'N/A'}'),
                      Text(
                          'Fallback URL: ${_lastLinkData!.fallbackUrl ?? 'N/A'}'),
                      if (_lastLinkData!.parameters != null)
                        Text('Parameters: ${_lastLinkData!.parameters}'),
                    ],
                  ),
            const SizedBox(height: 24),
            const Text(
              'Created Link:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(_createdLink),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _createLinkWithSocialMediaTags,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Create Link with SocialMediaTags'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _createLinkWithParametersOnly,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Create Link with Parameters Only'),
            ),
          ],
        ),
      ),
    );
  }
}
