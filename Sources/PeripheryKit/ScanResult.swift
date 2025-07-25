import Foundation
import SourceGraph

public struct ScanResult {
    enum Annotation {
        case unused
        case assignOnlyProperty
        case redundantProtocol(references: Set<Reference>, inherited: Set<String>)
        case redundantPublicAccessibility(modules: Set<String>)
        case redundantInternalAccessibility(files: Set<SourceFile>)
        case redundantFilePrivateAccessibility(files: Set<SourceFile>)
        case superfluousIgnoreCommand
    }

    let declaration: Declaration
    let annotation: Annotation

    public var usrs: Set<String> {
        if case .superfluousIgnoreCommand = annotation {
            return declaration.usrs.mapSet { "superfluous-ignore-\($0)" }
        }
        return declaration.usrs
    }
}
