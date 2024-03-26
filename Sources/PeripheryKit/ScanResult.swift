import Foundation

public struct ScanResult: Codable, Equatable, Hashable {
    enum Annotation: Codable, Equatable, Hashable {
        case unused
        case assignOnlyProperty
        case redundantProtocol(references: Set<Reference>, inherited: Set<String>)
        case redundantPublicAccessibility(modules: Set<String>)
    }

    let declaration: Declaration
    let annotation: Annotation
}
