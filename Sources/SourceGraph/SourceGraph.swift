import Foundation
import Shared

public final class SourceGraph {
    // Global shared instance to prevent costly deinitialization.
    public static var shared = SourceGraph()

    public var allDeclarations: Set<Declaration> = []
    public var usedDeclarations: Set<Declaration> = []
    public var redundantProtocols: [Declaration: (references: Set<Reference>, inherited: Set<Reference>)] = [:]
    public var rootDeclarations: Set<Declaration> = []
    public var redundantPublicAccessibility: [Declaration: Set<String>] = [:]
    public var rootReferences: Set<Reference> = []
    public var allReferences: Set<Reference> = []
    public var retainedDeclarations: Set<Declaration> = []
    public var ignoredDeclarations: Set<Declaration> = []
    public var assetReferences: Set<AssetReference> = []
    public var mainAttributedDeclarations: Set<Declaration> = []
    public var allReferencesByUsr: [String: Set<Reference>] = [:]
    public var indexedModules: Set<String> = []
    public var indexedSourceFiles: [SourceFile] = []
    public var unusedModuleImports: Set<Declaration> = []
    public var assignOnlyProperties: Set<Declaration> = []
    public var extensions: [Declaration: Set<Declaration>] = [:]

    private var allDeclarationsByKind: [Declaration.Kind: Set<Declaration>] = [:]
    private var allExplicitDeclarationsByUsr: [String: Declaration] = [:]
    private var moduleToExportingModules: [String: Set<String>] = [:]

    private let lock = UnfairLock()
    private let configuration: Configuration

    init(configuration: Configuration = .shared) {
        self.configuration = configuration
    }

    public func indexingComplete() {
        rootDeclarations = allDeclarations.filter { $0.parent == nil }
        rootReferences = allReferences.filter { $0.parent == nil }
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

    public func explicitDeclaration(withUsr usr: String) -> Declaration? {
        allExplicitDeclarationsByUsr[usr]
    }

    public func references(to decl: Declaration) -> Set<Reference> {
        decl.usrs.flatMapSet { allReferencesByUsr[$0, default: []] }
    }

    public func hasReferences(to decl: Declaration) -> Bool {
        decl.usrs.contains { !allReferencesByUsr[$0, default: []].isEmpty }
    }

    public func markRedundantProtocol(_ declaration: Declaration, references: Set<Reference>, inherited: Set<Reference>) {
        withLock {
            redundantProtocols[declaration] = (references, inherited)
        }
    }

    public func markRedundantPublicAccessibility(_ declaration: Declaration, modules: Set<String>) {
        withLock {
            redundantPublicAccessibility[declaration] = modules
        }
    }

    public func unmarkRedundantPublicAccessibility(_ declaration: Declaration) {
        withLock {
            _ = redundantPublicAccessibility.removeValue(forKey: declaration)
        }
    }

    public func markIgnored(_ declaration: Declaration) {
        withLock {
            _ = ignoredDeclarations.insert(declaration)
        }
    }

    public func markRetained(_ declaration: Declaration) {
        withLock {
            markRetainedUnsafe(declaration)
        }
    }

    public func markRetainedUnsafe(_ declaration: Declaration) {
        _ = retainedDeclarations.insert(declaration)
    }

    public func markRetainedUnsafe(_ declarations: Set<Declaration>) {
        retainedDeclarations.formUnion(declarations)
    }

    public func markAssignOnlyProperty(_ declaration: Declaration) {
        withLock {
            _ = assignOnlyProperties.insert(declaration)
        }
    }

    public func markMainAttributed(_ declaration: Declaration) {
        withLock {
            _ = mainAttributedDeclarations.insert(declaration)
        }
    }

    public func isRetained(_ declaration: Declaration) -> Bool {
        withLock {
            retainedDeclarations.contains(declaration)
        }
    }

    public func addUnsafe(_ declaration: Declaration) {
        allDeclarations.insert(declaration)
        allDeclarationsByKind[declaration.kind, default: []].insert(declaration)

        if !declaration.isImplicit {
            declaration.usrs.forEach { allExplicitDeclarationsByUsr[$0] = declaration }
        }
    }

    public func addUnsafe(_ declarations: Set<Declaration>) {
        allDeclarations.formUnion(declarations)

        for declaration in declarations {
            allDeclarationsByKind[declaration.kind, default: []].insert(declaration)

            if !declaration.isImplicit {
                declaration.usrs.forEach { allExplicitDeclarationsByUsr[$0] = declaration }
            }
        }
    }

    public func remove(_ declaration: Declaration) {
        withLock {
            removeUnsafe(declaration)
        }
    }

    public func removeUnsafe(_ declaration: Declaration) {
        declaration.parent?.declarations.remove(declaration)
        allDeclarations.remove(declaration)
        allDeclarationsByKind[declaration.kind]?.remove(declaration)
        rootDeclarations.remove(declaration)
        usedDeclarations.remove(declaration)
        assignOnlyProperties.remove(declaration)
        declaration.usrs.forEach { allExplicitDeclarationsByUsr.removeValue(forKey: $0) }
    }

    public func addUnsafe(_ reference: Reference) {
        _ = allReferences.insert(reference)
        allReferencesByUsr[reference.usr, default: []].insert(reference)
    }

    public func addUnsafe(_ references: Set<Reference>) {
        allReferences.formUnion(references)
        references.forEach { allReferencesByUsr[$0.usr, default: []].insert($0) }
    }

    public func add(_ reference: Reference, from declaration: Declaration) {
        withLock {
            if reference.isRelated {
                _ = declaration.related.insert(reference)
            } else {
                _ = declaration.references.insert(reference)
            }

            addUnsafe(reference)
        }
    }

    func remove(_ reference: Reference) {
        withLock {
            _ = allReferences.remove(reference)
            allReferences.subtract(reference.descendentReferences)
            allReferencesByUsr[reference.usr]?.remove(reference)
        }

        if let parent = reference.parent {
            withLock {
                parent.references.remove(reference)
                parent.related.remove(reference)
            }
        }
    }

    public func add(_ assetReference: AssetReference) {
        withLock {
            _ = assetReferences.insert(assetReference)
        }
    }

    func markUsed(_ declaration: Declaration) {
        withLock {
            _ = usedDeclarations.insert(declaration)
        }
    }

    func isUsed(_ declaration: Declaration) -> Bool {
        withLock {
            usedDeclarations.contains(declaration)
        }
    }

    func isExternal(_ reference: Reference) -> Bool {
        explicitDeclaration(withUsr: reference.usr) == nil
    }

    public func addIndexedSourceFile(_ file: SourceFile) {
        withLock {
            indexedSourceFiles.append(file)
        }
    }

    public func addIndexedModules(_ modules: Set<String>) {
        withLock {
            indexedModules.formUnion(modules)
        }
    }

    public func addExportedModule(_ module: String, exportedBy exportingModules: Set<String>) {
        withLock {
            moduleToExportingModules[module, default: []].formUnion(exportingModules)
        }
    }

    public func isModule(_ module: String, exportedBy exportingModule: String) -> Bool {
        withLock {
            isModuleUnsafe(module, exportedBy: exportingModule)
        }
    }

    private func isModuleUnsafe(_ module: String, exportedBy exportingModule: String) -> Bool {
        let exportingModules = moduleToExportingModules[module, default: []]

        if exportingModules.contains(exportingModule) {
            // The module is exported directly.
            return true
        }

        // Recursively check if the module is exported transitively.
        return exportingModules.contains { nestedExportingModule in
            return isModuleUnsafe(nestedExportingModule, exportedBy: exportingModule) &&
            isModuleUnsafe(module, exportedBy: nestedExportingModule)
        }
    }

    public func markUnusedModuleImport(_ statement: ImportStatement) {
        withLock {
            let location = statement.location.relativeTo(.current)
            let usr = "import-\(statement.module)-\(location)"
            let decl = Declaration(kind: .module, usrs: [usr], location: statement.location)
            decl.name = statement.module
            unusedModuleImports.insert(decl)
        }
    }

    public func markExtension(_ extensionDecl: Declaration, extending extendedDecl: Declaration) {
        withLock {
            _ = extensions[extendedDecl, default: []].insert(extensionDecl)
        }
    }

    public func inheritedTypeReferences(of decl: Declaration, seenDeclarations: Set<Declaration> = []) -> Set<Reference> {
        var references = Set<Reference>()

        for reference in decl.immediateInheritedTypeReferences {
            references.insert(reference)

            if let inheritedDecl = explicitDeclaration(withUsr: reference.usr) {
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

    public func inheritedDeclarations(of decl: Declaration) -> [Declaration] {
        inheritedTypeReferences(of: decl).compactMap { explicitDeclaration(withUsr: $0.usr) }
    }

    func immediateSubclasses(of decl: Declaration) -> Set<Declaration> {
        references(to: decl)
            .filter { $0.isRelated && $0.kind == .class }
            .flatMap { $0.parent?.usrs ?? [] }
            .compactMapSet { explicitDeclaration(withUsr: $0) }
    }

    func subclasses(of decl: Declaration) -> Set<Declaration> {
        let immediate = immediateSubclasses(of: decl)
        let allSubclasses = immediate.flatMapSet { subclasses(of: $0) }
        return immediate.union(allSubclasses)
    }

    public func withLock<T>(_ block: () -> T) -> T {
        lock.perform(block)
    }

    func extendedDeclarationReference(forExtension extensionDeclaration: Declaration) throws -> Reference? {
        guard let extendedKind = extensionDeclaration.kind.extendedKind else {
            throw PeripheryError.sourceGraphIntegrityError(message: "Unknown extended reference kind for extension '\(extensionDeclaration.kind.rawValue)'")
        }

        return extensionDeclaration.references.first(where: { $0.kind == extendedKind && $0.name == extensionDeclaration.name })
    }

    func extendedDeclaration(forExtension extensionDeclaration: Declaration) throws -> Declaration? {
        guard let extendedReference = try extendedDeclarationReference(forExtension: extensionDeclaration) else { return nil }

        if let extendedDeclaration = allExplicitDeclarationsByUsr[extendedReference.usr] {
            return extendedDeclaration
        }

        return nil
    }

    func baseDeclaration(fromOverride decl: Declaration) -> (Declaration, Bool) {
        guard decl.isOverride else { return (decl, true) }

        let baseDecl = references(to: decl)
            .filter {
                $0.isRelated &&
                $0.kind == decl.kind &&
                $0.name == decl.name
            }
            .compactMap { $0.parent }
            .first

        guard let baseDecl = baseDecl else {
            // Base reference is external, return the current function as it's the closest.
            return (decl, false)
        }

        return baseDeclaration(fromOverride: baseDecl)
    }

    func allOverrideDeclarations(fromBase decl: Declaration) -> Set<Declaration> {
        decl.relatedEquivalentReferences
            .compactMap { explicitDeclaration(withUsr: $0.usr) }
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
