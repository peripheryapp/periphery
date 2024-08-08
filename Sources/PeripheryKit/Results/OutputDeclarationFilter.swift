import FilenameMatcher
import Foundation
import Shared
import SystemPackage

public final class OutputDeclarationFilter {
    private let configuration: Configuration
    private let logger: Logger
    private let contextualLogger: ContextualLogger

    public required init(configuration: Configuration = .shared, logger: Logger = .init()) {
        self.configuration = configuration
        self.logger = logger
        self.contextualLogger = logger.contextualized(with: "report:filter")
    }

    public func filter(_ declarations: [ScanResult], with baseline: Baseline?) throws -> [ScanResult] {
        var declarations = declarations

        if let baseline {
            var didFilterDeclaration = false
            declarations = declarations.filter {
                let isDisjoint = $0.usrs.isDisjoint(with: baseline.usrs)
                if !isDisjoint {
                    didFilterDeclaration = true
                }
                return isDisjoint
            }

            if !didFilterDeclaration {
                logger.warn("No results were filtered by the baseline.")
            }
        }

        if configuration.reportInclude.isEmpty && configuration.reportExclude.isEmpty {
            return declarations.sorted { $0.declaration < $1.declaration }
        }

        return declarations
            .filter { [contextualLogger] in
                let path = $0.declaration.location.file.path

                if configuration.reportIncludeMatchers.isEmpty {
                    if configuration.reportExcludeMatchers.anyMatch(filename: path.string) {
                        contextualLogger.debug("Excluding \(path.string)")
                        return false
                    }

                    return true
                }

                if configuration.reportIncludeMatchers.anyMatch(filename: path.string) {
                    contextualLogger.debug("Including \(path.string)")
                    return true
                }

                return false
            }
            .sorted { $0.declaration < $1.declaration }
    }
}
