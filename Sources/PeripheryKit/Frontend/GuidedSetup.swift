import Foundation
import PathKit

class GuidedSetup: Injectable {
    static func make() -> Self {
        return self.init(configuration: inject(), logger: inject(), xcodebuild: inject())
    }

    private let configuration: Configuration
    private let logger: Logger
    private let xcodebuild: Xcodebuild

    required init(configuration: Configuration, logger: Logger, xcodebuild: Xcodebuild) {
        self.configuration = configuration
        self.logger = logger
        self.xcodebuild = xcodebuild
    }

    func perform() throws {
        print(colorize("Welcome to Periphery!", .boldGreen))
        print("This guided setup will help you select the appropriate configuration for your project.\n")
        print(colorize("*", .boldGreen) + " Inspecting project configuration...\n")

        var project: XcodeProjectlike?

        if let workspacePath = identifyWorkspace() {
            project = try Workspace.make(path: workspacePath)
        } else if let projectPath = identifyProject() {
            project = try Project.make(path: projectPath)
        }

        if let project = project {
            let targets = try selectTargets(in: project)
            targets.forEach { configuration.targets.append($0) }
            logger.debug("[targets] \(targets)")

            let schemes = try selectSchemes(in: project)
            schemes.forEach { configuration.schemes.append($0) }
            logger.debug("[schemes] \(schemes)")

            print(colorize("\nAssume all 'public' declarations are in use?", .bold))
            print(colorize("?", .boldYellow) + " You should choose Y here if your public interfaces are not used by any selected build target, such as may be the case for a framework project.")

            configuration.retainPublic = selectBoolean()

            print(colorize("\n*", .boldGreen) + " Executing command:")
            print(colorize(formatScanCommand() + "\n", .bold))
        } else {
            throw PeripheryKitError.guidedSetupError(message: "Failed to find .xcworkspace or .xcodeproj in current directory")
        }
    }

    // MARK: - Private

    private func identifyWorkspace() -> String? {
        var workspace: String?
        let paths = recursiveGlob("*.xcworkspace").filter {
            // Swift Package Manager generates a xcworkspace inside the xcodeproj that isn't useful.
            !$0.string.contains(".xcodeproj/")
        }

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

    private func identifyProject() -> String? {
        var project: String?
        let paths = recursiveGlob("*.xcodeproj")

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

    private func selectTargets(in project: XcodeProjectlike) throws -> [String] {
        guard !project.targets.isEmpty else {
            throw PeripheryKitError.guidedSetupError(message: "Failed to identify any targets in \(project.path.lastComponent)")
        }

        print(colorize("Select build targets to analyze:", .bold))
        let targetNames = project.targets.map { $0.name }.sorted()
        return select(multiple: targetNames)
    }

    private func selectSchemes(in project: XcodeProjectlike) throws -> [String] {
        let schemes = try filter(project.schemes(), project).map { $0.name }.sorted()
        print(colorize("\nSelect the schemes necessary to build your chosen targets:", .bold))
        return select(multiple: schemes)
    }

    private func getPodSchemes(in project: XcodeProjectlike) throws -> [String] {
        let path = project.sourceRoot + "Pods/Pods.xcodeproj"
        guard path.exists else { return [] }
        return try xcodebuild.schemes(type: "project", path: path.absolute().string)
    }

    private func select(single options: [String]) -> String {
        display(options: options)
        print(colorize("> ", .bold), terminator: "")

        if let strChoice = readLine(strippingNewline: true)?.trimmed,
            let choice = Int(strChoice) {
            if let option = options[safe: choice - 1] {
                return option
            } else {
                print(colorize("\nInvalid option: \(strChoice)\n", .boldYellow))
            }
        }

        print(colorize("\nInvalid input, expected a number.\n", .boldYellow))
        return select(single: options)
    }

    private func select(multiple options: [String]) -> [String] {
        print(colorize("?", .boldYellow) + " Delimit choices with a single space, e.g: 1 2 3")
        display(options: options)
        print(colorize("> ", .bold), terminator: "")
        var selected: [String] = []

        if let strChoices = readLine(strippingNewline: true)?.trimmed.split(separator: " ", omittingEmptySubsequences: true) {

            for strChoice in strChoices {
                if let choice = Int(strChoice),
                    let option = options[safe: choice - 1] {
                    selected.append(option)
                } else {
                    print(colorize("\nInvalid option: \(strChoice)\n", .boldYellow))
                    return select(multiple: options)
                }
            }
        }

        if !selected.isEmpty { return selected }

        print(colorize("\nInvalid input, expected a number.\n", .boldYellow))
        return select(multiple: options)
    }

    private func selectBoolean() -> Bool {
        print(
            "(" + colorize("Y", .boldGreen) + ")es" +
            "/" +
            "(" + colorize("N", .boldGreen) + ")o" +
            colorize(" > ", .bold),
            terminator: ""
        )

        if let answer = readLine(strippingNewline: true)?.trimmed.lowercased(),
            !answer.isEmpty {
            if ["y", "yes"].contains(answer) {
                return true
            } else if ["n", "no"].contains(answer) {
                return false
            }
        }

        print(colorize("\nInvalid input, expected 'y' or 'n'.\n", .boldYellow))
        return selectBoolean()
    }

    private func display(options: [String]) {
        let maxPaddingCount = String(options.count).count

        for (index, option) in options.enumerated() {
            let paddingCount = maxPaddingCount - String(index + 1).count
            let pading = String(repeating: " ", count: paddingCount)
            print(pading + colorize("\(index + 1) ", .boldGreen) + option)
        }
    }

    private func recursiveGlob(_ glob: String) -> [Path] {
        return Path.current.glob(glob) + Path.current.glob("**/\(glob)")
    }

    private func filter(_ schemes: Set<Scheme>, _ project: XcodeProjectlike) throws -> [Scheme] {
        let podSchemes = try Set(getPodSchemes(in: project))
        return schemes
            .filter { !$0.name.hasPrefix("Pods-") }
            .filter { !podSchemes.contains($0.name) }
    }

    private func formatScanCommand() -> String {
        var parts = ["periphery scan"]

        if let workspace = configuration.workspace {
            parts.append("--workspace \"\(workspace)\"")
        }

        if let project = configuration.project {
            parts.append("--project \"\(project)\"")
        }

        parts.append("--schemes " + configuration.schemes.map { "\"\($0)\"" }.joined(separator: ","))
        parts.append("--targets " + configuration.targets.map { "\"\($0)\"" }.joined(separator: ","))

        if configuration.retainPublic {
            parts.append("--retain-public")
        } else {
            parts.append("--no-retain-public")
        }

        return parts.joined(separator: " \\\n  ")
    }
}
