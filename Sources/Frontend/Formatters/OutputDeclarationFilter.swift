import Foundation
import Shared
import PeripheryKit

final class OutputDeclarationFilter: Injectable {
    static func make() -> Self {
        return self.init(configuration: inject(), logger: inject())
    }

    private let configuration: Configuration
    private let logger: Logger

    required init(configuration: Configuration, logger: Logger) {
        self.configuration = configuration
        self.logger = logger
    }

    func filter(_ declarations: [ScanResult]) -> [ScanResult] {
        let excludedSourceFiles = configuration.reportExcludeSourceFiles

        excludedSourceFiles.forEach {
            logger.debug("[report:exclude] \($0.string)")
        }

        return declarations.filter {
            !excludedSourceFiles.contains($0.declaration.location.file.path)
        }
    }
}
