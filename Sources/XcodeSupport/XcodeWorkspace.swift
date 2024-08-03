import Foundation
import XcodeProj
import SystemPackage
import Shared

final class XcodeWorkspace: XcodeProjectlike {
    let type: String = "workspace"
    let path: FilePath
    let sourceRoot: FilePath

    private let xcodebuild: Xcodebuild
    private let configuration: Configuration
    private let xcworkspace: XCWorkspace

    private(set) var targets: Set<XcodeTarget> = []

    required init(path: FilePath, xcodebuild: Xcodebuild = .init(), configuration: Configuration = .shared, logger: Logger = .init()) throws {
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
        let projects = try projectPaths.compactMapSet { try XcodeProject.build(path: (sourceRoot.pushing($0)), referencedBy: self.path) }

        targets = projects.reduce(into: .init()) { result, project in
            result.formUnion(project.targets)
        }
    }

    func schemes(additionalArguments: [String]) throws -> Set<String> {
        try xcodebuild.schemes(project: self, additionalArguments: additionalArguments)
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
