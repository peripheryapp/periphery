import Foundation
import Shared

final class CommonSetupGuide: SetupGuideHelpers, SetupGuide {
    private let configuration: Configuration

    required init(configuration: Configuration = .shared) {
        self.configuration = configuration
        super.init()
    }

    func perform() throws {
        print(colorize("Assume all 'public' declarations are in use?", .bold))
        print(colorize("?", .boldYellow) + " Choose 'Yes' if your project is a framework/library without a main application target.")
        configuration.retainPublic = selectBoolean()
    }

    var commandLineOptions: [String] {
        var options: [String] = []

        if configuration.retainPublic {
            options.append("--retain-public")
        }

        return options
    }
}
