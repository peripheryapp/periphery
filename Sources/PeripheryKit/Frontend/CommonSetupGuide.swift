import Foundation

final class CommonSetupGuide: SetupGuideHelpers, SetupGuide {
    static func make() -> Self {
        return self.init(configuration: inject())
    }

    private let configuration: Configuration

    required init(configuration: Configuration) {
        self.configuration = configuration
    }

    func perform() throws {
        print(colorize("\nAssume all 'public' declarations are in use?", .bold))
        print(colorize("?", .boldYellow) + " You should choose Y here if your public interfaces are not used by any selected build target, as may be the case for a framework/library project.")
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
