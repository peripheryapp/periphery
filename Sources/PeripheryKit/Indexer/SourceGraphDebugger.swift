// periphery:ignore:all

import Foundation

public final class SourceGraphDebugger {
    private let graph: SourceGraph

    required public init(graph: SourceGraph) {
        self.graph = graph
    }

    public func describeGraph() {
        var entities: [Entity] = graph.rootDeclarations.map { $0 as Entity }
        entities += graph.rootReferences.map { $0 as Entity }
        describe(entities.sorted(by: { $0.usr < $1.usr }))
    }

    func describe(_ entities: [Entity]) {
        for (index, entity) in entities.enumerated() {
            describe(entity)

            if index != entities.count - 1 {
                print("")
            }
        }
    }

    func describe(_ entity: Entity, depth: Int = 0) {
        let inset = String(repeating: "··", count: depth)
        print(inset + entity.description)

        for reference in entity.references.sorted(by: { $0.usr < $1.usr }) {
            describe(reference, depth: depth + 1)
        }

        if let declaration = entity as? Declaration {
            for reference in declaration.related.sorted(by: { $0.usr < $1.usr }) {
                describe(reference, depth: depth + 1)
            }
        }

        for declaration in entity.declarations.sorted(by: { $0.usr < $1.usr }) {
            describe(declaration, depth: depth + 1)
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
