// swift-tools-version:5.8
import PackageDescription

var dependencies: [Package.Dependency] = [
    .package(url: "https://github.com/apple/swift-system", from: "1.0.0"),
    .package(url: "https://github.com/jpsim/Yams", from: "5.0.0"),
    .package(url: "https://github.com/tadija/AEXML", from: "4.0.0"),
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
    .package(url: "https://github.com/ileitch/swift-indexstore", from: "9.0.4"),
    .package(url: "https://github.com/apple/swift-syntax", from: "509.1.0"),
    .package(url: "https://github.com/ileitch/swift-filename-matcher", from: "0.0.0"),
]

#if os(macOS)
dependencies.append(
    .package(
        url: "https://github.com/tuist/xcodeproj",
        from: "8.0.0"
    )
)
#endif

var frontendDependencies: [PackageDescription.Target.Dependency] = [
    .target(name: "Shared"),
    .target(name: "PeripheryKit"),
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
            .target(name: "Shared"),
            .product(name: "SystemPackage", package: "swift-system"),
            .product(name: "AEXML", package: "AEXML"),
            .product(name: "SwiftSyntax", package: "swift-syntax"),
            .product(name: "SwiftParser", package: "swift-syntax"),
            .product(name: "SwiftIndexStore", package: "swift-indexstore"),
            .product(name: "FilenameMatcher", package: "swift-filename-matcher")
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
    .target(
        name: "ExternalModuleFixtures",
        path: "Tests/Fixtures/ExternalModuleFixtures"
    ),
    .target(
        name: "CrossModuleRetentionFixtures",
        dependencies: [
            .target(name: "CrossModuleRetentionSupportFixtures")
        ],
        path: "Tests/Fixtures/CrossModuleRetentionFixtures"
    ),
    .target(
        name: "CrossModuleRetentionSupportFixtures",
        path: "Tests/Fixtures/CrossModuleRetentionSupportFixtures"
    ),
    .target(
        name: "RetentionFixtures",
        dependencies: [
            .target(name: "ExternalModuleFixtures")
        ],
        path: "Tests/Fixtures/RetentionFixtures"
    ),
    .target(
        name: "RemovalFixtures",
        path: "Tests/Fixtures/RemovalFixtures"
    ),
    .target(
        name: "UnusedParameterFixtures",
        path: "Tests/Fixtures/UnusedParameterFixtures",
        swiftSettings: [
            .unsafeFlags(["-suppress-warnings"]) // Suppress warnings from testLocalVariableAssignment
        ]
    ),
    .target(
        name: "TypeSyntaxInspectorFixtures",
        path: "Tests/Fixtures/TypeSyntaxInspectorFixtures"
    ),
    .target(
        name: "DeclarationVisitorFixtures",
        path: "Tests/Fixtures/DeclarationVisitorFixtures"
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
    ),
]

#if os(macOS)
targets.append(contentsOf: [
    .target(
        name: "XcodeSupport",
        dependencies: [
            .target(name: "Shared"),
            .target(name: "PeripheryKit"),
            .product(name: "XcodeProj", package: "XcodeProj"),
        ]
    ),
    .target(
        name: "ObjcAccessibleRetentionFixtures",
        path: "Tests/Fixtures/ObjcAccessibleRetentionFixtures"
    ),
    .target(
        name: "ObjcAnnotatedRetentionFixtures",
        path: "Tests/Fixtures/ObjcAnnotatedRetentionFixtures"
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
    ],
    dependencies: dependencies,
    targets: targets,
    swiftLanguageVersions: [.v5]
)
