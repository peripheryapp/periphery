import Foundation
import Shared

public struct SPM {
    public struct Package: Decodable {
        public static func load() throws -> Self {
            let shell: Shell = inject()
            let jsonString = try shell.exec(["swift", "package", "describe", "--type", "json"], stderr: false)

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

        func clean() throws {
            let shell: Shell = inject()
            try shell.exec(["swift", "package", "clean"])
        }
    }

    public struct Target: Decodable {
        public let name: String
        public let path: String
        public let sources: [String]
        public let moduleType: String

        func build(additionalArguments: [String]) throws {
            let shell: Shell = inject()
            var args: [String] = ["swift", "build", "--target", name] + additionalArguments

            if SwiftVersion.current.version.isVersion(lessThan: "5.4") {
                args.append("--enable-test-discovery")
            }

            try shell.exec(args)
        }
    }
}
