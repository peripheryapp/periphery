import Foundation
import SystemPackage
import Shared

protocol IndexExcludable {
    var configuration: Configuration { get }
    func filterIndexExcluded(from files: Set<FilePath>) -> (included: Set<FilePath>, excluded: Set<FilePath>)
}

extension IndexExcludable {
    func filterIndexExcluded(from files: Set<FilePath>) -> (included: Set<FilePath>, excluded: Set<FilePath>) {
        let included = files.filter { !configuration.indexExcludeSourceFiles.contains($0) }
        return (included, files.subtracting(included))
    }
}
