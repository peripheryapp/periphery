import Foundation

// Aggressive Mode Only.
// Removes all references to the setter accessor of simple properties.
// Properties that aren't referenced via their getter will thus be identified as unused.
class UnreadSimplePropertyReferenceEliminator: SourceGraphVisitor {
    static func make(graph: SourceGraph) -> Self {
        return self.init(graph: graph, configuration: inject())
    }

    private let graph: SourceGraph
    private let configuration: Configuration

    required init(graph: SourceGraph, configuration: Configuration) {
        self.graph = graph
        self.configuration = configuration
    }

    func visit() {
        guard configuration.aggressive else { return }

        let setters = graph.declarations(ofKind: .functionAccessorSetter)

        for setter in setters {
            let references = graph.references(to: setter)

            for reference in references {
                // Parent should be a reference to a simple property.
                guard let propertyReference = reference.parent as? Reference,
                    let property = graph.declaration(withUsr: propertyReference.usr),
                    !property.isComplexProperty else { continue }

                // If the property reference has no other descendent references we can remove it.
                if propertyReference.references == [reference] {
                    graph.remove(propertyReference)
                    property.analyzerHints.append(.unreadProperty)
                    property.analyzerHints.append(.aggressive)
                }
            }
        }
    }
}
