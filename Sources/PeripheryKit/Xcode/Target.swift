import Foundation
import XcodeProj
import PathKit

public final class Target {
    static func make(project: Project, target: PBXTarget) -> Self {
        return self.init(project: project,
                         target: target,
                         xcodebuild: inject(),
                         logger: inject())
    }

    public let project: Project
    private(set) var moduleName: String

    private let target: PBXTarget
    private var sourceFiles_: Set<SourceFile> = []
    private var xibFiles_: Set<Path> = []
    private var didIdentifySourceFiles = false
    private var didIdentifyXibFiles = false
    private let xcodebuild: Xcodebuild
    private let logger: Logger

    required init(project: Project, target: PBXTarget, xcodebuild: Xcodebuild, logger: Logger) {
        self.project = project
        self.target = target
        self.moduleName = target.name
        self.xcodebuild = xcodebuild
        self.logger = logger
    }

    public var isTestTarget: Bool {
        return target.productType?.rawValue.contains("test") ?? false
    }

    public var name: String {
        return target.name
    }

    func identifyModuleName() throws {
        let settings = try xcodebuild.buildSettings(for: project, target: name, configuration: debugConfig?.name, xcconfig: try debugBaseConfiguration())
        let parser = XcodebuildSettingsParser(settings: settings)

        if let moduleName = parser.setting(named: "PRODUCT_MODULE_NAME") {
            self.moduleName = moduleName
            return
        }

        logger.warn("Failed to identify module name for target '\(name)', defaulting to target name.")
        self.moduleName = name
    }

    func sourceFiles() throws -> Set<SourceFile> {
        if didIdentifySourceFiles {
            return sourceFiles_
        }

        try identifySourceFiles()
        didIdentifySourceFiles = true
        return sourceFiles_
    }

    func xibFiles() throws -> Set<Path> {
        if didIdentifyXibFiles {
            return xibFiles_
        }

        try identifyXibFiles()
        didIdentifyXibFiles = true
        return xibFiles_
    }

    func set(sourceFiles: Set<SourceFile>) {
        sourceFiles_ = sourceFiles
        didIdentifySourceFiles = true
    }

    // MARK: - Private

    private func debugBaseConfiguration() throws -> Path? {
        guard let ref = debugConfig?.baseConfiguration else { return nil }

        return try ref.fullPath(sourceRoot: project.sourceRoot)
    }

    private var debugConfig: XCBuildConfiguration? {
        guard let list = target.buildConfigurationList else { return nil }

        let debugConfig = list.buildConfigurations.first { $0.name.lowercased().contains("debug") }

        guard let config = debugConfig ?? list.buildConfigurations.first else { return nil }

        return config
    }

    private func identifySourceFiles() throws {
        let phases = project.xcodeProject.pbxproj.sourcesBuildPhases.filter { target.buildPhases.contains($0) }

        sourceFiles_ = Set(try phases.flatMap {
            try ($0.files ?? []).compactMap {
                let sourceRoot = project.sourceRoot.absolute()
                if let path = try $0.file?.fullPath(sourceRoot: sourceRoot),
                    path.extension?.lowercased() == "swift" {
                    return SourceFile(path: path)
                }

                return nil
            }
        })
    }

    private func identifyXibFiles() throws {
        let phases = project.xcodeProject.pbxproj.resourcesBuildPhases.filter { target.buildPhases.contains($0) }

        xibFiles_ = Set(try phases.flatMap {
            try ($0.files ?? []).compactMap {
                let sourceRoot = project.sourceRoot.absolute()
                if let path = try $0.file?.fullPath(sourceRoot: sourceRoot),
                    ["xib", "storyboard"].contains(path.extension?.lowercased()) {
                    return path
                }

                return nil
            }
        })
    }
}

extension Target: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(target.name)
    }
}

extension Target: Equatable {
    public static func == (lhs: Target, rhs: Target) -> Bool {
        return lhs.name == rhs.name
    }
}
