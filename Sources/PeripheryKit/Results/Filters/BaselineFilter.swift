import Configuration
import Foundation
import Logger

struct BaselineFilter: OutputFilterable {
    private let configuration: Configuration
    private let baseline: Baseline?
    private let logger: Logger
    private let contextualLogger: ContextualLogger
    
    init(
        configuration: Configuration,
        baseline: Baseline?,
        logger: Logger,
        contextualLogger: ContextualLogger
    ) {
        self.configuration = configuration
        self.baseline = baseline
        self.logger = logger
        self.contextualLogger = contextualLogger
    }
    
    func filter(_ declarations: [ScanResult]) -> [ScanResult] {
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

        if configuration.reportInclude.isEmpty, configuration.reportExclude.isEmpty {
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
