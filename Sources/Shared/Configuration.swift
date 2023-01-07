import Foundation
import SystemPackage
import Yams

public final class Configuration {
    public static var defaultConfigurationFile = ".periphery.yml"
    public static let shared = Configuration()

    public init(logger: BaseLogger = .shared) {
        self.logger = logger
    }

    @Setting(key: "workspace", defaultValue: nil)
    public var workspace: String?

    @Setting(key: "project", defaultValue: nil)
    public var project: String?

    @Setting(key: "format", defaultValue: .default, valueConverter: { OutputFormat(anyValue: $0) })
    public var outputFormat: OutputFormat

    @Setting(key: "schemes", defaultValue: [])
    public var schemes: [String]

    @Setting(key: "targets", defaultValue: [])
    public var targets: [String]

    @Setting(key: "index_exclude", defaultValue: [])
    public var indexExclude: [String]

    @Setting(key: "report_exclude", defaultValue: [])
    public var reportExclude: [String]

    @Setting(key: "report_include", defaultValue: [])
    public var reportInclude: [String]

    @Setting(key: "build_arguments", defaultValue: [])
    public var buildArguments: [String]

    @Setting(key: "retain_assign_only_property_types", defaultValue: [], valueSanitizer: PropertyTypeSanitizer.sanitize)
    public var retainAssignOnlyPropertyTypes: [String]

    @Setting(key: "external_encodable_protocols", defaultValue: [])
    public var externalEncodableProtocols: [String]

    @Setting(key: "retain_objc_accessible", defaultValue: false)
    public var retainObjcAccessible: Bool

    @Setting(key: "retain_public", defaultValue: false)
    public var retainPublic: Bool

    @Setting(key: "retain_assign_only_properties", defaultValue: false)
    public var retainAssignOnlyProperties: Bool

    @Setting(key: "retain_unused_protocol_func_params", defaultValue: false)
    public var retainUnusedProtocolFuncParams: Bool

    @Setting(key: "disable_redundant_public_analysis", defaultValue: false)
    public var disableRedundantPublicAnalysis: Bool

    @Setting(key: "verbose", defaultValue: false)
    public var verbose: Bool

    @Setting(key: "quiet", defaultValue: false)
    public var quiet: Bool

    @Setting(key: "disable_update_check", defaultValue: false)
    public var disableUpdateCheck: Bool

    @Setting(key: "strict", defaultValue: false)
    public var strict: Bool

    @Setting(key: "index_store_path", defaultValue: nil)
    public var indexStorePath: String?

    @Setting(key: "skip_build", defaultValue: false)
    public var skipBuild: Bool

    @Setting(key: "clean_build", defaultValue: false)
    public var cleanBuild: Bool

    // Non user facing.
    public var guidedSetup: Bool = false

    // Dependencies.
    private var logger: BaseLogger // Must use BaseLogger as Logger depends upon Configuration.

    public func asYaml() throws -> String {
        var config: [String: Any?] = [:]

        if $workspace.hasNonDefaultValue {
            config[$workspace.key] = workspace
        }

        if $project.hasNonDefaultValue {
            config[$project.key] = project
        }

        if $schemes.hasNonDefaultValue {
            config[$schemes.key] = schemes
        }

        if $targets.hasNonDefaultValue {
            config[$targets.key] = targets
        }

        if $outputFormat.hasNonDefaultValue {
            config[$outputFormat.key] = outputFormat.rawValue
        }

        if $indexExclude.hasNonDefaultValue {
            config[$indexExclude.key] = indexExclude
        }

        if $reportExclude.hasNonDefaultValue {
            config[$reportExclude.key] = reportExclude
        }

        if $retainObjcAccessible.hasNonDefaultValue {
            config[$retainObjcAccessible.key] = retainObjcAccessible
        }

        if $retainPublic.hasNonDefaultValue {
            config[$retainPublic.key] = retainPublic
        }

        if $retainAssignOnlyProperties.hasNonDefaultValue {
            config[$retainAssignOnlyProperties.key] = retainAssignOnlyProperties
        }

        if $retainAssignOnlyPropertyTypes.hasNonDefaultValue {
            config[$retainAssignOnlyPropertyTypes.key] = retainAssignOnlyPropertyTypes
        }

        if $externalEncodableProtocols.hasNonDefaultValue {
            config[$externalEncodableProtocols.key] = externalEncodableProtocols
        }

        if $retainUnusedProtocolFuncParams.hasNonDefaultValue {
            config[$retainUnusedProtocolFuncParams.key] = retainUnusedProtocolFuncParams
        }

        if $disableRedundantPublicAnalysis.hasNonDefaultValue {
            config[$disableRedundantPublicAnalysis.key] = disableRedundantPublicAnalysis
        }

        if $verbose.hasNonDefaultValue {
            config[$verbose.key] = verbose
        }

        if $quiet.hasNonDefaultValue {
            config[$quiet.key] = quiet
        }

        if $disableUpdateCheck.hasNonDefaultValue {
            config[$disableUpdateCheck.key] = disableUpdateCheck
        }

        if $strict.hasNonDefaultValue {
            config[$strict.key] = strict
        }

        if $indexStorePath.hasNonDefaultValue {
            config[$indexStorePath.key] = indexStorePath
        }

        if $skipBuild.hasNonDefaultValue {
            config[$skipBuild.key] = skipBuild
        }

        if $cleanBuild.hasNonDefaultValue {
            config[$cleanBuild.key] = cleanBuild
        }

        if $buildArguments.hasNonDefaultValue {
            config[$buildArguments.key] = buildArguments
        }

        return try Yams.dump(object: config)
    }

    public func save() throws {
        let data = try asYaml().data(using: .utf8)
        FileManager.default.createFile(atPath: Self.defaultConfigurationFile, contents: data)
    }

    public func load(from path: FilePath?) throws {
        guard let path = try configurationPath(withUserProvided: path) else { return }

        let encodedYAML = try String(contentsOf: path.url)
        let yaml = try Yams.load(yaml: encodedYAML) as? [String: Any] ?? [:]

        for (key, value) in yaml {
            switch key {
            case $workspace.key:
                $workspace.assign(value)
            case $project.key:
                $project.assign(value)
            case $schemes.key:
                $schemes.assign(value)
            case $targets.key:
                $targets.assign(value)
            case $indexExclude.key:
                $indexExclude.assign(value)
            case $reportExclude.key:
                $reportExclude.assign(value)
            case $outputFormat.key:
                $outputFormat.assign(value)
            case $retainPublic.key:
                $retainPublic.assign(value)
            case $retainAssignOnlyProperties.key:
                $retainAssignOnlyProperties.assign(value)
            case $retainAssignOnlyPropertyTypes.key:
                $retainAssignOnlyPropertyTypes.assign(value)
            case $externalEncodableProtocols.key:
                $externalEncodableProtocols.assign(value)
            case $retainObjcAccessible.key:
                $retainObjcAccessible.assign(value)
            case $retainUnusedProtocolFuncParams.key:
                $retainUnusedProtocolFuncParams.assign(value)
            case $disableRedundantPublicAnalysis.key:
                $disableRedundantPublicAnalysis.assign(value)
            case $verbose.key:
                $verbose.assign(value)
            case $quiet.key:
                $quiet.assign(value)
            case $disableUpdateCheck.key:
                $disableUpdateCheck.assign(value)
            case $strict.key:
                $strict.assign(value)
            case $indexStorePath.key:
                $indexStorePath.assign(value)
            case $skipBuild.key:
                $skipBuild.assign(value)
            case $cleanBuild.key:
                $cleanBuild.assign(value)
            case $buildArguments.key:
                $buildArguments.assign(value)
            default:
                logger.warn("\(path.string): invalid key '\(key)'")
            }
        }
    }

    public func reset() {
        $workspace.reset()
        $project.reset()
        $schemes.reset()
        $targets.reset()
        $indexExclude.reset()
        $reportExclude.reset()
        $outputFormat.reset()
        $retainPublic.reset()
        $retainAssignOnlyProperties.reset()
        $retainAssignOnlyPropertyTypes.reset()
        $retainObjcAccessible.reset()
        $retainUnusedProtocolFuncParams.reset()
        $disableRedundantPublicAnalysis.reset()
        $externalEncodableProtocols.reset()
        $verbose.reset()
        $quiet.reset()
        $disableUpdateCheck.reset()
        $strict.reset()
        $indexStorePath.reset()
        $skipBuild.reset()
        $cleanBuild.reset()
        $buildArguments.reset()
    }

    // MARK: - Helpers

    public func apply<T: Equatable>(_ path: KeyPath<Configuration, Setting<T>>, _ value: T) {
        let setting = self[keyPath: path]

        if setting.defaultValue != value {
            setting.wrappedValue = value
        }
    }

    private var _indexExcludeSourceFiles: Set<FilePath>?
    public var indexExcludeSourceFiles: Set<FilePath> {
        get {
            if let files = _indexExcludeSourceFiles {
                return files
            }

            let files = Set(indexExclude.flatMap { FilePath.glob($0) })
            _indexExcludeSourceFiles = files
            return files
        }
        set {
            _indexExcludeSourceFiles = newValue
        }
    }

    public lazy var reportExcludeSourceFiles: Set<FilePath> = {
        Set(reportExclude.flatMap { FilePath.glob($0) })
    }()

    public lazy var reportIncludeSourceFiles: Set<FilePath> = {
        Set(reportInclude.flatMap { FilePath.glob($0) })
    }()

    // MARK: - Private

    private func configurationPath(withUserProvided path: FilePath?) throws -> FilePath? {
        if let path = path {
            if !path.exists {
                throw PeripheryError.pathDoesNotExist(path: path.lexicallyNormalized().string)
            }

            return path
        }

        return [FilePath(Self.defaultConfigurationFile), FilePath(".periphery.yaml")].first { $0.exists }
    }
}

@propertyWrapper public final class Setting<Value: Equatable> {
    typealias ValueConverter = (Any) -> Value?
    typealias ValueSanitizer = (Value) -> Value

    public let defaultValue: Value
    fileprivate let key: String

    private let valueConverter: ValueConverter
    private let valueSanitizer: ValueSanitizer
    private var value: Value

    fileprivate init(key: String,
                     defaultValue: Value,
                     valueConverter: @escaping ValueConverter = { $0 as? Value },
                     valueSanitizer: @escaping ValueSanitizer = { $0 }) {
        self.key = key
        self.value = defaultValue
        self.defaultValue = defaultValue
        self.valueConverter = valueConverter
        self.valueSanitizer = valueSanitizer
    }

    public var wrappedValue: Value {
        get { value }
        set { value = valueSanitizer(newValue) }
    }

    public var projectedValue: Setting { self }

    fileprivate var hasNonDefaultValue: Bool {
        value != defaultValue
    }

    fileprivate func assign(_ value: Any) {
        wrappedValue = valueConverter(value) ?? defaultValue
    }

    fileprivate func reset() {
        wrappedValue = defaultValue
    }
}
