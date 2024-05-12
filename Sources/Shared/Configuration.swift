import Foundation
import SystemPackage
import Yams
import FilenameMatcher

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

    @Setting(key: "file_targets_path", defaultValue: [], valueConverter: filePathConverter)
    public var fileTargetsPath: [FilePath]

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

    @Setting(key: "enable_unused_import_analysis", defaultValue: false)
    public var enableUnusedImportsAnalysis: Bool

    @Setting(key: "retain_codable_properties", defaultValue: false)
    public var retainCodableProperties: Bool

    @Setting(key: "auto_remove", defaultValue: false)
    public var autoRemove: Bool

    @Setting(key: "verbose", defaultValue: false)
    public var verbose: Bool

    @Setting(key: "quiet", defaultValue: false)
    public var quiet: Bool

    @Setting(key: "disable_update_check", defaultValue: false)
    public var disableUpdateCheck: Bool

    @Setting(key: "strict", defaultValue: false)
    public var strict: Bool

    @Setting(key: "index_store_path", defaultValue: [], valueConverter: filePathConverter)
    public var indexStorePath: [FilePath]

    @Setting(key: "skip_build", defaultValue: false)
    public var skipBuild: Bool

    @Setting(key: "clean_build", defaultValue: false)
    public var cleanBuild: Bool

    @Setting(key: "relative_results", defaultValue: false)
    public var relativeResults: Bool

    @Setting(key: "json_package_manifest_path", defaultValue: [])
    public var jsonPackageManifestPath: [FilePath]

    // Non user facing.
    public var guidedSetup: Bool = false
    public var removalOutputBasePath: FilePath?

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

        if $fileTargetsPath.hasNonDefaultValue {
            config[$fileTargetsPath.key] = fileTargetsPath.map { $0.string }
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

        if $reportInclude.hasNonDefaultValue {
            config[$reportInclude.key] = reportInclude
        }

        if $retainObjcAccessible.hasNonDefaultValue {
            config[$retainObjcAccessible.key] = retainObjcAccessible
        }

        if $retainObjcAnnotated.hasNonDefaultValue {
            config[$retainObjcAnnotated.key] = retainObjcAnnotated
        }
        
        if $retainPublic.hasNonDefaultValue {
            config[$retainPublic.key] = retainPublic
        }

        if $retainFiles.hasNonDefaultValue {
            config[$retainFiles.key] = retainFiles
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

        if $externalCodableProtocols.hasNonDefaultValue {
            config[$externalCodableProtocols.key] = externalCodableProtocols
        }

        if $externalTestCaseClasses.hasNonDefaultValue {
            config[$externalTestCaseClasses.key] = externalTestCaseClasses
        }

        if $retainUnusedProtocolFuncParams.hasNonDefaultValue {
            config[$retainUnusedProtocolFuncParams.key] = retainUnusedProtocolFuncParams
        }

        if $retainSwiftUIPreviews.hasNonDefaultValue {
            config[$retainSwiftUIPreviews.key] = retainSwiftUIPreviews
        }

        if $disableRedundantPublicAnalysis.hasNonDefaultValue {
            config[$disableRedundantPublicAnalysis.key] = disableRedundantPublicAnalysis
        }

        if $enableUnusedImportsAnalysis.hasNonDefaultValue {
            config[$enableUnusedImportsAnalysis.key] = enableUnusedImportsAnalysis
        }

        if $autoRemove.hasNonDefaultValue {
            config[$autoRemove.key] = autoRemove
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
            config[$indexStorePath.key] = indexStorePath.map { $0.string }
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

        if $relativeResults.hasNonDefaultValue {
            config[$relativeResults.key] = relativeResults
        }

        if $retainCodableProperties.hasNonDefaultValue {
            config[$retainCodableProperties.key] = retainCodableProperties
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
            case $fileTargetsPath.key:
                $fileTargetsPath.assign(value)
            case $schemes.key:
                $schemes.assign(value)
            case $targets.key:
                $targets.assign(value)
            case $indexExclude.key:
                $indexExclude.assign(value)
            case $reportExclude.key:
                $reportExclude.assign(value)
            case $reportInclude.key:
                $reportInclude.assign(value)
            case $outputFormat.key:
                $outputFormat.assign(value)
            case $retainPublic.key:
                $retainPublic.assign(value)
            case $retainFiles.key:
                $retainFiles.assign(value)
            case $retainAssignOnlyProperties.key:
                $retainAssignOnlyProperties.assign(value)
            case $retainAssignOnlyPropertyTypes.key:
                $retainAssignOnlyPropertyTypes.assign(value)
            case $externalEncodableProtocols.key:
                if !externalEncodableProtocols.isEmpty {
                    logger.warn("The option '--external-encodable-protocols' is deprecated, use '--external-codable-protocols' instead.")
                }
                $externalEncodableProtocols.assign(value)
            case $externalCodableProtocols.key:
                $externalCodableProtocols.assign(value)
            case $externalTestCaseClasses.key:
                $externalTestCaseClasses.assign(value)
            case $retainObjcAccessible.key:
                $retainObjcAccessible.assign(value)
            case $retainObjcAnnotated.key:
                $retainObjcAnnotated.assign(value)
            case $retainUnusedProtocolFuncParams.key:
                $retainUnusedProtocolFuncParams.assign(value)
            case $retainSwiftUIPreviews.key:
                $retainSwiftUIPreviews.assign(value)
            case $disableRedundantPublicAnalysis.key:
                $disableRedundantPublicAnalysis.assign(value)
            case $enableUnusedImportsAnalysis.key:
                $enableUnusedImportsAnalysis.assign(value)
            case $autoRemove.key:
                $autoRemove.assign(value)
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
            case $relativeResults.key:
                $relativeResults.assign(value)
            case $retainCodableProperties.key:
                $retainCodableProperties.assign(value)
            default:
                logger.warn("\(path.string): invalid key '\(key)'")
            }
        }
    }

    public func reset() {
        $workspace.reset()
        $project.reset()
        $fileTargetsPath.reset()
        $schemes.reset()
        $targets.reset()
        $indexExclude.reset()
        $reportExclude.reset()
        $reportInclude.reset()
        $outputFormat.reset()
        $retainPublic.reset()
        $retainFiles.reset()
        $retainAssignOnlyProperties.reset()
        $retainAssignOnlyPropertyTypes.reset()
        $retainObjcAccessible.reset()
        $retainObjcAnnotated.reset()
        $retainUnusedProtocolFuncParams.reset()
        $retainSwiftUIPreviews.reset()
        $disableRedundantPublicAnalysis.reset()
        $enableUnusedImportsAnalysis.reset()
        $autoRemove.reset()
        $externalEncodableProtocols.reset()
        $externalCodableProtocols.reset()
        $externalTestCaseClasses.reset()
        $verbose.reset()
        $quiet.reset()
        $disableUpdateCheck.reset()
        $strict.reset()
        $indexStorePath.reset()
        $skipBuild.reset()
        $cleanBuild.reset()
        $buildArguments.reset()
        $relativeResults.reset()
        $retainCodableProperties.reset()
    }

    // MARK: - Helpers

    public func apply<T: Equatable>(_ path: KeyPath<Configuration, Setting<T>>, _ value: T) {
        let setting = self[keyPath: path]

        if setting.defaultValue != value {
            setting.wrappedValue = value
        }
    }

    private var _indexExcludeMatchers: [FilenameMatcher]?
    public var indexExcludeMatchers: [FilenameMatcher] {
        if let _indexExcludeMatchers {
            return _indexExcludeMatchers
        }

        let matchers = buildFilenameMatchers(with: indexExclude)
        _indexExcludeMatchers = matchers
        return matchers
    }

    private var _retainFilesMatchers: [FilenameMatcher]?
    public var retainFilesMatchers: [FilenameMatcher] {
        if let _retainFilesMatchers {
            return _retainFilesMatchers
        }

        let matchers = buildFilenameMatchers(with: retainFiles)
        _retainFilesMatchers = matchers
        return matchers
    }

    public func resetMatchers() {
        _indexExcludeMatchers = nil
        _retainFilesMatchers = nil
    }

    public lazy var reportExcludeMatchers: [FilenameMatcher] = {
        buildFilenameMatchers(with: reportExclude)
    }()

    public lazy var reportIncludeMatchers: [FilenameMatcher] = {
        buildFilenameMatchers(with: reportInclude)
    }()

    // MARK: - Private

    private func buildFilenameMatchers(with patterns: [String]) -> [FilenameMatcher] {
        // TODO: respect filesystem case sensitivity.
        let pwd = FilePath.current.string
        return patterns.map { FilenameMatcher(relativePattern: $0, to: pwd, caseSensitive: false) }
    }

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

private let filePathConverter: (Any) -> [FilePath]? = { value in
    if let path = value as? String {
        return [FilePath(path)]
    } else if let paths = value as? [String] {
        return paths.map { FilePath($0) }
    }

    return nil
}
