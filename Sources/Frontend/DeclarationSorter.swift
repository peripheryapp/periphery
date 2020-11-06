import Foundation
import PeripheryKit

final class DeclarationSorter {
    static func sort(_ declarations: Set<Declaration>) -> [Declaration] {
        return declarations.sorted(by: {
            if $0.location.file == $1.location.file {
                return ($0.location.line ?? 0) < ($1.location.line ?? 0)
            }

            return $0.location.file < $1.location.file
        })
    }
}
