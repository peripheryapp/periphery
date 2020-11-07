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

            for declaration in xibClass.declarations {
                let attributes = declaration.attributes

                if attributes.contains("IBOutlet") || attributes.contains("IBAction") {
                    declaration.markRetained()
                }
            }
        }
    }
}
