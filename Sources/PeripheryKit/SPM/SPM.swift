import Foundation
import Shared

public struct SPM {
    public struct Package: Decodable {
        public static func load() throws -> Self {
            let shell = Shell()
            let jsonString = try shell.exec(["swift", "package", "describe", "--type", "json"])

            guard let jsonData = jsonString.data(using: .utf8) else {
                throw PeripheryError.packageError(message: "Failed to read swift package description.")
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(Package.self, from: jsonData)
        }

        public let name: String
        public let path: String
        public let targets: [Target]

        public var swiftTargets: [Target] {
            targets.filter { $0.moduleType == "SwiftTarget" }
        }
    }

    public struct Target: Decodable {
        public let name: String
        public let path: String
        public let sources: [String]
        public let moduleType: String

        func build() throws {
            let shell = Shell()
            try shell.exec(["swift", "build", "--enable-test-discovery", "--target", name])
        }
    }
}
