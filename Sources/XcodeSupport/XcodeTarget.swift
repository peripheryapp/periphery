import Foundation
import XcodeProj
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
    private var sourceFiles_: Set<Path> = []
    private var xibFiles_: Set<Path> = []
    private var infoPlistFiles_: Set<Path> = []
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

    func sourceFiles() throws -> Set<Path> {
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

    func infoPlistFiles() throws -> Set<Path> {
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
                let sourceRoot = project.sourceRoot.absolute()
                if let path = try $0.file?.fullPath(sourceRoot: sourceRoot),
                   path.extension?.lowercased() == "swift" {
                    return path
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

    private func identifyInfoPlistFiles() throws {
        let files = target.buildConfigurationList?.buildConfigurations.compactMap {
            $0.buildSettings["INFOPLIST_FILE"] as? String
        } ?? []
        infoPlistFiles_ = Set(files.map { project.sourceRoot.absolute() + $0 })
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
