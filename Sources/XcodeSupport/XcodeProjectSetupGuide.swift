import Foundation
import PathKit
import Shared

public final class XcodeProjectSetupGuide: SetupGuideHelpers, ProjectSetupGuide {
    public static func make() -> Self {
        return self.init(configuration: inject(), xcodebuild: inject())
    }

    private let configuration: Configuration
    private let xcodebuild: Xcodebuild

    required init(configuration: Configuration, xcodebuild: Xcodebuild) {
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
            project = try XcodeWorkspace.make(path: workspacePath)
        } else if let projectPath = identifyProject() {
            project = try XcodeProject.make(path: projectPath)
        }

        if let project = project {
            guard !project.targets.isEmpty else {
                throw PeripheryError.guidedSetupError(message: "Failed to identify any targets in \(project.path.lastComponent)")
            }

            let targets = project.targets.map { $0.name }.sorted()
            let schemes = try filter(project.schemes(), project).map { $0.name }.sorted()

            print(colorize("Select build targets to analyze:", .bold))
            configuration.targets = select(multiple: targets, allowAll: true).selectedValues

            print(colorize("\nSelect the schemes necessary to build your chosen targets:", .bold))
            configuration.schemes = select(multiple: schemes, allowAll: false).selectedValues
        } else {
            throw PeripheryError.guidedSetupError(message: "Failed to find .xcworkspace or .xcodeproj in current directory")
        }

        print(colorize("\nAssume Objective-C accessible declarations are in use?", .bold))
        print(colorize("?", .boldYellow) + " Declarations exposed to the Objective-C runtime explicitly with @objc, or implicitly by inheriting NSObject will be assumed to be in use. You may want to choose 'Yes' here if your project contains a mix of Swift & Objective-C.")
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
        let path = project.sourceRoot + "Pods/Pods.xcodeproj"
        guard path.exists else { return [] }
        return try xcodebuild.schemes(type: "project", path: path.absolute().string)
    }

    private func filter(_ schemes: Set<XcodeScheme>, _ project: XcodeProjectlike) throws -> [XcodeScheme] {
        let podSchemes = try Set(getPodSchemes(in: project))
        return schemes
            .filter { !$0.name.hasPrefix("Pods-") }
            .filter { !podSchemes.contains($0.name) }
    }

    private func identifyWorkspace() -> String? {
        var workspace: String?
        let paths = workspacePaths()

        if paths.count > 1 {
            print(colorize("Found multiple workspaces, please select the one that defines the schemes for building your project:", .bold))
            let workspaces = paths.map { $0.relativeTo(Path.current).string }
            workspace = select(single: workspaces)
            print("")
        } else {
            workspace = paths.last?.string.trimmed
        }

        if let workspace = workspace {
            configuration.workspace = workspace
            return workspace
        }

        return nil
    }

    private func workspacePaths() -> [Path] {
        recursiveGlob("*.xcworkspace")
            .filter {
                // Swift Package Manager generates a xcworkspace inside the xcodeproj that isn't useful.
                !$0.string.contains(".xcodeproj/")
            }
            .filter {
                !$0.components.contains(".swiftpm")
            }
    }

    private func identifyProject() -> String? {
        var project: String?
        let paths = projectPaths()

        if paths.count > 1 {
            print(colorize("Found multiple projects, please select the one that defines the schemes for building your project:", .bold))
            let projects = paths.map { $0.relativeTo(Path.current).string }
            project = select(single: projects)
            print("")
        } else {
            project = paths.last?.string.trimmed
        }

        if let project = project {
            configuration.project = project
            return project
        }

        return nil
    }

    private func projectPaths() -> [Path] {
        recursiveGlob("*.xcodeproj")
    }

    private func recursiveGlob(_ glob: String) -> [Path] {
        return Path.current.glob(glob) + Path.current.glob("**/\(glob)")
    }
}
