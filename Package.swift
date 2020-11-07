// swift-tools-version:5.2
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
        .package(url: "https://github.com/kylef/PathKit", from: "1.0.0"),
        .package(url: "https://github.com/jpsim/Yams", from: "4.0.0"),
        .package(url: "https://github.com/tadija/AEXML", from: "4.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.3.0"),
        .package(name: "XcodeProj", url: "https://github.com/ileitch/xcodeproj", .revision("026d560a25bedc4eb31c9a991a8988df9c2e4b66")),
        .package(name: "SwiftSyntax", url: "https://github.com/apple/swift-syntax", .exact("0.50300.0")),
        .package(name: "SwiftIndexStore", url: "https://github.com/kateinoigakukun/swift-indexstore", .revision("047875b31d65a39919bf1b10304aec7f1d86f971")),
    ],
    targets: [
        .target(
            name: "Periphery",
            dependencies: ["PeripheryKit"]
        ),
        .target(
            name: "PeripheryKit",
            dependencies: [
                .product(name: "Yams", package: "Yams"),
                .product(name: "PathKit", package: "PathKit"),
                .product(name: "AEXML", package: "AEXML"),
                .product(name: "XcodeProj", package: "XcodeProj"),
                .product(name: "SwiftSyntax", package: "SwiftSyntax"),
                .product(name: "SwiftIndexStore", package: "SwiftIndexStore"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .target(
            name: "RetentionFixturesCrossModule"
        ),
        .testTarget(
            name: "RetentionFixtures",
            dependencies: ["RetentionFixturesCrossModule"]
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
