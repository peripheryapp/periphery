import Foundation
import Shared

#if canImport(XcodeSupport)
    import XcodeSupport
#endif

final class GuidedSetup: SetupGuideHelpers {
    private let configuration: Configuration
    private let shell: Shell
    private let logger: Logger

    required init(configuration: Configuration, shell: Shell, logger: Logger) {
        self.configuration = configuration
        self.shell = shell
        self.logger = logger
    }

    func perform() throws -> Project {
        print(colorize("Welcome to Periphery!", .boldGreen))
        print("This guided setup will help you select the appropriate configuration for your project.\n")

        var projectGuides: [SetupGuide] = []

        if let guide = SPMProjectSetupGuide.detect() {
            projectGuides.append(guide)
        }

        #if canImport(XcodeSupport)
            if let guide = XcodeProjectSetupGuide(configuration: configuration, shell: shell, logger: logger) {
                projectGuides.append(guide)
            }
        #endif

        var projectGuide_: SetupGuide?

        if projectGuides.count > 1 {
            print(colorize("Please select which project to use:", .bold))
            let kindName = select(single: projectGuides.map(\.projectKindName))
            projectGuide_ = projectGuides.first { $0.projectKindName == kindName }
            print("")
        } else {
            projectGuide_ = projectGuides.first
        }

        guard let projectGuide = projectGuide_ else {
            fatalError("Failed to identify project type.")
        }

        print(colorize("*", .boldGreen) + " Inspecting project...")

        let kind = try projectGuide.perform()
        let project = Project(kind: kind, configuration: configuration, shell: shell, logger: logger)

        let commonGuide = CommonSetupGuide(configuration: configuration)
        try commonGuide.perform()

        let options = projectGuide.commandLineOptions + commonGuide.commandLineOptions
        var shouldSave = false

        if configuration.hasNonDefaultValues {
            print(colorize("\nSave configuration to \(Configuration.defaultConfigurationFile)?", .bold))
            shouldSave = selectBoolean()

            if shouldSave {
                try configuration.save()
            }
        }

        print(colorize("\n*", .boldGreen) + " Executing command:")
        print(colorize(formatScanCommand(options: options, didSave: shouldSave) + "\n", .bold))

        return project
    }

    // MARK: - Private

    private func formatScanCommand(options: [String], didSave: Bool) -> String {
        let bareCommand = "periphery scan"

        if didSave {
            return bareCommand
        }

        let parts = [bareCommand] + options
        return parts.joined(separator: " \\\n  ")
    }
}
