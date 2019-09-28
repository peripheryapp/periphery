import Foundation

protocol Entity: CustomStringConvertible, AnyObject {
    var location: SourceLocation { get }
    var declarations: Set<Declaration> { get set }
    var references: Set<Reference> { get set }
    var parent: Entity? { get set }
}
