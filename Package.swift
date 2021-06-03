// swift-tools-version:5.2
import PackageDescription

var dependencies: [Package.Dependency] = [
    .package(url: "https://github.com/kylef/PathKit", from: "1.0.0"),
    .package(url: "https://github.com/jpsim/Yams", from: "4.0.0"),
    .package(url: "https://github.com/tadija/AEXML", from: "4.0.0"),
    .package(url: "https://github.com/apple/swift-argument-parser", from: "0.3.0"),
    .package(name: "SwiftIndexStore", url: "https://github.com/kateinoigakukun/swift-indexstore", from: "0.0.0")
]

#if swift(>=5.4)
dependencies.append(
    .package(
        name: "SwiftSyntax",
        url: "https://github.com/apple/swift-syntax",
        .exact("0.50400.0")
    )
)
#elseif swift(>=5.3)
dependencies.append(
    .package(
        name: "SwiftSyntax",
        url: "https://github.com/apple/swift-syntax",
        .exact("0.50300.0")
    )
)
#else
dependencies.append(
    .package(
        name: "SwiftSyntax",
        url: "https://github.com/apple/swift-syntax",
        .exact("0.50200.0")
    )
)
#endif

#if os(macOS)
dependencies.append(
    .package(
        name: "XcodeProj",
        url: "https://github.com/tuist/xcodeproj",
        from: "7.0.0"
    )
)
#endif

var frontendDependencies: [PackageDescription.Target.Dependency] = [
    .target(name: "Shared"),
    .target(name: "PeripheryKit"),
    .product(name: "ArgumentParser", package: "swift-argument-parser")
]

#if os(macOS)
frontendDependencies.append(.target(name: "XcodeSupport"))
#endif

var targets: [PackageDescription.Target] = [
    .target(
        name: "Frontend",
        dependencies: frontendDependencies
    ),
    .target(
        name: "PeripheryKit",
        dependencies: [
            .target(name: "Shared"),
            .product(name: "PathKit", package: "PathKit"),
            .product(name: "AEXML", package: "AEXML"),
            .product(name: "SwiftSyntax", package: "SwiftSyntax"),
            .product(name: "SwiftIndexStore", package: "SwiftIndexStore")
        ]
    ),
    .target(
        name: "Shared",
        dependencies: [
            .product(name: "Yams", package: "Yams")
        ]
    ),
    .target(
        name: "RetentionFixturesCrossModule"
    ),
    .target(
        name: "TestShared",
        dependencies: [
            .target(name: "PeripheryKit")
        ],
        path: "Tests/Shared"
    ),
    .target(
        name: "RetentionFixtures",
        dependencies: ["RetentionFixturesCrossModule"],
        path: "Tests/RetentionFixtures"
    ),
    .target(
        name: "UnusedParameterFixtures",
        path: "Tests/Fixtures/UnusedParameterFixtures"
    ),
    .target(
        name: "TypeSyntaxInspectorFixtures",
        path: "Tests/Fixtures/TypeSyntaxInspectorFixtures"
    ),
    .target(
        name: "FunctionVisitorFixtures",
        path: "Tests/Fixtures/FunctionVisitorFixtures"
    ),
    .target(
        name: "PropertyVisitorFixtures",
        path: "Tests/Fixtures/PropertyVisitorFixtures"
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
targets.append(
    .target(
        name: "XcodeSupport",
        dependencies: [
            .target(name: "Shared"),
            .target(name: "PeripheryKit"),
            .product(name: "XcodeProj", package: "XcodeProj"),
        ]
    )
)

targets.append(
    .testTarget(
        name: "XcodeTests",
        dependencies: [
            .target(name: "TestShared"),
            .target(name: "PeripheryKit"),
            .target(name: "XcodeSupport")
        ],
        exclude: ["iOSProject"]
    )
)
#endif

let package = Package(
    name: "Periphery",
    products: [
        .executable(name: "periphery", targets: ["Frontend"])
    ],
    dependencies: dependencies,
    targets: targets,
    swiftLanguageVersions: [.v5]
)
