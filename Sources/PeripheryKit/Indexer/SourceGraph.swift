import Foundation
import Shared

public final class SourceGraph {
    private(set) var rootDeclarations: Set<Declaration> = []
    private(set) var rootReferences: Set<Reference> = []
    private(set) var allDeclarations: Set<Declaration> = []
    private(set) var allReferences: Set<Reference> = []
    private(set) var markedDeclarations: Set<Declaration> = []
    private(set) var ignoredDeclarations: Set<Declaration> = []

    private var allReferencesByUsr: [String: Set<Reference>] = [:]
    private var allDeclarationsByKind: [Declaration.Kind: Set<Declaration>] = [:]
    private var allExplicitDeclarationsByUsr: [String: Declaration] = [:]

    private let mutationQueue: DispatchQueue

    var xibReferences: [XibReference] = []
    var infoPlistReferences: [InfoPlistReference] = []

    public var dereferencedDeclarations: Set<Declaration> {
        return allDeclarations
            .subtracting(referencedDeclarations)
            .subtracting(ignoredDeclarations)
    }

    var referencedDeclarations: Set<Declaration> {
        return markedDeclarations
            .union(retainedDeclarations)
            .subtracting(ignoredDeclarations)
    }

    var retainedDeclarations: Set<Declaration> {
        return allDeclarations.filter { $0.isRetained }
    }

    public init() {
        mutationQueue = DispatchQueue(label: "SourceGraph.mutationQueue")
    }

    func identifyRootDeclarations() {
        rootDeclarations = allDeclarations.filter { $0.parent == nil }
    }

    func identifyRootReferences() {
        rootReferences = allReferences.filter { $0.parent == nil }
    }

    func declarations(ofKind kind: Declaration.Kind) -> Set<Declaration> {
        return allDeclarationsByKind[kind] ?? []
    }

    func declarations(ofKinds kinds: [Declaration.Kind]) -> Set<Declaration> {
        return Set(kinds.compactMap { allDeclarationsByKind[$0] }.joined())
    }

    func explicitDeclaration(withUsr usr: String) -> Declaration? {
        return allExplicitDeclarationsByUsr[usr]
    }

    func references(toUsr usr: String) -> Set<Reference> {
        return allReferencesByUsr[usr] ?? []
    }

    func ignore(_ declaration: Declaration) {
        ignoredDeclarations.insert(declaration)
    }

    func add(_ declaration: Declaration) {
        mutationQueue.sync {
            allDeclarations.insert(declaration)
            allDeclarationsByKind[declaration.kind, default: []].insert(declaration)

            if !declaration.isImplicit {
                allExplicitDeclarationsByUsr[declaration.usr] = declaration
            }
        }
    }

    func remove(_ declaration: Declaration) {
        mutationQueue.sync {
            declaration.parent?.declarations.remove(declaration)
            allDeclarations.remove(declaration)
            allDeclarationsByKind[declaration.kind]?.remove(declaration)
            allExplicitDeclarationsByUsr.removeValue(forKey: declaration.usr)
            rootDeclarations.remove(declaration)
            markedDeclarations.remove(declaration)
        }
    }

    func add(_ reference: Reference) {
        mutationQueue.sync {
            _ = allReferences.insert(reference)

            if allReferencesByUsr[reference.usr] == nil {
                allReferencesByUsr[reference.usr] = []
            }

            allReferencesByUsr[reference.usr]?.insert(reference)
        }
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

        if let parent = reference.parent as? Declaration {
            mutationQueue.sync {
                parent.references.remove(reference)
                parent.related.remove(reference)
            }
        } else if let parent = reference.parent as? Reference {
            _ = mutationQueue.sync {
                parent.references.remove(reference)
            }
        }
    }

    func mark(_ declaration: Declaration) {
        markedDeclarations.insert(declaration)
    }

    func accept(visitor: SourceGraphVisitor.Type) throws {
        try visitor.make(graph: self).visit()
    }

    func superclassReferences(of decl: Declaration) -> [Reference] {
        var references: [Reference] = []

        for reference in decl.immediateSuperclassReferences {
            references.append(reference)

            if let superclassDecl = explicitDeclaration(withUsr: reference.usr) {
                references = superclassReferences(of: superclassDecl) + references
            }
        }

        return references
    }

    func superclasses(of decl: Declaration) -> [Declaration] {
        return superclassReferences(of: decl).compactMap {
            explicitDeclaration(withUsr: $0.usr)
        }
    }

    func immediateSubclasses(of decl: Declaration) -> [Declaration] {
        let allClasses = allDeclarationsByKind[.class] ?? []
        return allClasses
            .filter {
                $0.related.contains(where: { ref in
                    ref.kind == .class && ref.usr == decl.usr
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

    private let extendedReferenceKindMap: [Declaration.Kind: Reference.Kind] = [
        .extensionClass: .class,
        .extensionStruct: .struct,
        .extensionProtocol: .protocol,
        .extensionEnum: .enum
        ]

    func extendedDeclaration(forExtension extensionDeclaration: Declaration) throws -> Declaration? {
        guard let extendedKind = extendedReferenceKindMap[extensionDeclaration.kind] else {
            throw PeripheryError.sourceGraphIntegrityError(message: "Unknown extended reference kind for extension '\(extensionDeclaration.kind.rawValue)'")
        }

        guard let extendedReference = extensionDeclaration.references.first(where: { $0.kind == extendedKind && $0.name == extensionDeclaration.name }) else { return nil }

        if let extendedDeclaration = allExplicitDeclarationsByUsr[extendedReference.usr] {
            return extendedDeclaration
        }

        return nil
    }
}
