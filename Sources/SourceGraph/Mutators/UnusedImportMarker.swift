import Configuration
import Foundation
import Shared

/// Marks unused import statements (experimental).
///
/// A module import is unused when the source file contains no references to it, and no other
/// imported modules either export it, or extend declarations declared by it.
final class UnusedImportMarker: SourceGraphMutator {
    private let graph: SourceGraph
    private let configuration: Configuration

    required init(graph: SourceGraph, configuration: Configuration, swiftVersion _: SwiftVersion) {
        self.graph = graph
        self.configuration = configuration
    }

    func mutate() throws {
        guard !configuration.disableUnusedImportAnalysis else { return }

        var referencedModulesByFile = graph.indexedSourceFiles.reduce(into: [SourceFile: Set<String>]()) { result, file in
            result[file] = []
        }

        // Build a mapping of source files and the modules they reference.
        for ref in graph.allReferences {
            var directModules: Set<String> = []
            var indirectModules: Set<String> = []

            if let decl = graph.declaration(withUsr: ref.usr) {
                directModules = decl.location.file.modules
                let indirectRefs = referencedTypes(from: decl)

                indirectModules = indirectRefs
                    .compactMap { graph.declaration(withUsr: $0.usr) }
                    .flatMapSet(\.location.file.modules)
                    .union(indirectRefs.flatMapSet { modulesExtending($0) })

                if decl.isOverride {
                    let overrideModules = graph.allSuperDeclarationsInOverrideChain(from: decl)
                        .flatMapSet(\.location.file.modules)
                    indirectModules.formUnion(overrideModules)
                }
            }

            let referencedModules = directModules
                .union(indirectModules)
                .union(modulesExtending(ref))
            referencedModulesByFile[ref.location.file, default: []].formUnion(referencedModules)
        }

        // For each source file, determine whether its imports are unused.
        for (file, referencedModules) in referencedModulesByFile {
            // Ignore retained files.
            if configuration.retainFilesMatchers.anyMatch(filename: file.path.string) {
                continue
            }

            let unreferencedImports = file.importStatements
                .filter {
                    // Exclude ignore commented imports
                    !$0.commentCommands.contains(.ignore) &&
                        // Exclude exported/public imports because even though they may be unreferenced
                        // in the current file, their exported symbols may be referenced in others.
                        !$0.isExported &&
                        // Only Consider modules that have been indexed as we need to see which modules
                        // they export.
                        graph.isModuleIndexed($0.module) &&
                        !referencedModules.contains($0.module) &&
                        !graph.moduleExportsUnindexedModules($0.module)
                }

            for unreferencedImport in unreferencedImports {
                // In the simple case, a module is unused if it's not referenced. However, it's
                // possible the module exports other referenced modules.
                guard !referencedModules.contains(where: {
                    graph.isModule($0, exportedBy: unreferencedImport.module)
                }) else { continue }

                graph.markUnusedModuleImport(unreferencedImport)
            }
        }
    }

    // MARK: - Private

    private var extendedDeclCache: [String: Set<String>] = [:]

    /// Identifies any modules that extend the given declaration reference, as they may provide
    /// members and conformances that are required for compilation.
    private func modulesExtending(_ ref: Reference) -> Set<String> {
        guard ref.kind.isExtendableKind else { return [] }

        if let modules = extendedDeclCache[ref.usr] {
            return modules
        }

        let modules: Set<String> = graph.references(to: ref.usr)
            .flatMapSet {
                guard let parent = $0.parent,
                      parent.kind == ref.kind.extensionKind,
                      parent.name == ref.name
                else { return [] }

                return parent.location.file.modules
            }
        extendedDeclCache[ref.usr] = modules
        return modules
    }

    /// Identifies types referenced by a declaration whose module must be imported for compilation.
    private func referencedTypes(from decl: Declaration) -> Set<Reference> {
        let references: Set<Reference>

        if decl.kind.isVariableKind {
            references = decl.references.filter { $0.role == .varType }
        } else if decl.kind == .enumelement {
            references = decl.references
        } else if decl.kind == .typealias {
            let transitiveReferences = decl.references.flatMapSet { ref -> Set<Reference> in
                guard let refDecl = graph.declaration(withUsr: ref.usr) else { return [] }
                return referencedTypes(from: refDecl)
            }
            references = decl.references.union(transitiveReferences)
        } else if decl.kind.isFunctionKind {
            references = decl.references
                .filter {
                    [
                        .returnType,
                        .parameterType,
                    ].contains($0.role)
                }
        } else if decl.kind == .protocol {
            references = decl.related.filter { $0.role == .refinedProtocolType }
        } else {
            references = []
        }

        return references
    }
}
