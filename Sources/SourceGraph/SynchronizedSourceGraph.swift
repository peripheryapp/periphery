import Foundation
import Shared

/// A wrapper around for SourceGraph with synchronization for use during indexing.
public final class SynchronizedSourceGraph {
    private let graph: SourceGraph
    private let lock = UnfairLock()

    public init(graph: SourceGraph) {
        self.graph = graph
    }

    public func withLock<T>(_ block: () -> T) -> T {
        lock.perform(block)
    }

    public func indexingComplete() {
        graph.indexingComplete()
    }

    public func markRetained(_ declaration: Declaration) {
        withLock {
            graph.markRetained(declaration)
        }
    }

    public func addIndexedSourceFile(_ file: SourceFile) {
        withLock {
            graph.addIndexedSourceFile(file)
        }
    }

    public func addIndexedModules(_ modules: Set<String>) {
        withLock {
            graph.addIndexedModules(modules)
        }
    }

    public func addExportedModule(_ module: String, exportedBy exportingModules: Set<String>) {
        withLock {
            graph.addExportedModule(module, exportedBy: exportingModules)
        }
    }

    public func add(_ assetReference: AssetReference) {
        withLock {
            graph.add(assetReference)
        }
    }

    public func addUsedLocalizedStringKeys(_ keys: Set<String>) {
        withLock {
            graph.addUsedLocalizedStringKeys(keys)
        }
    }

    // MARK: - Without Lock

    public func removeWithoutLock(_ declaration: Declaration) {
        graph.remove(declaration)
    }

    public func declarationWithoutLock(withUsr usr: String) -> Declaration? {
        graph.declaration(withUsr: usr)
    }

    public func markRetainedWithoutLock(_ declaration: Declaration) {
        graph.markRetained(declaration)
    }

    public func markRetainedWithoutLock(_ declarations: Set<Declaration>) {
        graph.markRetained(declarations)
    }

    public func addWithoutLock(_ declaration: Declaration) {
        graph.add(declaration)
    }

    public func addWithoutLock(_ references: Set<Reference>) {
        graph.add(references)
    }

    public func addWithoutLock(_ declarations: Set<Declaration>) {
        graph.add(declarations)
    }
}
