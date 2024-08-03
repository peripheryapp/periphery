// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AccessibilityProject",
    platforms: [.macOS(.v13)],
    products: [
        .executable(
            name: "app",
            targets: ["MainTarget"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "MainTarget",
            dependencies: ["TargetA"]),
        .target(
            name: "ExternalTarget",
            dependencies: []),
        .target(
            name: "TargetA",
            dependencies: ["ExternalTarget"]),
        .testTarget(
            name: "TestTarget",
            dependencies: ["MainTarget", "TargetA"]),
    ]
)
