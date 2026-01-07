// Shared utilities for redundant accessibility analysis mutators.

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
    func isAnyAncestorMarked(in accessibilityMap: [Declaration: Any]) -> Bool {
        var current = parent
        var visited: Set<Declaration> = []

        while let currentParent = current {
            guard !visited.contains(currentParent) else {
                return false
            }

            visited.insert(currentParent)

            if accessibilityMap[currentParent] != nil {
                return true
            }
            current = currentParent.parent
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
}
