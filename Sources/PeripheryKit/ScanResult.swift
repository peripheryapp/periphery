import Foundation
import SourceGraph

public struct ScanResult {
    enum Annotation {
        case unused
        case assignOnlyProperty
        case redundantProtocol(references: Set<Reference>, inherited: Set<String>)
        case redundantPublicAccessibility(modules: Set<String>)
        case redundantInternalAccessibility(suggestedAccessibility: Accessibility?)
        case redundantFilePrivateAccessibility(containingTypeName: String?)
        case superfluousIgnoreCommand
    }

    let declaration: Declaration
    let annotation: Annotation

    public var usrs: Set<String> {
        declaration.usrs
    }

    /// Indicates whether this result should be included in baselines.
    /// Superfluous ignore command results are excluded since they're warnings
    /// about unnecessary comments, not unused code.
    public var includeInBaseline: Bool {
        if case .superfluousIgnoreCommand = annotation { return false }
        return true
    }
}
