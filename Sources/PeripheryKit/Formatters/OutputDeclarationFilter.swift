import Foundation

public class OutputDeclarationFilter: Injectable {
    public static func make() -> Self {
        return self.init(configuration: inject(), logger: inject())
    }

    private let configuration: Configuration
    private let logger: Logger

    public required init(configuration: Configuration, logger: Logger) {
        self.configuration = configuration
        self.logger = logger
    }

    public func filter(_ declarations: Set<Declaration>) -> Set<Declaration> {
        let excludedSourceFiles = configuration.reportExcludeSourceFiles

        excludedSourceFiles.forEach {
            logger.debug("[report:exclude] \($0.path.string)")
        }

        return declarations.filter {
            !excludedSourceFiles.contains($0.location.file)
        }
    }
}
