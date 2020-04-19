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
