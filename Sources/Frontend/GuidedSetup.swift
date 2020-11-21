import Foundation
import PathKit
import Shared

#if canImport(XcodeSupport)
import XcodeSupport
#endif

final class GuidedSetup: SetupGuideHelpers {
    func perform() throws {
        print(colorize("Welcome to Periphery!", .boldGreen))
        print("This guided setup will help you select the appropriate configuration for your project.\n")
        var projectGuides: [ProjectSetupGuide] = [SPMProjectSetupGuide.make()]

        #if os(macOS)
        projectGuides.append(XcodeProjectSetupGuide.make())
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

        print(colorize("*", .boldGreen) + " Inspecting project...\n")

        let commonGuide = CommonSetupGuide.make()
        let guides: [SetupGuide] = [projectGuide, commonGuide]
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
