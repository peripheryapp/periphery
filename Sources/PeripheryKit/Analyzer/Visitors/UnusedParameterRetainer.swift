import Foundation
import Shared

final class UnusedParameterRetainer: SourceGraphVisitor {
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
        let paramDecls = graph.declarations(ofKind: .varParameter)
        let functionDecls: Set<Declaration> = Set(paramDecls.compactMap { $0.parent as? Declaration })

        for functionDecl in functionDecls {
            retainIfNeeded(params: functionDecl.unusedParameters, inMethod: functionDecl)
        }

        let protocolDecls = graph.declarations(ofKind: .protocol)

        for protoDecl in protocolDecls {
            let extDecls = protoDecl.references
                .filter { $0.kind == .extensionProtocol && $0.name == protoDecl.name }
                .compactMap { graph.explicitDeclaration(withUsr: $0.usr) }

            // Since protocol declarations have no body, their params wil always be unused,
            // and thus present in functionDecls.
            let protoFuncDecls = protoDecl.declarations.filter { functionDecls.contains($0) }

            for protoFuncDecl in protoFuncDecls {
                let conformingDecls = protoFuncDecl.related
                    .filter { $0.kind.isFunctionKind && $0.name == protoFuncDecl.name }
                    .compactMap { graph.explicitDeclaration(withUsr: $0.usr) }
                let extFuncDecls = extDecls.flatMap {
                    $0.declarations.filter { $0.kind.isFunctionKind && $0.name == protoFuncDecl.name }
                }

                let allFunctionDecls = conformingDecls + extFuncDecls + [protoFuncDecl]

                for functionDecl in allFunctionDecls {
                    if configuration.retainUnusedProtocolFuncParams {
                        functionDecl.unusedParameters.forEach { graph.markRetained($0) }
                    } else {
                        retain(functionDecl.unusedParameters, usedIn: allFunctionDecls)
                    }
                }
            }
        }
    }

    // MARK: - Private

    private func retainIfNeeded(params: Set<Declaration>, inMethod methodDeclaration: Declaration) {
        let allMethodDeclarations: [Declaration]

        if let classDeclaration = methodDeclaration.parent as? Declaration, classDeclaration.kind == .class {
            let allClassDeclarations = [classDeclaration]
                + graph.superclasses(of: classDeclaration)
                + graph.subclasses(of: classDeclaration)

            allMethodDeclarations = allClassDeclarations.compactMap { declaration in
                declaration
                    .declarations
                    .lazy
                    .filter { $0.kind == methodDeclaration.kind }
                    .first { $0.name == methodDeclaration.name }
            }

            retainIfNeeded(
                params: params,
                inOverridenMethods: allMethodDeclarations
            )
        } else {
            allMethodDeclarations = [methodDeclaration]
        }

        retainParamsIfNeeded(inForeignProtocolMethods: allMethodDeclarations)
    }

    private func retainParamsIfNeeded(inForeignProtocolMethods methodDeclarations: [Declaration]) {
        guard let methodDeclaration = methodDeclarations.first else {
            return
        }

        guard let referenceKind = methodDeclaration.kind.referenceEquivalent else {
            return
        }

        let foreignReferences = methodDeclaration
            .related
            .lazy
            .filter { $0.kind == referenceKind }
            .filter { $0.name == methodDeclaration.name }
            .filter { self.graph.explicitDeclaration(withUsr: $0.usr) == nil }

        guard !foreignReferences.isEmpty else {
            return
        }

        methodDeclarations
            .lazy
            .flatMap { $0.unusedParameters }
            .forEach { graph.markRetained($0) }
    }

    private func retainIfNeeded(params: Set<Declaration>, inOverridenMethods methodDeclarations: [Declaration]) {
        let isSuperclassForeign = methodDeclarations.allSatisfy { declaration in
            declaration.modifiers.contains("override")
        }

        if isSuperclassForeign {
            // Must be overriding a declaration in a foreign class.
            methodDeclarations
                .lazy
                .flatMap { $0.unusedParameters }
                .forEach { graph.markRetained($0) }
        } else {
            // Retain all params that are used in any of the functions.
            retain(params, usedIn: methodDeclarations)
        }
    }

    private func retain(_ params: Set<Declaration>, usedIn functionDecls: [Declaration]) {
        for param in params {
            if isParam(param, usedInAnyOf: functionDecls) {
                graph.markRetained(param)
            }
        }
    }

    private func isParam(_ param: Declaration, usedInAnyOf decls: [Declaration]) -> Bool {
        for decl in decls {
            let matchingParam = decl.unusedParameters.first { $0.name == param.name }

            if let param = matchingParam, graph.isRetained(param) {
                // Already retained by a prior analysis.
                return true
            }

            if matchingParam == nil {
                // Used
                return true
            }
        }

        return false
    }
}
