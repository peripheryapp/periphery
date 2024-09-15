import Configuration
import Foundation
import Shared

// Builds references to getters and setters from complex properties. A complex property is one that
// explicitly implements a get, set, willSet or didSet. Accessors are distinct declarations and hold
// references, rather than the property declaration itself. References are not built for implicit
// property accessors as they do not hold references.
final class ComplexPropertyAccessorReferenceBuilder: SourceGraphMutator {
    private let graph: SourceGraph

    required init(graph: SourceGraph, configuration _: Configuration, swiftVersion _: SwiftVersion) {
        self.graph = graph
    }

    func mutate() {
        let declarations = graph.declarations(ofKinds: Array(Declaration.Kind.accessorKinds))

        for declaration in declarations {
            guard let parent = declaration.parent else { continue }

            if parent.isComplexProperty {
                for usr in declaration.usrs {
                    let reference = Reference(kind: declaration.kind,
                                              usr: usr,
                                              location: declaration.location)
                    reference.parent = parent
                    graph.add(reference, from: parent)
                }
            }
        }
    }
}
