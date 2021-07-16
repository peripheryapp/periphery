import Foundation
import PeripheryKit
import Shared
import SystemPackage

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
        var visited: [FilePath: Bool] = [:]

        excludedSourceFiles.forEach {
            logger.debug("[report:exclude] \($0.string)")
        }
        
        return declarations.filter { result in

            let path = result.declaration.location.file.path

            if let previous = visited[path] {

                return previous
            }

            let contains = !excludedSourceFiles.contains { path.starts(with: $0) }
            visited[path] = contains

            return contains
        }
    }
}
