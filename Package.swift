// swift-tools-version:5.9
import PackageDescription

var dependencies: [Package.Dependency] = [
    .package(url: "https://github.com/apple/swift-system", from: "1.0.0"),
    .package(url: "https://github.com/jpsim/Yams", from: "5.0.0"),
    .package(url: "https://github.com/tadija/AEXML", from: "4.0.0"),
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
    .package(url: "https://github.com/ileitch/swift-indexstore", from: "9.0.4"),
    .package(url: "https://github.com/apple/swift-syntax", from: "510.0.3"),
    .package(url: "https://github.com/ileitch/swift-filename-matcher", from: "0.0.0")
]

#if os(macOS)
dependencies.append(
    .package(
        url: "https://github.com/tuist/xcodeproj",
        from: "8.16.0"
    )
)
#endif

var frontendDependencies: [PackageDescription.Target.Dependency] = [
    .target(name: "Shared"),
    .target(name: "SourceGraph"),
    .target(name: "PeripheryKit"),
    .target(name: "ProjetDrivers"),
    .product(name: "ArgumentParser", package: "swift-argument-parser"),
    .product(name: "FilenameMatcher", package: "swift-filename-matcher")
]

#if os(macOS)
frontendDependencies.append(.target(name: "XcodeSupport"))
#endif

var targets: [PackageDescription.Target] = [
    .executableTarget(
        name: "Frontend",
        dependencies: frontendDependencies
    ),
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
            .product(name: "FilenameMatcher", package: "swift-filename-matcher")
        ]
    ),
    .target(
        name: "Indexer",
        dependencies: [
            .target(name: "SyntaxAnalysis"),
            .target(name: "Shared"),
            .product(name: "SwiftIndexStore", package: "swift-indexstore")
        ]
    ),
    .target(
      name: "ProjetDrivers",
      dependencies: [
        .target(name: "SourceGraph"),
        .target(name: "Shared"),
        .target(name: "Indexer"),
        .target(name: "XcodeSupport"),
      ]
    ),
    .target(
        name: "SyntaxAnalysis",
        dependencies: [
            .target(name: "SourceGraph"),
            .target(name: "Shared"),
            .product(name: "SwiftSyntax", package: "swift-syntax")
        ]
    ),
    .target(
        name: "SourceGraph",
        dependencies: [
            .product(name: "SwiftSyntax", package: "swift-syntax"),
            .target(name: "Shared")
        ]
    ),
    .target(
        name: "Shared",
        dependencies: [
            .product(name: "Yams", package: "Yams"),
            .product(name: "SystemPackage", package: "swift-system"),
            .product(name: "FilenameMatcher", package: "swift-filename-matcher")
        ]
    ),
    .target(
        name: "TestShared",
        dependencies: [
            .target(name: "PeripheryKit")
        ],
        path: "Tests/Shared"
    ),
    .testTarget(
        name: "PeripheryTests",
        dependencies: [
            .target(name: "TestShared"),
            .target(name: "PeripheryKit")
        ]
    ),
    .testTarget(
        name: "SPMTests",
        dependencies: [
            .target(name: "TestShared"),
            .target(name: "PeripheryKit")
        ],
        exclude: ["SPMProject"]
    ),
    .testTarget(
        name: "AccessibilityTests",
        dependencies: [
            .target(name: "TestShared"),
            .target(name: "PeripheryKit")
        ],
        exclude: ["AccessibilityProject"]
    )
]

#if os(macOS)
targets.append(contentsOf: [
    .target(
        name: "XcodeSupport",
        dependencies: [
            .target(name: "SourceGraph"),
            .target(name: "Shared"),
            .target(name: "PeripheryKit"),
            .product(name: "XcodeProj", package: "XcodeProj")
        ]
    ),
    .testTarget(
        name: "XcodeTests",
        dependencies: [
            .target(name: "TestShared"),
            .target(name: "PeripheryKit"),
            .target(name: "XcodeSupport")
        ],
        exclude: ["UIKitProject", "SwiftUIProject"]
    )
])
#endif

let package = Package(
    name: "Periphery",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "periphery", targets: ["Frontend"]),
        .library(name: "PeripheryKit", targets: ["PeripheryKit"])
    ],
    dependencies: dependencies,
    targets: targets,
    swiftLanguageVersions: [.v5]
)
