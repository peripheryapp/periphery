import Foundation
import SystemPackage

public class Location {
    public let file: SourceFile
    public let line: Int
    public let column: Int

    private let hashValueCache: Int

    public init(file: SourceFile, line: Int, column: Int) {
        self.file = file
        self.line = line
        self.column = column
        hashValueCache = [file.hashValue, line, column].hashValue
    }

    func relativeTo(_ path: FilePath) -> Location {
        let newPath = file.path.relativeTo(path)
        let newFile = SourceFile(path: newPath, modules: file.modules)
        newFile.importStatements = file.importStatements
        return Location(file: newFile, line: line, column: column)
    }

    // MARK: - Private

    private func buildDescription(path: String) -> String {
        [path, line.description, column.description].joined(separator: ":")
    }

    private lazy var descriptionInternal: String = buildDescription(path: file.path.string)

    private lazy var shortDescriptionInternal: String = buildDescription(path: file.path.lastComponent?.string ?? "")
}

extension Location: Equatable {
    public static func == (lhs: Location, rhs: Location) -> Bool {
        lhs.file == rhs.file && lhs.line == rhs.line && lhs.column == rhs.column
    }
}

extension Location: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(hashValueCache)
    }
}

extension Location: CustomStringConvertible {
    public var description: String {
        descriptionInternal
    }

    public var shortDescription: String {
        shortDescriptionInternal
    }
}

extension Location: Comparable {
    public static func < (lhs: Location, rhs: Location) -> Bool {
        if lhs.file == rhs.file {
            if lhs.line == rhs.line {
                return lhs.column < rhs.column
            }

            return lhs.line < rhs.line
        }

        return lhs.file < rhs.file
    }
}
