import Foundation
import XcodeProj
import PathKit
import PeripheryKit
import Shared

public final class XcodeWorkspace: XcodeProjectlike {
    public static func make(path: String) throws -> Self {
        return try self.init(path: path,
                             xcodebuild: inject(),
                             configuration: inject(),
                             logger: inject())
    }

    public let type: String = "workspace"
    public let path: Path
    public let sourceRoot: Path

    private let xcodebuild: Xcodebuild
    private let configuration: Configuration
    private let xcworkspace: XCWorkspace

    private(set) public var targets: Set<XcodeTarget> = []

    required public init(path: String, xcodebuild: Xcodebuild, configuration: Configuration, logger: Logger) throws {
        logger.debug("[xcode:workspace] Loading \(path)...")

        self.path = Path(path)
        self.xcodebuild = xcodebuild
        self.configuration = configuration
        self.sourceRoot = self.path.parent()

        do {
            self.xcworkspace = try XCWorkspace(pathString: self.path.absolute().string)
        } catch let error {
            throw PeripheryError.underlyingError(error)
        }

        let projectPaths = collectProjectPaths(in: xcworkspace.data.children)
        targets = Set(try projectPaths
            .compactMap { try XcodeProject.tryMake(path: (sourceRoot + $0), referencedBy: self.path) }
            .flatMap { $0.targets })
    }

    public func schemes() throws -> Set<XcodeScheme> {
        let schemes = try xcodebuild.schemes(project: self).map {
            try XcodeScheme.make(project: self, name: $0)
        }
        return Set(schemes)
    }

    // MARK: - Private

    private func collectProjectPaths(in elements: [XCWorkspaceDataElement], groups: [XCWorkspaceDataGroup] = []) -> [Path] {
        var paths: [Path] = []

        for child in elements {
            switch child {
            case .file(let ref):
                let basePath = Path(groups.map { $0.location.path }.joined(separator: "/"))
                let path = Path(ref.location.path)
                let fullPath = basePath + path

                if fullPath.extension == "xcodeproj" && shouldLoadProject(fullPath) {
                    paths.append(fullPath)
                }
            case .group(let group):
                paths += collectProjectPaths(in: group.children, groups: groups + [group])
            }
        }

        return paths
    }

    private func shouldLoadProject(_ path: Path) -> Bool {
        if configuration.guidedSetup && path.string.contains("Pods.xcodeproj") {
            return false
        }

        return true
    }
}
