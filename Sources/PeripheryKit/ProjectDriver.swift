import Foundation
import SourceGraph

public protocol ProjectDriver {
    static func build() throws -> Self

    func build() throws
    func index(graph: SourceGraph) throws
}
