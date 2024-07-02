import Foundation
import SystemPackage

public class SourceFile {
    public let path: FilePath
    public let modules: Set<String>
    public var importStatements: [ImportStatement] = []

    public init(path: FilePath, modules: Set<String>) {
        self.path = path
        self.modules = modules
    }
}

extension SourceFile: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(path)
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
