import TSCclibc
import TSCBasic
import PathKit

struct IndexStoreUnit {
    fileprivate let name: String
}

struct IndexStoreRecord {
    fileprivate let name: String
}

struct IndexStoreSymbol {

    enum Kind: UInt32 {
        case unknown = 0
        case module = 1
        case namespace = 2
        case namespacealias = 3
        case macro = 4
        case `enum` = 5
        case `struct` = 6
        case `class` = 7
        case `protocol` = 8
        case `extension` = 9
        case union = 10
        case `typealias` = 11
        case function = 12
        case variable = 13
        case field = 14
        case enumconstant = 15
        case instancemethod = 16
        case classmethod = 17
        case staticmethod = 18
        case instanceproperty = 19
        case classproperty = 20
        case staticproperty = 21
        case constructor = 22
        case destructor = 23
        case conversionfunction = 24
        case parameter = 25
        case using = 26
        case commenttag = 1000
    }

    enum SubKind: UInt32 {
        case none = 0
        case cxxCopyConstructor = 1
        case cxxMoveConstructor = 2
        case accessorGetter = 3
        case accessorSetter = 4
        case usingTypeName = 5
        case usingValue = 6

        case swiftAccessorWillSet = 1000
        case swiftAccessorDidSet = 1001
        case swiftAccessorAddressor = 1002
        case swiftAccessorMutableAddressor = 1003
        case swiftExtensionOfStruct = 1004
        case swiftExtensionOfClass = 1005
        case swiftExtensionOfEnum = 1006
        case swiftExtensionOfProtocol = 1007
        case swiftPrefixOperator = 1008
        case swiftPostfixOperator = 1009
        case swiftInfixOperator = 1010
        case swiftSubscript = 1011
        case swiftAssociatedtype = 1012
        case swiftGenericTypeParam = 1013
        case swiftAccessorRead = 1014
        case swiftAccessorModify = 1015
    }
    
    let usr: String
    let name: String
    let kind: Kind
    let subKind: SubKind
}

struct IndexStoreOccurrence {
    struct Role: OptionSet, Hashable {

        let rawValue: UInt64

        static let declaration = Role(rawValue: INDEXSTORE_SYMBOL_ROLE_DECLARATION)
        static let definition = Role(rawValue: INDEXSTORE_SYMBOL_ROLE_DEFINITION)
        static let reference = Role(rawValue: INDEXSTORE_SYMBOL_ROLE_REFERENCE)
        static let read = Role(rawValue: INDEXSTORE_SYMBOL_ROLE_READ)
        static let write = Role(rawValue: INDEXSTORE_SYMBOL_ROLE_WRITE)
        static let call = Role(rawValue: INDEXSTORE_SYMBOL_ROLE_CALL)
        static let `dynamic` = Role(rawValue: INDEXSTORE_SYMBOL_ROLE_DYNAMIC)
        static let addressOf = Role(rawValue: INDEXSTORE_SYMBOL_ROLE_ADDRESSOF)
        static let implicit = Role(rawValue: INDEXSTORE_SYMBOL_ROLE_IMPLICIT)

        static let childOf = Role(rawValue: INDEXSTORE_SYMBOL_ROLE_REL_CHILDOF)
        static let baseOf = Role(rawValue: INDEXSTORE_SYMBOL_ROLE_REL_BASEOF)
        static let overrideOf = Role(rawValue: INDEXSTORE_SYMBOL_ROLE_REL_OVERRIDEOF)
        static let receivedBy = Role(rawValue: INDEXSTORE_SYMBOL_ROLE_REL_RECEIVEDBY)
        static let calledBy = Role(rawValue: INDEXSTORE_SYMBOL_ROLE_REL_CALLEDBY)
        static let extendedBy = Role(rawValue: INDEXSTORE_SYMBOL_ROLE_REL_EXTENDEDBY)
        static let accessorOf = Role(rawValue: INDEXSTORE_SYMBOL_ROLE_REL_ACCESSOROF)
        static let containedBy = Role(rawValue: INDEXSTORE_SYMBOL_ROLE_REL_CONTAINEDBY)
        static let ibTypeOf = Role(rawValue: INDEXSTORE_SYMBOL_ROLE_REL_IBTYPEOF)
        static let specializationOf = Role(rawValue: INDEXSTORE_SYMBOL_ROLE_REL_SPECIALIZATIONOF)

        static let canonical = Role(rawValue: 1 << 63)

        static let all = Role(rawValue: ~0)

        init(rawValue: UInt64) {
            self.rawValue = rawValue
        }
        init(rawValue: indexstore_symbol_role_t) {
            self.rawValue = UInt64(rawValue.rawValue)
        }
    }

    struct Location: Equatable {
        var path: String
        var isSystem: Bool
        var line: Int64
        var column: Int64
    }

    let roles: Role
    let symbol: IndexStoreSymbol
    let location: Location
}

final class IndexStore {
    fileprivate var indexStoreLibCache = LazyCache(createIndexStoreLib)
    private func createIndexStoreLib() -> Result<AbsolutePath, Error> {
        if let toolchainDir = ProcessEnv.vars["TOOLCHAIN_DIR"] {
            return .success(AbsolutePath(toolchainDir).appending(components: "usr", "lib", "libIndexStore.dylib"))
        }
        return Result {
            let developerDirStr = try Process.checkNonZeroExit(arguments: ["/usr/bin/xcode-select", "--print-path"])
            return AbsolutePath(developerDirStr).appending(
                components: "Toolchains", "XcodeDefault.xctoolchain",
                            "usr", "lib", "libIndexStore.dylib"
            )
        }
    }

    let store: indexstore_t
    let api: IndexStoreAPI

    private init(store: indexstore_t, api: IndexStoreAPI) {
        self.store = store
        self.api = api
    }

    static func open(store path: AbsolutePath, api: IndexStoreAPI) throws -> IndexStore {
        guard let store = try api.throwsfy({ api.fn.store_create(path.pathString, &$0) }) else {
            throw PeripheryKitError.indexStoreError(message: "Unable to open store at \(path)")
        }
        return IndexStore(store: store, api: api)
    }

    fileprivate class Context<T> {
        let api: IndexStoreAPI
        var content: T
        var error: Error? = nil
        init(_ content: T, api: IndexStoreAPI) {
            self.content = content
            self.api = api
        }
    }

    func forEachUnits(_ next: (IndexStoreUnit) -> Bool) {
        typealias Ctx = Context<(IndexStoreUnit) -> Bool>
        withoutActuallyEscaping(next) { next in
            let handler = Ctx(next, api: api)
            let ctx = Unmanaged.passUnretained(handler).toOpaque()
            _ = api.fn.store_units_apply_f(store, false.bit, ctx) { ctx, unitName -> Bool in
                let ctx = Unmanaged<Ctx>.fromOpaque(ctx!).takeUnretainedValue()
                let unit = IndexStoreUnit(name: unitName.toSwiftString())
                return ctx.content(unit)
            }
        }
    }

    private func forEachRecordDependencies(for unit: IndexStoreUnit, _ next: (indexstore_unit_dependency_t) throws -> Bool) throws {
        guard let reader = try api.throwsfy({ api.fn.unit_reader_create(store, unit.name, &$0) }) else {
            throw PeripheryKitError.indexStoreError(message: "Unable to create unit reader for \(unit.name)")
        }
        typealias Ctx = Context<((indexstore_unit_dependency_t) throws -> Bool)>
        try withoutActuallyEscaping(next) { next in
            let handler = Ctx(next, api: api)
            let ctx = Unmanaged.passUnretained(handler).toOpaque()
            _ = api.fn.unit_reader_dependencies_apply_f(reader, ctx) { ctx, dependency -> Bool in
                let ctx = Unmanaged<Ctx>.fromOpaque(ctx!).takeUnretainedValue()
                switch ctx.api.fn.unit_dependency_get_kind(dependency) {
                case INDEXSTORE_UNIT_DEPENDENCY_RECORD:
                    do { return try ctx.content(dependency!) }
                    catch {
                        ctx.error = error
                        return false
                    }
                case INDEXSTORE_UNIT_DEPENDENCY_UNIT: break
                case INDEXSTORE_UNIT_DEPENDENCY_FILE: break
                default: fatalError("unreachable")
                }
                return true
            }
            if let error = handler.error {
                throw error
            }
        }
    }

    func forEachOccurrences(for unit: IndexStoreUnit, _ next: (IndexStoreOccurrence) -> Bool) throws {
        try forEachRecordDependencies(for: unit) { (record) -> Bool in
            let recordName = api.fn.unit_dependency_get_name(record).toSwiftString()
            let recordPath = api.fn.unit_dependency_get_filepath(record).toSwiftString()
            let isSystem = api.fn.unit_dependency_is_system(record)
            guard let reader = try api.throwsfy({ api.fn.record_reader_create(store, recordName, &$0) }) else {
                throw PeripheryKitError.indexStoreError(message: "Unable to create record reader for \(recordName)")
            }
            typealias Ctx = Context<(
                next: (IndexStoreOccurrence) -> Bool,
                filepath: String,
                isSystem: Bool
            )>
            withoutActuallyEscaping(next) { next in
                let handler = Ctx((next, recordPath, isSystem), api: api)
                let ctx = Unmanaged.passUnretained(handler).toOpaque()
                _ = api.fn.record_reader_occurrences_apply_f(reader, ctx) { ctx, occurrence -> Bool in
                    let ctx = Unmanaged<Ctx>.fromOpaque(ctx!).takeUnretainedValue()
                    let symbolRoles = IndexStoreOccurrence.Role(rawValue: ctx.api.fn.occurrence_get_roles(occurrence))
                    let symbol = ctx.api.fn.occurrence_get_symbol(occurrence)
                    let symbolKind = IndexStoreSymbol.Kind(rawValue: ctx.api.fn.symbol_get_kind(symbol).rawValue)!
                    let symbolSubKind = IndexStoreSymbol.SubKind(rawValue: ctx.api.fn.symbol_get_subkind(symbol).rawValue)!
                    let symbolUsr = ctx.api.fn.symbol_get_usr(symbol).toSwiftString()
                    let symbolName = ctx.api.fn.symbol_get_name(symbol).toSwiftString()
                    let sym = IndexStoreSymbol(
                        usr: symbolUsr, name: symbolName,
                        kind: symbolKind, subKind: symbolSubKind
                    )
                    var line: UInt32 = 0
                    var column: UInt32 = 0
                    ctx.api.fn.occurrence_get_line_col(occurrence, &line, &column)
                    let location = IndexStoreOccurrence.Location(
                        path: ctx.content.filepath, isSystem: ctx.content.isSystem,
                        line: Int64(line), column: Int64(column)
                    )
                    let occ = IndexStoreOccurrence(roles: symbolRoles, symbol: sym, location: location)
                    return ctx.content.next(occ)
                }
            }
            return true
        }
    }
}

extension Bool {
    fileprivate var bit: UInt32 {
        self ? 1 : 0
    }
}

final class IndexStoreAPI {

    struct Dylib {
        let handle: UnsafeMutableRawPointer
    }

    let path: AbsolutePath
    let dylib: Dylib

    let fn: indexstore_functions_t

    init(dylib path: AbsolutePath) throws {
        self.path = path
        self.dylib = Dylib(handle: dlopen(path.pathString, RTLD_LAZY | RTLD_LOCAL | RTLD_FIRST))
        var api = indexstore_functions_t()
        func requireSym<T>(_ dylib: Dylib, _ symbol: String) throws -> T {
            guard let sym = dlsym(dylib.handle, symbol) else {
                throw PeripheryKitError.indexStoreError(message: "Missing required symbol: \(symbol)")
            }
            return unsafeBitCast(sym, to: T.self)
        }

        api.store_create = try requireSym(dylib, "indexstore_store_create")
        api.store_units_apply_f = try requireSym(dylib, "indexstore_store_units_apply_f")
        api.error_get_description = try requireSym(dylib, "indexstore_error_get_description")
        self.fn = api
    }

    func throwsfy<T>(_ fn: (inout indexstore_error_t?) -> T) throws -> T {
        var error: indexstore_error_t? = nil
        let ret = fn(&error)

        if let error = error {
            guard let desc = self.fn.error_get_description(error) else {
                throw PeripheryKitError.indexStoreError(message: "Unable to get description for error: \(error)")
            }
            throw PeripheryKitError.indexStoreError(message: String(cString: desc))
        }
        return ret
    }
}

extension indexstore_string_ref_t {
    fileprivate func toSwiftString() -> String {
        String(
            bytesNoCopy: UnsafeMutableRawPointer(mutating: data),
            length: length,
            encoding: .utf8,
            freeWhenDone: false
        )!
    }
}
