import Foundation

public protocol ProjectDriver {
    func build() throws
    func index(graph: SourceGraph) throws
}
