import Foundation

class InterfaceBuilderPropertyRetainer {
    private let graph: SourceGraph
    private let ibAttributes = ["IBOutlet", "IBAction", "IBInspectable"]

    required init(graph: SourceGraph) {
        self.graph = graph
    }

    /// Some properties may be declared in extensions on external types, e.g IBInspectable.
    func retainPropertiesDeclaredInExtensions() {
        let extensions = graph.declarations(ofKind: .extensionClass)

        for extDecl in extensions {
            for decl in extDecl.declarations {
                if decl.attributes.contains(where: { ibAttributes.contains($0) }) {
                    graph.markRetained(decl)
                }
            }
        }
    }

    func retainPropertiesDeclared(in declaration: Declaration) {
        let inheritedDeclarations = graph.inheritedDeclarations(of: declaration)
        let descendentInheritedDeclarations = inheritedDeclarations.map { $0.declarations }.joined()
        let allDeclarations = declaration.declarations.union(descendentInheritedDeclarations)

        for declaration in allDeclarations {
            if declaration.attributes.contains(where: { ibAttributes.contains($0) }) {
                graph.markRetained(declaration)
            }
        }
    }
}
