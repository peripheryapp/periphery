import Foundation

public struct ScanResultBuilder {
    public static func build(for graph: SourceGraph) -> [ScanResult] {
        let assignOnlyProperties = graph.assignOnlyProperties
        let removableDeclarations = graph.unusedDeclarations
            .subtracting(assignOnlyProperties)
            .union(graph.unusedModuleImports)
        let redundantProtocols = graph.redundantProtocols.filter { !removableDeclarations.contains($0.0) }
        let redundantPublicAccessibility = graph.redundantPublicAccessibility.filter { !removableDeclarations.contains($0.0) }

        let annotatedRemovableDeclarations: [ScanResult] = removableDeclarations.map {
            .init(declaration: $0, annotation: .unused)
        }
        let annotatedAssignOnlyProperties: [ScanResult] = assignOnlyProperties.map {
            .init(declaration: $0, annotation: .assignOnlyProperty)
        }
        let annotatedRedundantProtocols: [ScanResult] = redundantProtocols.map {
            let inherited = graph.inheritedTypeReferences(of: $0.0).compactMapSet { $0.name }
            return .init(declaration: $0.0, annotation: .redundantProtocol(references: $0.1, inherited: inherited))
        }
        let annotatedRedundantPublicAccessibility: [ScanResult] = redundantPublicAccessibility.map {
            .init(declaration: $0.0, annotation: .redundantPublicAccessibility(modules: $0.1))
        }
        let allAnnotatedDeclarations = annotatedRemovableDeclarations +
            annotatedAssignOnlyProperties +
            annotatedRedundantProtocols +
            annotatedRedundantPublicAccessibility

        let result = allAnnotatedDeclarations
            .filter {
                !$0.declaration.isImplicit &&
                !$0.declaration.kind.isAccessorKind &&
                !graph.ignoredDeclarations.contains($0.declaration) &&
                !graph.retainedDeclarations.contains($0.declaration)
            }

        return result
    }
}
