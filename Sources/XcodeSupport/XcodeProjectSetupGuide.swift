import Foundation
import SystemPackage
import Shared

public final class XcodeProjectSetupGuide: SetupGuideHelpers, ProjectSetupGuide {
    private let configuration: Configuration
    private let xcodebuild: Xcodebuild

    public required init(configuration: Configuration = .shared, xcodebuild: Xcodebuild = .init()) {
        self.configuration = configuration
        self.xcodebuild = xcodebuild
        super.init()
    }

    public var projectKind: ProjectKind {
        return .xcode
    }

    public var isSupported: Bool {
        !projectPaths().isEmpty || !workspacePaths().isEmpty
    }

    public func perform() throws {
        var project: XcodeProjectlike?

        if let workspacePath = identifyWorkspace() {
            project = try XcodeWorkspace(path: workspacePath)
        } else if let projectPath = identifyProject() {
            project = try XcodeProject(path: projectPath)
        }

        if let project = project {
            guard !project.targets.isEmpty else {
                throw PeripheryError.guidedSetupError(message: "Failed to identify any targets in \(project.path.lastComponent?.string ?? "")")
            }

            var targets = project.targets.map { $0.name }
            targets += project.packageTargets.flatMap { (package, targets) in
                targets.map { "\(package.name).\($0.name)" }
            }
            targets = targets.sorted()

            print(colorize("Select build targets to analyze:", .bold))
            configuration.targets = select(multiple: targets, allowAll: true).selectedValues

            let schemes = try filter(project.schemes(), project).map { $0.name }.sorted()

            print(colorize("\nSelect the schemes necessary to build your chosen targets:", .bold))
            configuration.schemes = select(multiple: schemes, allowAll: false).selectedValues
        } else {
            throw PeripheryError.guidedSetupError(message: "Failed to find .xcworkspace or .xcodeproj in current directory")
        }

        print(colorize("\nAssume Objective-C accessible declarations are in use?", .bold))
        print(colorize("?", .boldYellow) + " Declarations exposed to the Objective-C runtime explicitly with @objc, or implicitly by inheriting NSObject will be assumed to be in use. Choose 'No' if your project is pure Swift.")
        configuration.retainObjcAccessible = selectBoolean()
    }

    public var commandLineOptions: [String] {
        var options: [String] = []

        if let workspace = configuration.workspace {
            options.append("--workspace \"\(workspace)\"")
        }

        if let project = configuration.project {
            options.append("--project \"\(project)\"")
        }

        options.append("--schemes " + configuration.schemes.map { "\"\($0)\"" }.joined(separator: ","))
        options.append("--targets " + configuration.targets.map { "\"\($0)\"" }.joined(separator: ","))

        if configuration.retainObjcAccessible {
            options.append("--retain-objc-accessible")
        }

        return options
    }

    // MARK: - Private

    private func getPodSchemes(in project: XcodeProjectlike) throws -> [String] {
        let path = project.sourceRoot.appending("Pods/Pods.xcodeproj")
        guard path.exists else { return [] }
        return try xcodebuild.schemes(type: "project", path: path.lexicallyNormalized().string)
    }

    private func filter(_ schemes: Set<XcodeScheme>, _ project: XcodeProjectlike) throws -> [XcodeScheme] {
        let podSchemes = try Set(getPodSchemes(in: project))
        return schemes
            .filter { !$0.name.hasPrefix("Pods-") }
            .filter { !podSchemes.contains($0.name) }
    }

    private func identifyWorkspace() -> FilePath? {
        var workspacePath: FilePath?
        let paths = workspacePaths()

        if paths.count > 1 {
            print(colorize("Found multiple workspaces, please select the one that defines the schemes for building your project:", .bold))
            let workspaces = paths.map { $0.relativeTo(.current).string }
            let workspace = select(single: workspaces)
            workspacePath = FilePath.makeAbsolute(workspace)
            print("")
        } else {
            workspacePath = paths.first
        }

        if let workspacePath = workspacePath {
            configuration.workspace = workspacePath.relativeTo(.current).string
            return workspacePath
        }

        return nil
    }

    private func workspacePaths() -> Set<FilePath> {
        FilePath.glob("**/*.xcworkspace").filter {
            // Swift Package Manager generates a xcworkspace inside the xcodeproj that isn't useful.
            !$0.string.contains(".xcodeproj/")
        }
    }

    private func identifyProject() -> FilePath? {
        var projectPath: FilePath?
        let paths = projectPaths()

        if paths.count > 1 {
            print(colorize("Found multiple projects, please select the one that defines the schemes for building your project:", .bold))
            let projects = paths.map { $0.relativeTo(.current).string }.sorted()
            let project = select(single: projects)
            projectPath = FilePath.makeAbsolute(project)
            print("")
        } else {
            projectPath = paths.first
        }

        if let projectPath = projectPath {
            configuration.project = projectPath.relativeTo(.current).string
            return projectPath
        }

        return nil
    }

    private func projectPaths() -> Set<FilePath> {
        FilePath.glob("**/*.xcodeproj")
    }
}
