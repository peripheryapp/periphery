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

    static func isEqual(_ lhs: SourceGraph, _ rhs: SourceGraph) -> Bool {
        lhs.rootDeclarations == rhs.rootDeclarations && lhs.rootReferences == rhs.rootReferences
            && zip(lhs.rootReferences, rhs.rootReferences).allSatisfy { isEqual($0, $1) }
            && zip(lhs.rootDeclarations, rhs.rootDeclarations).allSatisfy { isEqual($0, $1) }
    }

    static func isEqual(_ lhs: Entity, _ rhs: Entity, depth: Int = 0) -> Bool {
        lhs.references == rhs.references && lhs.declarations == rhs.declarations
            && zip(lhs.references, rhs.references).allSatisfy { isEqual($0, $1) }
            && zip(lhs.declarations, rhs.declarations).allSatisfy { isEqual($0, $1) }
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
