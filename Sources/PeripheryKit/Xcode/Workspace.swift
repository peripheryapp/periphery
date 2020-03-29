import Foundation
import XcodeProj
import PathKit

public final class Workspace: XcodeProjectlike {
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

    private(set) public var targets: Set<Target> = []

    required public init(path: String, xcodebuild: Xcodebuild, configuration: Configuration, logger: Logger) throws {
        logger.debug("[workspace] Loading \(path)...")

        self.path = Path(path)
        self.xcodebuild = xcodebuild
        self.configuration = configuration
        self.sourceRoot = self.path.parent()

        do {
            self.xcworkspace = try XCWorkspace(pathString: self.path.absolute().string)
        } catch let error {
            throw PeripheryKitError.underlyingError(error)
        }

        let projectPaths = collectProjectPaths(in: xcworkspace.data.children)
        targets = Set(try projectPaths
            .compactMap { try Project.tryMake(path: (sourceRoot + $0), referencedBy: self.path) }
            .flatMap { $0.targets })
    }

    public func schemes() throws -> Set<Scheme> {
        let schemes = try xcodebuild.schemes(project: self).map {
            try Scheme.make(project: self, name: $0)
        }
        return Set(schemes)
    }

    // MARK: - Private

    private func collectProjectPaths(in elements: [XCWorkspaceDataElement]) -> [Path] {
        var paths: [Path] = []

        for child in elements {
            switch child {
            case .file(let ref):
                let path = Path(ref.location.path)
                if path.extension == "xcodeproj" && shouldLoadProject(path) {
                    paths.append(path)
                }
            case .group(let group):
                paths += collectProjectPaths(in: group.children)
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
