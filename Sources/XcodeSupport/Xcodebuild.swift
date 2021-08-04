import Foundation
import SystemPackage
import PeripheryKit
import Shared

public final class Xcodebuild: Injectable {
    private let shell: Shell

    public static func make() -> Self {
        return self.init(shell: inject())
    }

    required init(shell: Shell) {
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
    func build(project: XcodeProjectlike, scheme: XcodeScheme, allSchemes: [XcodeScheme], additionalArguments: [String] = [], buildForTesting: Bool = false) throws -> String {
        let cmd = buildForTesting ? "build-for-testing" : "build"
        let args = [
            "-\(project.type)", "'\(project.path.lexicallyNormalized().string)'",
            "-scheme", "'\(scheme.name)'",
            "-parallelizeTargets",
            "-derivedDataPath", "'\(try derivedDataPath(for: project, schemes: allSchemes).string)'",
            "-quiet"
        ]
        let envs = [
            "CODE_SIGNING_ALLOWED=\"NO\"",
            "ENABLE_BITCODE=\"NO\"",
            "DEBUG_INFORMATION_FORMAT=\"dwarf\""
        ]

        let xcodebuild = "xcodebuild \((args + [cmd] + envs + additionalArguments).joined(separator: " "))"
        return try shell.exec(["/bin/sh", "-c", xcodebuild])
    }

    func removeDerivedData(for project: XcodeProjectlike, allSchemes: [XcodeScheme]) throws {
        try shell.exec(["rm", "-rf", try derivedDataPath(for: project, schemes: allSchemes).string])
    }

    func indexStorePath(project: XcodeProjectlike, schemes: [XcodeScheme]) throws -> String {
        (try derivedDataPath(for: project, schemes: schemes).appending("Index/DataStore")).string
    }

    func schemes(project: XcodeProjectlike) throws -> [String] {
        return try schemes(type: project.type, path: project.path.lexicallyNormalized().string)
    }

    func schemes(type: String, path: String) throws -> [String] {
        let args = [
            "-\(type)", path,
            "-list",
            "-json"
        ]

        let lines = try shell.exec(["xcodebuild"] + args, stderr: false).split(separator: "\n").map { String($0) }

        // xcodebuild may output unrelated warnings, we need to strip it out otherwise
        // JSON parsing will fail.
        // Note: this is likely not needed since `stderr: false` was added, but we might as well
        // keep it.
        let startIndex = lines.firstIndex { $0.trimmed == "{" }
        let jsonString = lines.suffix(from: startIndex ?? 0).joined(separator: "\n")

        guard let json = try deserialize(jsonString),
            let details = json[type] as? [String: Any],
            let schemes = details["schemes"] as? [String] else { return [] }

        return schemes
    }

    func buildSettings(for project: XcodeProjectlike, scheme: String) throws -> String {
        let args = [
            "-\(project.type)", project.path.lexicallyNormalized().string,
            "-showBuildSettings",
            "-scheme", scheme
        ]

        do {
            // Schemes that are not configured for testing will result in an error if the 'test'
            // action is supplied.
            // Note: we don't use -skipUnavailableActions here as it returns incorrect output.
            return try shell.exec(["xcodebuild"] + args + ["build", "test"], stderr: false)
        } catch PeripheryError.shellCommandFailed(_, _, _,  _) {
            return try shell.exec(["xcodebuild"] + args + ["build"], stderr: false)
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

    private func derivedDataPath(for project: XcodeProjectlike, schemes: [XcodeScheme]) throws -> FilePath {
        // Given a project with two schemes: A and B, a scenario can arise where the index store contains conflicting
        // data. If scheme A is built, then the source file modified and then scheme B built, the index store will
        // contain two records for that source file. One reflects the state of the file when scheme A was built, and the
        // other when B was built. We must therefore key the DerivedData path with the full list of schemes being built.

        let projectHash = project.name.djb2Hex
        let schemesHash = schemes.map { $0.name }.joined().djb2Hex
        return try (cachePath().appending("DerivedData-\(projectHash)-\(schemesHash)"))
    }

    private func cachePath() throws -> FilePath {
        let url = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return FilePath(url.appendingPathComponent("com.github.peripheryapp").path)
    }
}
