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

                let getterName = "getter:\(propertyName)"
                let hasGetterReference = caller.references.contains { $0.kind == .functionAccessorGetter && $0.name == getterName }

                if !hasGetterReference {
                    assignOnlyProperties[property, default: []].append(propertyReference)
                }
            }
        }

        var retainedProperties: Set<Declaration> = []
        let allProperties = Set(assignOnlyProperties.map { $0.0 })

        // A protocol property can technically be assigned and never used when the protocol is used as an existential
        // type, however communicating that succinctly would be very tricky, and most likely just lead to confusion.
        // Here we filter out protocol properties and thus restrict this analysis only to concrete properties.
        allProperties
            .filter { ($0.parent as? Declaration)?.kind == .protocol }
            .forEach { retainedProperties.insert($0) }

        if !configuration.retainAssignOnlyPropertyTypes.isEmpty {
            let propertiesByType = try PropertyTypeParser.parse(allProperties)

            for (type, properties) in propertiesByType {
                if configuration.retainAssignOnlyPropertyTypes.contains(type) {
                    retainedProperties.formUnion(properties)
                }
            }
        }

        for (property, references) in assignOnlyProperties {
            if !retainedProperties.contains(property) {
                property.analyzerHint = .assignOnlyProperty

                for reference in references {
                    graph.remove(reference)
                }
            }
        }
    }
}
