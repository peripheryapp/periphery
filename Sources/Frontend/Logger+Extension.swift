import Configuration
import Logger

public extension Logger {
    @inlinable
    init(configuration: Configuration) {
        self.init(
            quiet: configuration.quiet,
            verbose: configuration.verbose,
            coloredOutputEnabled: configuration.color
        )
    }
}
