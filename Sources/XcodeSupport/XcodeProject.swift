import Foundation
import XcodeProj
import SystemPackage
import PeripheryKit
import Shared

final class XcodeProject: XcodeProjectlike {
    private static var cache: [FilePath: XcodeProject] = [:]

    static func build(path: FilePath, referencedBy refPath: FilePath) throws -> XcodeProject? {
        if !path.exists {
            let logger = Logger()
            logger.warn("No such project exists at '\(path.lexicallyNormalized())', referenced by '\(refPath)'.")
            return nil
        }

        return try build(path: path)
    }

    static func build(path: FilePath) throws -> XcodeProject {
        if let cached = cache[path] {
            return cached
        }

        return try self.init(path: path)
    }

    let type: String = "project"
    let path: FilePath
    let sourceRoot: FilePath
    let xcodeProject: XcodeProj
    let name: String

    private let xcodebuild: Xcodebuild

    private(set) var targets: Set<XcodeTarget> = []
    private(set) var packageTargets: [SPM.Package: Set<SPM.Target>] = [:]

    required init(path: FilePath, xcodebuild: Xcodebuild = .init(), logger: Logger = .init()) throws {
        logger.contextualized(with: "xcode:project").debug("Loading \(path)")

        self.path = path
        self.xcodebuild = xcodebuild
        self.name = self.path.lastComponent?.stem ?? ""
        self.sourceRoot = self.path.removingLastComponent()

        do {
            self.xcodeProject = try XcodeProj(pathString: self.path.lexicallyNormalized().string)
        } catch let error {
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
                .compactMap { try XcodeProject.build(path: FilePath($0), referencedBy: path) }
        }

        targets = Set(xcodeProject.pbxproj.nativeTargets
            .map { XcodeTarget(project: self, target: $0) }
            + subProjects.flatMap { $0.targets })

        let packageTargetNames = Set(targets.flatMap { $0.packageDependencyNames })

        if !packageTargetNames.isEmpty {
            var packages: [SPM.Package] = []

            // The project file does not provide a clear way to identify file references for local SPM packages.
            // We need to iterate over all references and check for folders containing a Package.swift file.
            for fileRef in xcodeProject.pbxproj.fileReferences {
                // To avoid checking every single file reference, narrow our search down to the known file types Xcode uses
                // for package references.
                guard ["wrapper", "folder", "text"].contains(fileRef.lastKnownFileType),
                      let fullPath = try fileRef.fullPath(sourceRoot: sourceRoot.string)
                else { continue }

                let packagePath = FilePath(fullPath)

                if packagePath.appending("Package.swift").exists {
                    try packagePath.chdir {
                        let package = try SPM.Package.load()
                        packages.append(package)
                    }
                }
            }

            packageTargets = packageTargetNames.reduce(into: .init(), { result, targetName in
                for package in packages {
                    if let target = package.targets.first(where: { $0.name == targetName }) {
                        result[package, default: []].insert(target)

                        // Also include any test targets that depend upon this target, as they may be built by a scheme.
                        let testTargets = package.testTargets.filter { $0.depends(on: target) }
                        result[package, default: []].formUnion(testTargets)
                    }
                }
            })
        }
    }

    func schemes() throws -> Set<XcodeScheme> {
        let schemes = try xcodebuild.schemes(project: self).map {
            try XcodeScheme(project: self, name: $0)
        }
        return Set(schemes)
    }
}

extension XcodeProject: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(path.lexicallyNormalized().string)
    }
}

extension XcodeProject: Equatable {
    static func == (lhs: XcodeProject, rhs: XcodeProject) -> Bool {
        return lhs.path == rhs.path
    }
}
