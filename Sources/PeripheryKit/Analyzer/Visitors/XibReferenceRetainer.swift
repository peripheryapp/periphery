import Foundation

final class XibReferenceRetainer: SourceGraphVisitor {
    static func make(graph: SourceGraph) -> Self {
        return self.init(graph: graph)
    }

    private let graph: SourceGraph
    private let ibAttributes = ["IBOutlet", "IBAction", "IBInspectable"]

    required init(graph: SourceGraph) {
        self.graph = graph
    }

    func visit() {
        retainReferencedClasses()
        retainPropertiesDefinedInExtension()
    }

    // MARK: - Private

    private func retainReferencedClasses() {
        let classes = graph.declarations(ofKind: .class)
        let referencedClasses = classes.filter { cls in
            graph.xibReferences.contains { $0.className == cls.name }
        }

        for xibClass in referencedClasses {
            graph.markRetained(xibClass)

            let superclasses = graph.superclasses(of: xibClass)
            let superclassesDecls = superclasses.map { $0.declarations }.joined()
            let allDecls = xibClass.declarations.union(superclassesDecls)

            for declaration in allDecls {
                if declaration.attributes.contains(where: { ibAttributes.contains($0) }) {
                    graph.markRetained(declaration)
                }
            }
        }
    }

    private func retainPropertiesDefinedInExtension() {
        let extensions = graph.declarations(ofKind: .extensionClass)

        for extDecl in extensions {
            for decl in extDecl.declarations {
                if decl.attributes.contains(where: { ibAttributes.contains($0) }) {
                    graph.markRetained(decl)
                }
            }
        }
    }
}
