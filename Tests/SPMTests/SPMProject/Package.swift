// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "SPMProject",
    products: [
        .executable(
            name: "frontend",
            targets: ["Frontend", "SPMProjectKit"]
        )
    ],
    targets: [
        .target(
            name: "SPMProjectKit",
            dependencies: []),
        .target(
            name: "Frontend",
            dependencies: [])
    ]
)
