import Configuration
import Extensions
import Foundation
import Logger
import Shared
import SystemPackage

public enum SPM {
    public static var isSupported: Bool {
        FilePath.current.appending("Package.swift").exists
    }

    public struct Package {
        public let path: FilePath = .current

        private let configuration: Configuration
        private let shell: Shell
        private let logger: Logger

        public init(configuration: Configuration, shell: Shell, logger: Logger) {
            self.configuration = configuration
            self.shell = shell
            self.logger = logger
        }

        public func clean() throws {
            try shell.exec(["swift", "package", "clean"])
        }

        public func build(additionalArguments: [String]) throws {
            try shell.exec(["swift", "build", "--build-tests"] + additionalArguments)
        }

        public func load() throws -> PackageDescription {
            logger.contextualized(with: "spm:package").debug("Loading \(FilePath.current)")

            let jsonData: Data

            if let path = configuration.jsonPackageManifestPath {
                jsonData = try Data(contentsOf: path.url)
            } else {
                let jsonString = try shell.exec(["swift", "package", "describe", "--type", "json"])

                guard let data = jsonString.data(using: .utf8) else {
                    throw PeripheryError.packageError(message: "Failed to read swift package description.")
                }

                jsonData = data
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(PackageDescription.self, from: jsonData)
        }
    }
}

public struct PackageDescription: Decodable {
    public let targets: [Target]
}

public struct Target: Decodable {
    public let name: String
    public let type: String
    public let path: String
    public let resources: [Resource]?

    public var isTestTarget: Bool {
        type == "test"
    }
}

public struct Resource: Decodable {
    public let path: String
}
