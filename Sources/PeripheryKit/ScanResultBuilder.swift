import Foundation

public struct ScanResultBuilder {
    public static func build(for graph: SourceGraph) -> [ScanResult] {
        let assignOnlyProperties = graph.assignOnlyProperties
        let removableDeclarations = graph.unusedDeclarations
            .subtracting(assignOnlyProperties)
            .union(graph.unusedModuleImports)
        let redundantProtocols = graph.redundantProtocols.filter { !removableDeclarations.contains($0.0) }
        let redundantPublicAccessibility = graph.redundantPublicAccessibility.filter { !removableDeclarations.contains($0.0) }

        let annotatedRemovableDeclarations: [ScanResult] = removableDeclarations.flatMap {
            var extensionResults = [ScanResult]()

            if $0.kind.isExtendableKind,
               !graph.retainedDeclarations.contains($0),
               !graph.ignoredDeclarations.contains($0) {
                let decls = $0.descendentDeclarations.union([$0])

                for decl in decls {
                    let extensions = graph.extensions[decl, default: []]
                    for ext in extensions {
                        extensionResults.append(ScanResult(declaration: ext, annotation: .unused))
                    }
                }
            }

            return [ScanResult(declaration: $0, annotation: .unused)] + extensionResults
        }
        let annotatedAssignOnlyProperties: [ScanResult] = assignOnlyProperties.map {
            .init(declaration: $0, annotation: .assignOnlyProperty)
        }
        let annotatedRedundantProtocols: [ScanResult] = redundantProtocols.map { decl, tuple in
            let (references, inherited) = tuple
            let inheritedNames = inherited.compactMapSet { $0.name }
            return .init(declaration: decl, annotation: .redundantProtocol(references: references, inherited: inheritedNames))
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
