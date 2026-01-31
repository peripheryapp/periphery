import Configuration
import Shared

/// Identifies declarations explicitly marked `fileprivate` that don't actually need file-level access.
///
/// Swift's `fileprivate` exists specifically to allow access from other types within the same file.
/// If a `fileprivate` declaration is only accessed within its own type (not from other types in
/// the same file), it should be marked `private` instead.
///
/// This mutator is more complex than RedundantInternalAccessibilityMarker because it must:
/// - Distinguish between access from the same type vs. different types in the same file
/// - Handle extensions of types (both same-file and cross-file extensions)
/// - Walk the type hierarchy to find the top-level containing type for comparison
///
/// The key insight: `private` and `fileprivate` differ in that `private` is accessible only within
/// the declaration and its extensions in the same file, while `fileprivate` is accessible from
/// anywhere in the same file.
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
            if !graph.isRetained(decl),
               !decl.isReferencedOutsideFileIncludingChildren(graph: graph),
               !isReferencedFromDifferentTypeInSameFile(decl)
            {
                mark(decl)
            }
        }

        // Always check descendants, even if parent is not redundant.
        //
        // A parent declaration may be used outside its file (making it not redundant),
        // while still having child declarations that are only used within the same file
        // (making those children redundant). For example, a class used cross-file may have
        // a fileprivate property only referenced within the same file - that property should
        // be flagged as redundant even though the parent class is not.
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

        // Unless explicitly requested, skip marking nested declarations when an ancestor is already marked.
        // This avoids redundant warnings since fixing the parent's accessibility fixes the children too.
        if !configuration.showNestedRedundantAccessibility,
           decl.isAnyAncestorMarked(in: graph.redundantFilePrivateAccessibility)
        {
            return
        }

        let containingTypeName = containingTypeName(for: decl)
        graph.markRedundantFilePrivateAccessibility(decl, file: decl.location.file, containingTypeName: containingTypeName)
    }

    private func markExplicitFilePrivateDescendentDeclarations(from decl: Declaration) {
        // Sort descendants by their depth to ensure parents are marked before children.
        // This is important for the nested redundant accessibility suppression logic.
        let descendants = descendentFilePrivateDeclarations(from: decl).sorted { decl1, decl2 in
            decl1.ancestorCount < decl2.ancestorCount
        }

        for descDecl in descendants {
            if !graph.isRetained(descDecl),
               !descDecl.isReferencedOutsideFileIncludingChildren(graph: graph),
               !isReferencedFromDifferentTypeInSameFile(descDecl)
            {
                mark(descDecl)
            }
        }
    }

    private func descendentFilePrivateDeclarations(from decl: Declaration) -> Set<Declaration> {
        decl.descendentDeclarations(matching: {
            !$0.isImplicit && $0.accessibility.isExplicitly(.fileprivate)
        })
    }

    /// Finds the top-level type declaration by walking up the parent chain.
    /// Returns the outermost type that contains the given declaration.
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

    /// Gets the logical type for comparison purposes.
    /// For extensions of types in the SAME FILE, treats the extension as the extended type.
    /// For extensions of types in DIFFERENT FILES (like extending external types),
    /// treats the extension as its own distinct type for the purpose of this file.
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

    /// Extracts a display name for the containing type of a declaration.
    ///
    /// Returns a string like "class Foo" or "struct Bar" that identifies the type
    /// containing the declaration. Returns nil for top-level declarations.
    private func containingTypeName(for decl: Declaration) -> String? {
        guard let topLevel = topLevelType(of: decl) else { return nil }
        guard let name = topLevel.name else { return nil }

        return "\(topLevel.kind.displayName) \(name)"
    }

    /// Checks if a declaration is referenced from a different type in the same file.
    /// Returns true if any same-file reference comes from a different logical type,
    /// indicating that fileprivate access is necessary.
    ///
    /// Even for top-level declarations, private and fileprivate are different:
    /// - private: only accessible within the declaration itself and its extensions in the same file
    /// - fileprivate: accessible from anywhere in the same file
    private func isReferencedFromDifferentTypeInSameFile(_ decl: Declaration) -> Bool {
        let file = decl.location.file
        let sameFileReferences = graph.references(to: decl).filter { $0.location.file == file }

        guard let declTopLevel = topLevelType(of: decl) else {
            return false
        }

        let declLogicalType = logicalType(of: declTopLevel, inFile: file)

        for ref in sameFileReferences {
            guard let refParent = ref.parent else { continue }
            guard let refTopLevel = topLevelType(of: refParent) else {
                // Reference from a free function or top-level code — no containing type.
                return true
            }

            let refLogicalType = logicalType(of: refTopLevel, inFile: file)

            if declLogicalType !== refLogicalType {
                return true
            }
        }

        // For type declarations, also check if any child declaration is referenced
        // from a different type in the same file. This catches cases where enum cases
        // are used via type inference (e.g., `.small`) from outside the parent type.
        let typeKinds: Set<Declaration.Kind> = [.enum, .struct, .class, .protocol]
        if typeKinds.contains(decl.kind) {
            for child in decl.declarations {
                let childSameFileRefs = graph.references(to: child).filter { $0.location.file == file }
                for ref in childSameFileRefs {
                    guard let refParent = ref.parent else { continue }
                    guard let refTopLevel = topLevelType(of: refParent) else {
                        return true
                    }

                    let refLogicalType = logicalType(of: refTopLevel, inFile: file)

                    if declLogicalType !== refLogicalType {
                        return true
                    }
                }
            }
        }

        return false
    }
}
