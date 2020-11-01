import Foundation

/// Cascade objc.name attribute to members of classes attributed with objcMembers.
final class ObjcMembersAttributeBuilder: SourceGraphVisitor {
    static func make(graph: SourceGraph) -> Self {
        return self.init(graph: graph)
    }

    private let graph: SourceGraph

    required init(graph: SourceGraph) {
        self.graph = graph
    }

    func visit() {
        for clsDecl in graph.declarations(ofKind: .class) {
            guard clsDecl.attributes.contains("objcMembers") else { continue }

            for decl in clsDecl.declarations {
                guard decl.kind.isVariableKind || decl.kind.isFunctionKind else { continue }

                decl.attributes.insert("objc.name")
            }
        }
    }
}
