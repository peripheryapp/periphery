// periphery:ignore:all

import Foundation

public final class SourceGraphDebugger {
    private let graph: SourceGraph

    required public init(graph: SourceGraph) {
        self.graph = graph
    }

    public func describeGraph() {
        describe(graph.rootDeclarations.sorted())
        describe(graph.rootReferences.sorted())
    }

    // MARK: - Private

    private func describe(_ declarations: [Declaration]) {
        for (index, declaration) in declarations.enumerated() {
            describe(declaration)

            if index != declarations.count - 1 {
                print("")
            }
        }
    }

    private func describe(_ references: [Reference]) {
        for (index, reference) in references.enumerated() {
            describe(reference)

            if index != references.count - 1 {
                print("")
            }
        }
    }

    private func describe(_ declaration: Declaration, depth: Int = 0) {
        let inset = String(repeating: "··", count: depth)
        print(inset + declaration.description)

        for reference in declaration.references.sorted() {
            describe(reference, depth: depth + 1)
        }

        for declaration in declaration.declarations.sorted() {
            describe(declaration, depth: depth + 1)
        }
    }

    private func describe(_ reference: Reference, depth: Int = 0) {
        let inset = String(repeating: "··", count: depth)
        print(inset + reference.description)

        for reference in reference.references.sorted() {
            describe(reference, depth: depth + 1)
        }
    }
}

final class SourceGraphDebuggerVisitor: SourceGraphVisitor {
    static func make(graph: SourceGraph) -> Self {
        return self.init(graph: graph)
    }

    private let debugger: SourceGraphDebugger

    required init(graph: SourceGraph) {
        debugger = SourceGraphDebugger(graph: graph)
    }

    func visit() {
        debugger.describeGraph()
    }
}
