// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "linux-bug",
    products: [
        .executable(
            name: "linux-bug",
            targets: ["linux-bug"]),
    ],
    targets: [
        .target(
            name: "linux-bug"),
    ]
)
