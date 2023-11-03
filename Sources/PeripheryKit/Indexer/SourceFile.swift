import Foundation
import SystemPackage

class SourceFile {
    typealias ImportStatement = (parts: [String], isTestable: Bool)

    let path: FilePath
    let modules: Set<String>
    var importStatements: [ImportStatement] = []

    init(path: FilePath, modules: Set<String>) {
        self.path = path
        self.modules = modules
    }
}

extension SourceFile: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(path)
    }
}

extension SourceFile: Equatable {
    static func == (lhs: SourceFile, rhs: SourceFile) -> Bool {
        lhs.path == rhs.path
    }
}

extension SourceFile: Comparable {
    static func < (lhs: SourceFile, rhs: SourceFile) -> Bool {
        lhs.path.string < rhs.path.string
    }
}
