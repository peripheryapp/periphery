import Foundation
import XcodeProj
import SystemPackage
import PeripheryKit
import Shared

final class XcodeWorkspace: XcodeProjectlike {
    static func make(path: FilePath) throws -> Self {
        return try self.init(path: path,
                             xcodebuild: inject(),
                             configuration: inject(),
                             logger: inject())
    }

    let type: String = "workspace"
    let path: FilePath
    let sourceRoot: FilePath

    private let xcodebuild: Xcodebuild
    private let configuration: Configuration
    private let xcworkspace: XCWorkspace

    private(set) var targets: Set<XcodeTarget> = []

    required init(path: FilePath, xcodebuild: Xcodebuild, configuration: Configuration, logger: Logger) throws {
        logger.contextualized(with: "xcode:workspace").debug("Loading \(path)")

        self.path = path
        self.xcodebuild = xcodebuild
        self.configuration = configuration
        self.sourceRoot = self.path.removingLastComponent()

        do {
            self.xcworkspace = try XCWorkspace(pathString: self.path.string)
        } catch let error {
            throw PeripheryError.underlyingError(error)
        }

        let projectPaths = collectProjectPaths(in: xcworkspace.data.children)
        targets = Set(try projectPaths
                        .compactMap { try XcodeProject.tryMake(path: (sourceRoot.pushing( $0)), referencedBy: self.path) }
            .flatMap { $0.targets })
    }

    func schemes() throws -> Set<XcodeScheme> {
        let schemes = try xcodebuild.schemes(project: self).map {
            try XcodeScheme.make(project: self, name: $0)
        }
        return Set(schemes)
    }

    // MARK: - Private

    private func collectProjectPaths(in elements: [XCWorkspaceDataElement], groups: [XCWorkspaceDataGroup] = []) -> [FilePath] {
        var paths: [FilePath] = []

        for child in elements {
            switch child {
            case .file(let ref):
                let basePath = FilePath(groups.map { $0.location.path }.filter { !$0.isEmpty }.joined(separator: "/"))
                let path = FilePath(ref.location.path)
                let fullPath = basePath.pushing(path)

                if fullPath.extension == "xcodeproj" && shouldLoadProject(fullPath) {
                    paths.append(fullPath)
                }
            case .group(let group):
                paths += collectProjectPaths(in: group.children, groups: groups + [group])
            }
        }

        return paths
    }

    private func shouldLoadProject(_ path: FilePath) -> Bool {
        if configuration.guidedSetup && path.string.contains("Pods.xcodeproj") {
            return false
        }

        return true
    }
}
