import Foundation

protocol ProjectDriver {
    func index(graph: SourceGraph) throws
}
