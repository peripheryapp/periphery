import Foundation
import SystemPackage
import Shared

public struct SPM {
    static let packageFile = "Package.swift"

    public static var isSupported: Bool {
        FilePath.current.appending(packageFile).exists
    }

    public struct Package: Decodable {
        public static func load() throws -> Self {
            let jsonString = try Shell.shared.exec(["swift", "package", "describe", "--type", "json"], stderr: false)

            guard let jsonData = jsonString.data(using: .utf8) else {
                throw PeripheryError.packageError(message: "Failed to read swift package description.")
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(Package.self, from: jsonData)
        }

        public let name: String

        let targets: [Target]
        let path: String

        public var swiftTargets: [Target] {
            targets.filter { $0.moduleType == "SwiftTarget" }
        }

        func clean() throws {
            try Shell.shared.exec(["swift", "package", "clean"])
        }
    }

    public struct Target: Decodable {
        public let name: String

        let path: String
        let moduleType: String
        let sources: [String]

        func build(additionalArguments: [String]) throws {
            let args: [String] = ["swift", "build", "--target", name] + additionalArguments
            try Shell.shared.exec(args)
        }
    }
}
