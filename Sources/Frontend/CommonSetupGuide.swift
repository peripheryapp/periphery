import Foundation
import Shared

final class CommonSetupGuide: SetupGuideHelpers, SetupGuide {
    private let configuration: Configuration

    required init(configuration: Configuration = .shared) {
        self.configuration = configuration
        super.init()
    }

    func perform() throws {
        print(colorize("\nAssume all 'public' declarations are in use?", .bold))
        print(colorize("?", .boldYellow) + " You should choose 'Yes' here if your public interfaces are not used by any selected build target, as may be the case for a framework/library project.")
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
