import SwiftSyntax

final class SourceLocationBuilder {
    private let file: SourceFile
    private let locationConverter: SourceLocationConverter

    init(file: SourceFile, locationConverter: SourceLocationConverter) {
        self.file = file
        self.locationConverter = locationConverter
    }

    func location(at position: AbsolutePosition) -> SourceLocation {
        let location = locationConverter.location(for: position)
        return SourceLocation(file: file,
                              line: Int64(location.line ?? 0),
                              column: Int64(location.column ?? 0))
    }
 }
