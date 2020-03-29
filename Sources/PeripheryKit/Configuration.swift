import Foundation
import PathKit
import Yams

public final class Configuration: Singleton {
    public static func make() -> Self {
        return self.init()
    }

    public required init() {}

    var config: String?
    var workspace: String?
    var project: String?
    var saveBuildLog: String?
    var useBuildLog: String?
    var outputFormat: OutputFormat = OutputFormat.default
    var schemes: [String] = []
    var targets: [String] = []
    var indexExclude: [String] = []
    var reportExclude: [String] = []

    var retainObjcAnnotated: Bool = true
    var retainPublic: Bool = false
    var retainUnusedProtocolFuncParams: Bool = false
    var verbose: Bool = false
    var quiet: Bool = false
    var aggressive: Bool = false
    var updateCheck: Bool = true
    var diagnosisConsole: Bool = false
    var strict: Bool = false
    var xcargs: String? = nil
    var useIndexStore: Bool = false

    // Non user facing.
    var guidedSetup: Bool = false

    // Only used for tests.
    var entryPointFilenames: [String] = []

    public func asYaml() throws -> String {
        let config: [String: Any?] = [
            "workspace": workspace,
            "project": project,
            "save_build_log": saveBuildLog,
            "use_build_log": useBuildLog,
            "format": outputFormat.description.lowercased(),
            "schemes": schemes,
            "targets": targets,
            "index_exclude": indexExclude,
            "report_exclude": reportExclude,
            "retain_objc_annotated": retainObjcAnnotated,
            "retain_public": retainPublic,
            "retain_unused_protocol_func_params": retainUnusedProtocolFuncParams,
            "verbose": verbose,
            "quiet": quiet,
            "aggressive": aggressive,
            "disable_update_check": !updateCheck,
            "diagnose": diagnosisConsole,
            "strict": strict,
            "xcargs": xcargs,
            "use_index_store": useIndexStore
        ]

        return try Yams.dump(object: config)
    }

    func applyYamlConfiguration() throws {
        guard let path = try yamlConfigurationPath() else { return }

        let encodedYAML = try path.read(.utf8)
        let yaml = try Yams.load(yaml: encodedYAML) as? [String: Any] ?? [:]

        if let value = yaml["workspace"] as? String {
            self.workspace = value
        }

        if let value = yaml["project"] as? String {
            self.project = value
        }

        if let value = yaml["save_build_log"] as? String {
            self.saveBuildLog = value
        }

        if let value = yaml["use_build_log"] as? String {
            self.useBuildLog = value
        }

        if let value = yaml["schemes"] as? [String] {
            self.schemes = value
        }

        if let value = yaml["targets"] as? [String] {
            self.targets = value
        }

        if let value = yaml["index_exclude"] as? [String] {
            self.indexExclude = value
        }

        if let value = yaml["report_exclude"] as? [String] {
            self.reportExclude = value
        }

        if let value = yaml["format"] as? String {
            self.outputFormat = try OutputFormat.make(named: value)
        }

        if let value = yaml["retain_public"] as? Bool {
            self.retainPublic = value
        }

        if let value = yaml["retain_objc_annotated"] as? Bool {
            self.retainObjcAnnotated = value
        }

        if let value = yaml["retain_unused_protocol_func_params"] as? Bool {
            self.retainUnusedProtocolFuncParams = value
        }

        if let value = yaml["aggressive"] as? Bool {
            self.aggressive = value
        }

        if let value = yaml["diagnose"] as? Bool {
            self.diagnosisConsole = value
        }

        if let value = yaml["verbose"] as? Bool {
            self.verbose = value
        }

        if let value = yaml["quiet"] as? Bool {
            self.quiet = value
        }

        if let value = yaml["disable_update_check"] as? Bool {
            self.updateCheck = !value
        }

        if let value = yaml["strict"] as? Bool {
            self.strict = value
        }

        if let value = yaml["xcargs"] as? String {
            self.xcargs = value
        }

        if let value = yaml["use_index_store"] as? Bool {
            self.useIndexStore = value
        }
    }

    // MARK: - Helpers

    public var indexExcludeSourceFiles: [SourceFile] {
        return indexExclude.flatMap { glob($0) }
    }

    public var reportExcludeSourceFiles: [SourceFile] {
        return reportExclude.flatMap { glob($0) }
    }

    // MARK: - Private

    private func glob(_ pattern: String) -> [SourceFile] {
        var patternPath = Path(pattern)

        if patternPath.isRelative {
            patternPath = Path.current + patternPath
        }

        return Path.glob(patternPath.string).map {
            return $0.isRelative ?
                SourceFile(path: $0.relativeTo(Path.current)) :
                SourceFile(path: $0)
        }
    }

    private func yamlConfigurationPath() throws -> Path? {
        if let config = config {
            let path = Path(config)

            if !path.exists {
                throw PeripheryKitError.pathDoesNotExist(path: path.absolute().string)
            }

            return path
        }

        return [Path(".periphery.yml"), Path(".periphery.yaml")].first { $0.exists }
    }
}
