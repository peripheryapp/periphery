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
            let baselineUsrs = baseline.usrs

            declarations = declarations.filter {
                let isIgnored = $0.usrs.contains { baselineUsrs.contains($0) }
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

        var matchCache: [FilePath: Bool] = [:]

        return declarations
            .filter { [contextualLogger] in
                var path = $0.declaration.location.file.path

                if let override = $0.declaration.commentCommands.locationOverride {
                    let (overridePath, _, _) = override
                    path = overridePath
                }

                if let cached = matchCache[path] { return cached }

                let included: Bool

                if configuration.reportIncludeMatchers.isEmpty {
                    if configuration.reportExcludeMatchers.anyMatch(filename: path.string) {
                        contextualLogger.debug("Excluding \(path)")
                        included = false
                    } else {
                        included = true
                    }
                } else if configuration.reportIncludeMatchers.anyMatch(filename: path.string) {
                    contextualLogger.debug("Including \(path)")
                    included = true
                } else {
                    included = false
                }

                matchCache[path] = included
                return included
            }
            .sorted { $0.declaration < $1.declaration }
    }
}
