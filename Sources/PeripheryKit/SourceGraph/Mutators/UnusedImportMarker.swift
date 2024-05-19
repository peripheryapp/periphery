import Foundation
import Shared

/// Marks unused import statements (experimental).
///
/// A module import is unused when the source file contains no references to it, and no other
/// imported modules either export it, or extend declarations declared by it.
///
/// Testing TODO:
/// * Exports, including nested exports
/// * Public declaration extended by another module
final class UnusedImportMarker: SourceGraphMutator {
    private let graph: SourceGraph
    private let configuration: Configuration

    required init(graph: SourceGraph, configuration: Configuration) {
        self.graph = graph
        self.configuration = configuration
    }

    func mutate() throws {
        guard !configuration.disableUnusedImportAnalysis else { return }

        var referencedModulesByFile = [SourceFile: Set<String>]()

        // Build a mapping of source files and the modules they reference.
        for ref in graph.allReferences {
            guard let decl = graph.explicitDeclaration(withUsr: ref.usr) else { continue }
            // Record directly referenced modules and also identify any modules that extended
            // the declaration. These extensions may provide members/conformances that aren't
            // referenced directly but which are still required.
            let referencedModules = decl.location.file.modules.union(modulesExtending(decl))
            referencedModulesByFile[ref.location.file, default: []].formUnion(referencedModules)
        }

        // For each source file, determine whether its imports are unused.
        for (file, referencedModules) in referencedModulesByFile {
            let unreferencedImports = file.importStatements
                .filter {
                    // Only consider modules that have been indexed as we need to see which modules
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

    /// Identifies any modules that extend the given declaration.
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
}
