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
            if !decl.shouldSkipAccessibilityAnalysis,
               !graph.isRetained(decl),
               !decl.isReferencedOutsideFileIncludingChildren(graph: graph),
               !graph.isReferencedFromDifferentTypeInSameFile(decl)
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
           decl.isAnyAncestorMarked(in: graph.redundantFilePrivateAccessibility.keys)
        {
            return
        }

        let containingTypeName = containingTypeName(for: decl)
        graph.markRedundantFilePrivateAccessibility(decl, containingTypeName: containingTypeName)
    }

    private func markExplicitFilePrivateDescendentDeclarations(from decl: Declaration) {
        // Sort descendants by their depth to ensure parents are marked before children.
        // This is important for the nested redundant accessibility suppression logic.
        let descendants = descendentFilePrivateDeclarations(from: decl).sorted { decl1, decl2 in
            decl1.ancestorCount < decl2.ancestorCount
        }

        for descDecl in descendants {
            if !descDecl.shouldSkipAccessibilityAnalysis,
               !graph.isRetained(descDecl),
               !descDecl.isReferencedOutsideFileIncludingChildren(graph: graph),
               !graph.isReferencedFromDifferentTypeInSameFile(descDecl)
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

    /// Extracts a display name for the immediate containing type of a declaration.
    ///
    /// Returns a string like "class Foo" or "struct Bar" that identifies the type
    /// containing the declaration. Returns nil for top-level declarations.
    private func containingTypeName(for decl: Declaration) -> String? {
        guard let containingType = graph.immediateContainingType(of: decl) else { return nil }
        guard containingType !== decl else { return nil }
        guard let name = containingType.name else { return nil }

        return "\(containingType.kind.displayName) \(name)"
    }
}
