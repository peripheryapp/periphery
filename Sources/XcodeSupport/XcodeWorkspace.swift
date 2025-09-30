import Configuration
import Foundation
import Logger
import Shared
import SystemPackage
import XcodeProj

public final class XcodeWorkspace: XcodeProjectlike {
    public let type: String = "workspace"
    public let path: FilePath
    public let sourceRoot: FilePath

    private let xcodebuild: Xcodebuild
    private let configuration: Configuration
    private let xcworkspace: XCWorkspace

    public private(set) var targets: Set<XcodeTarget> = []

    public required init(path: FilePath, xcodebuild: Xcodebuild, configuration: Configuration, logger: Logger, shell: Shell) throws {
        logger.contextualized(with: "xcode:workspace").debug("Loading \(path)")

        self.path = path
        self.xcodebuild = xcodebuild
        self.configuration = configuration
        sourceRoot = self.path.removingLastComponent()

        do {
            xcworkspace = try XCWorkspace(pathString: self.path.string)
        } catch {
            throw PeripheryError.underlyingError(error)
        }

        let projectPaths = collectProjectPaths(in: xcworkspace.data.children)
        var loadedProjectPaths: Set<FilePath> = []
        let projects = try projectPaths.compactMapSet {
            try XcodeProject(path: sourceRoot.pushing($0), loadedProjectPaths: &loadedProjectPaths, referencedBy: self.path, shell: shell, logger: logger)
        }

        targets = projects.reduce(into: .init()) { result, project in
            result.formUnion(project.targets)
        }
    }

    public func schemes(additionalArguments: [String]) throws -> Set<String> {
        try xcodebuild.schemes(project: self, additionalArguments: additionalArguments)
    }

    // MARK: - Private

    private func collectProjectPaths(in elements: [XCWorkspaceDataElement], groups: [XCWorkspaceDataGroup] = []) -> [FilePath] {
        var paths: [FilePath] = []

        for child in elements {
            switch child {
            case let .file(ref):
                let basePath = FilePath(groups.map(\.location.path).filter { !$0.isEmpty }.joined(separator: "/"))
                let path = FilePath(ref.location.path)
                let fullPath = basePath.pushing(path)

                if fullPath.extension == "xcodeproj", shouldLoadProject(fullPath) {
                    paths.append(fullPath)
                }
            case let .group(group):
                paths += collectProjectPaths(in: group.children, groups: groups + [group])
            }
        }

        return paths
    }

    private func shouldLoadProject(_ path: FilePath) -> Bool {
        if configuration.guidedSetup, path.string.contains("Pods.xcodeproj") {
            return false
        }

        return true
    }
}
