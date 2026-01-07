import Configuration
import Shared

/// Identifies `internal` declarations (implicit, or explicitly marked) that are not referenced outside
/// the file they're defined in.
///
/// Since `internal` is Swift's default access level, declarations that are only used within
/// their defining file should be marked `private` or `fileprivate` instead. This improves
/// encapsulation and can help with compilation performance.
///
/// This mutator follows the same pattern as RedundantPublicAccessibilityMarker but checks
/// for file-scoped usage instead of module-scoped usage.
final class RedundantInternalAccessibilityMarker: SourceGraphMutator {
    private let graph: SourceGraph
    private let configuration: Configuration

    required init(graph: SourceGraph, configuration: Configuration, swiftVersion _: SwiftVersion) {
        self.graph = graph
        self.configuration = configuration
    }

    func mutate() throws {
        guard !configuration.disableRedundantInternalAnalysis else { return }

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
        if decl.accessibility.value == .internal {
            if !graph.isRetained(decl), !shouldSkipMarking(decl) {
                let isReferencedOutside = decl.isReferencedOutsideFile(graph: graph)
                if !isReferencedOutside {
                    mark(decl)
                }
            }
        }

        // Always check descendants, even if parent is not redundant.
        //
        // A parent declaration may be used outside its file (making it not redundant),
        // while still having child declarations that are only used within the same file
        // (making those children redundant). For example, a class used cross-file may have
        // an internal property only referenced within the same file - that property should
        // be flagged as redundant even though the parent class is not.
        markInternalDescendentDeclarations(from: decl)
    }

    private func validateExtension(_ decl: Declaration) throws {
        if decl.accessibility.value == .internal {
            if let extendedDecl = try? graph.extendedDeclaration(forExtension: decl),
               graph.redundantInternalAccessibility.keys.contains(extendedDecl)
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
           decl.isAnyAncestorMarked(in: graph.redundantInternalAccessibility)
        {
            return
        }

        // Determine the suggested accessibility level.
        // For top-level declarations, fileprivate is equivalent to private, so we pass nil
        // to indicate the ambiguity in the output message.
        // If the declaration is referenced from different types in the same file,
        // it needs fileprivate. Otherwise, private is sufficient.
        let isTopLevel = decl.parent == nil
        let suggestedAccessibility: Accessibility? = isTopLevel ? nil : (isReferencedFromDifferentTypeInSameFile(decl) ? .fileprivate : .private)

        // Check if the parent's accessibility already constrains this member.
        // If the parent is `private`, the member is already effectively `private`.
        // If the parent is `fileprivate` and we would suggest `fileprivate`, it's already constrained.
        // Marking these would be misleading since changing them would actually increase visibility.
        if let maxAccessibility = effectiveMaximumAccessibility(for: decl),
           let suggestedAccessibility
        {
            let accessibilityOrder: [Accessibility] = [.private, .fileprivate, .internal, .public, .open]
            let maxIndex = accessibilityOrder.firstIndex(of: maxAccessibility) ?? 0
            let suggestedIndex = accessibilityOrder.firstIndex(of: suggestedAccessibility) ?? 0

            if suggestedIndex >= maxIndex {
                return
            }
        }

        graph.markRedundantInternalAccessibility(decl, file: decl.location.file, suggestedAccessibility: suggestedAccessibility)
    }

    private func markInternalDescendentDeclarations(from decl: Declaration) {
        // Sort descendants by their depth to ensure parents are marked before children.
        // This is important for the nested redundant accessibility suppression logic.
        let descendants = descendentInternalDeclarations(from: decl).sorted { decl1, decl2 in
            decl1.ancestorCount < decl2.ancestorCount
        }

        for descDecl in descendants {
            if !graph.isRetained(descDecl), !shouldSkipMarking(descDecl) {
                let isReferencedOutside = descDecl.isReferencedOutsideFile(graph: graph)
                if !isReferencedOutside {
                    mark(descDecl)
                }
            }
        }
    }

    /// Determines if a declaration should be skipped from redundant internal marking.
    ///
    /// Declarations are skipped if:
    /// - They should be skipped from all accessibility analysis (generic type params, implicit decls)
    /// - They are protocol requirements (must maintain accessibility for protocol conformance)
    /// - They are part of a property wrapper's API (must be accessible to wrapper users)
    private func shouldSkipMarking(_ decl: Declaration) -> Bool {
        if shouldSkipAccessibilityAnalysis(for: decl) {
            return true
        }

        if isProtocolRequirement(decl) {
            return true
        }

        if isPropertyWrapperMember(decl) {
            return true
        }

        return false
    }

    private func descendentInternalDeclarations(from decl: Declaration) -> Set<Declaration> {
        decl.descendentDeclarations(matching: {
            $0.accessibility.value == .internal
        })
    }

    // MARK: - Internal Accessibility Analysis Helpers

    /// Determines if a declaration should be skipped from accessibility analysis entirely.
    ///
    /// This helper is specific to internal accessibility analysis, checking conditions
    /// that make a declaration ineligible for redundant internal marking.
    private func shouldSkipAccessibilityAnalysis(for decl: Declaration) -> Bool {
        // Generic type parameters must match their container's accessibility.
        if decl.kind == .genericTypeParam { return true }

        // Skip implicit (compiler-generated) declarations.
        if decl.isImplicit { return true }

        // Deinitializers cannot have explicit access modifiers in Swift.
        if decl.kind == .functionDestructor { return true }

        // Override methods must be at least as accessible as what they override.
        if decl.isOverride { return true }

        return false
    }

    /// Checks if a declaration is a protocol requirement or protocol conformance.
    ///
    /// Protocol requirements must maintain sufficient accessibility to fulfill the protocol
    /// contract, even if only referenced within the same file. This is critical for internal
    /// accessibility analysis to avoid marking protocol implementations as redundant.
    private func isProtocolRequirement(_ decl: Declaration) -> Bool {
        // Case 1: Direct protocol requirement - parent is a protocol.
        if let parent = decl.parent, parent.kind == .protocol {
            return true
        }

        // Case 2: Protocol conformance - this declaration implements a protocol requirement.
        //
        // When a type conforms to a protocol, Swift's indexer creates "related" references
        // from the conforming declaration to the protocol requirement. If this declaration
        // has any related references pointing to protocol members with matching names,
        // it's implementing a protocol requirement.
        let relatedReferences = graph.references(to: decl).filter(\.isRelated)
        for ref in relatedReferences {
            if let protocolDecl = graph.declaration(withUsr: ref.usr),
               protocolDecl.kind.isProtocolMemberKind || protocolDecl.kind == .associatedtype
            {
                return true
            }
        }

        // Alternative check: Look for related references FROM this declaration
        // to protocol members. The ProtocolConformanceReferenceBuilder inverts
        // these relationships, so we might find them either direction.
        for ref in decl.related where ref.kind.isProtocolMemberConformingKind {
            if let referencedDecl = graph.declaration(withUsr: ref.usr),
               let referencedParent = referencedDecl.parent,
               referencedParent.kind == .protocol
            {
                return true
            }
        }

        return false
    }

    /// Checks if a declaration is part of a property wrapper's public API.
    ///
    /// Property wrappers require certain members to be accessible even for internal
    /// accessibility analysis. This prevents marking essential property wrapper components
    /// as redundant when they're only referenced within the same file.
    private func isPropertyWrapperMember(_ decl: Declaration) -> Bool {
        guard let parent = decl.parent else { return false }

        // Check if parent type has @propertyWrapper attribute.
        let isPropertyWrapper = parent.attributes.contains { $0.name == "propertyWrapper" }
        guard isPropertyWrapper else { return false }

        // Property wrapper initializers are part of the API.
        if decl.kind == .functionConstructor { return true }

        // wrappedValue and projectedValue are part of the API.
        if decl.kind == .varInstance {
            let propertyWrapperSpecialProperties = ["wrappedValue", "projectedValue"]
            if propertyWrapperSpecialProperties.contains(decl.name ?? "") {
                return true
            }
        }

        // Typealiases used in method/init signatures must be accessible.
        // If this is a typealias and it's referenced by a function/init in the same
        // property wrapper type, it's part of the API.
        if decl.kind == .typealias {
            let siblings = parent.declarations
            let hasFunctionReference = siblings.contains { sibling in
                sibling.kind.isFunctionKind && sibling.references.contains { ref in
                    ref.kind == .typealias && decl.usrs.contains(ref.usr)
                }
            }
            if hasFunctionReference {
                return true
            }
        }

        return false
    }

    /// Determines the effective maximum accessibility a member can have based on its parent's accessibility.
    ///
    /// In Swift, a member's effective accessibility is constrained by its parent. This helper
    /// ensures internal accessibility analysis respects these constraints when suggesting
    /// more restrictive access levels.
    private func effectiveMaximumAccessibility(for decl: Declaration) -> Accessibility? {
        guard let parent = decl.parent else { return nil }

        let parentAccessibility = parent.accessibility.value

        switch parentAccessibility {
        case .private:
            return .private
        case .fileprivate:
            return .fileprivate
        case .internal:
            return .internal
        case .public, .open:
            return nil
        }
    }

    /// Checks if a declaration is referenced from a different type in the same file.
    ///
    /// For internal accessibility analysis, this determines whether to suggest `fileprivate`
    /// versus `private` when a declaration is only used within its file.
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

    // Finds the top-level type declaration by walking up the parent chain.
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

    // Gets the logical type for comparison purposes when analyzing internal accessibility.
    // For extensions of types in the SAME FILE, treats the extension as the extended type.
    // For extensions of types in DIFFERENT FILES, treats the extension as its own distinct type.
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
}
