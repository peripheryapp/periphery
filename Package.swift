// swift-tools-version:5.5
import PackageDescription

#if os(macOS)
private let staticSwiftSyntax = true
#else
private let staticSwiftSyntax = false
#endif

#if compiler(>=5.7)
let swiftSyntaxVersion: Version = "0.50700.0"
let staticInternalSwiftSyntaxParserVersion = "5.7"
let staticInternalSwiftSyntaxParserChecksum = "99803975d10b2664fc37cc223a39b4e37fe3c79d3d6a2c44432007206d49db15"
#else
fatalError("This version of Periphery requires Swift >= 5.7 to build from source.")
#endif

var dependencies: [Package.Dependency] = [
    .package(url: "https://github.com/apple/swift-system", from: "1.0.0"),
    .package(url: "https://github.com/jpsim/Yams", from: "5.0.0"),
    .package(url: "https://github.com/tadija/AEXML", from: "4.0.0"),
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
    .package(name: "SwiftIndexStore", url: "https://github.com/kateinoigakukun/swift-indexstore", from: "0.0.0"),
    .package(name: "SwiftSyntax", url: "https://github.com/apple/swift-syntax.git", .exact(swiftSyntaxVersion))
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
    .product(name: "SwiftSyntaxParser", package: "SwiftSyntax"),
    .product(name: "SwiftIndexStore", package: "SwiftIndexStore")
]
+ (staticSwiftSyntax ? ["lib_InternalSwiftSyntaxParser"] : [])

var targets: [PackageDescription.Target] = [
    .executableTarget(
        name: "Frontend",
        dependencies: frontendDependencies
    ),
    .target(
        name: "PeripheryKit",
        dependencies: peripheryKitDependencies,
        // Pass `-dead_strip_dylibs` to ignore the dynamic version of `lib_InternalSwiftSyntaxParser`
        // that ships with SwiftSyntax because we want the static version from
        // `StaticInternalSwiftSyntaxParser`.
        linkerSettings: staticSwiftSyntax ? [.unsafeFlags(["-Xlinker", "-dead_strip_dylibs"])] : []
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
    ),
    .binaryTarget(
        name: "lib_InternalSwiftSyntaxParser",
        url: "https://github.com/keith/StaticInternalSwiftSyntaxParser/releases/download/\(staticInternalSwiftSyntaxParserVersion)/lib_InternalSwiftSyntaxParser.xcframework.zip",
        checksum: staticInternalSwiftSyntaxParserChecksum
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
