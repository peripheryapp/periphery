// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "Periphery",
    platforms: [
      .macOS(.v10_12),
    ],
    products: [
        .executable(name: "periphery", targets: ["Periphery"]),
        .library(name: "PeripheryKit", targets: ["PeripheryKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/SourceKitten", from: "0.29.0"),
        .package(url: "https://github.com/tuist/xcodeproj", from: "7.9.0"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift", from: "1.3.0"),
        .package(url: "https://github.com/kylef/PathKit", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-syntax", .exact("0.50100.0")),
        .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMinor(from: "0.0.4")),
        .package(url: "https://github.com/apple/swift-tools-support-core.git", .branch("master")),
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
                .product(name: "XcodeProj", package: "xcodeproj"),
                .product(name: "CryptoSwift", package: "CryptoSwift"),
                .product(name: "PathKit", package: "PathKit"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SwiftToolsSupport-auto", package: "swift-tools-support-core"),
            ]
        ),
        .testTarget(
            name: "RetentionFixtures"
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
