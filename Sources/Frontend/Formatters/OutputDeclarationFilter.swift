import Foundation
import SystemPackage
import Shared
import PeripheryKit

final class OutputDeclarationFilter: Injectable {
    static func make() -> Self {
        return self.init(configuration: inject(), logger: inject())
    }

    private let configuration: Configuration
    private let logger: ContextualLogger

    required init(configuration: Configuration, logger: Logger) {
        self.configuration = configuration
        self.logger = logger.contextualized(with: "report:exclude")
    }

    func filter(_ declarations: [ScanResult]) -> [ScanResult] {
        let excludedSourceFiles = configuration.reportExcludeSourceFiles

        var reportedExclusions: Set<FilePath> = []

        return declarations.filter {
            let path = $0.declaration.location.file.path

            if excludedSourceFiles.contains(path) {
                if !reportedExclusions.contains(path) {
                    self.logger.debug(path.string)
                    reportedExclusions.insert(path)
                }

                return false
            }

            return true
        }
    }
}
