import Configuration
import Shared

final class RedundantFilePrivateAccessibilityMarker: SourceGraphMutator {
    private let graph: SourceGraph
    private let configuration: Configuration

    required init(graph: SourceGraph, configuration: Configuration, swiftVersion _: SwiftVersion) {
        self.graph = graph
        self.configuration = configuration
    }

    func mutate() throws {
        guard !configuration.disableRedundantFilePrivateAnalysis else { return }

        let nonExtensionKinds = graph.rootDeclarations.filter { !$0.kind.isExtensionKind }
        let extensionKinds = graph.rootDeclarations.filter(\.kind.isExtensionKind)

        for decl in nonExtensionKinds {
            try validate(decl)
        }

        for decl in extensionKinds {
            try validateExtension(decl)
        }
    }

    // MARK: - Private

    private func validate(_ decl: Declaration) throws {
        if decl.accessibility.isExplicitly(.fileprivate) {
            if !graph.isRetained(decl), !isReferencedOutsideFile(decl), !isReferencedFromDifferentTypeInSameFile(decl) {
                mark(decl)
            }
        }

        /*
          Always check descendents, even if parent is not redundant.

          A parent declaration may be used outside its file (making it not redundant),
          while still having child declarations that are only used within the same file
          (making those children redundant). For example, a class used cross-file may have
          a fileprivate property only referenced within the same file - that property should
          be flagged as redundant even though the parent class is not.
         */
        markExplicitFilePrivateDescendentDeclarations(from: decl)
    }

    private func validateExtension(_ decl: Declaration) throws {
        if decl.accessibility.isExplicitly(.fileprivate) {
            if let extendedDecl = try? graph.extendedDeclaration(forExtension: decl),
               graph.redundantFilePrivateAccessibility.keys.contains(extendedDecl)
            {
                mark(decl)
            }
        }
    }

    private func mark(_ decl: Declaration) {
        guard !graph.isRetained(decl) else { return }
        graph.markRedundantFilePrivateAccessibility(decl, file: decl.location.file)
    }

    private func markExplicitFilePrivateDescendentDeclarations(from decl: Declaration) {
        for descDecl in descendentFilePrivateDeclarations(from: decl) {
            if !graph.isRetained(descDecl), !isReferencedOutsideFile(descDecl), !isReferencedFromDifferentTypeInSameFile(descDecl) {
                mark(descDecl)
            }
        }
    }

    private func isReferencedOutsideFile(_ decl: Declaration) -> Bool {
        let referenceFiles = graph.references(to: decl).map(\.location.file)
        return referenceFiles.contains { $0 != decl.location.file }
    }

    private func descendentFilePrivateDeclarations(from decl: Declaration) -> Set<Declaration> {
        let filePrivateDeclarations = decl.declarations.filter { !$0.isImplicit && $0.accessibility.isExplicitly(.fileprivate) }
        return filePrivateDeclarations.flatMapSet { descendentFilePrivateDeclarations(from: $0) }.union(filePrivateDeclarations)
    }

    /**
     Finds the top-level type declaration by walking up the parent chain.
     Returns the outermost type that contains the given declaration.
     */
    private func topLevelType(of decl: Declaration) -> Declaration? {
        let baseTypeKinds: Set<Declaration.Kind> = [.class, .struct, .enum, .protocol]
        let typeKinds = baseTypeKinds.union(Declaration.Kind.extensionKinds)
        let ancestors = [decl] + Array(decl.ancestralDeclarations)
        return ancestors.last { typeDecl in
            guard typeKinds.contains(typeDecl.kind) else { return false }
            guard let parent = typeDecl.parent else { return true }
            return !typeKinds.contains(parent.kind)
        }
    }

    /**
     Gets the logical type for comparison purposes.
     For extensions of types in the SAME FILE, treats the extension as the extended type.
     For extensions of types in DIFFERENT FILES (like extending external types),
     treats the extension as its own distinct type for the purpose of this file.
     */
    private func logicalType(of decl: Declaration, inFile file: SourceFile) -> Declaration? {
        if decl.kind.isExtensionKind {
            if let extendedDecl = try? graph.extendedDeclaration(forExtension: decl),
               extendedDecl.location.file == file
            {
                return extendedDecl
            }
            return decl
        }
        return decl
    }

    /**
     Checks if a declaration is referenced from a different type in the same file.
     Returns true if any same-file reference comes from a different logical type,
     indicating that fileprivate access is necessary.

     Even for top-level declarations, private and fileprivate are different:
     - private: only accessible within the declaration itself and its extensions in the same file
     - fileprivate: accessible from anywhere in the same file
     */
    private func isReferencedFromDifferentTypeInSameFile(_ decl: Declaration) -> Bool {
        let file = decl.location.file
        let sameFileReferences = graph.references(to: decl).filter { $0.location.file == file }

        guard let declTopLevel = topLevelType(of: decl) else {
            return false
        }

        let declLogicalType = logicalType(of: declTopLevel, inFile: file)

        for ref in sameFileReferences {
            guard let refParent = ref.parent,
                  let refTopLevel = topLevelType(of: refParent)
            else {
                continue
            }

            let refLogicalType = logicalType(of: refTopLevel, inFile: file)

            if declLogicalType !== refLogicalType {
                return true
            }
        }
        return false
    }
}
