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
        interfaceBuilderPropertyRetainer.retainPropertiesDeclaredInExtensions()

        graph
            .declarations(ofKind: .class)
            .lazy
            .compactMap { declaration -> (AssetReference, Declaration)? in
                if let reference = self.reference(for: declaration) {
                    return (reference, declaration)
                }

                return nil
            }
            .forEach { reference, declaration in
                graph.markRetained(declaration)

                switch reference.source {
                case .xcDataModel:
                    // ValueTransformer subclasses are referenced by generated code that Periphery cannot analyze.
                    graph.unmarkRedundantPublicAccessibility(declaration)
                    declaration.descendentDeclarations.forEach { graph.unmarkRedundantPublicAccessibility($0) }
                case .interfaceBuilder:
                    interfaceBuilderPropertyRetainer.retainPropertiesDeclared(in: declaration)
                default:
                    break
                }
            }
    }

    // MARK: - Private

    private func reference(for declaration: Declaration) -> AssetReference? {
        graph.assetReferences.first { $0.name == declaration.name }
    }
}
