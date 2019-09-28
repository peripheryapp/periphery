import Foundation

// Since Xcode 10.2 declarations of classes marked @objcMembers do not have the objc.name attribute.
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
