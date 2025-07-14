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
            guard let decl = graph.declaration(withUsr: ref.usr) else { continue }

            let referencedModules = decl.location.file.modules
                .union(modulesExtending(decl))
                .union(modulesDeclaringReferencedTypes(decl))
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
                        // Consider modules that have been indexed as we need to see which modules
                        // they export.
                        graph.indexedModules.contains($0.module) &&
                        !referencedModules.contains($0.module)
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

    private var extendedDeclCache: [Declaration: Set<String>] = [:]

    /// Identifies any modules that extend the given declaration, as they may provide members and
    /// conformances that are required for compilation.
    private func modulesExtending(_ decl: Declaration) -> Set<String> {
        guard decl.kind.isExtendableKind else { return [] }

        if let modules = extendedDeclCache[decl] {
            return modules
        }

        let modules: Set<String> = graph.references(to: decl)
            .flatMapSet {
                guard let parent = $0.parent,
                      parent.kind == decl.kind.extensionKind,
                      parent.name == decl.name
                else { return [] }

                return parent.location.file.modules
            }
        extendedDeclCache[decl] = modules
        return modules
    }

    /// Identifies modules that declare types referenced by the given declaration that are not
    /// referenced directly at the usage site of the declaration, but are required for compilation.
    ///
    /// For example, where a property is used, only the property declaration and its accessors are
    /// referenced. If the module that declares the property _type_ is different from the module
    /// that declares the property, then the import for the module declaring the type is required
    /// for compilation.
    private func modulesDeclaringReferencedTypes(_ decl: Declaration) -> Set<String> {
        guard decl.kind.isVariableKind ||
            decl.kind == .enumelement ||
            decl.kind == .typealias
        else { return [] }

        return decl.references.flatMapSet { ref in
            guard let refDecl = graph.declaration(withUsr: ref.usr) else { return [] }

            var modules = refDecl.location.file.modules

            if refDecl.kind == .typealias {
                // Follow a typealias to also include the module that declares the aliased type.
                modules.formUnion(modulesDeclaringReferencedTypes(refDecl))
            }

            return modules
        }
    }
}
