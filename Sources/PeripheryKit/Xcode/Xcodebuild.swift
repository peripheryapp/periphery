import Foundation
import PathKit

// TODO: things hangs if e.g xcodebuild just prints its help options
public final class Xcodebuild: Injectable {
    private let shell: Shell

    public static func make() -> Self {
        return self.init(shell: inject())
    }

    required public init(shell: Shell) {
        self.shell = shell
    }

    private static var version: String?

    func version() throws -> String {
        if let version = Xcodebuild.version {
            return version
        }

        let version = try exec(["xcodebuild", "-version"]).trimmed
        Xcodebuild.version = version
        return version
    }

    func clearDerivedData(for project: XcodeProjectlike) throws {
        let old = try oldDerivedDataPath()

        if old.exists {
            try exec(["rm", "-rf", old.string])
        }

        try exec(["rm", "-rf", try derivedDataPath(for: project).string])
    }

    @discardableResult
    func build(project: XcodeProjectlike, scheme: String, additionalArguments: String?, buildForTesting: Bool = false) throws -> String {
        let cmd = buildForTesting ? "build-for-testing" : "build"

        var args = [
            "-\(project.type)", project.path.absolute().string,
            "-scheme", scheme,
            "-parallelizeTargets",
            "-derivedDataPath", "'\(try derivedDataPath(for: project).string)'",
        ]

        if let additionalArguments = additionalArguments {
            args.append(additionalArguments)
        }

        let envs = [
            "CODE_SIGNING_ALLOWED=\"NO\"",
            "ENABLE_BITCODE=\"NO\"",
            "SWIFT_COMPILATION_MODE=\"wholemodule\"",
            "DEBUG_INFORMATION_FORMAT=\"dwarf\""
        ]

        let xcodebuild = "xcodebuild \((args + [cmd] + envs).joined(separator: " "))"

        return try exec(["/bin/sh", "-c", xcodebuild])
    }

    func schemes(project: XcodeProjectlike) throws -> [String] {
        return try schemes(type: project.type, path: project.path.absolute().string)
    }

    func schemes(type: String, path: String) throws -> [String] {
        let args = [
            "-\(type)", path,
            "-list",
            "-json"
        ]

        let lines = try exec(["xcodebuild"] + args, stderr: false).split(separator: "\n").map { String($0) }

        // xcodebuild may output unrelated warnings, we need to strip it out otherwise
        // JSON parsing will fail.
        // Note: this is likely not needed since `stderr: false` was added, but we might as well
        // keep it.
        let startIndex = lines.firstIndex { $0.trimmed == "{" }
        let jsonString = lines.suffix(from: startIndex ?? 0).joined()

        guard let jsonData = jsonString.data(using: .utf8),
            let json = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
            let details = json[type] as? [String: Any],
            let schemes = details["schemes"] as? [String] else { return [] }

        return schemes
    }

    func buildSettings(for project: XcodeProjectlike, scheme: String) throws -> String {
        let args = [
            "-\(project.type)", project.path.absolute().string,
            "-showBuildSettings",
            "-scheme", scheme
        ]

        do {
            // Schemes that are not configured for testing will result in an error if the 'test'
            // action is supplied.
            // Note: we don't use -skipUnavailableActions here as it returns incorrect output.
            return try exec(["xcodebuild"] + args + ["build", "test"], stderr: false)
        } catch PeripheryKitError.shellCommandFailed(args: _, status: _, output: _) {
            return try exec(["xcodebuild"] + args + ["build"], stderr: false)
        }
    }

    func buildSettings(for project: XcodeProjectlike, target: String, configuration: String? = nil, xcconfig: Path? = nil) throws -> String {
        var args = [
            "-\(project.type)", project.path.absolute().string,
            "-showBuildSettings",
            "-target", target
        ]

        if let configuration = configuration {
            args.append(contentsOf: ["-configuration", configuration])
        }

        if let xcconfig = xcconfig {
            args.append(contentsOf: ["-xcconfig", xcconfig.absolute().string])
        }

        return try exec(["xcodebuild"] + args + ["build"], stderr: false)
    }

    // MARK: - Private

    private func derivedDataPath(for project: XcodeProjectlike) throws -> Path {
        let normalizedName = project.name.sha1()
        return try (PeripheryCachePath() + "DerivedData-\(normalizedName)")
    }

    private func oldDerivedDataPath() throws -> Path {
        return try (PeripheryCachePath() + "DerivedData")
    }

    @discardableResult
    private func exec(_ args: [String], stderr: Bool = true) throws -> String {
        let env = ProcessInfo.processInfo.environment
        let newEnv = env.filter {
            if ["CURRENT_ARCH", "arch"].contains($0.key) && $0.value == "undefined_arch" {
                return false
            }

            return true
        }

        return try shell.exec(args, stderr: stderr, env: newEnv)
    }
}
