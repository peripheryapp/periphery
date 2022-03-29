// swift-tools-version:5.2
import PackageDescription

var dependencies: [Package.Dependency] = [
    .package(url: "https://github.com/apple/swift-system", from: "1.0.0"),
    .package(url: "https://github.com/jpsim/Yams", from: "4.0.0"),
    .package(url: "https://github.com/tadija/AEXML", from: "4.0.0"),
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
    .package(name: "SwiftIndexStore", url: "https://github.com/kateinoigakukun/swift-indexstore", from: "0.0.0"),
    .package(name: "SwiftSyntax", url: "https://github.com/apple/swift-syntax", .exact("0.50600.1"))
]

#if os(macOS)
dependencies.append(
    .package(
        name: "XcodeProj",
        url: "https://github.com/tuist/xcodeproj",
        from: "8.0.0"
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

var peripheryKitDependencies: [PackageDescription.Target.Dependency] = [
    .target(name: "Shared"),
    .product(name: "SystemPackage", package: "swift-system"),
    .product(name: "AEXML", package: "AEXML"),
    .product(name: "SwiftSyntax", package: "SwiftSyntax"),
    .product(name: "SwiftIndexStore", package: "SwiftIndexStore")
]

#if swift(>=5.6)
peripheryKitDependencies.append(
    .product(
        name: "SwiftSyntaxParser",
        package: "SwiftSyntax"
    )
)
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
            .product(name: "SystemPackage", package: "swift-system"),
            .product(name: "AEXML", package: "AEXML"),
            .product(name: "SwiftSyntax", package: "SwiftSyntax"),
            .product(name: "SwiftSyntaxParser", package: "SwiftSyntax"),
            .target(name: "lib_InternalSwiftSyntaxParser"),
            .product(name: "SwiftIndexStore", package: "SwiftIndexStore")
        ],
        // Pass `-dead_strip_dylibs` to ignore the dynamic version of `lib_InternalSwiftSyntaxParser`
        // that ships with SwiftSyntax because we want the static version from
        // `StaticInternalSwiftSyntaxParser`.
        linkerSettings: [
            .unsafeFlags(["-Xlinker", "-dead_strip_dylibs"])
        ]
    ),
    .target(
        name: "Shared",
        dependencies: [
            .product(name: "Yams", package: "Yams"),
            .product(name: "SystemPackage", package: "swift-system")
        ]
    ),
    .target(
        name: "ExternalModuleFixtures"
    ),
    .target(
        name: "CrossModuleRetentionFixtures"
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
        dependencies: ["ExternalModuleFixtures", "CrossModuleRetentionFixtures"],
        path: "Tests/Fixtures/RetentionFixtures"
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
    .binaryTarget(
        name: "lib_InternalSwiftSyntaxParser",
        url: "https://github.com/keith/StaticInternalSwiftSyntaxParser/releases/download/5.6/lib_InternalSwiftSyntaxParser.xcframework.zip",
        checksum: "88d748f76ec45880a8250438bd68e5d6ba716c8042f520998a438db87083ae9d"
    )
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
        name: "ObjcRetentionFixtures",
        path: "Tests/Fixtures/ObjcRetentionFixtures"
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
    products: [
        .executable(name: "periphery", targets: ["Frontend"])
    ],
    dependencies: dependencies,
    targets: targets,
    swiftLanguageVersions: [.v5]
)
