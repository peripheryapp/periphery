import Foundation

public struct SourceLocation {
    let file: SourceFile
    let line: Int64?
    let column: Int64?
    let offset: Int64?

    private var descriptionInternal: String = ""
    private var shortDescriptionInternal: String = ""

    init(file: SourceFile, line: Int64?, column: Int64?, offset: Int64? = nil) {
        self.file = file
        self.line = line
        self.column = column
        self.offset = offset
        self.descriptionInternal = buildDescription(path: file.path.string)
        self.shortDescriptionInternal = buildDescription(path: file.path.lastComponent)
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
    public var hashValue: Int {
        return description.hashValue
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
