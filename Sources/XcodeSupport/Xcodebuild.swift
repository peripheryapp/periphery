import Foundation
import SystemPackage
import PeripheryKit
import Shared

public final class Xcodebuild {
    private let shell: Shell

    public required init(shell: Shell = .shared) {
        self.shell = shell
    }

    private static var version: String?

    public func version() throws -> String {
        if let version = Xcodebuild.version {
            return version
        }

        let version = try shell.exec(["xcodebuild", "-version"]).trimmed
        Xcodebuild.version = version
        return version
    }

    @discardableResult
    func build(project: XcodeProjectlike, scheme: String, allSchemes: [String], additionalArguments: [String] = [], buildForTesting: Bool = false) throws -> String {
        let cmd = buildForTesting ? "build-for-testing" : "build"
        let args = [
            "-\(project.type)", "'\(project.path.lexicallyNormalized().string)'",
            "-scheme", "'\(scheme)'",
            "-parallelizeTargets",
            "-derivedDataPath", "'\(try derivedDataPath(for: project, schemes: allSchemes).string)'",
            "-quiet"
        ]
        let envs = [
            "CODE_SIGNING_ALLOWED=\"NO\"",
            "ENABLE_BITCODE=\"NO\"",
            "DEBUG_INFORMATION_FORMAT=\"dwarf\"",
            "COMPILER_INDEX_STORE_ENABLE=\"YES\"",
            "INDEX_ENABLE_DATA_STORE=\"YES\""
        ]

        let xcodebuild = "xcodebuild \((args + [cmd] + envs + additionalArguments).joined(separator: " "))"
        return try shell.exec(["/bin/sh", "-c", xcodebuild])
    }

    func removeDerivedData(for project: XcodeProjectlike, allSchemes: [String]) throws {
        try shell.exec(["rm", "-rf", try derivedDataPath(for: project, schemes: allSchemes).string])
    }

    func indexStorePath(project: XcodeProjectlike, schemes: [String]) throws -> FilePath {
        let derivedDataPath = try derivedDataPath(for: project, schemes: schemes)
        let pathsToTry = ["Index.noindex/DataStore", "Index/DataStore"]
            .map { derivedDataPath.appending($0) }
        guard let path = pathsToTry.first(where: { $0.exists }) else {
            throw PeripheryError.indexStoreNotFound(derivedDataPath: derivedDataPath.string)
        }
        return path
    }

    func schemes(project: XcodeProjectlike) throws -> Set<String> {
        try schemes(type: project.type, path: project.path.lexicallyNormalized().string)
    }

    func schemes(type: String, path: String) throws -> Set<String> {
        let args = [
            "-\(type)", path,
            "-list",
            "-json"
        ]

        let lines = try shell.exec(["xcodebuild"] + args, stderr: false).split(separator: "\n").map { String($0).trimmed }

        // xcodebuild may output unrelated warnings, we need to strip them out otherwise
        // JSON parsing will fail.
        let startIndex = lines.firstIndex { $0 == "{" } ?? 0
        var jsonLines = lines.suffix(from: startIndex)

        if let lastIndex = jsonLines.lastIndex(where: { $0 == "}" }) {
            jsonLines = jsonLines.prefix(upTo: lastIndex + 1)
        }

        let jsonString = jsonLines.joined(separator: "\n")

        guard let json = try deserialize(jsonString),
            let details = json[type] as? [String: Any],
            let schemes = details["schemes"] as? [String] else { return [] }

        return Set(schemes)
    }

    func buildSettings(targets: Set<XcodeTarget>) throws -> [XcodeBuildAction] {
        try targets
            .reduce(into: [XcodeProject: Set<String>]()) { result, target in
                result[target.project, default: []].insert(target.name)
            }
            .reduce(into: [XcodeBuildAction]()) { result, pair in
                let (project, targets) = pair
                let args = [
                    "-project", project.path.lexicallyNormalized().string,
                    "-showBuildSettings",
                    "-json"
                ] + targets.flatMap { ["-target", $0] }

                let output = try shell.exec(["xcodebuild"] + args, stderr: false)

                guard let data = output.data(using: .utf8) else { return }

                let decoder = JSONDecoder()
                let actions = try decoder.decode([XcodeBuildAction].self, from: data)
                result.append(contentsOf: actions)
            }
    }

    // MARK: - Private

    private func deserialize(_ jsonString: String) throws -> [String: Any]? {
        do {
            guard let jsonData = jsonString.data(using: .utf8) else { return nil }
            return try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any]
        } catch {
            throw PeripheryError.jsonDeserializationError(error: error, json: jsonString)
        }
    }

    private func derivedDataPath(for project: XcodeProjectlike, schemes: [String]) throws -> FilePath {
        // Given a project with two schemes: A and B, a scenario can arise where the index store contains conflicting
        // data. If scheme A is built, then the source file modified and then scheme B built, the index store will
        // contain two records for that source file. One reflects the state of the file when scheme A was built, and the
        // other when B was built. We must therefore key the DerivedData path with the full list of schemes being built.

        let xcodeVersionHash = try version().djb2Hex
        let projectHash = project.name.djb2Hex
        let schemesHash = schemes.map { $0 }.joined().djb2Hex

        return try Constants.cachePath().appending("DerivedData-\(xcodeVersionHash)-\(projectHash)-\(schemesHash)")
    }
}
