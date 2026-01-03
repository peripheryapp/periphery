import Extensions
import FilenameMatcher
import Foundation
import Logger
import Shared
import SystemPackage
import Yams

public final class Configuration {
    public static var defaultConfigurationFile = FilePath(".periphery.yml")

    public init() {}

    @Setting(key: "project", defaultValue: nil, setter: filePathSetter)
    public var project: FilePath?

    @Setting(key: "format", defaultValue: .default, setter: { OutputFormat(anyValue: $0) })
    public var outputFormat: OutputFormat

    @Setting(key: "schemes", defaultValue: [])
    public var schemes: [String]

    @Setting(key: "exclude_tests", defaultValue: false)
    public var excludeTests: Bool

    @Setting(key: "exclude_targets", defaultValue: [])
    public var excludeTargets: [String]

    @Setting(key: "index_exclude", defaultValue: ["**/*?.build/**/*", "**/SourcePackages/checkouts/**"], requireDefaultValues: true)
    public var indexExclude: [String]

    @Setting(key: "report_exclude", defaultValue: [])
    public var reportExclude: [String]

    @Setting(key: "report_include", defaultValue: [])
    public var reportInclude: [String]

    @Setting(key: "build_arguments", defaultValue: [])
    public var buildArguments: [String]

    @Setting(key: "xcode_list_arguments", defaultValue: [])
    public var xcodeListArguments: [String]

    @Setting(key: "retain_assign_only_property_types", defaultValue: [])
    public var retainAssignOnlyPropertyTypes: [String]

    @Setting(key: "external_encodable_protocols", defaultValue: [])
    public var externalEncodableProtocols: [String]

    @Setting(key: "external_codable_protocols", defaultValue: [])
    public var externalCodableProtocols: [String]

    @Setting(key: "external_test_case_classes", defaultValue: [])
    public var externalTestCaseClasses: [String]

    @Setting(key: "retain_objc_accessible", defaultValue: false)
    public var retainObjcAccessible: Bool

    @Setting(key: "retain_objc_annotated", defaultValue: false)
    public var retainObjcAnnotated: Bool

    @Setting(key: "retain_files", defaultValue: [])
    public var retainFiles: [String]

    @Setting(key: "retain_public", defaultValue: false)
    public var retainPublic: Bool

    @Setting(key: "retain_assign_only_properties", defaultValue: false)
    public var retainAssignOnlyProperties: Bool

    @Setting(key: "retain_unused_protocol_func_params", defaultValue: false)
    public var retainUnusedProtocolFuncParams: Bool

    @Setting(key: "retain_swift_ui_previews", defaultValue: false)
    public var retainSwiftUIPreviews: Bool

    @Setting(key: "disable_redundant_public_analysis", defaultValue: false)
    public var disableRedundantPublicAnalysis: Bool

    @Setting(key: "disable_unused_import_analysis", defaultValue: false)
    public var disableUnusedImportAnalysis: Bool

    @Setting(key: "retain_unused_imported_modules", defaultValue: [])
    public var retainUnusedImportedModules: [String]

    @Setting(key: "retain_codable_properties", defaultValue: false)
    public var retainCodableProperties: Bool

    @Setting(key: "retain_encodable_properties", defaultValue: false)
    public var retainEncodableProperties: Bool

    @Setting(key: "verbose", defaultValue: false)
    public var verbose: Bool

    @Setting(key: "quiet", defaultValue: false)
    public var quiet: Bool

    @Setting(key: "color", defaultValue: true)
    public var color: Bool

    @Setting(key: "disable_update_check", defaultValue: false)
    public var disableUpdateCheck: Bool

    @Setting(key: "strict", defaultValue: false)
    public var strict: Bool

    @Setting(key: "index_store_path", defaultValue: [], setter: filePathArraySetter)
    public var indexStorePath: [FilePath]

    @Setting(key: "skip_build", defaultValue: false)
    public var skipBuild: Bool

    @Setting(key: "skip_schemes_validation", defaultValue: false)
    public var skipSchemesValidation: Bool

    @Setting(key: "clean_build", defaultValue: false)
    public var cleanBuild: Bool

    @Setting(key: "relative_results", defaultValue: false)
    public var relativeResults: Bool

    @Setting(key: "json_package_manifest_path", defaultValue: nil, setter: filePathSetter)
    public var jsonPackageManifestPath: FilePath?

    @Setting(key: "baseline", defaultValue: nil, setter: filePathSetter)
    public var baseline: FilePath?

    @Setting(key: "write_baseline", defaultValue: nil, setter: filePathSetter)
    public var writeBaseline: FilePath?

    @Setting(key: "write_results", defaultValue: nil, setter: filePathSetter)
    public var writeResults: FilePath?

    @Setting(key: "generic_project_config", defaultValue: nil, setter: filePathSetter)
    public var genericProjectConfig: FilePath?

    @Setting(key: "bazel", defaultValue: false)
    public var bazel: Bool

    @Setting(key: "bazel_filter", defaultValue: nil)
    public var bazelFilter: String?

    @Setting(key: "bazel_index_store", defaultValue: nil)
    public var bazelIndexStore: FilePath?

    // Non user facing.
    public var guidedSetup: Bool = false
    public var projectRoot: FilePath = .init()

    public var hasNonDefaultValues: Bool {
        settings.contains(where: \.hasNonDefaultValue)
    }

    public func asYaml() throws -> String {
        var config: [String: Any?] = [:]

        for setting in settings where setting.hasNonDefaultValue {
            config[setting.key] = setting.wrappedValue
        }

        return try Yams.dump(object: config)
    }

    public func save(to path: FilePath = defaultConfigurationFile) throws {
        let data = try asYaml().data(using: .utf8)
        FileManager.default.createFile(atPath: path.string, contents: data)
    }

    public func load(from path: FilePath?) throws {
        guard let path = try configurationPath(withUserProvided: path) else { return }

        let encodedYAML = try String(contentsOf: path.url)
        let yaml = try Yams.load(yaml: encodedYAML) as? [String: Any] ?? [:]
        let logger = Logger(quiet: false, verbose: false, coloredOutputEnabled: false)

        for (key, value) in yaml {
            if let setting = settings.first(where: { key == $0.key }) {
                setting.assign(value)
            } else {
                logger.warn("\(path.string): invalid key '\(key)'")
            }
        }
    }

    // MARK: - Helpers

    public func apply<T: Equatable>(_ path: KeyPath<Configuration, Setting<T>>, _ value: T) {
        let setting = self[keyPath: path]

        if setting.defaultValue != value {
            setting.wrappedValue = value
        }
    }

    public func buildFilenameMatchers() {
        indexExcludeMatchers = buildFilenameMatchers(with: indexExclude)
        retainFilesMatchers = buildFilenameMatchers(with: retainFiles)
        reportExcludeMatchers = buildFilenameMatchers(with: reportExclude)
        reportIncludeMatchers = buildFilenameMatchers(with: reportInclude)
    }

    public var indexExcludeMatchers: [FilenameMatcher] = []
    public var retainFilesMatchers: [FilenameMatcher] = []
    public var reportExcludeMatchers: [FilenameMatcher] = []
    public var reportIncludeMatchers: [FilenameMatcher] = []

    // MARK: - Private

    lazy var settings: [any AbstractSetting] = [
        $project, $schemes, $excludeTargets, $excludeTests, $indexExclude, $reportExclude, $reportInclude, $outputFormat,
        $retainPublic, $retainFiles, $retainAssignOnlyProperties, $retainAssignOnlyPropertyTypes, $retainObjcAccessible,
        $retainObjcAnnotated, $retainUnusedProtocolFuncParams, $retainSwiftUIPreviews, $disableRedundantPublicAnalysis,
        $disableUnusedImportAnalysis, $retainUnusedImportedModules, $externalEncodableProtocols, $externalCodableProtocols,
        $externalTestCaseClasses, $verbose, $quiet, $color, $disableUpdateCheck, $strict, $indexStorePath,
        $skipBuild, $skipSchemesValidation, $cleanBuild, $buildArguments, $xcodeListArguments, $relativeResults,
        $jsonPackageManifestPath, $retainCodableProperties, $retainEncodableProperties, $baseline, $writeBaseline,
        $writeResults, $genericProjectConfig, $bazel, $bazelFilter, $bazelIndexStore,
    ]

    private func buildFilenameMatchers(with patterns: [String]) -> [FilenameMatcher] {
        // TODO: respect filesystem case sensitivity.
        let pwd = FilePath.current.string
        return patterns.map { FilenameMatcher(relativePattern: $0, to: pwd, caseSensitive: false) }
    }

    private func configurationPath(withUserProvided path: FilePath?) throws -> FilePath? {
        if let path {
            if !path.exists {
                throw PeripheryError.pathDoesNotExist(path: path.lexicallyNormalized().string)
            }

            return path
        }

        return [Self.defaultConfigurationFile, FilePath(".periphery.yaml")].first { $0.exists }
    }
}

protocol AbstractSetting {
    associatedtype Value

    var key: String { get }
    var hasNonDefaultValue: Bool { get }
    var wrappedValue: Value { get }

    func assign(_ value: Any)
}

@propertyWrapper public final class Setting<Value: Equatable>: AbstractSetting {
    typealias Setter = (Any) -> Value?

    public let defaultValue: Value
    let key: String

    private let setter: Setter
    private var value: Value

    init(
        key: String,
        defaultValue: Value,
        setter: @escaping Setter = { $0 as? Value }
    ) {
        self.key = key
        value = defaultValue
        self.defaultValue = defaultValue
        self.setter = setter
    }

    public var wrappedValue: Value {
        get { value }
        set { value = setter(newValue) ?? defaultValue }
    }

    public var projectedValue: Setting { self }

    var hasNonDefaultValue: Bool {
        value != defaultValue
    }

    public func assign(_ newValue: Any) {
        value = setter(newValue) ?? defaultValue
    }
}

private let filePathSetter: (Any) -> FilePath? = { value in
    if let value = value as? FilePath {
        return value
    } else if let value = value as? String {
        return FilePath(value)
    }

    return nil
}

private let filePathArraySetter: (Any) -> [FilePath]? = { value in
    if let value = value as? [FilePath] {
        return value
    } else if let path = value as? String {
        return [FilePath(path)]
    } else if let paths = value as? [String] {
        return paths.map { FilePath($0) }
    }

    return nil
}

extension Setting where Value == [String] {
    convenience init(
        key: String,
        defaultValue: Value,
        requireDefaultValues: Bool
    ) {
        self.init(
            key: key,
            defaultValue: defaultValue,
            setter: { value in
                guard let typedValue = value as? [String] else { return nil }
                return requireDefaultValues ? Array(Set(typedValue).union(defaultValue)) : typedValue
            }
        )
    }
}

// MARK: - Yaml Encoding

extension OutputFormat: Yams.ScalarRepresentable {
    public func represented() -> Node.Scalar {
        rawValue.represented()
    }
}

extension FilePath: Yams.ScalarRepresentable {
    public func represented() -> Node.Scalar {
        string.represented()
    }
}
