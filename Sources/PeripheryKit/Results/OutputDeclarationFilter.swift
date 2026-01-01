import Configuration
import FilenameMatcher
import Foundation
import Logger
import SystemPackage

public final class OutputDeclarationFilter {
    private let configuration: Configuration
    private let logger: Logger
    private let contextualLogger: ContextualLogger

    public required init(configuration: Configuration, logger: Logger) {
        self.configuration = configuration
        self.logger = logger
        contextualLogger = logger.contextualized(with: "report:filter")
    }

    public func filter(_ declarations: [ScanResult], with baseline: Baseline?) throws -> [ScanResult] {
        var declarations = declarations

        if let baseline {
            var didFilterDeclaration = false
            let ignoredUsrs = declarations
                .flatMapSet(\.usrs)
                .intersection(baseline.usrs)

            declarations = declarations.filter {
                let isIgnored = $0.usrs.contains { ignoredUsrs.contains($0) }
                if isIgnored {
                    didFilterDeclaration = true
                }
                return !isIgnored
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
                var path = $0.declaration.location.file.path

                // If the declaration has a location override, use it as the path for filtering.
                if let override = $0.declaration.commentCommands.locationOverride {
                    let (overridePath, _, _) = override
                    path = overridePath
                }

                if configuration.reportIncludeMatchers.isEmpty {
                    if configuration.reportExcludeMatchers.anyMatch(filename: path.string) {
                        contextualLogger.debug("Excluding \(path)")
                        return false
                    }

                    return true
                }

                if configuration.reportIncludeMatchers.anyMatch(filename: path.string) {
                    contextualLogger.debug("Including \(path)")
                    return true
                }

                return false
            }
            .sorted { $0.declaration < $1.declaration }
    }
}
