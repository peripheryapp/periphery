import Foundation
import SystemPackage
import Shared
import FilenameMatcher

public class Indexer {
    private let configuration: Configuration

    init(configuration: Configuration) {
        self.configuration = configuration
    }

    func filterIndexExcluded(from files: Set<FilePath>) -> (included: Set<FilePath>, excluded: Set<FilePath>) {
        guard !configuration.indexExclude.isEmpty else { return (files, []) }

        let included = files.filter { !configuration.indexExcludeMatchers.anyMatch(filename: $0.string) }
        return (included, files.subtracting(included))
    }
}
