// swift-tools-version:6.0
import PackageDescription

var dependencies: [Package.Dependency] = [
    .package(url: "https://github.com/apple/swift-system", from: "1.0.0"),
    .package(url: "https://github.com/jpsim/Yams", from: "5.0.0"),
    .package(url: "https://github.com/tadija/AEXML", from: "4.0.0"),
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
    .package(url: "https://github.com/kateinoigakukun/swift-indexstore", from: "0.3.0"),
    .package(url: "https://github.com/apple/swift-syntax", from: "601.0.1"),
    .package(url: "https://github.com/ileitch/swift-filename-matcher", from: "2.0.0"),
]

#if os(macOS)
    dependencies.append(
        .package(
            url: "https://github.com/tuist/xcodeproj",
            from: "9.0.0"
        )
    )
#endif

var projectDriverDependencies: [PackageDescription.Target.Dependency] = [
    .target(name: "SourceGraph"),
    .target(name: "Shared"),
    .target(name: "Indexer"),
]

#if os(macOS)
    projectDriverDependencies.append(.target(name: "XcodeSupport"))
#endif

var targets: [PackageDescription.Target] = [
    .executableTarget(
        name: "Frontend",
        dependencies: [
            .target(name: "Shared"),
            .target(name: "Configuration"),
            .target(name: "SourceGraph"),
            .target(name: "PeripheryKit"),
            .target(name: "ProjectDrivers"),
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
            .product(name: "FilenameMatcher", package: "swift-filename-matcher"),
        ]
    ),
    .target(
        name: "Configuration",
        dependencies: [
            .target(name: "Extensions"),
            .target(name: "Shared"),
            .target(name: "Logger"),
            .product(name: "Yams", package: "Yams"),
            .product(name: "SystemPackage", package: "swift-system"),
            .product(name: "FilenameMatcher", package: "swift-filename-matcher"),
        ]
    ),
    .target(
        name: "Extensions",
        dependencies: [
            .product(name: "SystemPackage", package: "swift-system"),
            .product(name: "FilenameMatcher", package: "swift-filename-matcher"),
        ]
    ),
    .target(name: "Logger"),
    .target(
        name: "PeripheryKit",
        dependencies: [
            .target(name: "SourceGraph"),
            .target(name: "Shared"),
            .target(name: "Indexer"),
            .product(name: "SystemPackage", package: "swift-system"),
            .product(name: "AEXML", package: "AEXML"),
            .product(name: "SwiftSyntax", package: "swift-syntax"),
            .product(name: "SwiftParser", package: "swift-syntax"),
            .product(name: "SwiftIndexStore", package: "swift-indexstore"),
            .product(name: "FilenameMatcher", package: "swift-filename-matcher"),
        ]
    ),
    .target(
        name: "Indexer",
        dependencies: [
            .target(name: "SyntaxAnalysis"),
            .target(name: "Shared"),
            .product(name: "SwiftIndexStore", package: "swift-indexstore"),
            .product(name: "AEXML", package: "AEXML"),
        ]
    ),
    .target(
        name: "ProjectDrivers",
        dependencies: projectDriverDependencies
    ),
    .target(
        name: "SyntaxAnalysis",
        dependencies: [
            .target(name: "SourceGraph"),
            .target(name: "Shared"),
            .product(name: "SwiftSyntax", package: "swift-syntax"),
            .product(name: "SwiftParser", package: "swift-syntax"),
        ]
    ),
    .target(
        name: "SourceGraph",
        dependencies: [
            .target(name: "Configuration"),
            .product(name: "SwiftSyntax", package: "swift-syntax"),
            .target(name: "Shared"),
        ]
    ),
    .target(
        name: "Shared",
        dependencies: [
            .target(name: "Extensions"),
            .target(name: "Logger"),
            .product(name: "SystemPackage", package: "swift-system"),
            .product(name: "FilenameMatcher", package: "swift-filename-matcher"),
        ]
    ),
    .target(
        name: "TestShared",
        dependencies: [
            .target(name: "PeripheryKit"),
            .target(name: "ProjectDrivers"),
            .target(name: "Configuration"),
        ],
        path: "Tests/Shared"
    ),
    .testTarget(
        name: "PeripheryTests",
        dependencies: [
            .target(name: "TestShared"),
            .target(name: "PeripheryKit"),
        ]
    ),
    .testTarget(
        name: "SPMTests",
        dependencies: [
            .target(name: "TestShared"),
            .target(name: "PeripheryKit"),
        ],
        exclude: ["SPMProject"]
    ),
    .testTarget(
        name: "AccessibilityTests",
        dependencies: [
            .target(name: "TestShared"),
            .target(name: "PeripheryKit"),
            .target(name: "Configuration"),
        ],
        exclude: ["AccessibilityProject"]
    ),
]

#if os(macOS)
    targets.append(contentsOf: [
        .target(
            name: "XcodeSupport",
            dependencies: [
                .target(name: "SourceGraph"),
                .target(name: "Shared"),
                .target(name: "PeripheryKit"),
                .product(name: "XcodeProj", package: "XcodeProj"),
            ]
        ),
        .testTarget(
            name: "XcodeTests",
            dependencies: [
                .target(name: "ProjectDrivers"),
                .target(name: "TestShared"),
                .target(name: "PeripheryKit"),
            ],
            exclude: ["UIKitProject", "SwiftUIProject"]
        ),
    ])
#endif

let package = Package(
    name: "Periphery",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "periphery", targets: ["Frontend"]),
        .library(name: "PeripheryKit", targets: ["PeripheryKit"]),
    ],
    dependencies: dependencies,
    targets: targets,
    swiftLanguageModes: [.v5]
)
