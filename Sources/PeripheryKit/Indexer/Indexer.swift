import Foundation
import SystemPackage
import Shared

public class Indexer {
    private let configuration: Configuration

    init(configuration: Configuration) {
        self.configuration = configuration
    }

    func filterIndexExcluded(from files: Set<FilePath>) -> (included: Set<FilePath>, excluded: Set<FilePath>) {
        let excludedFiles = configuration.indexExcludeSourceFiles
        let included = files.filter { !excludedFiles.contains($0) }
        return (included, files.subtracting(included))
    }
}
