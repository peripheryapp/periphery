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
                if !isReferencedOutside, !isTransitivelyExposedOutsideFile(decl) {
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
        // If the declaration is referenced from different types in the same file,
        // it needs fileprivate. Otherwise, private is sufficient.
        // Also check transitive exposure: if the type is used as return/parameter type of a
        // function called from a different type in the same file, it needs fileprivate.
        // Additionally, types used in protocol requirement signatures need fileprivate even
        // at top level (private would make them inaccessible from the protocol method).
        let isTopLevel = decl.parent == nil
        let needsFileprivate = isReferencedFromDifferentTypeInSameFile(decl) ||
            isTransitivelyExposedFromDifferentTypeInSameFile(decl) ||
            isUsedInProtocolRequirementSignature(decl)

        // For top-level declarations where private and fileprivate would both work,
        // we pass nil to indicate the ambiguity. But if fileprivate is specifically needed
        // (e.g., the type is used in a protocol requirement signature), we suggest fileprivate.
        let suggestedAccessibility: Accessibility? = if isTopLevel, !needsFileprivate {
            nil
        } else {
            needsFileprivate ? .fileprivate : .private
        }

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
                if !isReferencedOutside, !isTransitivelyExposedOutsideFile(descDecl) {
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
    /// - They are struct stored properties used in an implicit memberwise initializer
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

        if isStructMemberwiseInitProperty(decl) {
            return true
        }

        if isUsedInExternalProtocolRequirementSignature(decl) {
            return true
        }

        // Check if type is constrained by same-file type usage
        if isConstrainedBySameFileTypeUsage(decl) {
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

        // Enum cases cannot have explicit access modifiers in Swift.
        // They inherit the accessibility of their containing enum.
        if decl.kind == .enumelement { return true }

        // Override methods must be at least as accessible as what they override.
        if decl.isOverride { return true }

        // Declarations with @usableFromInline must remain internal (or package).
        // This attribute allows internal declarations to be inlined into client code,
        // requiring them to maintain internal visibility.
        if decl.attributes.contains(where: { $0.name == "usableFromInline" }) {
            return true
        }

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
        let relatedReferences = graph.references(to: decl).filter { $0.kind == .related }
        for ref in relatedReferences {
            if let protocolDecl = graph.declaration(withUsr: ref.usr),
               protocolDecl.kind.isProtocolMemberKind || protocolDecl.kind == .associatedtype
            {
                return true
            }
        }

        // Case 3: Check for .related references FROM this declaration to protocol members.
        // This covers both internal AND external protocol conformances.
        for ref in decl.related where ref.declarationKind.isProtocolMemberConformingKind {
            if let referencedDecl = graph.declaration(withUsr: ref.usr) {
                // Internal protocol: verify the referenced declaration's parent is a protocol.
                if let referencedParent = referencedDecl.parent,
                   referencedParent.kind == .protocol
                {
                    return true
                }
            } else if ref.name == decl.name {
                // External protocol: the declaration doesn't exist in our graph,
                // but the indexer created a .related reference with a protocol member kind
                // AND the names match. This means this declaration implements an external
                // protocol requirement.
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
                    ref.declarationKind == .typealias && decl.usrs.contains(ref.usr)
                }
            }
            if hasFunctionReference {
                return true
            }
        }

        return false
    }

    /// Checks if a declaration is a stored property that's part of a struct's implicit memberwise
    /// initializer AND that initializer is used (either from outside the file OR from within
    /// the same file when the struct must remain internal).
    private func isStructMemberwiseInitProperty(_ decl: Declaration) -> Bool {
        guard decl.kind == .varInstance,
              let parent = decl.parent,
              parent.kind == .struct
        else { return false }

        let implicitInits = parent.declarations.filter { $0.kind == .functionConstructor && $0.isImplicit }

        for implicitInit in implicitInits {
            guard let initName = implicitInit.name,
                  let propertyName = decl.name
            else { continue }

            let parameterNames = initName
                .dropFirst("init(".count)
                .dropLast(")".count)
                .split(separator: ":")
                .map(String.init)

            guard parameterNames.contains(propertyName) else { continue }

            // Case 1: Init referenced outside file -> properties must stay internal
            if implicitInit.isReferencedOutsideFile(graph: graph) {
                return true
            }

            // Case 2: Init referenced in same file AND struct must remain internal
            // (because it's used outside file or transitively exposed)
            let hasAnyReference = !graph.references(to: implicitInit).isEmpty
            if hasAnyReference {
                if parent.isReferencedOutsideFile(graph: graph) {
                    return true
                }
                if isTransitivelyExposedOutsideFile(parent) {
                    return true
                }
            }
        }

        return false
    }

    /// Checks if a type is constrained by being used in the signature of another
    /// internal declaration (in the same file) that must remain internal.
    ///
    /// In Swift, types used in a declaration's signature must be at least as accessible
    /// as that declaration. If TypeA is used as a property type, return type, parameter
    /// type, or generic constraint in TypeB/MemberB, and TypeB must remain internal
    /// (because it's referenced outside the file or transitively exposed), then TypeA
    /// cannot be made fileprivate/private.
    ///
    /// This complements isTransitivelyExposedOutsideFile() which handles cross-file
    /// scenarios. This function handles same-file scenarios where the constraint chain
    /// exists entirely within one file.
    private func isConstrainedBySameFileTypeUsage(_ decl: Declaration) -> Bool {
        let typeKinds: Set<Declaration.Kind> = [.enum, .struct, .class, .protocol]
        guard typeKinds.contains(decl.kind) else { return false }

        var visited: Set<ObjectIdentifier> = []
        return isConstrainedBySameFileTypeUsageRecursive(decl, visited: &visited)
    }

    private func isConstrainedBySameFileTypeUsageRecursive(
        _ decl: Declaration,
        visited: inout Set<ObjectIdentifier>
    ) -> Bool {
        let id = ObjectIdentifier(decl)
        guard !visited.contains(id) else { return false }

        visited.insert(id)

        let typeKinds: Set<Declaration.Kind> = [.enum, .struct, .class, .protocol]
        let file = decl.location.file
        let refs = graph.references(to: decl)

        for ref in refs {
            // Check if this reference is in ANY publicly exposable role
            // (property type, return type, parameter type, generic constraint, etc.)
            guard ref.role.isPubliclyExposable else { continue }

            // Must be in the same file (cross-file is handled by isTransitivelyExposedOutsideFile)
            guard ref.location.file == file else { continue }

            // Get the declaration that uses this type in its signature
            guard let usingDecl = ref.parent else { continue }

            // Find the containing type of that declaration
            let containingType: Declaration?
            if typeKinds.contains(usingDecl.kind) || usingDecl.kind.isExtensionKind {
                // The using declaration IS a type (e.g., conformedType, inheritedType)
                containingType = usingDecl
            } else if let parent = usingDecl.parent,
                      typeKinds.contains(parent.kind) || parent.kind.isExtensionKind
            {
                // The using declaration is a member of a type
                containingType = parent
            } else {
                continue
            }

            guard let containingType else { continue }

            // Check if the containing type must remain internal
            guard containingType.accessibility.value == .internal else { continue }

            // If the containing type is referenced outside the file, our type is constrained
            if containingType.isReferencedOutsideFile(graph: graph) {
                return true
            }

            // If the containing type is transitively exposed outside the file
            if isTransitivelyExposedOutsideFile(containingType) {
                return true
            }

            // Recursive: if the containing type is itself constrained
            if isConstrainedBySameFileTypeUsageRecursive(containingType, visited: &visited) {
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
    ///
    /// This uses the **immediate containing type** (not the top-level type) because:
    /// - For nested types like `OuterStruct.InnerStruct`, a member of `InnerStruct` that's
    ///   accessed from code inside `OuterStruct` (but outside `InnerStruct`) needs `fileprivate`
    /// - Using top-level type would incorrectly see both as belonging to `OuterStruct`
    private func isReferencedFromDifferentTypeInSameFile(_ decl: Declaration) -> Bool {
        let file = decl.location.file
        let sameFileReferences = graph.references(to: decl).filter { $0.location.file == file }

        guard let declContainingType = immediateContainingType(of: decl) else {
            return false
        }

        let declLogicalType = logicalType(of: declContainingType, inFile: file)

        for ref in sameFileReferences {
            guard let refParent = ref.parent,
                  let refContainingType = immediateContainingType(of: refParent)
            else {
                continue
            }

            let refLogicalType = logicalType(of: refContainingType, inFile: file)

            if declLogicalType !== refLogicalType {
                return true
            }
        }
        return false
    }

    /// Finds the immediate containing type of a declaration.
    ///
    /// For members (properties, methods, etc.), this returns their containing type.
    /// For nested types, this returns the type that contains them (the outer type).
    /// For top-level types, this returns the type itself (they are their own container).
    private func immediateContainingType(of decl: Declaration) -> Declaration? {
        let baseTypeKinds: Set<Declaration.Kind> = [.class, .struct, .enum, .protocol]
        let typeKinds = baseTypeKinds.union(Declaration.Kind.extensionKinds)

        // For types, check if they have a parent type (nested type case).
        // If so, return the parent type. If not (top-level), return the type itself.
        if typeKinds.contains(decl.kind) {
            if let parent = decl.parent, typeKinds.contains(parent.kind) {
                return parent
            }
            return decl
        }

        // Walk up the parent chain to find the first containing type
        var current = decl.parent
        while let parent = current {
            if typeKinds.contains(parent.kind) {
                return parent
            }
            current = parent.parent
        }

        return nil
    }

    /// Gets the logical type for comparison purposes when analyzing internal accessibility.
    ///
    /// For extensions of types in the SAME FILE, treats the extension as the extended type.
    /// For extensions of types in DIFFERENT FILES, treats the extension as its own distinct type.
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

    /// Checks if a type is transitively exposed outside its file through an API signature.
    ///
    /// A type is transitively exposed when it appears in the signature of a function, property,
    /// or initializer (as return type, parameter type, etc.) where that API is referenced from
    /// a different file. Even if the type itself is never directly referenced outside its file,
    /// it must remain `internal` (not `fileprivate` or `private`) if it's part of an API that
    /// is used from other files.
    ///
    /// For example, if `ScanProgress` is the return type of `runFullScanWithStreaming()`, and
    /// that function is called from another file, then `ScanProgress` is transitively exposed
    /// and should not be marked as redundantly internal.
    ///
    /// This check is recursive: if TypeA is used as a property type in Container, and Container
    /// is used as a property type in OuterContainer, and OuterContainer is referenced from
    /// outside the file, then TypeA is transitively exposed through the chain.
    private func isTransitivelyExposedOutsideFile(_ decl: Declaration) -> Bool {
        var visited: Set<ObjectIdentifier> = []
        return isTransitivelyExposedOutsideFileRecursive(decl, visited: &visited)
    }

    private func isTransitivelyExposedOutsideFileRecursive(_ decl: Declaration, visited: inout Set<ObjectIdentifier>) -> Bool {
        let id = ObjectIdentifier(decl)
        guard !visited.contains(id) else { return false }

        visited.insert(id)

        let refs = graph.references(to: decl)

        for ref in refs {
            // Check if this reference is in an API signature role (return type, parameter type, etc.)
            guard ref.role.isPubliclyExposable else { continue }

            // Get the parent declaration (the function/property that uses this type in its signature)
            guard let parent = ref.parent else { continue }

            // Check if that parent API is referenced from outside this file
            if parent.isReferencedOutsideFile(graph: graph) {
                return true
            }

            // For properties, also check if they could be accessed from outside the file
            // through their containing type. The property's type is exposed when:
            // 1. The property is internal (accessible from outside the file)
            // 2. The containing type is used from outside the file OR transitively exposed
            // 3. The property is not actually referenced from outside (already checked above)
            if parent.kind.isVariableKind,
               parent.accessibility.value == .internal || parent.accessibility.isAccessibleCrossModule
            {
                if let containingType = parent.parent {
                    // Direct reference from outside the file
                    if containingType.isReferencedOutsideFile(graph: graph) {
                        return true
                    }
                    // Recursive: the containing type itself is transitively exposed
                    if isTransitivelyExposedOutsideFileRecursive(containingType, visited: &visited) {
                        return true
                    }
                }
            }
        }

        return false
    }

    /// Checks if a type is transitively exposed from a different type within the same file.
    ///
    /// This is similar to `isTransitivelyExposedOutsideFile`, but checks for exposure within
    /// the same file from a different type. When a type is used as a return type or parameter
    /// type of a function that is called from a different type in the same file, the type
    /// needs to be at least `fileprivate` (not `private`).
    ///
    /// For example:
    /// ```swift
    /// class ClassA {
    ///     enum Status { case active }  // Only directly referenced in ClassA
    ///     func getStatus() -> Status { .active }  // Called from ClassB
    /// }
    /// class ClassB {
    ///     func use() { _ = ClassA().getStatus() }  // Uses Status transitively
    /// }
    /// ```
    /// Here, `Status` should be suggested as `fileprivate`, not `private`.
    ///
    /// This check is recursive: if TypeA is used as a property type in Container, and Container
    /// is used as a property type in another type that is accessed from a different type in
    /// the same file, then TypeA needs fileprivate.
    private func isTransitivelyExposedFromDifferentTypeInSameFile(_ decl: Declaration) -> Bool {
        let file = decl.location.file

        guard let declContainingType = immediateContainingType(of: decl) else {
            return false
        }

        let declLogicalType = logicalType(of: declContainingType, inFile: file)
        var visited: Set<ObjectIdentifier> = []

        return isTransitivelyExposedFromDifferentTypeInSameFileRecursive(
            decl,
            declLogicalType: declLogicalType,
            file: file,
            visited: &visited
        )
    }

    private func isTransitivelyExposedFromDifferentTypeInSameFileRecursive(
        _ decl: Declaration,
        declLogicalType: Declaration?,
        file: SourceFile,
        visited: inout Set<ObjectIdentifier>
    ) -> Bool {
        let id = ObjectIdentifier(decl)
        guard !visited.contains(id) else { return false }

        visited.insert(id)

        let refs = graph.references(to: decl)

        for ref in refs {
            // Check if this reference is in an API signature role (return type, parameter type, etc.)
            guard ref.role.isPubliclyExposable else { continue }

            // Get the parent declaration (the function/property that uses this type in its signature)
            guard let parent = ref.parent else { continue }

            // Check references to that parent from the same file
            let parentRefs = graph.references(to: parent).filter { $0.location.file == file }

            for parentRef in parentRefs {
                guard let refParent = parentRef.parent,
                      let refContainingType = immediateContainingType(of: refParent)
                else {
                    continue
                }

                let refLogicalType = logicalType(of: refContainingType, inFile: file)

                if declLogicalType !== refLogicalType {
                    return true
                }
            }

            // For properties, also check if the containing type is transitively exposed
            // from a different type in the same file
            if parent.kind.isVariableKind,
               parent.accessibility.value == .internal || parent.accessibility.isAccessibleCrossModule
            {
                if let containingType = parent.parent {
                    if isTransitivelyExposedFromDifferentTypeInSameFileRecursive(
                        containingType,
                        declLogicalType: declLogicalType,
                        file: file,
                        visited: &visited
                    ) {
                        return true
                    }
                }
            }
        }

        return false
    }

    /// Checks if a type is used in a protocol requirement's signature (return type, parameter type, etc.).
    ///
    /// When a type is used as the return type or parameter type of a protocol requirement method,
    /// the type must be at least `fileprivate` - making it `private` would cause a compiler error
    /// because the protocol method's signature would expose an inaccessible type.
    ///
    /// For example, in NSViewRepresentable:
    /// ```swift
    /// class FocusableNSView: NSView { ... }  // Used as return type of makeNSView
    ///
    /// struct FocusClaimingView: NSViewRepresentable {
    ///     func makeNSView(context: Context) -> FocusableNSView { ... }
    /// }
    /// ```
    /// Here, `FocusableNSView` cannot be `private` because it's exposed through `makeNSView`'s signature.
    private func isUsedInProtocolRequirementSignature(_ decl: Declaration) -> Bool {
        let refs = graph.references(to: decl)

        for ref in refs {
            // Check if this reference is in an API signature role (return type, parameter type, etc.)
            guard ref.role.isPubliclyExposable else { continue }

            // Get the parent declaration (the function/property that uses this type in its signature)
            guard let parent = ref.parent else { continue }

            // Check if that parent is a protocol requirement
            if isProtocolRequirement(parent) {
                return true
            }
        }

        return false
    }

    /// Checks if a type is used in the signature of a method that conforms to an external protocol.
    ///
    /// Types used in external protocol requirement signatures must remain `internal` because:
    /// 1. The method implementing the protocol requirement can't be more restrictive than the protocol
    /// 2. The types used in its signature must be at least as accessible as the method
    ///
    /// For example, with NSViewRepresentable:
    /// ```swift
    /// class FocusableNSView: NSView { ... }  // Must stay internal!
    ///
    /// struct FocusClaimingView: NSViewRepresentable {
    ///     func makeNSView(context: Context) -> FocusableNSView { ... }  // Protocol requirement
    ///     func updateNSView(_ nsView: FocusableNSView, context: Context) { ... }  // Protocol requirement
    /// }
    /// ```
    /// Here, `FocusableNSView` cannot be made `fileprivate` or `private` because the protocol
    /// methods that use it must remain at the protocol's required accessibility level.
    private func isUsedInExternalProtocolRequirementSignature(_ decl: Declaration) -> Bool {
        let refs = graph.references(to: decl)

        for ref in refs {
            // Check if this reference is in an API signature role (return type, parameter type, etc.)
            guard ref.role.isPubliclyExposable else { continue }

            // Get the parent declaration (the function/property that uses this type in its signature)
            guard let parent = ref.parent else { continue }

            // Check if that parent conforms to an external protocol requirement
            if isExternalProtocolRequirement(parent) {
                return true
            }
        }

        return false
    }

    /// Checks if a declaration implements an external protocol requirement.
    ///
    /// External protocols are those defined outside our codebase (e.g., NSViewRepresentable,
    /// Codable, etc.). When a declaration implements such a protocol, its accessibility is
    /// constrained by the protocol.
    private func isExternalProtocolRequirement(_ decl: Declaration) -> Bool {
        // Check for .related references FROM this declaration to protocol members
        // where the protocol is external (not in our graph).
        for ref in decl.related where ref.declarationKind.isProtocolMemberConformingKind {
            // If we can't find the declaration in our graph, it's external
            if graph.declaration(withUsr: ref.usr) == nil, ref.name == decl.name {
                return true
            }
        }

        return false
    }
}
