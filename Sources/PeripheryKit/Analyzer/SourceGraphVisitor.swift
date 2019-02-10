import Foundation

protocol SourceGraphVisitor {
    static func make(graph: SourceGraph) -> Self
    func visit() throws
}
