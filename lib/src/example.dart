import 'package:flutter/material.dart';
import 'package:flutter_ulink_sdk/flutter_ulink_sdk.dart';

/// Example of how to use the ULink SDK
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the SDK
  await ULink.initialize(
    config: ULinkConfig(
      apiKey: 'ulk_839405e4d92e04109829a3d0fafc24b78f6aef0d062a38cb',
      debug: true,
    ),
  );

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
  String _lastLink = 'No link received yet';
  String _createdLink = 'No link created yet';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Listen for incoming links
    _ulink.onLink.listen((ULinkResolvedData uri) {
      setState(() {
        _lastLink = uri.toString();
      });

      // Process the link parameters
      final params = uri.parameters;
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
          socialMediaTags: SocialMediaTags(
            ogTitle: 'Amazing Product Title',
            ogDescription: 'Product description for social sharing',
            ogImage: 'https://example.com/images/product.jpg',
          ),
          parameters: {
            'utm_source': 'example_app',
            'campaign': 'test',
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
            Text(_lastLink),
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
