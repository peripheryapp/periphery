// swift-tools-version: 5.10
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
