import Foundation
import Shared

final class AssignOnlyPropertyReferenceEliminator: SourceGraphMutator {
    private let graph: SourceGraph
    private let configuration: Configuration
    private let retainAssignOnlyPropertyTypes: [String]
    private let defaultRetainedTypes = ["AnyCancellable", "Set<AnyCancellable>", "[AnyCancellable]", "NSKeyValueObservation"]

    required init(graph: SourceGraph, configuration: Configuration) {
        self.graph = graph
        self.configuration = configuration
        self.retainAssignOnlyPropertyTypes = defaultRetainedTypes + configuration.retainAssignOnlyPropertyTypes
    }

    func mutate() throws {
        guard !configuration.retainAssignOnlyProperties else { return }

        let setters = graph.declarations(ofKind: .functionAccessorSetter)
        var assignOnlyProperties: [Declaration: [Reference]] = [:]

        for setter in setters {
            // Ensure the property being assigned is simple.
            guard let property = setter.parent, !property.isComplexProperty else { continue }

            // Ensure the property hasn't been been explicitly retained, e.g by a comment command.
            guard !graph.isRetained(property) else { continue }

            // A protocol property can technically be assigned and never used when the protocol is used as an existential
            // type, however communicating that succinctly would be very tricky, and most likely just lead to confusion.
            // Here we filter out protocol properties and thus restrict this analysis only to concrete properties.
            guard property.parent?.kind != .protocol else { continue }

            let propertyGetterUSRs = property.declarations
                .filter { $0.kind == .functionAccessorGetter }
                .flatMap { $0.usrs }

            // TODO: Consider all static initializer scenarios
            if property.references.contains(where: { $0.role == .variableInitFunctionCall }) {
                // This property has a static function call initializer.
                // Check if the getter is referenced.
                let hasGetterReference = propertyGetterUSRs.contains { graph.hasReferences(to: $0) }

                if !hasGetterReference {
                    markPotentialAssignOnlyProperty(property: property)
                    continue
                }
            }

            let references = graph.references(to: setter)

            for reference in references {
                guard let caller = reference.parent else { continue }

                // Find all references to the property at the same call site as the setter reference.
                let propertyReferences = caller.references.filter {
                    property.usrs.contains($0.usr) && $0.location == reference.location
                }

                // Determine if the containing method contains references to the property's getter accessor.
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
            markPotentialAssignOnlyProperty(property: property, references: references)
        }
    }

    // MARK: - Private

    private func markPotentialAssignOnlyProperty(property: Declaration, references: [Reference] = []) {
        if let declaredType = property.declaredType,
           retainAssignOnlyPropertyTypes.contains(declaredType) {
            return
        }

        graph.markPotentialAssignOnlyProperty(property)

        for reference in references {
            graph.remove(reference)
        }
    }
}
