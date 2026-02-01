// Shared utilities for redundant accessibility analysis mutators.

/// Tracks visited declarations to prevent infinite recursion in graph traversals.
struct RecursionGuard {
    private var visited: Set<ObjectIdentifier> = []

    /// Returns true if the declaration has not been visited before, and marks it as visited.
    /// Returns false if already visited (caller should bail out).
    mutating func firstVisit(_ decl: Declaration) -> Bool {
        visited.insert(ObjectIdentifier(decl)).inserted
    }
}

extension Declaration {
    /// Checks if this declaration is referenced outside its defining file.
    /// This is a common check used by multiple accessibility markers to determine
    /// if a declaration needs file-level or module-level accessibility.
    func isReferencedOutsideFile(graph: SourceGraph) -> Bool {
        graph.references(to: self).map(\.location.file).contains { $0 != location.file }
    }

    /// Generic recursive descendent declaration finder with filtering.
    /// Recursively traverses the declaration tree and returns all descendants matching the predicate.
    /// Used by all accessibility markers to find declarations with specific accessibility levels.
    func descendentDeclarations(matching predicate: (Declaration) -> Bool) -> Set<Declaration> {
        let matchingDeclarations = declarations.filter(predicate)
        return matchingDeclarations
            .flatMapSet { $0.descendentDeclarations(matching: predicate) }
            .union(matchingDeclarations)
    }

    /// Checks if any ancestor declaration is marked as redundant in the given accessibility map.
    /// Used by accessibility markers to suppress nested warnings when a containing type is already flagged.
    /// This avoids redundant warnings since fixing the parent's accessibility fixes the children too.
    func isAnyAncestorMarked(in markedDeclarations: Dictionary<Declaration, some Any>.Keys) -> Bool {
        var current = parent
        var visited: Set<Declaration> = []

        while let currentParent = current {
            guard !visited.contains(currentParent) else {
                return false
            }

            visited.insert(currentParent)

            if markedDeclarations.contains(currentParent) {
                return true
            }
            current = currentParent.parent
        }
        return false
    }

    /// Checks if this declaration or any of its immediate child declarations are
    /// referenced outside the defining file.
    ///
    /// For type declarations (enum, struct, class, protocol), Swift's indexer may create
    /// references to child declarations (e.g., enum cases via type inference like `.small`)
    /// without creating a reference to the parent type itself. This method catches those
    /// indirect cross-file usages that `isReferencedOutsideFile` would miss.
    func isReferencedOutsideFileIncludingChildren(graph: SourceGraph) -> Bool {
        if isReferencedOutsideFile(graph: graph) {
            return true
        }

        guard Declaration.Kind.concreteTypeKinds.contains(kind) else { return false }

        for child in declarations {
            if child.isReferencedOutsideFile(graph: graph) {
                return true
            }
        }

        return false
    }

    /// Counts the number of ancestors for this declaration.
    /// Used for sorting declarations by depth to ensure parents are marked before children,
    /// which is important for nested redundant accessibility suppression logic.
    var ancestorCount: Int {
        var count = 0
        var current = parent
        while current != nil {
            count += 1
            current = current?.parent
        }
        return count
    }

    /// Determines if a declaration should be skipped from all accessibility analysis.
    ///
    /// These are declarations where changing the access level is either impossible
    /// (compiler-generated, destructors, enum cases) or constrained by other rules
    /// (generic type params, overrides, @usableFromInline).
    var shouldSkipAccessibilityAnalysis: Bool {
        // Generic type parameters must match their container's accessibility.
        if kind == .genericTypeParam { return true }

        // Skip implicit (compiler-generated) declarations.
        if isImplicit { return true }

        // Deinitializers cannot have explicit access modifiers in Swift.
        if kind == .functionDestructor { return true }

        // Enum cases cannot have explicit access modifiers in Swift.
        if kind == .enumelement { return true }

        // Override methods must be at least as accessible as what they override.
        if isOverride { return true }

        // Declarations with @usableFromInline must remain internal (or package).
        if attributes.contains(where: { $0.name == "usableFromInline" }) {
            return true
        }

        return false
    }
}

extension SourceGraph {
    /// Gets the logical type for comparison purposes when analyzing accessibility.
    ///
    /// For extensions of types in the SAME FILE, treats the extension as the extended type.
    /// For extensions of types in DIFFERENT FILES, treats the extension as its own distinct type.
    func logicalType(of decl: Declaration, inFile file: SourceFile) -> Declaration? {
        if decl.kind.isExtensionKind {
            if let extendedDecl = try? extendedDeclaration(forExtension: decl),
               extendedDecl.location.file == file
            {
                return extendedDecl
            }
            return decl
        }
        return decl
    }

    /// Finds the immediate containing type of a declaration.
    ///
    /// For members (properties, methods, etc.), this returns their containing type.
    /// For nested types, this returns the type that contains them (the outer type).
    /// For top-level types, this returns the type itself (they are their own container).
    func immediateContainingType(of decl: Declaration) -> Declaration? {
        // For types, check if they have a parent type (nested type case).
        // If so, return the parent type. If not (top-level), return the type itself.
        if Declaration.Kind.allTypeKinds.contains(decl.kind) {
            if let parent = decl.parent, Declaration.Kind.allTypeKinds.contains(parent.kind) {
                return parent
            }
            return decl
        }

        // Walk up the parent chain to find the first containing type
        var current = decl.parent
        while let parent = current {
            if Declaration.Kind.allTypeKinds.contains(parent.kind) {
                return parent
            }
            current = parent.parent
        }

        return nil
    }

    /// Checks if a declaration is referenced from a different type in the same file.
    ///
    /// Uses the immediate containing type (not top-level type) for comparison because:
    /// - For nested types like `Outer.Inner`, a member of `Inner` accessed from `Outer`
    ///   (but outside `Inner`) needs `fileprivate`
    /// - Using top-level type would incorrectly see both as belonging to `Outer`
    ///
    /// Also checks child declarations (e.g., enum cases used via type inference like `.small`)
    /// since the indexer may reference children without referencing the parent type.
    func isReferencedFromDifferentTypeInSameFile(_ decl: Declaration) -> Bool {
        let file = decl.location.file
        let sameFileReferences = references(to: decl).filter { $0.location.file == file }

        guard let declContainingType = immediateContainingType(of: decl) else {
            return false
        }

        let declLogicalType = logicalType(of: declContainingType, inFile: file)

        for ref in sameFileReferences {
            guard let refParent = ref.parent else { continue }
            guard let refContainingType = immediateContainingType(of: refParent) else {
                // Reference from a free function or top-level code — no containing type.
                // This is effectively a different type, so fileprivate is needed.
                return true
            }

            let refLogicalType = logicalType(of: refContainingType, inFile: file)

            if declLogicalType !== refLogicalType {
                return true
            }
        }

        // For type declarations, also check if any child declaration is referenced
        // from a different type in the same file. This catches cases where enum cases
        // are used via type inference (e.g., `.small`) from outside the parent type.
        if Declaration.Kind.concreteTypeKinds.contains(decl.kind) {
            for child in decl.declarations {
                let childSameFileRefs = references(to: child).filter { $0.location.file == file }
                for ref in childSameFileRefs {
                    guard let refParent = ref.parent else { continue }
                    guard let refContainingType = immediateContainingType(of: refParent) else {
                        return true
                    }

                    let refLogicalType = logicalType(of: refContainingType, inFile: file)

                    if declLogicalType !== refLogicalType {
                        return true
                    }
                }
            }
        }

        return false
    }
}
