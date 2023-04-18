import Foundation

public struct ScanResult {
    public enum Annotation {
        case unused
        case assignOnlyProperty
        case redundantProtocol(references: Set<Reference>)
        case redundantPublicAccessibility(modules: Set<String>)
        case redundantInternalAccessibility(file: SourceFile)
        case redundantFilePrivateAccessibility(file: SourceFile)
    }

    public let declaration: Declaration
    public let annotation: Annotation
}
