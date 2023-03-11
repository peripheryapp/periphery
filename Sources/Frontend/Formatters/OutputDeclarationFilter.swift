import Foundation
import SystemPackage
import Shared
import PeripheryKit
import FilenameMatcher

final class OutputDeclarationFilter {
    private let configuration: Configuration
    private let logger: ContextualLogger

    required init(configuration: Configuration = .shared, logger: Logger = .init()) {
        self.configuration = configuration
        self.logger = logger.contextualized(with: "report:filter")
    }

    func filter(_ declarations: [ScanResult]) -> [ScanResult] {
        if configuration.reportInclude.isEmpty && configuration.reportExclude.isEmpty {
            return declarations
        }

        return declarations.filter {
            let path = $0.declaration.location.file.path

            if configuration.reportIncludeMatchers.isEmpty {
                if configuration.reportExcludeMatchers.anyMatch(filename: path.string) {
                    self.logger.debug("Excluding \(path.string)")
                    return false
                }

                return true
            }

            if configuration.reportIncludeMatchers.anyMatch(filename: path.string) {
                self.logger.debug("Including \(path.string)")
                return true
            }

            return false
        }
    }
}
