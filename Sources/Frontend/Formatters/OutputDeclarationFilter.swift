import Foundation
import SystemPackage
import Shared
import PeripheryKit

final class OutputDeclarationFilter {
    private let configuration: Configuration
    private let logger: ContextualLogger

    required init(configuration: Configuration = .shared, logger: Logger = .init()) {
        self.configuration = configuration
        self.logger = logger.contextualized(with: "report:filter")
    }

    func filter(_ declarations: [ScanResult]) -> [ScanResult] {
        let excludedSourceFiles = configuration.reportExcludeSourceFiles
        let includedSourceFiles = configuration.reportIncludeSourceFiles

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

            if !includedSourceFiles.isEmpty && !includedSourceFiles.contains(path) {
                return false
            }

            return true
        }
    }
}
