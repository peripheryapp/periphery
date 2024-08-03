import Foundation
import SourceGraph
import SwiftIndexStore
import Shared

public protocol ProjectDriver {
    static func build() throws -> Self

    func build() throws
    func collect(logger: ContextualLogger) throws -> [SourceFile: [IndexUnit]]
    func index(
        sourceFiles: [SourceFile: [IndexUnit]],
        graph: SourceGraph,
        logger: ContextualLogger
    ) throws
}
