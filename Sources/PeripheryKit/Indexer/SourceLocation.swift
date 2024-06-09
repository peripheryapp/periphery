import Foundation
import SystemPackage

class SourceLocation {
    let file: SourceFile
    let line: Int
    let column: Int

    private let hashValueCache: Int

    init(file: SourceFile, line: Int, column: Int) {
        self.file = file
        self.line = line
        self.column = column
        self.hashValueCache = [file.hashValue, line, column].hashValue
    }

    func relativeTo(_ path: FilePath) -> SourceLocation {
        let newPath = file.path.relativeTo(path)
        let newFile = SourceFile(path: newPath, modules: file.modules)
        newFile.importStatements = file.importStatements
        return SourceLocation(file: newFile, line: line, column: column)
    }

    // MARK: - Private

    private func buildDescription(path: String) -> String {
        [path, line.description, column.description].joined(separator: ":")
    }

    private lazy var descriptionInternal: String = {
        buildDescription(path: file.path.string)
    }()

    private lazy var shortDescriptionInternal: String = {
        buildDescription(path: file.path.lastComponent?.string ?? "")
    }()
}

extension SourceLocation: Equatable {
    static func == (lhs: SourceLocation, rhs: SourceLocation) -> Bool {
        lhs.file == rhs.file && lhs.line == rhs.line && lhs.column == rhs.column
    }
}

extension SourceLocation: Hashable {
    func hash(into hasher: inout Hasher) {

        hasher.combine(hashValueCache)
    }
}

extension SourceLocation: CustomStringConvertible {
    var description: String {
        return descriptionInternal
    }

    var shortDescription: String {
        return shortDescriptionInternal
    }
}

extension SourceLocation: Comparable {
    static func < (lhs: SourceLocation, rhs: SourceLocation) -> Bool {
        if lhs.file == rhs.file {
            if lhs.line == rhs.line {
                return lhs.column < rhs.column
            }

            return lhs.line < rhs.line
        }

        return lhs.file < rhs.file
    }
}
