import Foundation

public struct ScanResult: Codable, Hashable {
    enum Annotation: Codable, Hashable {
        case unused
        case assignOnlyProperty
        case redundantProtocol(references: Set<Reference>, inherited: Set<String>)
        case redundantPublicAccessibility(modules: Set<String>)
    }

    let declaration: Declaration
    let annotation: Annotation
}
