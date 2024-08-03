// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LocalPackage",
    products: [
        .library(
            name: "LocalPackageTarget",
            targets: ["LocalPackageTarget"])
    ],
    targets: [
        .target(
            name: "LocalPackageTarget",
            dependencies: [])
    ]
)
