import Configuration
import Foundation
import Logger
import Shared

final class CommonSetupGuide: SetupGuideHelpers {
    private let configuration: Configuration

    required init(configuration: Configuration) {
        self.configuration = configuration
        super.init()
    }

    func perform() throws {
        print(Logger.colorize("\nAssume all 'public' declarations are in use?", .bold))
        print("Choose 'Yes' if your project is a framework/library without a main application target.")
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
