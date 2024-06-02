import Foundation
import Shared

public final class SourceGraph {
    // Global shared instance to prevent costly deinitialization.
    public static var shared = SourceGraph()

    private(set) var allDeclarations: Set<Declaration> = []
    private(set) var usedDeclarations: Set<Declaration> = []
    private(set) var redundantProtocols: [Declaration: (references: Set<Reference>, inherited: Set<Reference>)] = [:]
    private(set) var rootDeclarations: Set<Declaration> = []
    private(set) var redundantPublicAccessibility: [Declaration: Set<String>] = [:]
    private(set) var rootReferences: Set<Reference> = []
    private(set) var allReferences: Set<Reference> = []
    private(set) var retainedDeclarations: Set<Declaration> = []
    private(set) var ignoredDeclarations: Set<Declaration> = []
    private(set) var assetReferences: Set<AssetReference> = []
    private(set) var mainAttributedDeclarations: Set<Declaration> = []
    private(set) var allReferencesByUsr: [String: Set<Reference>] = [:]
    private(set) var indexedModules: Set<String> = []
    private(set) var indexedSourceFiles: [SourceFile] = []
    private(set) var unusedModuleImports: Set<Declaration> = []
    private(set) var assignOnlyProperties: Set<Declaration> = []
    private(set) var extensions: [Declaration: Set<Declaration>] = [:]

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

    var unusedDeclarations: Set<Declaration> {
        allDeclarations.subtracting(usedDeclarations)
    }

    func declarations(ofKind kind: Declaration.Kind) -> Set<Declaration> {
        allDeclarationsByKind[kind] ?? []
    }

    func declarations(ofKinds kinds: Set<Declaration.Kind>) -> Set<Declaration> {
        declarations(ofKinds: Array(kinds))
    }

    func declarations(ofKinds kinds: [Declaration.Kind]) -> Set<Declaration> {
        kinds.flatMapSet { allDeclarationsByKind[$0, default: []] }
    }

    func explicitDeclaration(withUsr usr: String) -> Declaration? {
        allExplicitDeclarationsByUsr[usr]
    }

    func references(to decl: Declaration) -> Set<Reference> {
        decl.usrs.flatMapSet { allReferencesByUsr[$0, default: []] }
    }

    func hasReferences(to decl: Declaration) -> Bool {
        decl.usrs.contains { !allReferencesByUsr[$0, default: []].isEmpty }
    }

    func markRedundantProtocol(_ declaration: Declaration, references: Set<Reference>, inherited: Set<Reference>) {
        withLock {
            redundantProtocols[declaration] = (references, inherited)
        }
    }

    func markRedundantPublicAccessibility(_ declaration: Declaration, modules: Set<String>) {
        withLock {
            redundantPublicAccessibility[declaration] = modules
        }
    }

    func unmarkRedundantPublicAccessibility(_ declaration: Declaration) {
        withLock {
            _ = redundantPublicAccessibility.removeValue(forKey: declaration)
        }
    }

    func markIgnored(_ declaration: Declaration) {
        withLock {
            _ = ignoredDeclarations.insert(declaration)
        }
    }

    func markRetained(_ declaration: Declaration) {
        withLock {
            markRetainedUnsafe(declaration)
        }
    }

    func markRetainedUnsafe(_ declaration: Declaration) {
        _ = retainedDeclarations.insert(declaration)
    }

    func markRetainedUnsafe(_ declarations: Set<Declaration>) {
        retainedDeclarations.formUnion(declarations)
    }

    func markAssignOnlyProperty(_ declaration: Declaration) {
        withLock {
            _ = assignOnlyProperties.insert(declaration)
        }
    }

    func markMainAttributed(_ declaration: Declaration) {
        withLock {
            _ = mainAttributedDeclarations.insert(declaration)
        }
    }

    func isRetained(_ declaration: Declaration) -> Bool {
        withLock {
            retainedDeclarations.contains(declaration)
        }
    }

    func addUnsafe(_ declaration: Declaration) {
        allDeclarations.insert(declaration)
        allDeclarationsByKind[declaration.kind, default: []].insert(declaration)

        if !declaration.isImplicit {
            declaration.usrs.forEach { allExplicitDeclarationsByUsr[$0] = declaration }
        }
    }

    func addUnsafe(_ declarations: Set<Declaration>) {
        allDeclarations.formUnion(declarations)

        for declaration in declarations {
            allDeclarationsByKind[declaration.kind, default: []].insert(declaration)

            if !declaration.isImplicit {
                declaration.usrs.forEach { allExplicitDeclarationsByUsr[$0] = declaration }
            }
        }
    }

    func remove(_ declaration: Declaration) {
        withLock {
            removeUnsafe(declaration)
        }
    }

    func removeUnsafe(_ declaration: Declaration) {
        declaration.parent?.declarations.remove(declaration)
        allDeclarations.remove(declaration)
        allDeclarationsByKind[declaration.kind]?.remove(declaration)
        rootDeclarations.remove(declaration)
        usedDeclarations.remove(declaration)
        assignOnlyProperties.remove(declaration)
        declaration.usrs.forEach { allExplicitDeclarationsByUsr.removeValue(forKey: $0) }
    }

    func addUnsafe(_ reference: Reference) {
        _ = allReferences.insert(reference)
        allReferencesByUsr[reference.usr, default: []].insert(reference)
    }

    func addUnsafe(_ references: Set<Reference>) {
        allReferences.formUnion(references)
        references.forEach { allReferencesByUsr[$0.usr, default: []].insert($0) }
    }

    func add(_ reference: Reference, from declaration: Declaration) {
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

    func add(_ assetReference: AssetReference) {
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

    func addIndexedSourceFile(_ file: SourceFile) {
        withLock {
            indexedSourceFiles.append(file)
        }
    }

    func addIndexedModules(_ modules: Set<String>) {
        withLock {
            indexedModules.formUnion(modules)
        }
    }

    func addExportedModule(_ module: String, exportedBy exportingModules: Set<String>) {
        withLock {
            moduleToExportingModules[module, default: []].formUnion(exportingModules)
        }
    }

    func isModule(_ module: String, exportedBy exportingModule: String) -> Bool {
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

    func markUnusedModuleImport(_ statement: ImportStatement) {
        withLock {
            let location = statement.location.relativeTo(.current)
            let usr = "import-\(statement.module)-\(location)"
            let decl = Declaration(kind: .module, usrs: [usr], location: statement.location)
            decl.name = statement.module
            unusedModuleImports.insert(decl)
        }
    }

    func markExtension(_ extensionDecl: Declaration, extending extendedDecl: Declaration) {
        withLock {
            _ = extensions[extendedDecl, default: []].insert(extensionDecl)
        }
    }

    func inheritedTypeReferences(of decl: Declaration, seenDeclarations: Set<Declaration> = []) -> Set<Reference> {
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

    func inheritedDeclarations(of decl: Declaration) -> [Declaration] {
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

    func withLock<T>(_ block: () -> T) -> T {
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
