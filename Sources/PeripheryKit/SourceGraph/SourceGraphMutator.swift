import Foundation

protocol SourceGraphMutator: AnyObject {
    static func make(graph: SourceGraph) -> Self
    func mutate() throws
}
