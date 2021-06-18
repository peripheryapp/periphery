import Foundation
import Shared

public final class SourceGraph {
    private(set) public var allDeclarations: Set<Declaration> = []
    private(set) public var reachableDeclarations: Set<Declaration> = []
    private(set) public var redundantProtocols: [Declaration: Set<Reference>] = [:]
    private(set) public var rootDeclarations: Set<Declaration> = []
    private(set) public var redundantPublicAccessibility: [Declaration: Set<String>] = [:]

    private(set) var rootReferences: Set<Reference> = []
    private(set) var allReferences: Set<Reference> = []
    private(set) var retainedDeclarations: Set<Declaration> = []
    private(set) var potentialAssignOnlyProperties: Set<Declaration> = []
    private(set) var ignoredDeclarations: Set<Declaration> = []

    private var allReferencesByUsr: [String: Set<Reference>] = [:]
    private var allDeclarationsByKind: [Declaration.Kind: Set<Declaration>] = [:]
    private var allExplicitDeclarationsByUsr: [String: Declaration] = [:]

    private let mutationQueue: DispatchQueue

    private var _allDeclarationsUnmodified: Set<Declaration> = []
    public var allDeclarationsUnmodified: Set<Declaration> { _allDeclarationsUnmodified }

    var xibReferences: [XibReference] = []
    var infoPlistReferences: [InfoPlistReference] = []

    public var unreachableDeclarations: Set<Declaration> {
        allDeclarations.subtracting(reachableDeclarations)
    }

    public init() {
        mutationQueue = DispatchQueue(label: "SourceGraph.mutationQueue")
    }

    public func indexingComplete() {
        rootDeclarations = allDeclarations.filter { $0.parent == nil }
        rootReferences = allReferences.filter { $0.parent == nil }
        _allDeclarationsUnmodified = allDeclarations
    }

    func declarations(ofKind kind: Declaration.Kind) -> Set<Declaration> {
        allDeclarationsByKind[kind] ?? []
    }

    func declarations(ofKinds kinds: Set<Declaration.Kind>) -> Set<Declaration> {
        declarations(ofKinds: Array(kinds))
    }

    func declarations(ofKinds kinds: [Declaration.Kind]) -> Set<Declaration> {
        Set(kinds.compactMap { allDeclarationsByKind[$0] }.joined())
    }

    func explicitDeclaration(withUsr usr: String) -> Declaration? {
        allExplicitDeclarationsByUsr[usr]
    }

    func references(to decl: Declaration) -> Set<Reference> {
        Set(decl.usrs.flatMap { allReferencesByUsr[$0, default: []] })
    }

    func hasReferences(to decl: Declaration) -> Bool {
        decl.usrs.contains { !allReferencesByUsr[$0, default: []].isEmpty }
    }

    func markRedundantProtocol(_ declaration: Declaration, references: Set<Reference>) {
        mutationQueue.sync {
            redundantProtocols[declaration] = references
        }
    }

    func markRedundantPublicAccessibility(_ declaration: Declaration, modules: Set<String>) {
        mutationQueue.sync {
            redundantPublicAccessibility[declaration] = modules
        }
    }

    func markIgnored(_ declaration: Declaration) {
        mutationQueue.sync {
            _ = ignoredDeclarations.insert(declaration)
        }
    }

    func markRetained(_ declaration: Declaration) {
        mutationQueue.sync {
            _ = retainedDeclarations.insert(declaration)
        }
    }

    func markPotentialAssignOnlyProperty(_ declaration: Declaration) {
        mutationQueue.sync {
            _ = potentialAssignOnlyProperties.insert(declaration)
        }
    }

    func isRetained(_ declaration: Declaration) -> Bool {
        mutationQueue.sync {
            retainedDeclarations.contains(declaration)
        }
    }

    func add(_ declaration: Declaration) {
        mutationQueue.sync {
            allDeclarations.insert(declaration)
            allDeclarationsByKind[declaration.kind, default: []].insert(declaration)

            if !declaration.isImplicit {
                declaration.usrs.forEach { allExplicitDeclarationsByUsr[$0] = declaration }
            }
        }
    }

    func remove(_ declaration: Declaration) {
        mutationQueue.sync {
            removeUnsafe(declaration)
        }
    }

    func removeUnsafe(_ declaration: Declaration) {
        declaration.parent?.declarations.remove(declaration)
        allDeclarations.remove(declaration)
        allDeclarationsByKind[declaration.kind]?.remove(declaration)
        rootDeclarations.remove(declaration)
        reachableDeclarations.remove(declaration)
        potentialAssignOnlyProperties.remove(declaration)
        declaration.usrs.forEach { allExplicitDeclarationsByUsr.removeValue(forKey: $0) }
    }

    func add(_ reference: Reference) {
        mutationQueue.sync {
            addUnsafe(reference)
        }
    }

    func addUnsafe(_ reference: Reference) {
        _ = allReferences.insert(reference)

        if allReferencesByUsr[reference.usr] == nil {
            allReferencesByUsr[reference.usr] = []
        }

        allReferencesByUsr[reference.usr]?.insert(reference)
    }

    func add(_ reference: Reference, from declaration: Declaration) {
        mutationQueue.sync {
            if reference.isRelated {
                _ = declaration.related.insert(reference)
            } else {
                _ = declaration.references.insert(reference)
            }
        }

        add(reference)
    }

    func remove(_ reference: Reference) {
        mutationQueue.sync {
            _ = allReferences.remove(reference)
            allReferences.subtract(reference.descendentReferences)
            allReferencesByUsr[reference.usr]?.remove(reference)
        }

        if let parent = reference.parent {
            mutationQueue.sync {
                parent.references.remove(reference)
                parent.related.remove(reference)
            }
        }
    }

    func markReachable(_ declaration: Declaration) {
        mutationQueue.sync {
            _ = reachableDeclarations.insert(declaration)
        }
    }

    func isReachable(_ declaration: Declaration) -> Bool {
        mutationQueue.sync {
            reachableDeclarations.contains(declaration)
        }
    }

    func isExternal(_ reference: Reference) -> Bool {
        explicitDeclaration(withUsr: reference.usr) == nil
    }

    func accept(visitor: SourceGraphVisitor.Type) throws {
        try visitor.make(graph: self).visit()
    }

    func inheritedTypeReferences(of decl: Declaration) -> [Reference] {
        var references: [Reference] = []

        for reference in decl.immediateInheritedTypeReferences {
            references.append(reference)

            if let inheritedDecl = explicitDeclaration(withUsr: reference.usr) {
                references = inheritedTypeReferences(of: inheritedDecl) + references
            }
        }

        return references
    }

    func inheritedDeclarations(of decl: Declaration) -> [Declaration] {
        inheritedTypeReferences(of: decl).compactMap { explicitDeclaration(withUsr: $0.usr) }
    }

    func immediateSubclasses(of decl: Declaration) -> [Declaration] {
        let allClasses = allDeclarationsByKind[.class] ?? []
        return allClasses
            .filter {
                $0.related.contains(where: { ref in
                    ref.kind == .class && decl.usrs.contains(ref.usr)
                })
            }.filter { $0 != decl }
    }

    func subclasses(of decl: Declaration) -> [Declaration] {
        let immediate = immediateSubclasses(of: decl)
        return immediate + immediate.flatMap { subclasses(of: $0) }
    }

    func mutating(_ block: () -> Void) {
        mutationQueue.sync(execute: block)
    }

    func extendedDeclaration(forExtension extensionDeclaration: Declaration) throws -> Declaration? {
        guard let extendedKind = extensionDeclaration.kind.extendedKind?.referenceEquivalent else {
            throw PeripheryError.sourceGraphIntegrityError(message: "Unknown extended reference kind for extension '\(extensionDeclaration.kind.rawValue)'")
        }

        guard let extendedReference = extensionDeclaration.references.first(where: { $0.kind == extendedKind && $0.name == extensionDeclaration.name }) else { return nil }

        if let extendedDeclaration = allExplicitDeclarationsByUsr[extendedReference.usr] {
            return extendedDeclaration
        }

        return nil
    }
}
