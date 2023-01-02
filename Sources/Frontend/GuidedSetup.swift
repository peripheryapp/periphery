import Foundation
import Shared

#if canImport(XcodeSupport)
import XcodeSupport
#endif

final class GuidedSetup: SetupGuideHelpers {
    required init(configuration: Configuration = .shared) {
        self.configuration = configuration
    }

    private let configuration: Configuration

    func perform() throws -> Project {
        print(colorize("Welcome to Periphery!", .boldGreen))
        print("This guided setup will help you select the appropriate configuration for your project.\n")
        var projectGuides: [ProjectSetupGuide] = [SPMProjectSetupGuide()]

        #if os(macOS)
        projectGuides.append(XcodeProjectSetupGuide())
        #endif

        let supportedProjectGuides = projectGuides.filter { $0.isSupported }
        var projectGuide_: ProjectSetupGuide?

        if supportedProjectGuides.count > 1 {
            print(colorize("Please select which project to use:", .bold))
            let kindName = select(single: supportedProjectGuides.map { $0.projectKind.rawValue })
            projectGuide_ = supportedProjectGuides.first { $0.projectKind.rawValue == kindName }
            print("")
        } else {
            projectGuide_ = supportedProjectGuides.first
        }

        guard let projectGuide = projectGuide_ else {
            fatalError("Failed to identify project type.")
        }

        let project = Project(kind: projectGuide.projectKind)
        try project.validateEnvironment()

        print(colorize("*", .boldGreen) + " Inspecting project...\n")

        let commonGuide = CommonSetupGuide()
        let guides: [SetupGuide] = [projectGuide, commonGuide]
        try guides.forEach { try $0.perform() }
        let options = Array(guides.map { $0.commandLineOptions }.joined())

        print(colorize("\nSave configuration to \(Configuration.defaultConfigurationFile)?", .bold))
        let shouldSave = selectBoolean()

        if shouldSave {
            try configuration.save()
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
