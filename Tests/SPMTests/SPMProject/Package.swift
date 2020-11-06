// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "SPMProject",
    products: [
        .library(
            name: "SPMProject",
            targets: ["SPMProjectKit"]),
    ],
    targets: [
        .target(
            name: "SPMProjectKit",
            dependencies: []),
    ]
)
