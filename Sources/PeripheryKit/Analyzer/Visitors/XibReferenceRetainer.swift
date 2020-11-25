import Foundation

final class XibReferenceRetainer: SourceGraphVisitor {
    static func make(graph: SourceGraph) -> Self {
        return self.init(graph: graph)
    }

    private let graph: SourceGraph

    required init(graph: SourceGraph) {
        self.graph = graph
    }

    func visit() {
        let classes = graph.declarations(ofKind: .class)
        let referencedClasses = classes.filter { cls in
            graph.xibReferences.contains { $0.className == cls.name }
        }

        for xibClass in referencedClasses {
            xibClass.markRetained()

            let superclasses = graph.superclasses(of: xibClass)
            let superclassesDecls = superclasses.map { $0.declarations }.joined()
            let allDecls = xibClass.declarations.union(superclassesDecls)

            for declaration in allDecls {
                let attributes = declaration.attributes

                if attributes.contains("IBOutlet") || attributes.contains("IBAction") || attributes.contains("IBInspectable") {
                    declaration.markRetained()
                }
            }
        }
    }
}
