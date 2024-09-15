import Configuration
import Logger

public extension Logger {
    @inlinable
    convenience init(configuration: Configuration) {
        self.init(quiet: configuration.quiet, verbose: configuration.verbose)
    }
}
