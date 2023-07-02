import Shared

final class RedundantExplicitPublicAccessibilityMarker: SourceGraphMutator {
    private let graph: SourceGraph
    private let configuration: Configuration

    required init(graph: SourceGraph, configuration: Configuration) {
        self.graph = graph
        self.configuration = configuration
    }

    func mutate() throws {
        guard !configuration.retainPublic else { return }
        guard !configuration.disableRedundantPublicAnalysis else { return }

        let nonExtensionKinds = graph.rootDeclarations.filter { !$0.kind.isExtensionKind }
        let extensionKinds = graph.rootDeclarations.filter { $0.kind.isExtensionKind }

        for decl in nonExtensionKinds {
            // Open declarations are not yet implemented.
            guard !decl.accessibility.isExplicitly(.open) else { continue }
            try validate(decl)
        }

        for decl in extensionKinds {
            // Open declarations are not yet implemented.
            guard !decl.accessibility.isExplicitly(.open) else { continue }
            try validateExtension(decl)
        }
    }

    // MARK: - Private

    private func validate(_ decl: Declaration) throws {
        // Check if the declaration is public, and is referenced cross module.
        if decl.accessibility.isExplicitly(.public) {
            if try !isReferencedCrossModule(decl) && !isExposedPubliclyByAnotherDeclaration(decl) && !graph.isRetained(decl) {
                // Public accessibility is redundant.
                mark(decl)
                markExplicitPublicDescendentDeclarations(from: decl)
            }

            // Note: we don't check the descendent declarations on correctly marked publicly accessible declarations
            // because it would lead to many warnings of questionable value. For example, it's common for a set of
            // properties to be marked public, even if they're not yet all used cross module.
        } else {
            // Declaration is not explicitly public, any explicit public descendants are therefore redundant.
            markExplicitPublicDescendentDeclarations(from: decl)
        }
    }

    private func validateExtension(_ decl: Declaration) throws {
        if decl.accessibility.isExplicitly(.public) {
            // If the extended kind is already marked as having redundant public accessibility, then this extension
            // must also have redundant accessibility.
            if let extendedDecl = try graph.extendedDeclaration(forExtension: decl),
               graph.redundantPublicAccessibility.keys.contains(extendedDecl) {
                mark(decl)
            }
        }
    }

    private func mark(_ decl: Declaration) {
        // This declaration may already be retained by a comment command.
        guard !graph.isRetained(decl) else { return }
        graph.markRedundantPublicAccessibility(decl, modules: decl.location.file.modules)
    }

    private func markExplicitPublicDescendentDeclarations(from decl: Declaration) {
        for descDecl in descendentPublicDeclarations(from: decl) {
            mark(descDecl)
        }
    }

    private func isExposedPubliclyByAnotherDeclaration(_ decl: Declaration) -> Bool {
        let referenceDecls = graph.references(to: decl)
            .compactMap {
                if $0.role.isPubliclyExposable {
                    if $0.role == .functionCallMetatypeArgument {
                        // This reference is a function metatype argument. If the called function
                        // also has generic metatype parameters, and returns any of the generic
                        // types, then we must assume the argument type is publicly accessible.
                        // Note that this isn't 100% accurate, as the metatype argument may not
                        // correspond to a generic type. However, it's too complex to match up
                        // the call site arguments with function parameters, as parameters with
                        // default types can cause misalignment between the positions of the two.
                        if let functionRef = $0.parent?.references.first(where: { $0.role == .variableInitFunctionCall }),
                           let functionDecl = graph.explicitDeclaration(withUsr: functionRef.usr),
                           functionDecl.hasGenericFunctionReturnedMetatypeParameters {
                            return $0.parent
                        }

                        return nil
                    } else if $0.role == .returnType, let parent = $0.parent {
                        // This reference is a return type. If the parent is a function used as a
                        // variable initializer, return the variable that references the function.
                        let variableDecl = graph
                            .references(to: parent)
                            .mapFirst { $0.role == .variableInitFunctionCall ? $0.parent : nil }
                        if let variableDecl {
                            return variableDecl
                        }
                    }

                    return $0.parent
                }

                return nil
            }

        return referenceDecls.contains { refDecl in
            refDecl.accessibility.value == .public || refDecl.accessibility.value == .open
        }
    }

    private func isReferencedCrossModule(_ decl: Declaration) throws -> Bool {
        let referenceModules = try nonTestableModulesReferencing(decl)
        return !referenceModules.subtracting(decl.location.file.modules).isEmpty
    }

    private func nonTestableModulesReferencing(_ decl: Declaration) throws -> Set<String> {
        let referenceFiles = graph.references(to: decl).mapSet { $0.location.file }

        let referenceModules = referenceFiles.flatMapSet { file -> Set<String> in
            let importsDeclModuleTestable = file.importStatements.contains(where: { (parts, isTestable) in
                isTestable && !Set(parts).isDisjoint(with: decl.location.file.modules)
            })

            if !importsDeclModuleTestable {
                return file.modules
            }

            return []
        }

        return referenceModules
    }

    private func descendentPublicDeclarations(from decl: Declaration) -> Set<Declaration> {
        let publicDeclarations = decl.declarations.filter { !$0.isImplicit && $0.accessibility.isExplicitly(.public) }
        return publicDeclarations.flatMapSet { descendentPublicDeclarations(from: $0) }.union(publicDeclarations)
    }
}
