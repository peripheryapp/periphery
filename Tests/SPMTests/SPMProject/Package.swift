import CompilerPluginSupport

// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SPMProject",
    platforms: [.macOS(.v13)],
    products: [
        .executable(
            name: "frontend",
            targets: ["Frontend"],
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax", from: "601.0.1"),
    ],
    targets: [
        .executableTarget(
            name: "Frontend",
            dependencies: ["SPMProjectKit"],
        ),
        .target(
            name: "SPMProjectKit",
            dependencies: ["SPMProjectMacros"],
        ),
        .macro(
            name: "SPMProjectMacros",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ],
        ),
        .testTarget(
            name: "Tests",
            dependencies: ["SPMProjectKit"],
        ),
    ],
)
