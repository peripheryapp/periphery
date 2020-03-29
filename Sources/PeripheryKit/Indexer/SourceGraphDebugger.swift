import Foundation

public final class SourceGraphDebugger {
    private let graph: SourceGraph

    required public init(graph: SourceGraph) {
        self.graph = graph
    }

    public func describeGraph() {
        describe(graph.rootDeclarations.sorted(by: { $0.usr < $1.usr }))
    }

    func describe(_ declarations: [Declaration]) {
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

    static func isEqual(_ lhs: SourceGraph, _ rhs: SourceGraph) -> Bool {
        lhs.rootDeclarations.count == rhs.rootDeclarations.count
            && lhs.rootReferences.count == rhs.rootReferences.count
            && zip(lhs.rootReferences, rhs.rootReferences).allSatisfy { isEqual($0, $1) }
            && zip(lhs.rootDeclarations, rhs.rootDeclarations).allSatisfy { isEqual($0, $1) }
    }

    static func isEqual(_ lhs: Entity, _ rhs: Entity) -> Bool {
        let result = lhs.references.count == rhs.references.count
            && lhs.declarations.count == rhs.declarations.count
            && zip(lhs.references, rhs.references).allSatisfy { isEqual($0, $1) }
            && zip(lhs.declarations, rhs.declarations).allSatisfy { isEqual($0, $1) }
        if !result {
            print("⛔️ \(lhs.description) is not equal \(rhs.description)")
        }
        return result
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
