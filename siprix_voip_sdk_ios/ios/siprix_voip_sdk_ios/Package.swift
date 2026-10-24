// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "siprix_voip_sdk_ios",
    platforms: [
        .iOS("11.0")
    ],
    products: [
        .library(name: "siprix-voip-sdk-ios", targets: ["siprix_voip_sdk_ios", "siprix", "siprixMedia"])
    ],
    dependencies: [],
    targets: [
        .binaryTarget(name: "siprix", path: "Frameworks/siprix.xcframework.zip"),
        .binaryTarget(name: "siprixMedia", path: "Frameworks/siprixMedia.xcframework.zip"),
        .target(
            name: "siprix_voip_sdk_ios",
            dependencies: ["siprix", "siprixMedia"]
        )
    ]
)
