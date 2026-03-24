import Foundation
import SystemPackage

public final class SourceFile {
    public let path: FilePath
    public let modules: Set<String>
    public var importStatements: [ImportStatement] = []
    public var importsSwiftTesting = false

    // Pre-computed to avoid re-hashing the FilePath on every Set/Dictionary operation,
    // since SourceFile is used as a key in many hot-path collections.
    private let hashValueCache: Int

    public init(path: FilePath, modules: Set<String>) {
        self.path = path
        self.modules = modules
        hashValueCache = path.hashValue
    }
}

extension SourceFile: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(hashValueCache)
    }
}

extension SourceFile: Equatable {
    public static func == (lhs: SourceFile, rhs: SourceFile) -> Bool {
        lhs.path == rhs.path
    }
}

extension SourceFile: Comparable {
    public static func < (lhs: SourceFile, rhs: SourceFile) -> Bool {
        lhs.path.string < rhs.path.string
    }
}
