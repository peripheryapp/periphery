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

        let filteredDeclarations = declarations.filter {
            !excludedSourceFiles.contains($0.location.file)
        }

        // Since Xcode 10.2 some unnamed declarations are reported at invalid locations.
        // We've no way currently to determine the correct USR and location of these declarations, so our only
        // option is to just hide them.
        return filteredDeclarations.filter { $0.name != nil }
    }
}
