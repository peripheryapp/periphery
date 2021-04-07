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

        var assignOnlyProperties: [(Declaration, Reference)] = []

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

                let getterName = "getter:\(propertyName)"
                let hasGetterReference = caller.references.contains { $0.kind == .functionAccessorGetter && $0.name == getterName }

                if !hasGetterReference {
                    assignOnlyProperties.append((property, propertyReference))
                }
            }
        }

        var retainedProperties: Set<Declaration> = []

        if !configuration.retainAssignOnlyPropertyTypes.isEmpty {
            let allProperties = Set(assignOnlyProperties.map { $0.0 })
            let propertiesByType = try PropertyTypeParser.parse(allProperties)

            for (type, properties) in propertiesByType {
                if configuration.retainAssignOnlyPropertyTypes.contains(type) {
                    retainedProperties.formUnion(properties)
                }
            }
        }

        for (property, reference) in assignOnlyProperties {
            if !retainedProperties.contains(property) {
                graph.remove(reference)
                property.analyzerHint = .assignOnlyProperty
            }
        }
    }
}
