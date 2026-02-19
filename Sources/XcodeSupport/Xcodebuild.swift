import Foundation
import Logger
import Shared
import SystemPackage

public final class Xcodebuild {
    private let shell: Shell
    private let logger: Logger

    public required init(shell: Shell, logger: Logger) {
        self.shell = shell
        self.logger = logger
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

    public func ensureConfigured() throws {
        do {
            try logger.debug(version())
        } catch {
            throw PeripheryError.xcodebuildNotConfigured
        }
    }

    @discardableResult
    public func build(project: XcodeProjectlike, scheme: String, allSchemes: [String], additionalArguments: [String] = []) throws -> String {
        let args = try [
            "-\(project.type)", "\"\(project.path.lexicallyNormalized().string.withEscapedQuotes)\"",
            "-scheme", "\"\(scheme.withEscapedQuotes)\"",
            "-parallelizeTargets",
            "-derivedDataPath", "'\(derivedDataPath(for: project, schemes: allSchemes).string)'",
            "-quiet",
            "build-for-testing",
        ]
        let envs = [
            "CODE_SIGNING_ALLOWED=\"NO\"",
            "ENABLE_BITCODE=\"NO\"",
            "DEBUG_INFORMATION_FORMAT=\"dwarf\"",
            "COMPILER_INDEX_STORE_ENABLE=\"YES\"",
            "INDEX_ENABLE_DATA_STORE=\"YES\"",
        ]

        let quotedArguments = quote(arguments: additionalArguments)
        let xcodebuild = ["xcodebuild"] + args + envs + quotedArguments
        return try shell.exec(xcodebuild)
    }

    public func removeDerivedData(for project: XcodeProjectlike, allSchemes: [String]) throws {
        try shell.exec(["rm", "-rf", derivedDataPath(for: project, schemes: allSchemes).string])
    }

    public func indexStorePath(project: XcodeProjectlike, schemes: [String]) throws -> FilePath {
        let derivedDataPath = try derivedDataPath(for: project, schemes: schemes)

        if let path = findIndexStorePath(in: derivedDataPath) {
            return path
        }

        // Periphery's own DerivedData may not exist when --skip-build is used and
        // the project was built by Xcode or xcodebuild. Fall back to searching
        // Xcode's default DerivedData location for a matching project directory.
        if let path = findIndexStoreInDefaultDerivedData(projectName: project.name) {
            return path
        }

        throw PeripheryError.indexStoreNotFound(derivedDataPath: derivedDataPath.string)
    }

    func schemes(project: XcodeProjectlike, additionalArguments: [String]) throws -> Set<String> {
        try schemes(
            type: project.type,
            path: project.path.lexicallyNormalized().string,
            additionalArguments: additionalArguments
        )
    }

    func schemes(type: String, path: String, additionalArguments: [String]) throws -> Set<String> {
        let args = [
            "-\(type)", "\"\(path.withEscapedQuotes)\"",
            "-list",
            "-json",
        ]

        let quotedArguments = quote(arguments: additionalArguments)
        let xcodebuild = ["xcodebuild"] + args + quotedArguments
        let lines = try shell.exec(xcodebuild).split(separator: "\n").map { String($0).trimmed }

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

    // MARK: - Private

    private func deserialize(_ jsonString: String) throws -> [String: Any]? {
        do {
            guard let jsonData = jsonString.data(using: .utf8) else { return nil }

            return try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any]
        } catch {
            throw PeripheryError.jsonDeserializationError(error: error, json: jsonString)
        }
    }

    func findIndexStorePath(in derivedDataPath: FilePath) -> FilePath? {
        ["Index.noindex/DataStore", "Index/DataStore"]
            .map { derivedDataPath.appending($0) }
            .first { $0.exists }
    }

    func findIndexStoreInDefaultDerivedData(projectName: String) -> FilePath? {
        let defaultDerivedData = FilePath(
            NSHomeDirectory()
        ).appending("Library/Developer/Xcode/DerivedData")

        return findIndexStoreInDerivedData(projectName: projectName, derivedDataRoot: defaultDerivedData)
    }

    func findIndexStoreInDerivedData(projectName: String, derivedDataRoot: FilePath) -> FilePath? {
        guard derivedDataRoot.exists else { return nil }

        // Xcode names DerivedData subdirectories as "<ProjectName>-<hash>".
        // Find the most recently modified one matching the project name.
        let fm = FileManager.default
        guard let entries = try? fm.contentsOfDirectory(atPath: derivedDataRoot.string) else {
            return nil
        }

        let candidates = entries
            .filter { $0.hasPrefix("\(projectName)-") }
            .compactMap { entry -> (path: FilePath, modified: Date)? in
                let entryPath = derivedDataRoot.appending(entry)
                guard let attrs = try? fm.attributesOfItem(atPath: entryPath.string),
                      let modified = attrs[.modificationDate] as? Date else {
                    return nil
                }
                return (entryPath, modified)
            }
            .sorted { $0.modified > $1.modified }

        for candidate in candidates {
            if let path = findIndexStorePath(in: candidate.path) {
                return path
            }
        }

        return nil
    }

    private func derivedDataPath(for project: XcodeProjectlike, schemes: [String]) throws -> FilePath {
        // Given a project with two schemes: A and B, a scenario can arise where the index store contains conflicting
        // data. If scheme A is built, then the source file modified and then scheme B built, the index store will
        // contain two records for that source file. One reflects the state of the file when scheme A was built, and the
        // other when B was built. We must therefore key the DerivedData path with the full list of schemes being built.

        let xcodeVersionHash = try version().djb2Hex
        let projectHash = project.name.djb2Hex
        let schemesHash = Array(schemes).joined().djb2Hex

        return try Constants.cachePath().appending("DerivedData-\(xcodeVersionHash)-\(projectHash)-\(schemesHash)")
    }

    private func quote(arguments: [String]) -> [String] {
        var quotedArguments = arguments

        for (i, arg) in arguments.enumerated() {
            if arg.hasPrefix("-"),
               let value = arguments[safe: i + 1],
               !value.hasPrefix("-"),
               !value.hasPrefix("\""),
               !value.hasPrefix("\'")
            {
                quotedArguments[i + 1] = "\"\(value)\""
            }
        }

        return quotedArguments
    }
}
