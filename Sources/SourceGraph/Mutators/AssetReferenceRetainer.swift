import Configuration
import Foundation
import Shared

/// Retains references from non-Swift assets, such as interface builder, Info.plist and CoreData models.
final class AssetReferenceRetainer: SourceGraphMutator {
    private let graph: SourceGraph
    private let interfaceBuilderPropertyRetainer: InterfaceBuilderPropertyRetainer

    required init(graph: SourceGraph, configuration _: Configuration, swiftVersion _: SwiftVersion) {
        self.graph = graph
        interfaceBuilderPropertyRetainer = .init(graph: graph)
    }

    func mutate() {
        // Aggregate all IB references by class name to collect all outlets/actions/attributes
        // across multiple XIB/storyboard files that might reference the same class.
        let ibReferencesByClass = aggregateInterfaceBuilderReferences()

        // Collect all runtime attributes for extension-based IBInspectable properties
        let allRuntimeAttributes = ibReferencesByClass.values.reduce(into: Set<String>()) { result, refs in
            result.formUnion(refs.runtimeAttributes)
        }
        interfaceBuilderPropertyRetainer.retainPropertiesDeclaredInExtensions(referencedAttributes: allRuntimeAttributes)

        graph
            .declarations(ofKind: .class)
            .lazy
            .compactMap { declaration -> ([AssetReference], Declaration)? in
                let references = self.references(for: declaration)
                if !references.isEmpty {
                    return (references, declaration)
                }

                return nil
            }
            .forEach { references, declaration in
                graph.markRetained(declaration)

                let sources = Set(references.map(\.source))

                if sources.contains(.xcDataModel) {
                    // ValueTransformer subclasses are referenced by generated code that Periphery cannot analyze.
                    graph.unmarkRedundantPublicAccessibility(declaration)
                    declaration.descendentDeclarations.forEach { graph.unmarkRedundantPublicAccessibility($0) }
                }

                if sources.contains(.interfaceBuilder) {
                    // Get aggregated references for this class
                    let aggregated = ibReferencesByClass[declaration.name ?? ""]
                    interfaceBuilderPropertyRetainer.retainPropertiesDeclared(
                        in: declaration,
                        referencedOutlets: aggregated?.outlets ?? [],
                        referencedActions: aggregated?.actions ?? [],
                        referencedAttributes: aggregated?.runtimeAttributes ?? []
                    )
                }
            }
    }

    // MARK: - Private

    private func references(for declaration: Declaration) -> [AssetReference] {
        graph.assetReferences.filter { $0.name == declaration.name }
    }

    /// Aggregates all Interface Builder references by class name, combining outlets, actions,
    /// and runtime attributes from all XIB/storyboard files that reference each class.
    private func aggregateInterfaceBuilderReferences() -> [String: (outlets: Set<String>, actions: Set<String>, runtimeAttributes: Set<String>)] {
        var result: [String: (outlets: Set<String>, actions: Set<String>, runtimeAttributes: Set<String>)] = [:]

        for ref in graph.assetReferences where ref.source == .interfaceBuilder {
            if result[ref.name] == nil {
                result[ref.name] = (outlets: [], actions: [], runtimeAttributes: [])
            }
            result[ref.name]?.outlets.formUnion(ref.outlets)
            result[ref.name]?.actions.formUnion(ref.actions)
            result[ref.name]?.runtimeAttributes.formUnion(ref.runtimeAttributes)
        }

        return result
    }
}
