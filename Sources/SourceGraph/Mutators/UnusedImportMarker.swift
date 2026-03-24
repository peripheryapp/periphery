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
    private let retainedModules: Set<String>

    required init(graph: SourceGraph, configuration: Configuration, swiftVersion _: SwiftVersion) {
        self.graph = graph
        self.configuration = configuration
        retainedModules = Set(configuration.retainUnusedImportedModules)
    }

    private var wordCount: Int = 0
    private var emptyBitset = ModuleBitset(wordCount: 0)
    private var fileModuleBitsetCache: [ObjectIdentifier: ModuleBitset] = [:]
    private var extCacheFilled: [Bool] = []
    private var extCacheValues: [ModuleBitset] = []
    private var refTypesCached: [Bool] = []
    private var refTypesCacheValues: [Set<Reference>] = []

    private func fileModuleBitset(_ file: SourceFile) -> ModuleBitset {
        let oid = ObjectIdentifier(file)
        if let cached = fileModuleBitsetCache[oid] { return cached }
        let bitset = graph.moduleInterner.internBitset(file.modules, wordCount: wordCount)
        fileModuleBitsetCache[oid] = bitset
        return bitset
    }

    func mutate() throws {
        guard !configuration.disableUnusedImportAnalysis else { return }

        // Pre-intern all module names (source file modules, import statements,
        // retained modules) so that wordCount is stable for all bitsets.
        for file in graph.indexedSourceFiles {
            for name in file.modules {
                _ = graph.moduleInterner.intern(name)
            }
            for stmt in file.importStatements {
                _ = graph.moduleInterner.intern(stmt.module)
            }
        }
        for name in retainedModules {
            _ = graph.moduleInterner.intern(name)
        }

        wordCount = graph.moduleInterner.wordCount
        emptyBitset = ModuleBitset(wordCount: wordCount)
        let retainedModuleIDs = graph.moduleInterner.internBitset(retainedModules, wordCount: wordCount)

        let files = graph.indexedSourceFiles
        var fileToIndex = [ObjectIdentifier: Int](minimumCapacity: files.count)
        for (i, file) in files.enumerated() {
            fileToIndex[ObjectIdentifier(file)] = i
        }

        // Manual pointer instead of [UInt64] to eliminate bounds checking and
        // copy-on-write overhead in the inner loops that accumulate module bits.
        let totalWords = files.count * wordCount
        let perFileModules = UnsafeMutablePointer<UInt64>.allocate(capacity: totalWords)
        perFileModules.initialize(repeating: 0, count: totalWords)
        defer { perFileModules.deallocate() }

        let usrCount = graph.usrInterner.count
        var moduleCached = [Bool](repeating: false, count: usrCount)
        var moduleCacheValues = [ModuleBitset](repeating: emptyBitset, count: usrCount)
        extCacheFilled = [Bool](repeating: false, count: usrCount)
        extCacheValues = [ModuleBitset](repeating: emptyBitset, count: usrCount)
        refTypesCached = [Bool](repeating: false, count: usrCount)
        refTypesCacheValues = [Set<Reference>](repeating: [], count: usrCount)

        // Build a mapping of source files and the modules they reference.
        for ref in graph.allReferences {
            let idx = ref.usrID.rawValue

            if moduleCached[idx] {
                let modules = moduleCacheValues[idx]
                if !modules.isEmpty, let fileIdx = fileToIndex[ObjectIdentifier(ref.location.file)] {
                    let base = fileIdx * wordCount
                    for j in 0 ..< wordCount {
                        perFileModules[base + j] |= modules.words[j]
                    }
                }
                continue
            }

            var referencedModules = ModuleBitset(wordCount: wordCount)

            if let decl = graph.declaration(withUsrID: ref.usrID) {
                referencedModules.formUnion(fileModuleBitset(decl.location.file))
                let indirectRefs = referencedTypes(from: decl)

                for indirectRef in indirectRefs {
                    if let indirectDecl = graph.declaration(withUsrID: indirectRef.usrID) {
                        referencedModules.formUnion(fileModuleBitset(indirectDecl.location.file))
                    }
                    referencedModules.formUnion(modulesExtending(indirectRef))
                }

                if decl.isOverride {
                    for superDecl in graph.allSuperDeclarationsInOverrideChain(from: decl) {
                        referencedModules.formUnion(fileModuleBitset(superDecl.location.file))
                    }
                }
            }

            referencedModules.formUnion(modulesExtending(ref))
            moduleCached[idx] = true
            moduleCacheValues[idx] = referencedModules

            if !referencedModules.isEmpty, let fileIdx = fileToIndex[ObjectIdentifier(ref.location.file)] {
                let base = fileIdx * wordCount
                for j in 0 ..< wordCount {
                    perFileModules[base + j] |= referencedModules.words[j]
                }
            }
        }

        // For each source file, determine whether its imports are unused.
        for (fileIdx, file) in files.enumerated() {
            if configuration.retainFilesMatchers.anyMatch(filename: file.path.string) {
                continue
            }

            let base = fileIdx * wordCount
            let unreferencedImports = file.importStatements
                .filter {
                    let moduleID = graph.moduleInterner.intern($0.module)
                    let (word, bit) = moduleID.rawValue.quotientAndRemainder(dividingBy: 64)
                    return !$0.isConditional &&
                        !$0.commentCommands.contains(.ignore) &&
                        !$0.isExported &&
                        !retainedModuleIDs.contains(moduleID) &&
                        graph.isModuleIndexed(moduleID) &&
                        (perFileModules[base + word] & (1 &<< bit) == 0) &&
                        !graph.moduleExportsUnindexedModules(moduleID)
                }

            for unreferencedImport in unreferencedImports {
                let importModuleID = graph.moduleInterner.intern(unreferencedImport.module)

                // Check if any referenced module is exported by this import.
                var isExported = false
                for j in 0 ..< wordCount {
                    var bits = perFileModules[base + j]
                    while bits != 0 {
                        let bit = bits.trailingZeroBitCount
                        if graph.isModule(ModuleID(j * 64 + bit), exportedBy: importModuleID) {
                            isExported = true
                            break
                        }
                        bits &= bits &- 1
                    }
                    if isExported { break }
                }
                guard !isExported else { continue }

                graph.markUnusedModuleImport(unreferencedImport)
            }
        }
    }

    // MARK: - Private

    /// Identifies any modules that extend the given declaration reference, as they may provide
    /// members and conformances that are required for compilation.
    private func modulesExtending(_ ref: Reference) -> ModuleBitset {
        guard ref.declarationKind.isExtendableKind else {
            return emptyBitset
        }

        let idx = ref.usrID.rawValue

        if extCacheFilled[idx] {
            return extCacheValues[idx]
        }

        var modules = ModuleBitset(wordCount: wordCount)
        for extRef in graph.references(toUsrID: ref.usrID) {
            guard let parent = extRef.parent,
                  parent.kind == ref.declarationKind.extensionKind,
                  parent.name == ref.name
            else { continue }

            modules.formUnion(fileModuleBitset(parent.location.file))
        }
        extCacheFilled[idx] = true
        extCacheValues[idx] = modules
        return modules
    }

    /// Identifies types referenced by a declaration whose module must be imported for compilation.
    private func referencedTypes(from decl: Declaration) -> Set<Reference> {
        let cacheIdx: Int?
        if decl.usrIDs.count == 1 {
            let idx = decl.usrIDs[0].rawValue
            if refTypesCached[idx] {
                return refTypesCacheValues[idx]
            }
            cacheIdx = idx
        } else {
            cacheIdx = nil
        }

        let references: Set<Reference>

        if decl.kind.isVariableKind {
            references = decl.references.filter { $0.role == .varType }
        } else if decl.kind == .enumelement {
            references = decl.references
        } else if decl.kind == .typealias {
            let transitiveReferences = decl.references.flatMapSet { ref -> Set<Reference> in
                guard let refDecl = graph.declaration(withUsrID: ref.usrID) else { return [] }

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

        if let cacheIdx {
            refTypesCached[cacheIdx] = true
            refTypesCacheValues[cacheIdx] = references
        }

        return references
    }
}
