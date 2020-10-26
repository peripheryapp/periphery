import Foundation
import XcodeProj
import PathKit

public final class XcodeProject: XcodeProjectlike {
    private static var cache: [Path: XcodeProject] = [:]

    public static func tryMake(path: Path, referencedBy refPath: Path) throws -> XcodeProject? {
        if !path.exists {
            let logger: Logger = inject()
            logger.warn("No such project exists at '\(path.absolute())', referenced by '\(refPath)'.")
            return nil
        }

        return try make(path: path)
    }

    public static func make(path: String) throws -> XcodeProject {
        return try make(path: Path(path))
    }

    public static func make(path: Path) throws -> XcodeProject {
        if let cached = cache[path] {
            return cached
        }

        return try self.init(path: path, xcodebuild: inject(), logger: inject())
    }

    public let type: String = "project"
    public let path: Path
    public let sourceRoot: Path
    public let xcodeProject: XcodeProj
    public let name: String

    private let xcodebuild: Xcodebuild

    private(set) public var targets: Set<XcodeTarget> = []

    required public init(path: Path, xcodebuild: Xcodebuild, logger: Logger) throws {
        logger.debug("[xcode:project] Loading \(path)...")

        self.path = path
        self.xcodebuild = xcodebuild
        self.name = self.path.lastComponentWithoutExtension
        self.sourceRoot = self.path.parent()

        do {
            self.xcodeProject = try XcodeProj(pathString: self.path.absolute().string)
        } catch let error {
            throw PeripheryKitError.underlyingError(error)
        }

        // Cache before loading sub-projects to avoid infinate loop from cyclic project references.
        XcodeProject.cache[path] = self

        var subProjects: [XcodeProject] = []

        // Don't search for sub projects within CocoaPods.
        if !path.contains("Pods.xcodeproj") {
            subProjects = try xcodeProject.pbxproj.fileReferences
                .filter { $0.path?.hasSuffix(".xcodeproj") ?? false }
                .compactMap { try $0.fullPath(sourceRoot: sourceRoot) }
                .compactMap { try XcodeProject.tryMake(path: $0, referencedBy: path) }
        }

        targets = Set(xcodeProject.pbxproj.nativeTargets
            .map { XcodeTarget.make(project: self, target: $0) }
            + subProjects.flatMap { $0.targets })
    }

    public func schemes() throws -> Set<XcodeScheme> {
        let schemes = try xcodebuild.schemes(project: self).map {
            try XcodeScheme.make(project: self, name: $0)
        }
        return Set(schemes)
    }
}

extension XcodeProject: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(path.absolute().string)
    }
}

extension XcodeProject: Equatable {
    public static func == (lhs: XcodeProject, rhs: XcodeProject) -> Bool {
        return lhs.path == rhs.path
    }
}
