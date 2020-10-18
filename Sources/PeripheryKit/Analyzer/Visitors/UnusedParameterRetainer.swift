import Foundation

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
        if configuration.useIndexStore {
            try IndexStoreRetainer(graph: graph, configuration: configuration).visit()
        } else {
            try SourceKitRetainer(graph: graph, configuration: configuration).visit()
        }
    }
}

private class IndexStoreRetainer {
    private let graph: SourceGraph
    private let configuration: Configuration

    required init(graph: SourceGraph, configuration: Configuration) {
        self.graph = graph
        self.configuration = configuration
    }

    func visit() throws {
        let allParams = graph.declarations(ofKind: .varParameter)
        let paramFunctions = allParams.compactMap { $0.parent as? Declaration }

        if configuration.retainUnusedProtocolFuncParams {
            retainProtocolFunctionParameters(in: paramFunctions)
        }

        retainExplicityIgnored(params: allParams)
        buildRelatedReferences(for: paramFunctions)
    }

    // MARK: - Private

    private func retainProtocolFunctionParameters(in funcDecls: [Declaration]) {
        funcDecls.forEach { funcDecl in
            if let parent = funcDecl.parent as? Declaration, parent.kind == .protocol {
                funcDecl.parameterDeclarations.forEach { $0.markRetained(reason: .protocolFuncParamForceRetained) }
            }
        }
    }

    private func retainExplicityIgnored(params: Set<Declaration>) {
        params.forEach { param in
            if param.name == "_" {
                param.markRetained(reason: .paramExplicitlyIgnored)
            }
        }
    }

    // For each parameter declaration, using the parent function declaration, find all related methods and build
    // bi-directional related references between each parameter.
    private func buildRelatedReferences(for funcDecls: [Declaration]) {
        for funcDecl in funcDecls {
            guard let funcRefKind = funcDecl.kind.referenceEquivalent else { continue }

            let funcRelated = funcDecl.related.filter({ $0.kind == funcRefKind && $0.name == funcDecl.name })

            for related in funcRelated {
                guard let relatedFuncDecl = graph.explicitDeclaration(withUsr: related.usr) else {
                    // Must be an external protocol conformance.
                    funcDecl.parameterDeclarations.forEach { $0.markRetained(reason: .paramFuncForeginProtocol) }
                    continue
                }

                for relatedParamDecl in relatedFuncDecl.parameterDeclarations {
                    guard let paramDecl = funcDecl.parameterDeclarations.first(where: { $0.name == relatedParamDecl.name }) else { continue }

                    let relatedRef1 = Reference(kind: .varParameter, usr: paramDecl.usr, location: paramDecl.location)
                    relatedRef1.isRelated = true
                    relatedRef1.name = paramDecl.name

                    graph.add(relatedRef1, from: relatedParamDecl)

                    let relatedRef2 = Reference(kind: .varParameter, usr: relatedParamDecl.usr, location: relatedParamDecl.location)
                    relatedRef2.isRelated = true
                    relatedRef2.name = relatedParamDecl.name

                    graph.add(relatedRef2, from: paramDecl)
                }
            }
        }
    }
}

private class SourceKitRetainer {
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
            let paramDecls = functionDecl.unusedParameters
            retain(paramDecls, inForeignProtocolFunction: functionDecl)
            retain(paramDecls, inOverriddenFunction: functionDecl)
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
                        functionDecl.unusedParameters.forEach { $0.markRetained(reason: .paramFuncLocalProtocol) }
                    } else {
                        retain(functionDecl.unusedParameters, usedIn: allFunctionDecls, reason: .paramFuncLocalProtocol)
                    }
                }
            }
        }
    }

    // MARK: - Private

    private func retain(_ params: Set<Declaration>, inForeignProtocolFunction decl: Declaration) {
        guard let refKind = decl.kind.referenceEquivalent,
              let related = decl.related.first(where: { $0.kind == refKind && $0.name == decl.name }) else { return }

        if graph.explicitDeclaration(withUsr: related.usr) == nil {
            params.forEach { $0.markRetained(reason: .paramFuncForeginProtocol) }
        }
    }

    private func retain(_ params: Set<Declaration>, inOverriddenFunction decl: Declaration) {
        guard let classDecl = decl.parent as? Declaration,
              classDecl.kind == .class else { return }

        let superclasses = graph.superclasses(of: classDecl)
        let subclasses = graph.subclasses(of: classDecl)
        let allClasses = superclasses + [classDecl] + subclasses
        var functionDecls: [Declaration] = []

        allClasses.forEach {
            let functionDecl = $0.declarations.first {
                $0.kind == decl.kind && $0.name == decl.name
            }

            if let functionDecl = functionDecl {
                functionDecls.append(functionDecl)
            }
        }

        guard let firstFunctionDecl = functionDecls.first else { return }

        if firstFunctionDecl.attributes.contains("override") {
            // Must be overriding a declaration in a foreign class.
            functionDecls.forEach {
                $0.unusedParameters.forEach { $0.markRetained(reason: .paramFuncOverridden) }
            }
        } else {
            // Retain all params that are used in any of the functions.
            retain(params, usedIn: functionDecls, reason: .paramFuncOverridden)
        }
    }

    private func retain(_ params: Set<Declaration>, usedIn functionDecls: [Declaration], reason: Declaration.RetentionReason) {
        for param in params {
            if isParam(param, usedInAnyOf: functionDecls) {
                param.markRetained(reason: reason)
            }
        }
    }

    private func isParam(_ param: Declaration, usedInAnyOf decls: [Declaration]) -> Bool {
        for decl in decls {
            let matchingParam = decl.unusedParameters.first { $0.name == param.name }

            if matchingParam?.isRetained ?? false {
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
