// swift-tools-version:5.0
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
        .package(url: "https://github.com/ileitch/Commandant", .branch("boolean-option")),
        .package(url: "https://github.com/jpsim/SourceKitten", from: "0.20.0"),
        .package(url: "https://github.com/tuist/xcodeproj", from: "6.0.0"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift", from: "0.1.0"),
        .package(url: "https://github.com/kylef/PathKit", from: "0.9.2"),
        .package(url: "https://github.com/apple/swift-syntax", from: "0.50100.0")
    ],
    targets: [
        .target(
            name: "Periphery",
            dependencies: ["PeripheryKit"]
        ),
        .target(
            name: "PeripheryKit",
            dependencies: [
                "Commandant",
                "SourceKittenFramework",
                "xcodeproj",
                "CryptoSwift",
                "PathKit",
                "SwiftSyntax"
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
    swiftLanguageVersions: [.v4_2, .v5]
)
