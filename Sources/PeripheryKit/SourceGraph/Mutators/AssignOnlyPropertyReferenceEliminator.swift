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

        for property in graph.declarations(ofKinds: Declaration.Kind.variableKinds) {
            guard let declaredType = property.declaredType,
                  !retainAssignOnlyPropertyTypes.contains(declaredType),
                  !graph.isRetained(property),
                  !property.isComplexProperty,
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
