import Foundation
import SystemPackage
import Shared

public struct SPM {
    static let packageFile = "Package.swift"

    public static var isSupported: Bool {
        FilePath.current.appending(packageFile).exists
    }

    public struct Package: Decodable {
        public static func load(jsonPackageManifestPath: String? = nil) throws -> Self {
            Logger().contextualized(with: "spm:package").debug("Loading \(FilePath.current)")

            let jsonData: Data

            if let jsonPackageManifestPath {
                jsonData = try Data(contentsOf: URL(fileURLWithPath: jsonPackageManifestPath))
            } else {
                let jsonString = try Shell.shared.exec(["swift", "package", "describe", "--type", "json"], stderr: false)

                guard let data = jsonString.data(using: .utf8) else {
                    throw PeripheryError.packageError(message: "Failed to read swift package description.")
                }

                jsonData = data
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(Package.self, from: jsonData)
        }

        public let name: String
        public let path: String
        public let targets: [Target]

        public var swiftTargets: [Target] {
            targets.filter(\.isSwiftTarget)
        }

        func clean() throws {
            try Shell.shared.exec(["swift", "package", "clean"])
        }
    }

    public struct Target: Decodable {
        public let name: String

        let sources: [String]
        let path: String
        let moduleType: String
        let type: String

        public var sourcePaths: [FilePath] {
            let root = FilePath(path)
            return sources.map { root.appending($0) }
        }

        func build(additionalArguments: [String]) throws {
            let args: [String] = ["swift", "build", "--target", name] + additionalArguments
            try Shell.shared.exec(args)
        }

        var isSwiftTarget: Bool {
            moduleType == "SwiftTarget"
        }

        public var isTestTarget: Bool {
            type == "test"
        }
    }
}

extension SPM.Package: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(path)
    }
}

extension SPM.Package: Equatable {
    public static func == (lhs: SPM.Package, rhs: SPM.Package) -> Bool {
        lhs.path == rhs.path
    }
}

extension SPM.Target: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

extension SPM.Target: Equatable {
    public static func == (lhs: SPM.Target, rhs: SPM.Target) -> Bool {
        lhs.name == rhs.name
    }
}
