import Foundation
import XcodeProj
import SystemPackage
import PeripheryKit
import Shared

final class XcodeTarget {
    static func make(project: XcodeProject, target: PBXTarget) -> Self {
        return self.init(project: project,
                         target: target)
    }

    let project: XcodeProject

    private let target: PBXTarget
    private var files: [ProjectFileKind: Set<FilePath>] = [:]

    required init(project: XcodeProject, target: PBXTarget) {
        self.project = project
        self.target = target
    }

    var isTestTarget: Bool {
        target.productType?.rawValue.contains("test") ?? false
    }

    var name: String {
        target.name
    }

    func identifyFiles() throws {
        let sourcesBuildPhases = project.xcodeProject.pbxproj.sourcesBuildPhases
        let resourcesBuildPhases = project.xcodeProject.pbxproj.resourcesBuildPhases

        try identifyFiles(kind: .swift, in: sourcesBuildPhases)
        try identifyFiles(kind: .xcDataModel, in: sourcesBuildPhases)
        try identifyFiles(kind: .xcMappingModel, in: sourcesBuildPhases)
        try identifyFiles(kind: .interfaceBuilder, in: resourcesBuildPhases)
        try identifyInfoPlistFiles()
    }

    func files(kind: ProjectFileKind) -> Set<FilePath> {
        files[kind, default: []]
    }

    // MARK: - Private

    private func identifyFiles(kind: ProjectFileKind, in buildPhases: [PBXBuildPhase]) throws {
        let targetPhases = buildPhases.filter { target.buildPhases.contains($0) }
        let sourceRoot = project.sourceRoot.lexicallyNormalized()

        files[kind] = Set(try targetPhases.flatMap {
            try ($0.files ?? []).compactMap {
                if let stringPath = try $0.file?.fullPath(sourceRoot: sourceRoot.string) {
                    let path = FilePath(stringPath)
                    if let ext = path.extension, kind.extensions.contains(ext.lowercased()) {
                        return path
                    }
                }

                return nil
            }
        })
    }

    private func identifyInfoPlistFiles() throws {
        let plistFiles = target.buildConfigurationList?.buildConfigurations.compactMap {
            $0.buildSettings["INFOPLIST_FILE"] as? String
        } ?? []
        files[.infoPlist] = Set(plistFiles.map { parseInfoPlistSetting($0) })
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
    func hash(into hasher: inout Hasher) {
        hasher.combine(target.name)
    }
}

extension XcodeTarget: Equatable {
    static func == (lhs: XcodeTarget, rhs: XcodeTarget) -> Bool {
        return lhs.name == rhs.name
    }
}
