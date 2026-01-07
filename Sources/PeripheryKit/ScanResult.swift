import Foundation
import SourceGraph

public struct ScanResult {
    enum Annotation {
        case unused
        case assignOnlyProperty
        case redundantProtocol(references: Set<Reference>, inherited: Set<String>)
        case redundantPublicAccessibility(modules: Set<String>)
        case redundantInternalAccessibility(files: Set<SourceFile>, suggestedAccessibility: Accessibility?)
        case redundantFilePrivateAccessibility(files: Set<SourceFile>, containingTypeName: String?)
    }

    let declaration: Declaration
    let annotation: Annotation

    public var usrs: Set<String> {
        declaration.usrs
    }
}
