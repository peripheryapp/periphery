import Configuration
import Foundation
import Shared

final class AssignOnlyPropertyReferenceEliminator: SourceGraphMutator {
    private let graph: SourceGraph
    private let configuration: Configuration
    private let retainAssignOnlyPropertyTypes: [String]
    private let defaultRetainedTypes = ["AnyCancellable", "Set<AnyCancellable>", "[AnyCancellable]", "NSKeyValueObservation"]
    private let retainedAttributes = ["State", "Binding"]

    required init(graph: SourceGraph, configuration: Configuration, swiftVersion _: SwiftVersion) {
        self.graph = graph
        self.configuration = configuration
        retainAssignOnlyPropertyTypes = defaultRetainedTypes + configuration.retainAssignOnlyPropertyTypes.map {
            PropertyTypeSanitizer.sanitize($0)
        }
    }

    func mutate() throws {
        guard !configuration.retainAssignOnlyProperties else { return }

        for property in graph.declarations(ofKinds: Declaration.Kind.variableKinds) {
            guard let declaredType = property.declaredType,
                  !retainAssignOnlyPropertyTypes.contains(declaredType),
                  !graph.isRetained(property),
                  property.attributes.isDisjoint(with: retainedAttributes),
                  !property.isComplexProperty,
                  // A protocol property can technically be assigned and never used when the protocol is used as an existential
                  // type, however communicating that succinctly would be very tricky, and most likely just lead to confusion.
                  // Here we filter out protocol properties and thus restrict this analysis only to concrete properties.
                  property.parent?.kind != .protocol,
                  !graph.references(to: property).contains(where: { $0.parent?.parent?.kind == .protocol }),
                  let setter = property.declarations.first(where: { $0.kind == .functionAccessorSetter }),
                  let getter = property.declarations.first(where: { $0.kind == .functionAccessorGetter }),
                  graph.hasReferences(to: setter),
                  !graph.hasReferences(to: getter)
            else { continue }

            graph.markAssignOnlyProperty(property)
        }
    }
}
