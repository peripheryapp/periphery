import Foundation

public class SourceLocation {
    public let file: SourceFile
    public let line: Int64
    public let column: Int64

    init(file: SourceFile, line: Int64, column: Int64) {
        self.file = file
        self.line = line
        self.column = column
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
    public static func == (lhs: SourceLocation, rhs: SourceLocation) -> Bool {
        let fileIsEqual = lhs.file == rhs.file
        let lineIsEqual = lhs.line == rhs.line
        let columnIsEqual = lhs.column == rhs.column

        return fileIsEqual && lineIsEqual && columnIsEqual
    }
}

extension SourceLocation: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(file)
        hasher.combine(line)
        hasher.combine(column)
    }
}

extension SourceLocation: CustomStringConvertible {
    public var description: String {
        return descriptionInternal
    }

    var shortDescription: String {
        return shortDescriptionInternal
    }
}

extension SourceLocation: Comparable {
    public static func < (lhs: SourceLocation, rhs: SourceLocation) -> Bool {
        if lhs.file == rhs.file {
            if lhs.line == rhs.line {
                return lhs.column < rhs.column
            }

            return lhs.line < rhs.line
        }

        return lhs.file < rhs.file
    }
}
