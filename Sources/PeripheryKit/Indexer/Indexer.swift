import Foundation
import SystemPackage
import Shared

public class Indexer {
    private let configuration: Configuration

    init(configuration: Configuration) {
        self.configuration = configuration
    }

    func filterIndexExcluded(from files: Set<FilePath>) -> (included: Set<FilePath>, excluded: Set<FilePath>) {
        let included = files.filter { !configuration.indexExcludeSourceFiles.contains($0) }
        return (included, files.subtracting(included))
    }
}
