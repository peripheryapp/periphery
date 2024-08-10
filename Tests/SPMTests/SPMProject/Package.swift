// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SPMProject",
    products: [
        .executable(
            name: "frontend",
            targets: ["Frontend"]
        )
    ],
    targets: [
        .executableTarget(
            name: "Frontend",
            dependencies: ["SPMProjectKit"]),
        .target(
            name: "SPMProjectKit",
            dependencies: [])
    ]
)
