import Foundation

protocol Entity: CustomStringConvertible {
    var location: SourceLocation { get }
    var declarations: Set<Declaration> { get set }
    var references: Set<Reference> { get set }
    var parent: Entity? { get set }
}
