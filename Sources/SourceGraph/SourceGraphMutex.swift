import Foundation
import Synchronization

/// A shareable wrapper around `SourceGraph` providing synchronized access.
/// `Mutex` is non-copyable, so this reference type allows multiple indexers
/// to share the same lock-protected graph during concurrent indexing.
public final class SourceGraphMutex: @unchecked Sendable {
    private let graph: Mutex<SourceGraph>

    public init(graph: SourceGraph) {
        self.graph = Mutex(graph)
    }

    @discardableResult
    public func withLock<T>(_ body: (SourceGraph) throws -> T) rethrows -> T {
        try graph.withLock { try body($0) }
    }
}
