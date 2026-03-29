import Extensions
import Foundation
import SystemPackage

public struct Location {
    public let file: SourceFile
    public let line: Int
    public let column: Int

    private let hashValueCache: Int

    public init(file: SourceFile, line: Int, column: Int) {
        self.file = file
        self.line = line
        self.column = column
        var hasher = Hasher()
        hasher.combine(file)
        hasher.combine(line)
        hasher.combine(column)
        hashValueCache = hasher.finalize()
    }

    // MARK: - Private

    private func buildDescription(path: String) -> String {
        [path, line.description, column.description].joined(separator: ":")
    }
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
        buildDescription(path: file.path.string)
    }

    public var shortDescription: String {
        buildDescription(path: file.path.lastComponent?.string ?? "")
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
