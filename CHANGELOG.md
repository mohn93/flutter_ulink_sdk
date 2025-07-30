# Changelog

## 0.1.4

  - Fixed issue with unified links and added getInitialLink method

## 0.1.3

  - Changed dependecies

## 0.1.2

  - changed package_info to package_info_plus

## 0.1.1

### 🔧 Improvements

* **Removed deepLink Field**: Removed unused `deepLink` field from `ULinkParameters` class and all related documentation
* **Factory Methods**: Added `ULinkParameters.dynamic()` and `ULinkParameters.unified()` factory constructors for cleaner API
  - Improved type safety and developer experience
  - Better IDE support with parameter validation
  - More intuitive API for creating different link types

* **Path Structure Update**: Updated all examples and documentation to use slug on root path instead of `/d/slug` format
  - Updated link resolution examples to use direct slug paths
  - Simplified URL structure across all documentation
  - Updated test files to reflect new path format

### 📚 Documentation

* Updated README.md with factory method examples and benefits
* Updated UNIFIED_LINKS.md to use new factory constructors
* Added comprehensive documentation for factory method usage
* Updated all code examples to demonstrate cleaner API patterns

### 🗂️ Breaking Changes

* Removed `deepLink` field from `ULinkParameters` (was unused)
* Updated URL path structure from `/d/slug` to `/slug` format

## 0.1.0

### ✨ New Features

* **Metadata Support**: Added dedicated `metadata` field for social media data separation
  - Social media parameters (Open Graph, Twitter) are now automatically moved to a separate `metadata` field
  - Added `metadata` parameter to `ULinkParameters` for explicit social media data
  - Added `metadata` field to `ULinkResolvedData` for parsing API responses
  - Automatic detection and separation of social media parameters from regular parameters
  - Support for additional social media platforms (Twitter, OpenGraph extended properties)

### 🔧 Improvements

* **Better Data Organization**: Clear separation between business/tracking parameters and social media metadata
* **Backward Compatibility**: Existing code continues to work without modifications
* **Enhanced Social Media Tags**: Extended `SocialMediaTags` class now populates metadata instead of parameters
* **Auto-Migration**: Social media parameters in the `parameters` field are automatically moved to `metadata`

### 📚 Documentation

* Added comprehensive examples showing metadata usage patterns
* Added unit tests for metadata functionality
* Added demo script showing JSON structure changes
* Updated examples to demonstrate new metadata features

### 🗂️ Breaking Changes

* None - all changes are backward compatible

## 0.0.3

### Fixes

* Refactor ULink dynamic link handling;
* Remove redundant checks for dynamic links

## 0.0.2

* Added resolveLink method to retrieve original data from dynamic links
* Added ULinkResolvedData model for handling resolved link data
* Added automatic resolution of ULink format links (slug on root path) in link listeners
* Added comprehensive documentation for link resolution
* Added example for resolving links in example/test/link_resolve_test.dart

## 0.0.1

* Initial development release
