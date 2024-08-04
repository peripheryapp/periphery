import Foundation
import SystemPackage
import Shared

public struct SPM {
    static let packageFile = "Package.swift"

    public static var isSupported: Bool {
        Package().exists
    }

    public struct Package {
        let path: FilePath = .current
        let configuration: Configuration = .shared

        var exists: Bool {
            path.appending(packageFile).exists
        }

        func clean() throws {
            try Shell.shared.exec(["swift", "package", "clean"])
        }

        func build(additionalArguments: [String]) throws {
            try Shell.shared.exec(["swift", "build", "--build-tests"] + additionalArguments)
        }

        func testTargetNames() throws -> Set<String> {
            let description = try load()
            return description.targets.filter(\.isTestTarget).mapSet(\.name)
        }

        // MARK: - Private

        private func load() throws -> PackageDescription {
            Logger().contextualized(with: "spm:package").debug("Loading \(FilePath.current)")

            let jsonData: Data

            if let path = configuration.jsonPackageManifestPath {
                jsonData = try Data(contentsOf: URL(fileURLWithPath: path))
            } else {
                let jsonString = try Shell.shared.exec(["swift", "package", "describe", "--type", "json"], stderr: false)

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

struct PackageDescription: Decodable {
    let targets: [Target]
}

struct Target: Decodable {
    let name: String
    let type: String

    var isTestTarget: Bool {
        type == "test"
    }
}
