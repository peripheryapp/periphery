import Foundation
import PathKit
import Yams

public final class Configuration: Singleton {
    public static func make() -> Self {
        return self.init(logger: inject())
    }

    public required init(logger: BaseLogger) {
        self.logger = logger
    }

    public var config: String?
    public var workspace: String?
    public var project: String?
    public var outputFormat: OutputFormat = OutputFormat.default
    public var schemes: [String] = []
    public var targets: [String] = []
    public var indexExclude: [String] = []
    public var reportExclude: [String] = []
    public var buildArguments: [String] = []

    private var _retainAssignOnlyPropertyTypes: [String] = []
    public var retainAssignOnlyPropertyTypes: [String] {
        get {
            _retainAssignOnlyPropertyTypes
        }
        set {
            _retainAssignOnlyPropertyTypes = newValue.map { PropertyTypeSanitizer.sanitize($0) }
        }
    }

    public var retainObjcAccessible: Bool = false
    public var retainPublic: Bool = false
    public var retainAssignOnlyProperties: Bool = false
    public var retainUnusedProtocolFuncParams: Bool = false
    public var verbose: Bool = false
    public var quiet: Bool = false
    public var updateCheck: Bool = true
    public var strict: Bool = false
    public var indexStorePath: String?
    public var skipBuild: Bool = false
    public var cleanBuild: Bool = false

    // Non user facing.
    public var guidedSetup: Bool = false

    // Only used for tests.
    public var entryPointFilenames: [String] = []

    // Dependencies
    private var logger: BaseLogger // Must use BaseLogger as Logger depends upon Configuration.

    public func asYaml() throws -> String {
        let config: [String: Any?] = [
            "workspace": workspace,
            "project": project,
            "format": outputFormat.rawValue.lowercased(),
            "schemes": schemes,
            "targets": targets,
            "index_exclude": indexExclude,
            "report_exclude": reportExclude,
            "retain_objc_accessible": retainObjcAccessible,
            "retain_public": retainPublic,
            "retain_assign_only_properties": retainAssignOnlyProperties,
            "retain_assign_only_property_types": retainAssignOnlyPropertyTypes,
            "retain_unused_protocol_func_params": retainUnusedProtocolFuncParams,
            "verbose": verbose,
            "quiet": quiet,
            "disable_update_check": !updateCheck,
            "strict": strict,
            "index_store_path": indexStorePath,
            "skip_build": skipBuild,
            "clean_build": cleanBuild,
            "build_arguments": buildArguments
        ]

        return try Yams.dump(object: config)
    }

    public func applyYamlConfiguration() throws {
        guard let path = try yamlConfigurationPath() else { return }

        let encodedYAML = try path.read(.utf8)
        let yaml = try Yams.load(yaml: encodedYAML) as? [String: Any] ?? [:]

        for (key, value) in yaml {
            switch key {
            case "workspace":
                self.workspace = convert(value, to: String.self)
            case "project":
                self.project = convert(value, to: String.self)
            case "schemes":
                self.schemes = convert(value, to: [String].self) ?? []
            case "targets":
                self.targets = convert(value, to: [String].self) ?? []
            case "index_exclude":
                self.indexExclude = convert(value, to: [String].self) ?? []
            case "report_exclude":
                self.reportExclude = convert(value, to: [String].self) ?? []
            case "format":
                if let value = convert(value, to: String.self) {
                    self.outputFormat = try OutputFormat.make(named: value)
                }
            case "retain_public":
                self.retainPublic = convert(value, to: Bool.self) ?? false
            case "retain_assign_only_properties":
                self.retainAssignOnlyProperties = convert(value, to: Bool.self) ?? false
            case "retain_assign_only_property_types":
                self.retainAssignOnlyPropertyTypes = convert(value, to: [String].self) ?? []
            case "retain_objc_accessible":
                self.retainObjcAccessible = convert(value, to: Bool.self) ?? false
            case "retain_unused_protocol_func_params":
                self.retainUnusedProtocolFuncParams = convert(value, to: Bool.self) ?? false
            case "verbose":
                self.verbose = convert(value, to: Bool.self) ?? false
            case "quiet":
                self.quiet = convert(value, to: Bool.self) ?? false
            case "disable_update_check":
                self.updateCheck = !(convert(value, to: Bool.self) ?? false)
            case "strict":
                self.strict = convert(value, to: Bool.self) ?? false
            case "xcargs":
                logger.warn("\(path.string): 'xcargs' is deprecated and has been superseded by 'build_arguments'")
                self.buildArguments = (convert(value, to: String.self) ?? "").split(separator: " ").map { String($0) }
            case "index_store_path":
                self.indexStorePath = convert(value, to: String.self)
            case "skip_build":
                self.skipBuild = convert(value, to: Bool.self) ?? false
            case "clean_build":
                self.cleanBuild = convert(value, to: Bool.self) ?? false
            case "build_arguments":
                self.buildArguments = convert(value, to: [String].self) ?? []
            default:
                logger.warn("\(path.string): invalid key '\(key)'")
            }
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

    private func convert<T>(_ value: Any, to type: T.Type) -> T? {
        value as? T
    }

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
