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
        describe(sort(entities))
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

        for reference in sort(Array(entity.references)) {
            describe(reference, depth: depth + 1)
        }

        if let declaration = entity as? Declaration {
            for reference in sort(Array(declaration.related)) {
                describe(reference, depth: depth + 1)
            }
        }

        for declaration in sort(Array(entity.declarations)) {
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

private func sort(_ entities: [Entity]) -> [Entity] {
    return entities.sorted(by: {
        if $0.location.file == $1.location.file {
            return $0.location.line < $1.location.line
        }

        return $0.location.file < $1.location.file
    })
}
