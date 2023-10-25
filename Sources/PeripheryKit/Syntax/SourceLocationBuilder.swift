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
                              line: location.line,
                              column: location.column)
    }
 }
