import Foundation
import PathKit
import Yams

public final class Configuration: Singleton {
    public static func make() -> Self {
        return self.init()
    }

    public required init() {}

    public var config: String?
    public var workspace: String?
    public var project: String?
    public var outputFormat: OutputFormat = OutputFormat.default
    public var schemes: [String] = []
    public var targets: [String] = []
    public var indexExclude: [String] = []
    public var reportExclude: [String] = []

    public var retainObjcAnnotated: Bool = true
    public var retainPublic: Bool = false
    public var retainAssignOnlyProperties: Bool = false
    public var retainUnusedProtocolFuncParams: Bool = false
    public var verbose: Bool = false
    public var quiet: Bool = false
    public var updateCheck: Bool = true
    public var strict: Bool = false
    public var xcargs: String? = nil
    public var indexStorePath: String?
    public var skipBuild: Bool = false
    public var cleanBuild: Bool = false

    // Non user facing.
    public var guidedSetup: Bool = false

    // Only used for tests.
    public var entryPointFilenames: [String] = []

    public func asYaml() throws -> String {
        let config: [String: Any?] = [
            "workspace": workspace,
            "project": project,
            "format": outputFormat.rawValue.lowercased(),
            "schemes": schemes,
            "targets": targets,
            "index_exclude": indexExclude,
            "report_exclude": reportExclude,
            "retain_objc_annotated": retainObjcAnnotated,
            "retain_public": retainPublic,
            "retain_assign_only_properties": retainAssignOnlyProperties,
            "retain_unused_protocol_func_params": retainUnusedProtocolFuncParams,
            "verbose": verbose,
            "quiet": quiet,
            "disable_update_check": !updateCheck,
            "strict": strict,
            "xcargs": xcargs,
            "index_store_path": indexStorePath,
            "skip_build": skipBuild,
            "clean_build": cleanBuild
        ]

        return try Yams.dump(object: config)
    }

    public func applyYamlConfiguration() throws {
        guard let path = try yamlConfigurationPath() else { return }

        let encodedYAML = try path.read(.utf8)
        let yaml = try Yams.load(yaml: encodedYAML) as? [String: Any] ?? [:]

        if let value = yaml["workspace"] as? String {
            self.workspace = value
        }

        if let value = yaml["project"] as? String {
            self.project = value
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

        if let value = yaml["retain_assign_only_properties"] as? Bool {
            self.retainAssignOnlyProperties = value
        }

        if let value = yaml["retain_objc_annotated"] as? Bool {
            self.retainObjcAnnotated = value
        }

        if let value = yaml["retain_unused_protocol_func_params"] as? Bool {
            self.retainUnusedProtocolFuncParams = value
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

        if let value = yaml["index_store_path"] as? String {
            self.indexStorePath = value
        }

        if let value = yaml["skip_build"] as? Bool {
            self.skipBuild = value
        }

        if let value = yaml["clean_build"] as? Bool {
            self.cleanBuild = value
        }
    }

    // MARK: - Helpers

    public var indexExcludeSourceFiles: [Path] {
        return indexExclude.flatMap { glob($0) }
    }

    public var reportExcludeSourceFiles: [Path] {
        return reportExclude.flatMap { glob($0) }
    }

    // MARK: - Private

    private func glob(_ pattern: String) -> [Path] {
        var patternPath = Path(pattern)

        if patternPath.isRelative {
            patternPath = Path.current + patternPath
        }

        return Path.glob(patternPath.string).map {
            return $0.isRelative ? $0.relativeTo(Path.current) : $0
        }
    }

    private func yamlConfigurationPath() throws -> Path? {
        if let config = config {
            let path = Path(config)

            if !path.exists {
                throw PeripheryError.pathDoesNotExist(path: path.absolute().string)
            }

            return path
        }

        return [Path(".periphery.yml"), Path(".periphery.yaml")].first { $0.exists }
    }
}
