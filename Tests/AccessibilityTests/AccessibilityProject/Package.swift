// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "AccessibilityProject",
    products: [
        .executable(
            name: "app",
            targets: ["MainTarget"]
        ),
    ],
    targets: [
        .target(
            name: "MainTarget",
            dependencies: ["TargetA"]),
        .target(
            name: "TargetA",
            dependencies: []),
        .testTarget(
            name: "TestTarget",
            dependencies: ["MainTarget", "TargetA"]),
    ]
)
