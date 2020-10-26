import Foundation

struct SPM {
    struct Package: Decodable {
        static func load() throws -> Self {
            let shell = Shell()
            let jsonString = try shell.exec(["swift", "package", "describe", "--type", "json"])

            guard let jsonData = jsonString.data(using: .utf8) else {
                throw PeripheryKitError.packageError(message: "Failed to read swift package description.")
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(Package.self, from: jsonData)
        }

        let name: String
        let path: String
        let targets: [Target]

        var swiftTargets: [Target] {
            targets.filter { $0.moduleType == "SwiftTarget" }
        }
    }

    struct Target: Decodable {
        let name: String
        let path: String
        let sources: [String]
        let moduleType: String

        func build() throws {
            let shell = Shell()
            try shell.exec(["swift", "build", "--target", name])
        }
    }
}
