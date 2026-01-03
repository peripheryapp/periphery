// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SPMProjectMacOS",
    platforms: [.macOS(.v13)],
    products: [
        .executable(
            name: "frontend",
            targets: ["Frontend"]
        ),
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Frontend",
            dependencies: ["SPMProjectMacOSKit"]
        ),
        .target(
            name: "SPMProjectMacOSKit",
            resources: [.process("Resources")]
        ),
    ]
)
