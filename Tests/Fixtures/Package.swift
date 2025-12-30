// swift-tools-version:5.10
import PackageDescription

var targets: [PackageDescription.Target] = [
    .target(
        name: "ExternalModuleFixtures"
    ),
    .target(
        name: "UnusedModuleFixtures"
    ),
    .target(
        name: "CrossModuleRetentionFixtures",
        dependencies: [
            .target(name: "CrossModuleRetentionSupportFixtures")
        ]
    ),
    .target(
        name: "CrossModuleRetentionSupportFixtures"
    ),
    .target(
        name: "UnusedImportFixtureA",
        path: "Sources/UnusedImportFixtures/A"
    ),
    .target(
        name: "UnusedImportFixtureB",
        dependencies: [
            .target(name: "UnusedImportFixtureA")
        ],
        path: "Sources/UnusedImportFixtures/B"
    ),
    .target(
        name: "UnusedImportFixtureC",
        dependencies: [
            .target(name: "UnusedImportFixtureA")
        ],
        path: "Sources/UnusedImportFixtures/C"
    ),
    .target(
        name: "UnusedImportFixtureD",
        dependencies: [
            .target(name: "UnusedImportFixtureA"),
            .target(name: "UnusedImportFixtureB"),
            .target(name: "UnusedImportFixtureC")
        ],
        path: "Sources/UnusedImportFixtures/D"
    ),
    .target(
        name: "RetentionFixtures",
        dependencies: [
            .target(name: "ExternalModuleFixtures"),
            .target(name: "UnusedModuleFixtures")
        ]
    ),
    .target(
        name: "UnusedParameterFixtures",
        swiftSettings: [
            .unsafeFlags(["-suppress-warnings"]) // Suppress warnings from testLocalVariableAssignment
        ]
    ),
    .target(
        name: "TypeSyntaxInspectorFixtures"
    ),
    .target(
        name: "DeclarationVisitorFixtures"
    ),
]

#if os(macOS)
targets.append(contentsOf: [
    .target(
        name: "ObjcAccessibleRetentionFixtures"
    ),
    .target(
        name: "ObjcAnnotatedRetentionFixtures"
    ),
    .target(
        name: "AppIntentsRetentionFixtures"
    )
])
#endif

let package = Package(
    name: "Fixtures",
    platforms: [.macOS(.v13)],
    targets: targets,
    swiftLanguageVersions: [.v5]
)
