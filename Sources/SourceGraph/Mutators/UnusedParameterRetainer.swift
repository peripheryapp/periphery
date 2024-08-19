import Foundation
import Shared

final class UnusedParameterRetainer: SourceGraphMutator {
    private let graph: SourceGraph
    private let configuration: Configuration

    required init(graph: SourceGraph, configuration: Configuration) {
        self.graph = graph
        self.configuration = configuration
    }

    func mutate() throws {
        let functionDecls = graph
            .declarations(ofKind: .varParameter) // These are only unused params.
            .compactMapSet { $0.parent }

        retainParams(inFunctions: functionDecls)

        for protoDecl in graph.declarations(ofKind: .protocol) {
            let protoFuncDecls = protoDecl.declarations.filter { functionDecls.contains($0) }

            for protoFuncDecl in protoFuncDecls {
                let relatedFuncDecls = protoFuncDecl.related
                    .filter(\.kind.isFunctionKind)
                    .compactMapSet { graph.explicitDeclaration(withUsr: $0.usr) }
                let extFuncDecls = relatedFuncDecls.filter { $0.parent?.kind.isExtensionKind ?? false }
                let conformingDecls = relatedFuncDecls.subtracting(extFuncDecls)

                if conformingDecls.isEmpty {
                    // This protocol function declaration is not implemented, though it may still be referenced from an
                    // existential type. Leaving the function parameters as unused would put produce awkward results.
                    let allFunctionDecls = extFuncDecls + [protoFuncDecl]
                    for functionDecl in allFunctionDecls {
                        functionDecl.unusedParameters.forEach { graph.markRetained($0) }
                    }
                } else {
                    let overrideDecls = conformingDecls.flatMap { graph.allOverrideDeclarations(fromBase: $0) }
                    let allFunctionDecls = conformingDecls + overrideDecls + extFuncDecls + [protoFuncDecl]

                    for functionDecl in allFunctionDecls {
                        if configuration.retainUnusedProtocolFuncParams {
                            functionDecl.unusedParameters.forEach { graph.markRetained($0) }
                        } else {
                            retain(params: Array(functionDecl.unusedParameters), usedIn: allFunctionDecls)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Private

    private func retainParams(inFunctions functionDecls: Set<Declaration>) {
        var visitedDecls: Set<Declaration> = []

        for functionDecl in functionDecls {
            guard !visitedDecls.contains(functionDecl) else { continue }

            let (baseFunctionDecl, didResolveBase) = graph.baseDeclaration(fromOverride: functionDecl)
            let overrideFunctionDecls = graph.allOverrideDeclarations(fromBase: baseFunctionDecl)
            let allFunctionDecls = overrideFunctionDecls + [baseFunctionDecl]
            visitedDecls.formUnion(allFunctionDecls)

            if didResolveBase {
                if baseFunctionDecl.accessibility.value == .open, configuration.retainPublic {
                    retainAllUnusedParams(inMethods: allFunctionDecls)
                } else if hasExternalRelatedReferences(from: baseFunctionDecl) {
                    retainAllUnusedParams(inMethods: allFunctionDecls)
                } else {
                    let params = allFunctionDecls.flatMap(\.unusedParameters)
                    retain(params: params, usedIn: allFunctionDecls)
                }
            } else {
                retainAllUnusedParams(inMethods: allFunctionDecls)
            }
        }
    }

    private func hasExternalRelatedReferences(from decl: Declaration) -> Bool {
        decl.relatedEquivalentReferences.contains { graph.isExternal($0) }
    }

    private func retainAllUnusedParams(inMethods methodDeclarations: [Declaration]) {
        methodDeclarations
            .lazy
            .flatMap(\.unusedParameters)
            .forEach { graph.markRetained($0) }
    }

    private func retain(params: [Declaration], usedIn functionDecls: [Declaration]) {
        for param in params where isParam(param, usedInAnyOf: functionDecls) {
            graph.markRetained(param)
        }
    }

    private func isParam(_ param: Declaration, usedInAnyOf decls: [Declaration]) -> Bool {
        for decl in decls {
            let matchingParam = decl.unusedParameters.first { $0.name == param.name }

            if matchingParam == nil {
                // Used
                return true
            }

            if let param = matchingParam, graph.isRetained(param) {
                // Already retained by a prior analysis, e.g by an ignore command.
                return true
            }
        }

        return false
    }
}
