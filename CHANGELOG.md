# Changelog

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
* Added automatic resolution of ULink format links (d/[slug]) in link listeners
* Added comprehensive documentation for link resolution
* Added example for resolving links in example/test/link_resolve_test.dart

## 0.0.1

* Initial development release
