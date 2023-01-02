import Foundation
import Shared

final class AssignOnlyPropertyReferenceEliminator: SourceGraphMutator {
    static func make(graph: SourceGraph) -> Self {
        return self.init(graph: graph, configuration: inject())
    }

    private let graph: SourceGraph
    private let configuration: Configuration

    required init(graph: SourceGraph, configuration: Configuration) {
        self.graph = graph
        self.configuration = configuration
    }

    func mutate() throws {
        guard !configuration.retainAssignOnlyProperties else { return }

        let setters = graph.declarations(ofKind: .functionAccessorSetter)
        var assignOnlyProperties: [Declaration: [Reference]] = [:]

        for setter in setters {
            let references = graph.references(to: setter)

            for reference in references {
                // Ensure the property being assigned is simple.
                guard
                    let caller = reference.parent,
                    let property = setter.parent,
                    !property.isComplexProperty
                else { continue }

                // Ensure the property hasn't been been explicitly retained, e.g by a comment command.
                guard !graph.isRetained(property) else { continue }

                // A protocol property can technically be assigned and never used when the protocol is used as an existential
                // type, however communicating that succinctly would be very tricky, and most likely just lead to confusion.
                // Here we filter out protocol properties and thus restrict this analysis only to concrete properties.
                guard property.parent?.kind != .protocol else { continue }

                // Find all references to the property at the same call site as the setter reference.
                let propertyReferences = caller.references.filter {
                    property.usrs.contains($0.usr) && $0.location == reference.location
                }

                // Determine if the containing method contains references to the property's getter accessor.
                let propertyGetterUSRs = property.declarations
                    .filter { $0.kind == .functionAccessorGetter }
                    .flatMap { $0.usrs }
                let hasGetterReference = caller.references
                    .contains { $0.kind == .functionAccessorGetter && propertyGetterUSRs.contains($0.usr) }

                if !hasGetterReference {
                    propertyReferences.forEach {
                        assignOnlyProperties[property, default: []].append($0)
                    }
                }
            }
        }

        for (property, references) in assignOnlyProperties {
            if let declaredType = property.declaredType,
               configuration.retainAssignOnlyPropertyTypes.contains(declaredType) {
                continue
            }

            graph.markPotentialAssignOnlyProperty(property)

            for reference in references {
                graph.remove(reference)
            }
        }
    }
}
