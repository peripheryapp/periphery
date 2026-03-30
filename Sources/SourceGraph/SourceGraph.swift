import Configuration
import Foundation
import Shared

public final class SourceGraph {
    public private(set) var redundantProtocols: [Declaration: (references: [Reference], inherited: [Reference])] = [:]
    public private(set) var rootDeclarations: Set<Declaration> = []
    public private(set) var redundantPublicAccessibility: [Declaration: Set<String>] = [:]
    public private(set) var rootReferences: [Reference] = []
    public private(set) var retainedDeclarations: Set<Declaration> = []
    public private(set) var ignoredDeclarations: Set<Declaration> = []
    public private(set) var assetReferences: Set<AssetReference> = []
    public private(set) var mainAttributedDeclarations: Set<Declaration> = []
    /// Flat array indexed by `USRID.rawValue` for O(1) reference lookup by USR.
    /// Maintained incrementally during indexing so that `indexingComplete()` has
    /// no per-reference hashing work to do.
    private var referencesByUsrID: [[Reference]] = []
    public private(set) var indexedSourceFiles: [SourceFile] = []
    public private(set) var unusedModuleImports: Set<Declaration> = []
    public private(set) var assignOnlyProperties: Set<Declaration> = []
    public private(set) var suppressedAssignOnlyProperties: Set<Declaration> = []
    public private(set) var extensions: [Declaration: Set<Declaration>] = [:]
    public private(set) var commandIgnoredDeclarations: [Declaration: CommandIgnoreKind] = [:]
    public private(set) var functionsWithIgnoredParameters: Set<Declaration> = []

    let moduleInterner = ModuleNameInterner()
    public let usrInterner = USRInterner()
    private var indexedModules: Set<ModuleID> = []
    private var unindexedExportedModules: Set<ModuleID> = []
    private var allDeclarationsByKind: [Declaration.Kind: Set<Declaration>] = [:]
    private var declarationsOfKindsCache: [Set<Declaration.Kind>: Set<Declaration>] = [:]
    private var declarationsOfKindsCacheDirty = false
    /// Flat array indexed by `USRID.rawValue` for O(1) declaration lookup by USR.
    private var declarationsByUsrID: [Declaration?] = []
    private var moduleToExportingModules: [ModuleID: Set<ModuleID>] = [:]
    private var moduleExportsUnindexedCache: [ModuleID: Bool] = [:]

    private let configuration: Configuration

    public init(configuration: Configuration) {
        self.configuration = configuration
    }

    public func reserveCapacity(forFileCount fileCount: Int) {
        let estimatedDeclarations = fileCount * 100
        let estimatedUsrs = fileCount * 80
        usrInterner.reserveCapacity(estimatedUsrs)
        retainedDeclarations.reserveCapacity(estimatedDeclarations / 4)
        referencesByUsrID.reserveCapacity(estimatedUsrs)
    }

    public func indexingComplete() {
        rootDeclarations = Set(allDeclarationsByKind.values.joined().filter { $0.parent == nil })
        rootReferences = referencesByUsrID.flatMap { $0.filter { $0.parent == nil } }
        unindexedExportedModules = Set(moduleToExportingModules.keys).subtracting(indexedModules)
    }

    public var allDeclarations: FlattenSequence<Dictionary<Declaration.Kind, Set<Declaration>>.Values> {
        allDeclarationsByKind.values.joined()
    }

    public var allReferences: FlattenSequence<[[Reference]]> {
        referencesByUsrID.joined()
    }

    public var unusedDeclarations: Set<Declaration> {
        Set(allDeclarationsByKind.values.joined().filter { !$0.isUsed })
    }

    public func declarations(ofKind kind: Declaration.Kind) -> Set<Declaration> {
        allDeclarationsByKind[kind] ?? []
    }

    public func declarations(ofKinds kinds: Set<Declaration.Kind>) -> Set<Declaration> {
        if declarationsOfKindsCacheDirty {
            declarationsOfKindsCache.removeAll(keepingCapacity: true)
            declarationsOfKindsCacheDirty = false
        }
        if let cached = declarationsOfKindsCache[kinds] { return cached }
        // Pre-size the set to avoid incremental rehashing during formUnion.
        // Per-kind sets are disjoint so the sum is exact.
        let totalCount = kinds.reduce(0) { $0 + (allDeclarationsByKind[$1]?.count ?? 0) }
        var result = Set<Declaration>(minimumCapacity: totalCount)
        for kind in kinds {
            result.formUnion(allDeclarationsByKind[kind, default: []])
        }
        declarationsOfKindsCache[kinds] = result
        return result
    }

    public func declarations(ofKinds kinds: [Declaration.Kind]) -> Set<Declaration> {
        declarations(ofKinds: Set(kinds))
    }

    public func declaration(withUsr usr: String) -> Declaration? {
        guard let usrID = usrInterner.existing(usr) else { return nil }

        let idx = usrID.rawValue
        guard idx < declarationsByUsrID.count else { return nil }

        return declarationsByUsrID[idx]
    }

    func declaration(withUsrID usrID: USRID) -> Declaration? {
        let idx = usrID.rawValue
        guard idx < declarationsByUsrID.count else { return nil }

        return declarationsByUsrID[idx]
    }

    public func references(to decl: Declaration) -> [Reference] {
        if decl.usrIDs.count == 1 {
            return refsForUsr(decl.usrIDs[0])
        }
        return decl.usrIDs.flatMap { refsForUsr($0) }
    }

    public func references(to usr: String) -> [Reference] {
        guard let usrID = usrInterner.existing(usr) else { return [] }

        return refsForUsr(usrID)
    }

    func references(toUsrID usrID: USRID) -> [Reference] {
        refsForUsr(usrID)
    }

    public func hasReferences(to decl: Declaration) -> Bool {
        decl.usrIDs.contains { usrHasRefs($0) }
    }

    private func refsForUsr(_ usrID: USRID) -> [Reference] {
        let idx = usrID.rawValue
        return idx < referencesByUsrID.count ? referencesByUsrID[idx] : []
    }

    private func usrHasRefs(_ usrID: USRID) -> Bool {
        let idx = usrID.rawValue
        return idx < referencesByUsrID.count && !referencesByUsrID[idx].isEmpty
    }

    private func ensureUsrBucket(for usrID: USRID) {
        let idx = usrID.rawValue
        if idx >= referencesByUsrID.count {
            referencesByUsrID.append(contentsOf: repeatElement([Reference](), count: idx + 1 - referencesByUsrID.count))
        }
    }

    private func ensureUsrDeclBucket(for usrID: USRID) {
        let idx = usrID.rawValue
        if idx >= declarationsByUsrID.count {
            declarationsByUsrID.append(contentsOf: repeatElement(nil, count: idx + 1 - declarationsByUsrID.count))
        }
    }

    func markRedundantProtocol(_ declaration: Declaration, references: [Reference], inherited: [Reference]) {
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

    public func markCommandIgnored(_ declaration: Declaration, kind: CommandIgnoreKind) {
        commandIgnoredDeclarations[declaration] = kind
    }

    public func markHasIgnoredParameters(_ declaration: Declaration) {
        _ = functionsWithIgnoredParameters.insert(declaration)
    }

    public func markRetained(_ declaration: Declaration) {
        if let parent = declaration.parent {
            for usrID in declaration.usrIDs {
                let usr = usrInterner.string(for: usrID)
                let reference = Reference(
                    name: declaration.name,
                    kind: .retained,
                    declarationKind: declaration.kind,
                    usrID: usrID,
                    usr: usr,
                    location: declaration.location
                )
                reference.parent = parent
                add(reference, from: parent)
            }
        } else {
            _ = retainedDeclarations.insert(declaration)
        }
    }

    func unmarkRetained(_ declaration: Declaration) {
        retainedDeclarations.remove(declaration)

        let retainedReferences = references(to: declaration)
            .filter { $0.kind == .retained && $0.parent === declaration.parent }

        for reference in retainedReferences {
            remove(reference)
        }
    }

    public func markRetained(_ declarations: Set<Declaration>) {
        declarations.forEach { markRetained($0) }
    }

    func markAssignOnlyProperty(_ declaration: Declaration) {
        _ = assignOnlyProperties.insert(declaration)
    }

    func markSuppressedAssignOnlyProperty(_ declaration: Declaration) {
        _ = suppressedAssignOnlyProperties.insert(declaration)
    }

    func markMainAttributed(_ declaration: Declaration) {
        _ = mainAttributedDeclarations.insert(declaration)
    }

    public func isRetained(_ declaration: Declaration) -> Bool {
        retainedDeclarations.contains(declaration) || references(to: declaration).contains { $0.kind == .retained }
    }

    public func add(_ declaration: Declaration) throws {
        try validateNoDeclarationConflict(for: declaration)

        allDeclarationsByKind[declaration.kind, default: []].insert(declaration)
        declarationsOfKindsCacheDirty = true
        for usrID in declaration.usrIDs {
            ensureUsrDeclBucket(for: usrID)
            declarationsByUsrID[usrID.rawValue] = declaration
        }
    }

    public func add(_ declarations: Set<Declaration>) throws {
        for declaration in declarations {
            try add(declaration)
        }
    }

    public func remove(_ declaration: Declaration) {
        if let i = declaration.parent?.declarations.firstIndex(where: { $0 === declaration }) {
            declaration.parent?.declarations.remove(at: i)
        }
        allDeclarationsByKind[declaration.kind]?.remove(declaration)
        declarationsOfKindsCacheDirty = true
        rootDeclarations.remove(declaration)
        declaration.isUsed = false
        assignOnlyProperties.remove(declaration)
        suppressedAssignOnlyProperties.remove(declaration)
        for usrID in declaration.usrIDs {
            let idx = usrID.rawValue
            if idx < declarationsByUsrID.count {
                declarationsByUsrID[idx] = nil
            }
        }
    }

    public func add(_ reference: Reference) {
        ensureUsrBucket(for: reference.usrID)
        referencesByUsrID[reference.usrID.rawValue].append(reference)
    }

    public func add(_ references: [Reference]) {
        if let maxID = references.lazy.map(\.usrID.rawValue).max() {
            ensureUsrBucket(for: USRID(maxID))
        }
        for ref in references {
            referencesByUsrID[ref.usrID.rawValue].append(ref)
        }
    }

    public func add(_ reference: Reference, from declaration: Declaration) {
        if reference.kind == .related {
            declaration.related.append(reference)
        } else {
            declaration.references.append(reference)
        }

        add(reference)
    }

    func remove(_ reference: Reference) {
        let idx = reference.usrID.rawValue
        if idx < referencesByUsrID.count,
           let i = referencesByUsrID[idx].firstIndex(where: { $0 === reference })
        {
            referencesByUsrID[idx].remove(at: i)
        }

        if let parent = reference.parent {
            if let i = parent.references.firstIndex(where: { $0 === reference }) {
                parent.references.remove(at: i)
            }
            if let i = parent.related.firstIndex(where: { $0 === reference }) {
                parent.related.remove(at: i)
            }
        }
    }

    public func add(_ assetReference: AssetReference) {
        _ = assetReferences.insert(assetReference)
    }

    func markUsed(_ declaration: Declaration) {
        declaration.isUsed = true
    }

    func isUsed(_ declaration: Declaration) -> Bool {
        declaration.isUsed
    }

    func isExternal(_ reference: Reference) -> Bool {
        declaration(withUsrID: reference.usrID) == nil
    }

    public func addIndexedSourceFile(_ file: SourceFile) {
        indexedSourceFiles.append(file)
    }

    public func addIndexedModules(_ modules: Set<String>) {
        indexedModules.formUnion(moduleInterner.intern(modules))
    }

    func isModuleIndexed(_ moduleID: ModuleID) -> Bool {
        indexedModules.contains(moduleID)
    }

    public func addExportedModule(_ module: String, exportedBy exportingModules: Set<String>) {
        let moduleID = moduleInterner.intern(module)
        let exportingIDs = moduleInterner.intern(exportingModules)
        moduleToExportingModules[moduleID, default: []].formUnion(exportingIDs)
    }

    func moduleExportsUnindexedModules(_ moduleID: ModuleID) -> Bool {
        if let cached = moduleExportsUnindexedCache[moduleID] { return cached }
        let result = unindexedExportedModules.contains { unindexedModule in
            isModule(unindexedModule, exportedBy: moduleID)
        }
        moduleExportsUnindexedCache[moduleID] = result
        return result
    }

    private var isModuleExportedCache: [Int: Bool] = [:]

    func isModule(_ module: ModuleID, exportedBy exportingModule: ModuleID) -> Bool {
        // Pack the module pair into a single Int to keep this hot-path cache
        // lookup cheaper than hashing a tuple or custom key type. `ModuleID`
        // enforces the radix bound so this base-`packingRadix` encoding is unique.
        let key = module.rawValue &* ModuleID.packingRadix &+ exportingModule.rawValue
        if let cached = isModuleExportedCache[key] { return cached }

        let exportingModules = moduleToExportingModules[module, default: []]
        var result = exportingModules.contains(exportingModule)
        if !result {
            result = exportingModules.contains { nestedExportingModule in
                isModule(nestedExportingModule, exportedBy: exportingModule) &&
                    isModule(module, exportedBy: nestedExportingModule)
            }
        }
        isModuleExportedCache[key] = result
        return result
    }

    private var relativePathCache: [ObjectIdentifier: String] = [:]

    func markUnusedModuleImport(_ statement: ImportStatement) {
        let loc = statement.location
        let fileOID = ObjectIdentifier(loc.file)
        let relativePath: String
        if let cached = relativePathCache[fileOID] {
            relativePath = cached
        } else {
            relativePath = loc.file.path.relativeTo(configuration.projectRoot).string
            relativePathCache[fileOID] = relativePath
        }
        let usr = "import-\(statement.module)-\(relativePath):\(loc.line):\(loc.column)"
        let usrID = usrInterner.intern(usr)
        let decl = Declaration(name: statement.module, kind: .module, usrs: [usr], usrIDs: [usrID], location: loc)
        unusedModuleImports.insert(decl)
    }

    func markExtension(_ extensionDecl: Declaration, extending extendedDecl: Declaration) {
        _ = extensions[extendedDecl, default: []].insert(extensionDecl)
    }

    func inheritedTypeReferences(of decl: Declaration, seenDeclarations: Set<Declaration> = []) -> Set<Reference> {
        var references = Set<Reference>()

        for reference in decl.immediateInheritedTypeReferences {
            references.insert(reference)

            if let inheritedDecl = declaration(withUsrID: reference.usrID) {
                guard !seenDeclarations.contains(inheritedDecl) else { continue }

                references = inheritedTypeReferences(of: inheritedDecl, seenDeclarations: seenDeclarations.union([decl])).union(references)
            }
        }

        return references
    }

    func inheritedDeclarations(of decl: Declaration) -> [Declaration] {
        inheritedTypeReferences(of: decl).compactMap { declaration(withUsrID: $0.usrID) }
    }

    func immediateSubclasses(of decl: Declaration) -> Set<Declaration> {
        references(to: decl)
            .filter { $0.kind == .related && $0.declarationKind == .class }
            .flatMap { $0.parent?.usrIDs ?? [] }
            .compactMapSet { declaration(withUsrID: $0) }
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

        return extensionDeclaration.references
            .filter { $0.declarationKind == extendedKind && $0.name == extensionDeclaration.name }
            .min()
    }

    func extendedDeclaration(forExtension extensionDeclaration: Declaration) throws -> Declaration? {
        guard let extendedReference = try extendedDeclarationReference(forExtension: extensionDeclaration) else { return nil }

        if let extendedDeclaration = declaration(withUsrID: extendedReference.usrID) {
            return extendedDeclaration
        }

        return nil
    }

    func allSuperDeclarationsInOverrideChain(from decl: Declaration) -> Set<Declaration> {
        guard decl.isOverride else { return [] }

        let overridenDecl = decl.related
            .filter { $0.declarationKind == decl.kind && $0.name == decl.name }
            .compactMap { declaration(withUsrID: $0.usrID) }
            .min()

        guard let overridenDecl else {
            return []
        }

        return Set([overridenDecl]).union(allSuperDeclarationsInOverrideChain(from: overridenDecl))
    }

    func baseDeclaration(fromOverride decl: Declaration) -> (Declaration, Bool) {
        guard decl.isOverride else { return (decl, true) }

        let baseDecl = references(to: decl)
            .filter {
                $0.kind == .related &&
                    $0.declarationKind == decl.kind &&
                    $0.name == decl.name
            }
            .compactMap(\.parent)
            .min()

        guard let baseDecl else {
            // Base reference is external, return the current function as it's the closest.
            return (decl, false)
        }

        return baseDeclaration(fromOverride: baseDecl)
    }

    func allOverrideDeclarations(fromBase decl: Declaration) -> Set<Declaration> {
        decl.relatedEquivalentReferences
            .compactMap { declaration(withUsrID: $0.usrID) }
            .reduce(into: .init()) { result, decl in
                guard decl.isOverride else { return }

                result.insert(decl)
                result.formUnion(allOverrideDeclarations(fromBase: decl))
            }
    }

    func isCodable(_ decl: Declaration) -> Bool {
        let codableTypes = ["Codable", "Decodable", "Encodable"] + configuration.externalEncodableProtocols + configuration.externalCodableProtocols

        return inheritedTypeReferences(of: decl).contains {
            [.protocol, .typealias].contains($0.declarationKind) && codableTypes.contains($0.name)
        }
    }

    func isEncodable(_ decl: Declaration) -> Bool {
        let encodableTypes = ["Encodable"] + configuration.externalEncodableProtocols + configuration.externalCodableProtocols

        return inheritedTypeReferences(of: decl).contains {
            [.protocol, .typealias].contains($0.declarationKind) && encodableTypes.contains($0.name)
        }
    }

    private func validateNoDeclarationConflict(for declaration: Declaration) throws {
        for usrID in declaration.usrIDs {
            let idx = usrID.rawValue
            if idx < declarationsByUsrID.count, let existingDecl = declarationsByUsrID[idx] {
                let usr = usrInterner.string(for: usrID)
                throw PeripheryError.sourceGraphIntegrityError(message: """
                Declaration conflict detected: a declaration with the USR '\(usr)' has already been indexed.
                Existing declaration: \(existingDecl), declared in modules: \(existingDecl.location.file.modules.sorted())
                Conflicting declaration: \(declaration), declared in modules: \(declaration.location.file.modules.sorted())
                Make sure all build modules are uniquely named.
                """)
            }
        }
    }
}
