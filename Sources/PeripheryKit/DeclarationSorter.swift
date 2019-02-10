import Foundation

class DeclarationSorter {
    static func sort(_ declarations: Set<Declaration>) -> [Declaration] {
        return declarations.sorted(by: {
            if $0.location.file.path == $1.location.file.path {
                return ($0.location.line ?? 0) < ($1.location.line ?? 0)
            }

            return $0.location.file.path < $1.location.file.path
        })
    }
}
