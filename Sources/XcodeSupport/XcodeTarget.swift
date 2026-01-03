import Foundation
import SourceGraph
import SystemPackage
import XcodeProj

public final class XcodeTarget {
    let project: XcodeProject

    private let target: PBXTarget
    private var files: [ProjectFileKind: Set<FilePath>] = [:]

    required init(project: XcodeProject, target: PBXTarget) {
        self.project = project
        self.target = target
    }

    public var isTestTarget: Bool {
        target.productType?.rawValue.contains("test") ?? false
    }

    public var name: String {
        target.name
    }

    public func identifyFiles() throws {
        let sourceRoot = project.sourceRoot.lexicallyNormalized()
        let rootFileSystemFiles = try project.xcodeProject.pbxproj.fileSystemSynchronizedRootGroups.flatMapSet {
            if let stringPath = try $0.fullPath(sourceRoot: sourceRoot.string) {
                let path = FilePath(stringPath)
                return FilePath.glob(path.appending("**/*").string)
            }

            return []
        }

        try identifyFiles(in: rootFileSystemFiles)
        try identifyFiles(in: rootFileSystemFiles)
        try identifyFiles(in: rootFileSystemFiles)

        let sourcesBuildPhases = project.xcodeProject.pbxproj.sourcesBuildPhases
        let resourcesBuildPhases = project.xcodeProject.pbxproj.resourcesBuildPhases

        try identifyFiles(kind: .xcDataModel, in: sourcesBuildPhases)
        try identifyFiles(kind: .xcMappingModel, in: sourcesBuildPhases)
        try identifyFiles(kind: .interfaceBuilder, in: resourcesBuildPhases)
        try identifyFiles(kind: .xcStrings, in: resourcesBuildPhases)
        try identifyInfoPlistFiles()
    }

    public func files(kind: ProjectFileKind) -> Set<FilePath> {
        files[kind, default: []]
    }

    // MARK: - Private

    private func identifyFiles(kind: ProjectFileKind, in buildPhases: [PBXBuildPhase]) throws {
        let targetPhases = buildPhases.filter { target.buildPhases.contains($0) }
        let sourceRoot = project.sourceRoot.lexicallyNormalized()

        let foundFiles = try targetPhases.flatMapSet {
            try ($0.files ?? []).compactMapSet {
                if let stringPath = try $0.file?.fullPath(sourceRoot: sourceRoot.string) {
                    let path = FilePath(stringPath)
                    if let ext = path.extension, kind.extensions.contains(ext.lowercased()) {
                        return path
                    }
                }

                return nil
            }
        }
        files[kind, default: []].formUnion(foundFiles)
    }

    private func identifyFiles(in paths: Set<FilePath>) throws {
        for path in paths {
            for kind in ProjectFileKind.allCases {
                if let ext = path.extension, kind.extensions.contains(ext.lowercased()) {
                    files[kind, default: []].insert(path)
                }
            }
        }
    }

    private func identifyInfoPlistFiles() throws {
        let plistFiles = target.buildConfigurationList?.buildConfigurations.flatMap {
            if let setting = $0.buildSettings["INFOPLIST_FILE"] {
                switch setting {
                case let .string(value):
                    return [value]
                case let .array(values):
                    return values
                }
            }

            return []
        } ?? []
        files[.infoPlist] = plistFiles.mapSet { parseInfoPlistSetting($0) }
    }

    private func parseInfoPlistSetting(_ setting: String) -> FilePath {
        var setting = setting.replacingOccurrences(of: "$(SRCROOT)", with: "")

        if setting.hasPrefix("/") {
            setting.removeFirst()
        }

        return project.sourceRoot.lexicallyNormalized().appending(setting)
    }
}

extension XcodeTarget: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(target.name)
    }
}

extension XcodeTarget: Equatable {
    public static func == (lhs: XcodeTarget, rhs: XcodeTarget) -> Bool {
        lhs.name == rhs.name
    }
}
