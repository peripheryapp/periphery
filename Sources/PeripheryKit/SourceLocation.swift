import Foundation
import PathKit

public class SourceLocation {
    let file: Path
    let line: Int64?
    let column: Int64?
    let offset: Int64?

    init(file: Path, line: Int64?, column: Int64?, offset: Int64? = nil) {
        self.file = file
        self.line = line
        self.column = column
        self.offset = offset
    }

    // MARK: - Private

    private func buildDescription(path: String) -> String {
        var parts: [String] = [path]

        if let line = line {
            parts.append(line.description)
        }

        if let column = column {
            parts.append(column.description)
        }

        return parts.joined(separator: ":")
    }

    private lazy var descriptionInternal: String = {
        buildDescription(path: file.string)
    }()

    private lazy var shortDescriptionInternal: String = {
        buildDescription(path: file.lastComponent)
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
