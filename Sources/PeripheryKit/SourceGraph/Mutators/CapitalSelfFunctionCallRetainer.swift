import Foundation
import Shared

/// Retains all constructors on types instantiated via `Self(...)` to workaround false positives caused by a bug in Swift.
/// https://bugs.swift.org/browse/SR-14181
/// https://github.com/peripheryapp/periphery/issues/264
final class CapitalSelfFunctionCallRetainer: SourceGraphMutator {
    private let graph: SourceGraph

    required init(graph: SourceGraph, configuration: Configuration) {
        self.graph = graph
    }

    func mutate() {
        for decl in graph.declarations(ofKinds: [.struct, .class]) {
            guard decl.hasCapitalSelfFunctionCall else { continue }
            decl.declarations
                .lazy
                .filter { $0.kind == .functionConstructor }
                .forEach { graph.markRetained($0) }
        }
    }
}
