// swift-tools-version:5.9
import PackageDescription

var targets: [PackageDescription.Target] = [
    .target(
        name: "ExternalModuleFixtures"
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
        name: "RetentionFixtures",
        dependencies: [
            .target(name: "ExternalModuleFixtures")
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
    )
])
#endif

let package = Package(
    name: "Fixtures",
    platforms: [.macOS(.v13)],
    targets: targets,
    swiftLanguageVersions: [.v5]
)
