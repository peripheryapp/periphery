import Configuration
import Foundation
import SourceGraph

public enum ScanResultBuilder {
    public static func build(for graph: SourceGraph, configuration: Configuration) -> [ScanResult] {
        let assignOnlyProperties = graph.assignOnlyProperties
        let removableDeclarations = graph.unusedDeclarations
            .subtracting(assignOnlyProperties)
            .union(graph.unusedModuleImports)
        let redundantProtocols = graph.redundantProtocols.filter { !removableDeclarations.contains($0.0) }
        let redundantPublicAccessibility = graph.redundantPublicAccessibility.filter { !removableDeclarations.contains($0.0) }

        let annotatedRemovableDeclarations: [ScanResult] = removableDeclarations.flatMap { removableDeclaration in
            var extensionResults = [ScanResult]()

            if removableDeclaration.kind.isExtendableKind,
               !graph.retainedDeclarations.contains(removableDeclaration),
               !graph.ignoredDeclarations.contains(removableDeclaration)
            {
                let decls = removableDeclaration.descendentDeclarations.union([removableDeclaration])

                for decl in decls {
                    let extensions = graph.extensions[decl, default: []]
                    for ext in extensions {
                        extensionResults.append(ScanResult(declaration: ext, annotation: .unused))
                    }
                }
            }

            return [ScanResult(declaration: removableDeclaration, annotation: .unused)] + extensionResults
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

        let annotatedSuperfluousIgnoreCommands: [ScanResult] = {
            guard configuration.superfluousIgnoreComments else { return [] }

            // Detect superfluous ignore commands.
            let superfluousDeclarations = graph.commandIgnoredDeclarations
                .filter { _, kind in kind == .declaration }
                .keys
                .filter { decl in
                    hasReferencesFromNonIgnoredCode(decl, graph: graph)
                }

            // 2. Parameters with ignore comments that are actually used (not in unusedParameters)
            let superfluousParamResults = findSuperfluousParameterIgnores(graph: graph)

            return superfluousDeclarations
                .map { .init(declaration: $0, annotation: .superfluousIgnoreCommand) }
                + superfluousParamResults
        }()

        let allAnnotatedDeclarations = annotatedRemovableDeclarations +
            annotatedAssignOnlyProperties +
            annotatedRedundantProtocols +
            annotatedRedundantPublicAccessibility +
            annotatedSuperfluousIgnoreCommands

        return allAnnotatedDeclarations
            .filter { result in
                guard !result.declaration.isImplicit,
                      !result.declaration.kind.isAccessorKind,
                      !graph.ignoredDeclarations.contains(result.declaration)
                else { return false }

                // Superfluous ignore command results must bypass the retained filter below.
                // Declarations with ignore comments are always in retainedDeclarations (that's
                // how ignore comments work), so filtering them out would prevent us from ever
                // reporting superfluous ignore commands.
                if case .superfluousIgnoreCommand = result.annotation {
                    return true
                }

                return !graph.retainedDeclarations.contains(result.declaration)
            }
    }

    /// Checks if a declaration has references from code that is not part of the command ignored set.
    /// This indicates that the declaration would have been marked as used even without the ignore command.
    private static func hasReferencesFromNonIgnoredCode(_ decl: Declaration, graph: SourceGraph) -> Bool {
        let references = graph.references(to: decl)

        for ref in references {
            guard ref.kind != .retained, let parent = ref.parent else { continue }

            if graph.commandIgnoredDeclarations[parent] == nil {
                // Check that the parent is actually used (not itself unused)
                if graph.usedDeclarations.contains(parent) {
                    return true
                }
            }
        }

        return false
    }

    /// Finds parameters that have `// periphery:ignore:parameters` comments but are actually used.
    /// If a parameter is ignored but NOT in unusedParameters, it means it's used and the ignore is superfluous.
    private static func findSuperfluousParameterIgnores(graph: SourceGraph) -> [ScanResult] {
        var results: [ScanResult] = []

        for decl in graph.functionsWithIgnoredParameters {
            let ignoredParamNames = decl.commentCommands.ignoredParameterNames
            let unusedParamNames = Set(decl.unusedParameters.compactMap(\.name))

            for ignoredParamName in ignoredParamNames {
                if !unusedParamNames.contains(ignoredParamName) {
                    // The ignored parameter is actually used - create a result for it
                    let parentUsrs = decl.usrs.sorted().joined(separator: "-")
                    let usr = "param-\(ignoredParamName)-\(decl.name ?? "unknown-function")-\(parentUsrs)"
                    let paramDecl = Declaration(kind: .varParameter, usrs: [usr], location: decl.location)
                    paramDecl.name = ignoredParamName
                    paramDecl.parent = decl
                    results.append(.init(declaration: paramDecl, annotation: .superfluousIgnoreCommand))
                }
            }
        }

        return results
    }
}
