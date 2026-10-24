// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "siprix_voip_sdk_macos",
    platforms: [
        .macOS("10.11")
    ],
    products: [
        .library(name: "siprix-voip-sdk-macos", targets: ["siprix_voip_sdk_macos", "siprix", "siprixMedia"])
    ],
    dependencies: [],
    targets: [
        .binaryTarget(name: "siprix", path: "Frameworks/siprix.xcframework.zip"),
        .binaryTarget(name: "siprixMedia", path: "Frameworks/siprixMedia.xcframework.zip"),
        .target(
            name: "siprix_voip_sdk_macos",
            dependencies: ["siprix", "siprixMedia"]
        )
    ]
)
