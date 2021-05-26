import Foundation
import PathKit

public class SourceFile {
    public typealias ImportStatement = (parts: [String], isTestable: Bool)

    public let path: Path
    public let modules: Set<String>
    public var importStatements: [ImportStatement] = []

    init(path: Path, modules: Set<String>) {
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
        lhs.path < rhs.path
    }
}
