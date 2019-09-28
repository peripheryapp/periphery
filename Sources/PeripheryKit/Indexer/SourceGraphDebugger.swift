import Foundation

public final class SourceGraphDebugger {
    private let graph: SourceGraph

    required public init(graph: SourceGraph) {
        self.graph = graph
    }

    public func describeGraph() {
        describe(graph.rootDeclarations)
    }

    func describe(_ declarations: Set<Declaration>) {
        for (index, declaration) in declarations.enumerated() {
            describe(declaration)

            if index != declarations.count - 1 {
                print("")
            }
        }
    }

    func describe(_ entity: Entity, depth: Int = 0) {
        let inset = String(repeating: "··", count: depth)
        print(inset + entity.description)

        for reference in entity.references {
            describe(reference, depth: depth + 1)
        }

        if let declaration = entity as? Declaration {
            for reference in declaration.related {
                describe(reference, depth: depth + 1)
            }
        }

        for declaration in entity.declarations {
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
