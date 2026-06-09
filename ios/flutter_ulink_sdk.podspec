#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_ulink_sdk.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_ulink_sdk'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter plugin project.'
  s.description      = <<-DESC
A new Flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'flutter_ulink_sdk/Sources/flutter_ulink_sdk/**/*.swift'
  s.dependency 'Flutter'
  s.dependency 'ULinkSDK', '~> 1.1.1'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # Privacy manifest, shared with the Swift Package Manager target. Both build
  # systems reference the same file under Sources/flutter_ulink_sdk/Resources.
  s.resource_bundles = {'flutter_ulink_sdk_privacy' => ['flutter_ulink_sdk/Sources/flutter_ulink_sdk/Resources/PrivacyInfo.xcprivacy']}
end
