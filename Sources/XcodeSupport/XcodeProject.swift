import Foundation
import Shared
import SystemPackage
import XcodeProj

public final class XcodeProject: XcodeProjectlike {
    private static var cache: [FilePath: XcodeProject] = [:]

    public let type: String = "project"
    public let path: FilePath
    public let sourceRoot: FilePath
    public let name: String
    public private(set) var targets: Set<XcodeTarget> = []

    let xcodeProject: XcodeProj

    private let xcodebuild: Xcodebuild

    convenience init?(path: FilePath, referencedBy refPath: FilePath, shell: Shell, logger: Logger) throws {
        if !path.exists {
            logger.warn("No such project exists at '\(path.lexicallyNormalized())', referenced by '\(refPath)'.")
            return nil
        }

        let xcodebuild = Xcodebuild(shell: shell, logger: logger)
        try self.init(path: path, xcodebuild: xcodebuild, shell: shell, logger: logger)
    }

    public required init(path: FilePath, xcodebuild: Xcodebuild, shell: Shell, logger: Logger) throws {
        logger.contextualized(with: "xcode:project").debug("Loading \(path)")

        self.path = path
        self.xcodebuild = xcodebuild
        name = self.path.lastComponent?.stem ?? ""
        sourceRoot = self.path.removingLastComponent()

        do {
            xcodeProject = try XcodeProj(pathString: self.path.lexicallyNormalized().string)
        } catch {
            throw PeripheryError.underlyingError(error)
        }

        // Cache before loading sub-projects to avoid infinite loop from cyclic project references.
        XcodeProject.cache[path] = self

        var subProjects: [XcodeProject] = []

        // Don't search for sub projects within CocoaPods.
        if !path.components.contains("Pods.xcodeproj") {
            subProjects = try xcodeProject.pbxproj.fileReferences
                .filter { $0.path?.hasSuffix(".xcodeproj") ?? false }
                .compactMap { try $0.fullPath(sourceRoot: sourceRoot.string) }
                .compactMap { try XcodeProject(path: FilePath($0), referencedBy: path, shell: shell, logger: logger) }
        }

        targets = xcodeProject.pbxproj.nativeTargets
            .mapSet { XcodeTarget(project: self, target: $0) }
            .union(subProjects.flatMapSet { $0.targets })
    }

    public func schemes(additionalArguments: [String]) throws -> Set<String> {
        try xcodebuild.schemes(project: self, additionalArguments: additionalArguments)
    }
}

extension XcodeProject: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(path.lexicallyNormalized().string)
    }
}

extension XcodeProject: Equatable {
    public static func == (lhs: XcodeProject, rhs: XcodeProject) -> Bool {
        lhs.path == rhs.path
    }
}
