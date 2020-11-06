import Foundation
import PathKit
import Shared

final class GuidedSetup {
    static func make(project: Project) -> Self {
        return self.init(project: project, configuration: inject(), logger: inject())
    }

    private let project: Project
    private let configuration: Configuration
    private let logger: Logger

    required init(project: Project, configuration: Configuration, logger: Logger) {
        self.project = project
        self.configuration = configuration
        self.logger = logger
    }

    func perform() throws {
        print(colorize("Welcome to Periphery!", .boldGreen))
        print("This guided setup will help you select the appropriate configuration for your project.\n")
        print(colorize("*", .boldGreen) + " Project type: \(project.kind)")
        print(colorize("*", .boldGreen) + " Inspecting project...\n")

        let commonGuide = CommonSetupGuide.make()
        let projectGuide = project.setupGuide()
        let guides = [projectGuide, commonGuide]
        try guides.forEach { try $0.perform() }
        let options = Array(guides.map { $0.commandLineOptions }.joined())

        print(colorize("\n*", .boldGreen) + " Executing command:")
        print(colorize(formatScanCommand(options: options) + "\n", .bold))
    }

    // MARK: - Private

    private func formatScanCommand(options: [String]) -> String {
        let parts = ["periphery scan"] + options
        return parts.joined(separator: " \\\n  ")
    }
}
