import Configuration
import Foundation
import Logger
import Shared
import SystemPackage

public final class XcodeProjectSetupGuide: SetupGuideHelpers, SetupGuide {
    private let workspacePaths: Set<FilePath>
    private let projectPaths: Set<FilePath>
    private let configuration: Configuration
    private let logger: Logger
    private let shell: Shell
    private let xcodebuild: Xcodebuild

    public convenience init?(configuration: Configuration, shell: Shell, logger: Logger) {
        let workspacePaths = FilePath
            .glob("**/*.xcworkspace")
            .filter {
                // Swift Package Manager generates a xcworkspace inside the xcodeproj that isn't useful.
                !$0.string.contains(".xcodeproj/")
            }
        let projectPaths = FilePath.glob("**/*.xcodeproj")

        if workspacePaths.isEmpty, projectPaths.isEmpty {
            return nil
        }

        self.init(
            workspacePaths: workspacePaths,
            projectPaths: projectPaths,
            configuration: configuration,
            shell: shell,
            logger: logger
        )
    }

    public required init(
        workspacePaths: Set<FilePath>,
        projectPaths: Set<FilePath>,
        configuration: Configuration,
        shell: Shell,
        logger: Logger
    ) {
        self.workspacePaths = workspacePaths
        self.projectPaths = projectPaths
        self.configuration = configuration
        self.logger = logger
        self.shell = shell
        xcodebuild = Xcodebuild(shell: shell, logger: logger)
        super.init()
    }

    public var projectKindName: String {
        "Xcode"
    }

    public func perform() throws -> ProjectKind {
        try xcodebuild.ensureConfigured()

        var project: XcodeProjectlike?

        if let workspacePath = identifyWorkspace() {
            project = try XcodeWorkspace(
                path: workspacePath,
                xcodebuild: xcodebuild,
                configuration: configuration,
                logger: logger,
                shell: shell
            )
        } else if let projectPath = identifyProject() {
            project = try XcodeProject(
                path: projectPath,
                xcodebuild: xcodebuild,
                shell: shell,
                logger: logger
            )
        }

        guard let project else {
            throw PeripheryError.guidedSetupError(message: "Failed to find .xcworkspace or .xcodeproj in current directory")
        }

        let schemes = try filter(
            project.schemes(additionalArguments: configuration.xcodeListArguments),
            project
        ).map(\.self).sorted()

        print(colorize("\nSelect the schemes to build:", .bold))
        print("Periphery will scan all files built by your chosen schemes.")
        configuration.schemes = select(multiple: schemes).selectedValues

        print(colorize("\nDoes this project contain Objective-C code?", .bold))
        let containsObjC = selectBoolean()

        if containsObjC {
            print(colorize("\nPeriphery cannot scan Objective-C code and, as a result, cannot detect Swift types referenced by Objective-C code.", .bold))
            print("To avoid false positives, you have a few options:")
            let retainObjcAccessibleOption = colorize("Assume all types accessible from Objective-C are in use:", .bold) + " This includes public NSObject instances (and their subclasses), as well as any types explicitly annotated with @objc. This approach will eliminate false positives but may also result in a lot of missed unused code."
            let retainObjcAnnotationOption = colorize("Assume only types annotated with @objc are in use:", .bold) + " This option may lead to false positives, but they can be easily corrected by adding the necessary @objc annotations."
            let objcChoice = select(single: [
                retainObjcAccessibleOption,
                retainObjcAnnotationOption,
                colorize("Do nothing:", .bold) + " Do not assume any Swift types are used in Objective-C code.",
            ])

            if objcChoice == retainObjcAccessibleOption {
                configuration.retainObjcAccessible = true
            } else if objcChoice == retainObjcAnnotationOption {
                configuration.retainObjcAnnotated = true
            }
        }

        return .xcode(projectPath: project.path)
    }

    public var commandLineOptions: [String] {
        var options: [String] = []

        if let project = configuration.project {
            options.append("--project \"\(project.string.withEscapedQuotes)\"")
        }

        options.append("--schemes " + configuration.schemes.map { "\"\($0.withEscapedQuotes)\"" }.joined(separator: ","))

        if configuration.retainObjcAccessible {
            options.append("--retain-objc-accessible")
        }

        if configuration.retainObjcAnnotated {
            options.append("--retain-objc-annotated")
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

        if let workspacePath {
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

        if let projectPath {
            configuration.project = projectPath.relativeTo(.current)
            return projectPath
        }

        return nil
    }
}
