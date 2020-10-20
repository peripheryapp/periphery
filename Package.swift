// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "Periphery",
    platforms: [
      .macOS(.v10_15),
    ],
    products: [
        .executable(name: "periphery", targets: ["Periphery"]),
        .library(name: "PeripheryKit", targets: ["PeripheryKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/SourceKitten", from: "0.30.1"),
        .package(name: "XcodeProj", url: "https://github.com/tuist/xcodeproj", from: "7.9.0"),
        .package(url: "https://github.com/kylef/PathKit", from: "1.0.0"),
        .package(name: "SwiftSyntax", url: "https://github.com/apple/swift-syntax", .exact("0.50300.0")),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.3.0"),
        .package(name: "SwiftIndexStore", url: "https://github.com/kateinoigakukun/swift-indexstore", from: "0.1.0"),
    ],
    targets: [
        .target(
            name: "Periphery",
            dependencies: ["PeripheryKit"]
        ),
        .target(
            name: "PeripheryKit",
            dependencies: [
                .product(name: "SourceKittenFramework", package: "SourceKitten"),
                .product(name: "XcodeProj", package: "XcodeProj"),
                .product(name: "PathKit", package: "PathKit"),
                .product(name: "SwiftSyntax", package: "SwiftSyntax"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SwiftIndexStore", package: "SwiftIndexStore"),
            ]
        ),
        .testTarget(
            name: "RetentionFixtures"
        ),
        .testTarget(
            name: "TestEmptyTarget"
        ),
        .testTarget(
            name: "SyntaxFixtures"
        ),
        .testTarget(
            name: "PeripheryKitTests",
            dependencies: ["PeripheryKit"]
        )
    ],
    swiftLanguageVersions: [.v5]
)
