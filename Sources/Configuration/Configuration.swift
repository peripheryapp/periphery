import Extensions
import FilenameMatcher
import Foundation
import Logger
import Shared
import SystemPackage
import Yams

public struct Configuration: Codable, Sendable {
    enum CodingKeys: String, CodingKey {
        case project = "project"
        case outputFormat = "format"
        case schemes = "schemes"
        case excludeTests = "exclude_tests"
        case excludeTargets = "exclude_targets"
        case indexExclude = "index_exclude"
        case reportExclude = "report_exclude"
        case reportInclude = "report_include"
        case buildArguments = "build_arguments"
        case xcodeListArguments = "xcode_list_arguments"
        case retainAssignOnlyPropertyTypes = "retain_assign_only_property_types"
        case externalEncodableProtocols = "external_encodable_protocols"
        case externalCodableProtocols = "external_codable_protocols"
        case externalTestCaseClasses = "external_test_case_classes"
        case retainObjcAccessible = "retain_objc_accessible"
        case retainObjcAnnotated = "retain_objc_annotated"
        case retainFiles = "retain_files"
        case retainPublic = "retain_public"
        case retainAssignOnlyProperties = "retain_assign_only_properties"
        case retainUnusedProtocolFuncParams = "retain_unused_protocol_func_params"
        case retainSwiftUIPreviews = "retain_swift_ui_previews"
        case disableRedundantPublicAnalysis = "disable_redundant_public_analysis"
        case disableUnusedImportAnalysis = "disable_unused_import_analysis"
        case retainCodableProperties = "retain_codable_properties"
        case retainEncodableProperties = "retain_encodable_properties"
        case verbose = "verbose"
        case quiet = "quiet"
        case disableUpdateCheck = "disable_update_check"
        case strict = "strict"
        case indexStorePath = "index_store_path"
        case skipBuild = "skip_build"
        case skipSchemesValidation = "skip_schemes_validation"
        case cleanBuild = "clean_build"
        case relativeResults = "relative_results"
        case jsonPackageManifestPath = "json_package_manifest_path"
        case baseline = "baseline"
        case writeBaseline = "write_baseline"
        case writeResults = "write_results"
        case genericProjectConfig = "generic_project_config"
        case bazel = "bazel"
        case bazelFilter = "bazel_filter"
    }

    public struct Default {
        public static let project: FilePath? = nil
        public static let outputFormat: OutputFormat = .default
        public static let schemes: [String] = []
        public static let excludeTests: Bool = false
        public static let excludeTargets: [String] = []
        public static let indexExclude: [String] = ["**/*?.build/**/*", "**/SourcePackages/checkouts/**"]
        public static let reportExclude: [String] = []
        public static let reportInclude: [String] = []
        public static let buildArguments: [String] = []
        public static let xcodeListArguments: [String] = []
        public static let retainAssignOnlyPropertyTypes: [String] = []
        public static let externalEncodableProtocols: [String] = []
        public static let externalCodableProtocols: [String] = []
        public static let externalTestCaseClasses: [String] = []
        public static let retainObjcAccessible: Bool = false
        public static let retainObjcAnnotated: Bool = false
        public static let retainFiles: [String] = []
        public static let retainPublic: Bool = false
        public static let retainAssignOnlyProperties: Bool = false
        public static let retainUnusedProtocolFuncParams: Bool = false
        public static let retainSwiftUIPreviews: Bool = false
        public static let disableRedundantPublicAnalysis: Bool = false
        public static let disableUnusedImportAnalysis: Bool = false
        public static let retainCodableProperties: Bool = false
        public static let retainEncodableProperties: Bool = false
        public static let verbose: Bool = false
        public static let quiet: Bool = false
        public static let disableUpdateCheck: Bool = false
        public static let strict: Bool = false
        public static let indexStorePath: [FilePath] = []
        public static let skipBuild: Bool = false
        public static let skipSchemesValidation: Bool = false
        public static let cleanBuild: Bool = false
        public static let relativeResults: Bool = false
        public static let jsonPackageManifestPath: FilePath? = nil
        public static let baseline: FilePath? = nil
        public static let writeBaseline: FilePath? = nil
        public static let writeResults: FilePath? = nil
        public static let genericProjectConfig: FilePath? = nil
        public static let bazel: Bool = false
        public static let bazelFilter: String? = nil
        public static let guidedSetup = false
    }

    public let project: FilePath?
    public let outputFormat: OutputFormat
    public let schemes: [String]
    public let excludeTests: Bool
    public let excludeTargets: [String]
    public let indexExclude: [String]
    public let reportExclude: [String]
    public let reportInclude: [String]
    public let buildArguments: [String]
    public let xcodeListArguments: [String]
    public let retainAssignOnlyPropertyTypes: [String]
    public let externalEncodableProtocols: [String]
    public let externalCodableProtocols: [String]
    public let externalTestCaseClasses: [String]
    public let retainObjcAccessible: Bool
    public let retainObjcAnnotated: Bool
    public let retainFiles: [String]
    public let retainPublic: Bool
    public let retainAssignOnlyProperties: Bool
    public let retainUnusedProtocolFuncParams: Bool
    public let retainSwiftUIPreviews: Bool
    public let disableRedundantPublicAnalysis: Bool
    public let disableUnusedImportAnalysis: Bool
    public let retainCodableProperties: Bool
    public let retainEncodableProperties: Bool
    public let verbose: Bool
    public let quiet: Bool
    public let disableUpdateCheck: Bool
    public let strict: Bool
    public let indexStorePath: [FilePath]
    public let skipBuild: Bool
    public let skipSchemesValidation: Bool
    public let cleanBuild: Bool
    public let relativeResults: Bool
    public let jsonPackageManifestPath: FilePath?
    public let baseline: FilePath?
    public let writeBaseline: FilePath?
    public let writeResults: FilePath?
    public let genericProjectConfig: FilePath?
    public let bazel: Bool
    public let bazelFilter: String?

    // Non user facing.
    public let guidedSetup: Bool = false

      public init(
        project: FilePath?,
        outputFormat: OutputFormat,
        schemes: [String],
        excludeTests: Bool,
        excludeTargets: [String],
        indexExclude: [String],
        reportExclude: [String],
        reportInclude: [String],
        buildArguments: [String],
        xcodeListArguments: [String],
        retainAssignOnlyPropertyTypes: [String],
        externalEncodableProtocols: [String],
        externalCodableProtocols: [String],
        externalTestCaseClasses: [String],
        retainObjcAccessible: Bool,
        retainObjcAnnotated: Bool,
        retainFiles: [String],
        retainPublic: Bool,
        retainAssignOnlyProperties: Bool,
        retainUnusedProtocolFuncParams: Bool,
        retainSwiftUIPreviews: Bool,
        disableRedundantPublicAnalysis: Bool,
        disableUnusedImportAnalysis: Bool,
        retainCodableProperties: Bool,
        retainEncodableProperties: Bool,
        verbose: Bool,
        quiet: Bool,
        disableUpdateCheck: Bool,
        strict: Bool,
        indexStorePath: [FilePath],
        skipBuild: Bool,
        skipSchemesValidation: Bool,
        cleanBuild: Bool,
        relativeResults: Bool,
        jsonPackageManifestPath: FilePath?,
        baseline: FilePath?,
        writeBaseline: FilePath?,
        writeResults: FilePath?,
        genericProjectConfig: FilePath?,
        bazel: Bool,
        bazelFilter: String?
      ) {

      }

    public func asYaml() throws -> String {
      let encoder = YAMLEncoder()
      return try encoder.encode(self)
    }
}

public final class ConfigurationOld {
    public init() {}

    public let defaultConfigurationFile = FilePath(".periphery.yml")

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

    @Setting(key: "retain_codable_properties", defaultValue: false)
    public var retainCodableProperties: Bool

    @Setting(key: "retain_encodable_properties", defaultValue: false)
    public var retainEncodableProperties: Bool

    @Setting(key: "verbose", defaultValue: false)
    public var verbose: Bool

    @Setting(key: "quiet", defaultValue: false)
    public var quiet: Bool

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

    // Non user facing.
    public var guidedSetup: Bool = false

    public var hasNonDefaultValues: Bool {
        settings.contains(where: \.hasNonDefaultValue)
    }

    public func save(to path: FilePath? = nil) throws {
        let path = path ?? defaultConfigurationFile
        let data = try asYaml().data(using: .utf8)
        FileManager.default.createFile(atPath: path.string, contents: data)
    }

    public func load(from path: FilePath?) throws {
        guard let path = try configurationPath(withUserProvided: path) else { return }

        let encodedYAML = try String(contentsOf: path.url)
        let yaml = try Yams.load(yaml: encodedYAML) as? [String: Any] ?? [:]
        let logger = Logger(quiet: false)

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

    public lazy var indexExcludeMatchers: [FilenameMatcher] = buildFilenameMatchers(with: indexExclude)
    public lazy var retainFilesMatchers: [FilenameMatcher] = buildFilenameMatchers(with: retainFiles)
    public lazy var reportExcludeMatchers: [FilenameMatcher] = buildFilenameMatchers(with: reportExclude)
    public lazy var reportIncludeMatchers: [FilenameMatcher] = buildFilenameMatchers(with: reportInclude)

    // MARK: - Private

    lazy var settings: [any AbstractSetting] = [
        $project, $schemes, $excludeTargets, $excludeTests, $indexExclude, $reportExclude, $reportInclude, $outputFormat,
        $retainPublic, $retainFiles, $retainAssignOnlyProperties, $retainAssignOnlyPropertyTypes, $retainObjcAccessible,
        $retainObjcAnnotated, $retainUnusedProtocolFuncParams, $retainSwiftUIPreviews, $disableRedundantPublicAnalysis,
        $disableUnusedImportAnalysis, $externalEncodableProtocols, $externalCodableProtocols, $externalTestCaseClasses,
        $verbose, $quiet, $disableUpdateCheck, $strict, $indexStorePath, $skipBuild, $skipSchemesValidation, $cleanBuild,
        $buildArguments, $xcodeListArguments, $relativeResults, $jsonPackageManifestPath, $retainCodableProperties,
        $retainEncodableProperties, $baseline, $writeBaseline, $writeResults, $genericProjectConfig, $bazel, $bazelFilter,
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

        return [defaultConfigurationFile, FilePath(".periphery.yaml")].first { $0.exists }
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
    public let defaultValue: Value
    let key: String

    private var value: Value

    init(
        key: String,
        defaultValue: Value,
    ) {
        self.key = key
        value = defaultValue
        self.defaultValue = defaultValue
    }

    public var wrappedValue: Value { value }
    public var projectedValue: Setting { self }

    var hasNonDefaultValue: Bool {
        value != defaultValue
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
