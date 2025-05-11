# Changelog

## Upcoming

### Features
- Updated API endpoint for resolving links from `/sdk/links/$slug/resolve` to `/sdk/resolve?url=...`
- Removed deepLink references from the SDK as the API no longer uses this property
- Updated link handling to emit ULinkResolvedData objects instead of just URIs
- Moved environment configuration from the main SDK to the example project
- Set up production defaults in the main SDK while allowing custom configuration
- Improved test files and examples
- Create dynamic links with custom slugs and parameters
- Social media tag support for better link sharing
- Automatic handling of dynamic links in your app
- Support for custom API configuration
- Test utilities for easier development and testing

## 0.0.2

* Added resolveLink method to retrieve original data from dynamic links
* Added ULinkResolvedData model for handling resolved link data
* Added automatic resolution of ULink format links (d/[slug]) in link listeners
* Added comprehensive documentation for link resolution
* Added example for resolving links in example/test/link_resolve_test.dart

## 0.0.1

- Initial development release
