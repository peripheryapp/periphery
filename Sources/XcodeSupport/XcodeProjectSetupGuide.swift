import Foundation
import SystemPackage
import Shared

public final class XcodeProjectSetupGuide: SetupGuideHelpers, SetupGuide {
    public static func detect() -> Self? {
        let workspacePaths = FilePath
            .glob("**/*.xcworkspace")
            .filter {
                // Swift Package Manager generates a xcworkspace inside the xcodeproj that isn't useful.
                !$0.string.contains(".xcodeproj/")
            }
        let projectPaths = FilePath.glob("**/*.xcodeproj")

        if workspacePaths.isEmpty && projectPaths.isEmpty {
            return nil
        }

        return Self(
            workspacePaths: workspacePaths,
            projectPaths: projectPaths
        )
    }

    private let workspacePaths: Set<FilePath>
    private let projectPaths: Set<FilePath>
    private let configuration: Configuration
    private let xcodebuild: Xcodebuild

    public required init(
        workspacePaths: Set<FilePath>,
        projectPaths: Set<FilePath>,
        configuration: Configuration = .shared,
        xcodebuild: Xcodebuild = .init()
    ) {
        self.workspacePaths = workspacePaths
        self.projectPaths = projectPaths
        self.configuration = configuration
        self.xcodebuild = xcodebuild
        super.init()
    }

    public var projectKindName: String {
        "Xcode"
    }

    public func perform() throws -> ProjectKind {
        try xcodebuild.ensureConfigured()

        var project: XcodeProjectlike?

        if let workspacePath = identifyWorkspace() {
            project = try XcodeWorkspace(path: workspacePath)
        } else if let projectPath = identifyProject() {
            project = try XcodeProject(path: projectPath)
        }

        guard let project else {
            throw PeripheryError.guidedSetupError(message: "Failed to find .xcworkspace or .xcodeproj in current directory")
        }

        let schemes = try filter(
            project.schemes(additionalArguments: configuration.xcodeListArguments),
            project
        ).map { $0 }.sorted()

        print(colorize("\nSelect the schemes necessary to build your chosen targets:", .bold))
        configuration.schemes = select(multiple: schemes, allowAll: false).selectedValues

        print(colorize("\nAssume Objective-C accessible declarations are in use?", .bold))
        print(colorize("?", .boldYellow) + " Declarations exposed to the Objective-C runtime explicitly with @objc, or implicitly by inheriting NSObject will be assumed to be in use. Choose 'No' if your project is pure Swift.")
        configuration.retainObjcAccessible = selectBoolean()

        return .xcode(projectPath: project.path)
    }

    public var commandLineOptions: [String] {
        var options: [String] = []

        if let project = configuration.project {
            options.append("--project \"\(project)\"")
        }

        options.append("--schemes " + configuration.schemes.map { "\"\($0)\"" }.joined(separator: ","))

        if configuration.retainObjcAccessible {
            options.append("--retain-objc-accessible")
        }

        return options
    }

    // MARK: - Private

    private func getPodSchemes(in project: XcodeProjectlike) throws -> Set<String> {
        let path = project.sourceRoot.appending("Pods/Pods.xcodeproj")
        guard path.exists else { return [] }
        return try xcodebuild.schemes(
            type: "project",
            path: path.lexicallyNormalized().string,
            additionalArguments: configuration.xcodeListArguments
        )
    }

    private func filter(_ schemes: Set<String>, _ project: XcodeProjectlike) throws -> [String] {
        let podSchemes = try getPodSchemes(in: project)
        return schemes
            .filter { !$0.hasPrefix("Pods-") }
            .filter { !podSchemes.contains($0) }
    }

    private func identifyWorkspace() -> FilePath? {
        var workspacePath: FilePath?

        if workspacePaths.count > 1 {
            print(colorize("Found multiple workspaces, please select the one that defines the schemes for building your project:", .bold))
            let workspaces = workspacePaths.map { $0.relativeTo(.current).string }
            let workspace = select(single: workspaces)
            workspacePath = FilePath.makeAbsolute(workspace)
            print("")
        } else {
            workspacePath = workspacePaths.first
        }

        if let workspacePath = workspacePath {
            configuration.project = workspacePath.relativeTo(.current)
            return workspacePath
        }

        return nil
    }

    private func identifyProject() -> FilePath? {
        var projectPath: FilePath?

        if projectPaths.count > 1 {
            print(colorize("Found multiple projects, please select the one that defines the schemes for building your project:", .bold))
            let projects = projectPaths.map { $0.relativeTo(.current).string }.sorted()
            let project = select(single: projects)
            projectPath = FilePath.makeAbsolute(project)
            print("")
        } else {
            projectPath = projectPaths.first
        }

        if let projectPath = projectPath {
            configuration.project = projectPath.relativeTo(.current)
            return projectPath
        }

        return nil
    }
}
