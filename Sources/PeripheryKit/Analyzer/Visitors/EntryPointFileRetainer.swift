import Foundation
import PathKit

final class EntryPointFileRetainer: SourceGraphVisitor {
    static func make(graph: SourceGraph) -> Self {
        return self.init(graph: graph, configuration: inject())
    }

    private let graph: SourceGraph
    private var entryPointFilenames = ["main.swift", "linuxmain.swift"]

    required init(graph: SourceGraph, configuration: Configuration) {
        self.graph = graph
        self.entryPointFilenames += configuration.entryPointFilenames
    }

    func visit() {
        graph.rootDeclarations.forEach {
            if isInMainFile($0) {
                $0.markRetained()
            }
        }
    }

    // MARK: - Private

    private func isInMainFile(_ entity: Entity) -> Bool {
        return entryPointFilenames.contains(entity.location.file.lastComponent.lowercased())
    }
}
