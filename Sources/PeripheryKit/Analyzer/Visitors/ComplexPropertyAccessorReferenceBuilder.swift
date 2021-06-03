import Foundation

// Builds references to getters and setters from complex properties. A complex property is one that
// explicitly implements a get, set, willSet or didSet. Accessors are distinct declarations and hold
// references, rather than the property declaration itself. References are not built for implicit
// property accessors as they do not hold references.
final class ComplexPropertyAccessorReferenceBuilder: SourceGraphVisitor {
    static func make(graph: SourceGraph) -> Self {
        return self.init(graph: graph)
    }

    private let graph: SourceGraph

    required init(graph: SourceGraph) {
        self.graph = graph
    }

    func visit() {
        let declarations = graph.declarations(ofKinds: Array(Declaration.Kind.accessorKinds))

        for declaration in declarations {
            guard let parent = declaration.parent,
                let kind = declaration.kind.referenceEquivalent else { continue }

            if parent.isComplexProperty {
                for usr in declaration.usrs {
                    let reference = Reference(kind: kind,
                                              usr: usr,
                                              location: declaration.location)
                    reference.parent = parent
                    graph.add(reference, from: parent)
                }
            }
        }
    }
}
