// swift-tools-version:5.3
import PackageDescription

// Use the appropriate version of SwiftSyntax based on the current compiler
#if compiler(>=5.5)
let swiftSyntaxVersion: Package.Dependency.Requirement = .exact("0.50600.1")
#elseif compiler(>=5.4)
let swiftSyntaxVersion: Package.Dependency.Requirement = .exact("0.50400.0")
#elseif compiler(>=5.3)
let swiftSyntaxVersion: Package.Dependency.Requirement = .exact("0.50300.0")
#else
fatalError("This version of Periphery does not support Swift <= 5.2.")
#endif

var dependencies: [Package.Dependency] = [
    .package(url: "https://github.com/apple/swift-system", from: "1.0.0"),
    .package(url: "https://github.com/jpsim/Yams", from: "4.0.0"),
    .package(url: "https://github.com/tadija/AEXML", from: "4.0.0"),
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
    .package(name: "SwiftIndexStore", url: "https://github.com/kateinoigakukun/swift-indexstore", from: "0.0.0"),
    .package(name: "SwiftSyntax", url: "https://github.com/apple/swift-syntax", swiftSyntaxVersion)
]

// When on macOS, using SwiftSyntax for 5.6, also include StaticSwiftSyntaxParser to statically link internal dependencies
#if os(macOS) && compiler(>=5.5)
dependencies.append(
    .package(
        name: "StaticSwiftSyntaxParser",
        url: "https://gist.github.com/liamnichols/92f8fdcf2864d0fd1619a18828acafb8.git",
        .branch("main")
    )
)
#endif

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

// Using Swift 5.5+, we need the SwiftSyntaxParser library, but on macOS specifically we also want to use the statically linked version
#if os(macOS) && compiler(>=5.5)
peripheryKitDependencies.append(.product(name: "StaticSwiftSyntaxParser", package: "StaticSwiftSyntaxParser"))
#elseif compiler(>=5.5)
peripheryKitDependencies.append(.product(name: "SwiftSyntaxParser", package: "SwiftSyntax"))
#endif

var targets: [PackageDescription.Target] = [
    .target(
        name: "Frontend",
        dependencies: frontendDependencies
    ),
    .target(
        name: "PeripheryKit",
        dependencies: peripheryKitDependencies
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
