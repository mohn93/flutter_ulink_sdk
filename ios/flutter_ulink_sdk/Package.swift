// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "flutter_ulink_sdk",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "flutter-ulink-sdk", targets: ["flutter_ulink_sdk"])
    ],
    dependencies: [
        // Native ULink iOS SDK. Mirrors the `ULinkSDK ~> 1.1.1` CocoaPods
        // dependency declared in flutter_ulink_sdk.podspec.
        .package(url: "https://github.com/mohn93/ios_ulink_sdk.git", from: "1.1.1")
    ],
    targets: [
        .target(
            name: "flutter_ulink_sdk",
            dependencies: [
                .product(name: "ULinkSDK", package: "ios_ulink_sdk")
            ],
            resources: [
                .process("Resources/PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
