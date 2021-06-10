import Foundation
import XcodeProj
import SystemPackage
import PathKit
import PeripheryKit
import Shared

final class XcodeTarget {
    static func make(project: XcodeProject, target: PBXTarget) -> Self {
        return self.init(project: project,
                         target: target)
    }

    let project: XcodeProject

    private let target: PBXTarget
    private var sourceFiles_: Set<FilePath> = []
    private var xibFiles_: Set<FilePath> = []
    private var infoPlistFiles_: Set<FilePath> = []
    private var didIdentifySourceFiles = false
    private var didIdentifyXibFiles = false
    private var didIdentifyInfoPlistFiles = false

    required init(project: XcodeProject, target: PBXTarget) {
        self.project = project
        self.target = target
    }

    var isTestTarget: Bool {
        return target.productType?.rawValue.contains("test") ?? false
    }

    var name: String {
        return target.name
    }

    func sourceFiles() throws -> Set<FilePath> {
        if didIdentifySourceFiles {
            return sourceFiles_
        }

        try identifySourceFiles()
        didIdentifySourceFiles = true
        return sourceFiles_
    }

    func xibFiles() throws -> Set<FilePath> {
        if didIdentifyXibFiles {
            return xibFiles_
        }

        try identifyXibFiles()
        didIdentifyXibFiles = true
        return xibFiles_
    }

    func infoPlistFiles() throws -> Set<FilePath> {
        if didIdentifyInfoPlistFiles {
            return infoPlistFiles_
        }

        try identifyInfoPlistFiles()
        didIdentifyInfoPlistFiles = true
        return infoPlistFiles_
    }

    // MARK: - Private

    private func identifySourceFiles() throws {
        let phases = project.xcodeProject.pbxproj.sourcesBuildPhases.filter { target.buildPhases.contains($0) }

        sourceFiles_ = Set(try phases.flatMap {
            try ($0.files ?? []).compactMap {
                let sourceRoot = project.sourceRoot.lexicallyNormalized()
                if let path = try $0.file?.fullPath(sourceRoot: Path(sourceRoot.string)),
                   path.extension?.lowercased() == "swift" {
                    return FilePath(path.absolute().string)
                }

                return nil
            }
        })
    }

    private func identifyXibFiles() throws {
        let phases = project.xcodeProject.pbxproj.resourcesBuildPhases.filter { target.buildPhases.contains($0) }

        xibFiles_ = Set(try phases.flatMap {
            try ($0.files ?? []).compactMap {
                let sourceRoot = project.sourceRoot.lexicallyNormalized()
                if let path = try $0.file?.fullPath(sourceRoot: Path(sourceRoot.string)),
                    ["xib", "storyboard"].contains(path.extension?.lowercased()) {
                    return FilePath(path.absolute().string)
                }

                return nil
            }
        })
    }

    private func identifyInfoPlistFiles() throws {
        let files = target.buildConfigurationList?.buildConfigurations.compactMap {
            $0.buildSettings["INFOPLIST_FILE"] as? String
        } ?? []
        infoPlistFiles_ = Set(files.map { parseInfoPlistSetting($0) })
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
