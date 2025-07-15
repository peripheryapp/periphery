import Configuration
import Foundation
import Logger
import Shared

public final class SourceGraph {
    public private(set) var allDeclarations: Set<Declaration> = []
    public private(set) var usedDeclarations: Set<Declaration> = []
    public private(set) var redundantProtocols: [Declaration: (references: Set<Reference>, inherited: Set<Reference>)] = [:]
    public private(set) var rootDeclarations: Set<Declaration> = []
    public private(set) var redundantPublicAccessibility: [Declaration: Set<String>] = [:]
    public private(set) var rootReferences: Set<Reference> = []
    public private(set) var allReferences: Set<Reference> = []
    public private(set) var retainedDeclarations: Set<Declaration> = []
    public private(set) var ignoredDeclarations: Set<Declaration> = []
    public private(set) var assetReferences: Set<AssetReference> = []
    public private(set) var mainAttributedDeclarations: Set<Declaration> = []
    public private(set) var allReferencesByUsr: [String: Set<Reference>] = [:]
    public private(set) var indexedSourceFiles: [SourceFile] = []
    public private(set) var unusedModuleImports: Set<Declaration> = []
    public private(set) var assignOnlyProperties: Set<Declaration> = []
    public private(set) var extensions: [Declaration: Set<Declaration>] = [:]

    private var indexedModules: Set<String> = []
    private var unindexedExportedModules: Set<String> = []
    private var allDeclarationsByKind: [Declaration.Kind: Set<Declaration>] = [:]
    private var allDeclarationsByUsr: [String: Declaration] = [:]
    private var moduleToExportingModules: [String: Set<String>] = [:]

    private let configuration: Configuration
    private let logger: Logger

    public init(configuration: Configuration, logger: Logger) {
        self.configuration = configuration
        self.logger = logger
    }

    public func indexingComplete() {
        rootDeclarations = allDeclarations.filter { $0.parent == nil }
        rootReferences = allReferences.filter { $0.parent == nil }
        unindexedExportedModules = Set(moduleToExportingModules.keys).subtracting(indexedModules)
    }

    public var unusedDeclarations: Set<Declaration> {
        allDeclarations.subtracting(usedDeclarations)
    }

    public func declarations(ofKind kind: Declaration.Kind) -> Set<Declaration> {
        allDeclarationsByKind[kind] ?? []
    }

    public func declarations(ofKinds kinds: Set<Declaration.Kind>) -> Set<Declaration> {
        declarations(ofKinds: Array(kinds))
    }

    public func declarations(ofKinds kinds: [Declaration.Kind]) -> Set<Declaration> {
        kinds.flatMapSet { allDeclarationsByKind[$0, default: []] }
    }

    public func declaration(withUsr usr: String) -> Declaration? {
        allDeclarationsByUsr[usr]
    }

    public func references(to decl: Declaration) -> Set<Reference> {
        decl.usrs.flatMapSet { references(to: $0) }
    }

    public func references(to usr: String) -> Set<Reference> {
        allReferencesByUsr[usr, default: []]
    }

    public func hasReferences(to decl: Declaration) -> Bool {
        decl.usrs.contains { !allReferencesByUsr[$0, default: []].isEmpty }
    }

    func markRedundantProtocol(_ declaration: Declaration, references: Set<Reference>, inherited: Set<Reference>) {
        redundantProtocols[declaration] = (references, inherited)
    }

    func markRedundantPublicAccessibility(_ declaration: Declaration, modules: Set<String>) {
        redundantPublicAccessibility[declaration] = modules
    }

    func unmarkRedundantPublicAccessibility(_ declaration: Declaration) {
        _ = redundantPublicAccessibility.removeValue(forKey: declaration)
    }

    func markIgnored(_ declaration: Declaration) {
        _ = ignoredDeclarations.insert(declaration)
    }

    public func markRetained(_ declaration: Declaration) {
        _ = retainedDeclarations.insert(declaration)
    }

    public func markRetained(_ declarations: Set<Declaration>) {
        retainedDeclarations.formUnion(declarations)
    }

    func markAssignOnlyProperty(_ declaration: Declaration) {
        _ = assignOnlyProperties.insert(declaration)
    }

    func markMainAttributed(_ declaration: Declaration) {
        _ = mainAttributedDeclarations.insert(declaration)
    }

    public func isRetained(_ declaration: Declaration) -> Bool {
        retainedDeclarations.contains(declaration)
    }

    public func add(_ declaration: Declaration) {
        allDeclarations.insert(declaration)
        allDeclarationsByKind[declaration.kind, default: []].insert(declaration)
        for usr in declaration.usrs {
            if let existingDecl = allDeclarationsByUsr[usr] {
                logger.warn("""
                Declaration conflict detected: a declaration with the USR '\(usr)' has already been indexed.
                This issue can cause inconsistent and incorrect results.
                Existing declaration: \(existingDecl), declared in modules: \(existingDecl.location.file.modules.sorted())
                Conflicting declaration: \(declaration), declared in modules: \(declaration.location.file.modules.sorted())
                To resolve this warning, make sure all build modules are uniquely named.
                """)
            }
            allDeclarationsByUsr[usr] = declaration
        }
    }

    public func add(_ declarations: Set<Declaration>) {
        declarations.forEach { add($0) }
    }

    public func remove(_ declaration: Declaration) {
        declaration.parent?.declarations.remove(declaration)
        allDeclarations.remove(declaration)
        allDeclarationsByKind[declaration.kind]?.remove(declaration)
        rootDeclarations.remove(declaration)
        usedDeclarations.remove(declaration)
        assignOnlyProperties.remove(declaration)
        declaration.usrs.forEach { allDeclarationsByUsr.removeValue(forKey: $0) }
    }

    public func add(_ reference: Reference) {
        _ = allReferences.insert(reference)
        allReferencesByUsr[reference.usr, default: []].insert(reference)
    }

    public func add(_ references: Set<Reference>) {
        allReferences.formUnion(references)
        references.forEach { allReferencesByUsr[$0.usr, default: []].insert($0) }
    }

    public func add(_ reference: Reference, from declaration: Declaration) {
        if reference.isRelated {
            _ = declaration.related.insert(reference)
        } else {
            _ = declaration.references.insert(reference)
        }

        add(reference)
    }

    func remove(_ reference: Reference) {
        _ = allReferences.remove(reference)
        allReferences.subtract(reference.descendentReferences)
        allReferencesByUsr[reference.usr]?.remove(reference)

        if let parent = reference.parent {
            parent.references.remove(reference)
            parent.related.remove(reference)
        }
    }

    public func add(_ assetReference: AssetReference) {
        _ = assetReferences.insert(assetReference)
    }

    func markUsed(_ declaration: Declaration) {
        _ = usedDeclarations.insert(declaration)
    }

    func isUsed(_ declaration: Declaration) -> Bool {
        usedDeclarations.contains(declaration)
    }

    func isExternal(_ reference: Reference) -> Bool {
        declaration(withUsr: reference.usr) == nil
    }

    public func addIndexedSourceFile(_ file: SourceFile) {
        indexedSourceFiles.append(file)
    }

    public func addIndexedModules(_ modules: Set<String>) {
        indexedModules.formUnion(modules)
    }

    public func isModuleIndexed(_ module: String) -> Bool {
        indexedModules.contains(module)
    }

    public func addExportedModule(_ module: String, exportedBy exportingModules: Set<String>) {
        moduleToExportingModules[module, default: []].formUnion(exportingModules)
    }

    public func moduleExportsUnindexedModules(_ module: String) -> Bool {
        unindexedExportedModules.contains { unindexedModule in
            isModule(unindexedModule, exportedBy: module)
        }
    }

    public func isModule(_ module: String, exportedBy exportingModule: String) -> Bool {
        let exportingModules = moduleToExportingModules[module, default: []]

        if exportingModules.contains(exportingModule) {
            // The module is exported directly.
            return true
        }

        // Recursively check if the module is exported transitively.
        return exportingModules.contains { nestedExportingModule in
            isModule(nestedExportingModule, exportedBy: exportingModule) &&
                isModule(module, exportedBy: nestedExportingModule)
        }
    }

    func markUnusedModuleImport(_ statement: ImportStatement) {
        let location = statement.location.relativeTo(.current)
        let usr = "import-\(statement.module)-\(location)"
        let decl = Declaration(kind: .module, usrs: [usr], location: statement.location)
        decl.name = statement.module
        unusedModuleImports.insert(decl)
    }

    func markExtension(_ extensionDecl: Declaration, extending extendedDecl: Declaration) {
        _ = extensions[extendedDecl, default: []].insert(extensionDecl)
    }

    func inheritedTypeReferences(of decl: Declaration, seenDeclarations: Set<Declaration> = []) -> Set<Reference> {
        var references = Set<Reference>()

        for reference in decl.immediateInheritedTypeReferences {
            references.insert(reference)

            if let inheritedDecl = declaration(withUsr: reference.usr) {
                // Detect circular references. The following is valid Swift.
                // class SomeClass {}
                // extension SomeClass: SomeProtocol {}
                // protocol SomeProtocol: SomeClass {}
                guard !seenDeclarations.contains(inheritedDecl) else { continue }
                references = inheritedTypeReferences(of: inheritedDecl, seenDeclarations: seenDeclarations.union([decl])).union(references)
            }
        }

        return references
    }

    func inheritedDeclarations(of decl: Declaration) -> [Declaration] {
        inheritedTypeReferences(of: decl).compactMap { declaration(withUsr: $0.usr) }
    }

    func immediateSubclasses(of decl: Declaration) -> Set<Declaration> {
        references(to: decl)
            .filter { $0.isRelated && $0.kind == .class }
            .flatMap { $0.parent?.usrs ?? [] }
            .compactMapSet { declaration(withUsr: $0) }
    }

    func subclasses(of decl: Declaration) -> Set<Declaration> {
        let immediate = immediateSubclasses(of: decl)
        let allSubclasses = immediate.flatMapSet { subclasses(of: $0) }
        return immediate.union(allSubclasses)
    }

    func extendedDeclarationReference(forExtension extensionDeclaration: Declaration) throws -> Reference? {
        guard let extendedKind = extensionDeclaration.kind.extendedKind else {
            throw PeripheryError.sourceGraphIntegrityError(message: "Unknown extended reference kind for extension '\(extensionDeclaration.kind.rawValue)'")
        }

        return extensionDeclaration.references.first(where: { $0.kind == extendedKind && $0.name == extensionDeclaration.name })
    }

    func extendedDeclaration(forExtension extensionDeclaration: Declaration) throws -> Declaration? {
        guard let extendedReference = try extendedDeclarationReference(forExtension: extensionDeclaration) else { return nil }

        if let extendedDeclaration = declaration(withUsr: extendedReference.usr) {
            return extendedDeclaration
        }

        return nil
    }

    func allSuperDeclarationsInOverrideChain(from decl: Declaration) -> Set<Declaration> {
        guard decl.isOverride else { return [] }

        let overridenDecl = decl.related
            .filter { $0.kind == decl.kind && $0.name == decl.name }
            .compactMap { declaration(withUsr: $0.usr) }
            .first

        guard let overridenDecl else {
            return []
        }

        return Set([overridenDecl]).union(allSuperDeclarationsInOverrideChain(from: overridenDecl))
    }

    func baseDeclaration(fromOverride decl: Declaration) -> (Declaration, Bool) {
        guard decl.isOverride else { return (decl, true) }

        let baseDecl = references(to: decl)
            .filter {
                $0.isRelated &&
                    $0.kind == decl.kind &&
                    $0.name == decl.name
            }
            .compactMap(\.parent)
            .first

        guard let baseDecl else {
            // Base reference is external, return the current function as it's the closest.
            return (decl, false)
        }

        return baseDeclaration(fromOverride: baseDecl)
    }

    func allOverrideDeclarations(fromBase decl: Declaration) -> Set<Declaration> {
        decl.relatedEquivalentReferences
            .compactMap { declaration(withUsr: $0.usr) }
            .reduce(into: .init()) { result, decl in
                guard decl.isOverride else { return }
                result.insert(decl)
                result.formUnion(allOverrideDeclarations(fromBase: decl))
            }
    }

    func isCodable(_ decl: Declaration) -> Bool {
        let codableTypes = ["Codable", "Decodable", "Encodable"] + configuration.externalEncodableProtocols + configuration.externalCodableProtocols

        return inheritedTypeReferences(of: decl).contains {
            guard let name = $0.name else { return false }
            return [.protocol, .typealias].contains($0.kind) && codableTypes.contains(name)
        }
    }

    func isEncodable(_ decl: Declaration) -> Bool {
        let encodableTypes = ["Encodable"] + configuration.externalEncodableProtocols + configuration.externalCodableProtocols

        return inheritedTypeReferences(of: decl).contains {
            guard let name = $0.name else { return false }
            return [.protocol, .typealias].contains($0.kind) && encodableTypes.contains(name)
        }
    }
}
