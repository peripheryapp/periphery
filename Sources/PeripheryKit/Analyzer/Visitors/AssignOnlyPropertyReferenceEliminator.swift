import Foundation
import Shared

final class AssignOnlyPropertyReferenceEliminator: SourceGraphVisitor {
    static func make(graph: SourceGraph) -> Self {
        return self.init(graph: graph, configuration: inject())
    }

    private let graph: SourceGraph
    private let configuration: Configuration

    required init(graph: SourceGraph, configuration: Configuration) {
        self.graph = graph
        self.configuration = configuration
    }

    func visit() throws {
        guard !configuration.retainAssignOnlyProperties else { return }

        let setters = graph.declarations(ofKind: .functionAccessorSetter)

        var assignOnlyProperties: [Declaration: [Reference]] = [:]

        for setter in setters {
            let references = graph.references(to: setter)

            for reference in references {
                guard let caller = reference.parent,
                      let propertyName = setter.name?.replacingOccurrences(of: "setter:", with: ""),
                      let propertyReference = caller.references.first(where: { $0.kind.isVariableKind && $0.name == propertyName })
                else { continue }

                guard let property = graph.explicitDeclaration(withUsr: propertyReference.usr),
                      !property.isComplexProperty
                else { continue }

                // A protocol property can technically be assigned and never used when the protocol is used as an existential
                // type, however communicating that succinctly would be very tricky, and most likely just lead to confusion.
                // Here we filter out protocol properties and thus restrict this analysis only to concrete properties.
                if let parent = property.parent {
                    if parent.kind == .protocol {
                        continue
                    }
                }

                let getterName = "getter:\(propertyName)"
                let hasGetterReference = caller.references.contains { $0.kind == .functionAccessorGetter && $0.name == getterName }

                if !hasGetterReference {
                    assignOnlyProperties[property, default: []].append(propertyReference)
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
