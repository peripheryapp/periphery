import Foundation
import Synchronization

/// A shareable wrapper around `SourceGraph` providing synchronized access.
/// `Mutex` is non-copyable, so this reference type allows multiple indexers
/// to share the same lock-protected graph during concurrent indexing.
public final class SourceGraphMutex: @unchecked Sendable {
    private let graph: Mutex<SourceGraph>

    /// Self-synchronizing interner, safe to call without the graph lock.
    public let usrInterner: USRInterner

    public init(graph: SourceGraph) {
        self.graph = Mutex(graph)
        usrInterner = graph.usrInterner
    }

    public func reserveCapacity(forFileCount fileCount: Int) {
        graph.withLock { $0.reserveCapacity(forFileCount: fileCount) }
    }

    @discardableResult
    public func withLock<T>(_ body: (SourceGraph) throws -> T) rethrows -> T {
        try graph.withLock { try body($0) }
    }
}
